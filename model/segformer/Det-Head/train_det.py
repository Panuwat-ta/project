"""Train SegFormer DetHead standalone (Track B, plan.md หัวข้อ 32-36).

ไม่ผ่าน mmseg Runner เพราะ feedback มีแค่ image tag ไม่มี mask:
- backbone + seg head แช่แข็ง เทรนแค่ DetHead (~1K params)
- input: CSV `path,label` (label 1=ตัดต่อ 0=จริง) หรือ derive จาก mask ด้วย --mask-dir
- loss: BCE(hard) + [ออปชัน] α*BCE(soft teacher score จาก --teacher-csv)
- output: work_dir/det_head.pth + train_log.json (config/data hash, metrics)
- recommended: precompute_det_features.py + --feature-cache เมื่อ SegFormer ถูก freeze

ตัวอย่าง bootstrap จาก with_mask:
  python Det-Head/train_det.py --config work_dirs/v1.0.6/segformer_mit-b2-v11.py \\
      --checkpoint work_dirs/v1.0.6/best_mIoU_iter_195000.pth \\
      --img-dir /home/panuwat/Pictures/Test-Cases/with_mask \\
      --derive-from-mask --work-dir Det-Head/det_bootstrap --epochs 20
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import random
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import torch
import torch.nn as nn
import numpy as np
from PIL import Image
from torch.utils.data import DataLoader, Dataset, WeightedRandomSampler

from det_head import DetHead, build_det_head, build_seg_model, freeze_seg, load_det

MEAN = [123.675, 116.28, 103.53]
STD = [58.395, 57.12, 57.375]
SIZE = (512, 512)


def sha1_of_file(path: str) -> str:
    h = hashlib.sha1()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


class ImgLabelDataset(Dataset):
    def __init__(self, items):
        self.items = items  # (img_path, label, teacher_or_None)

    def __len__(self):
        return len(self.items)

    def __getitem__(self, i):
        path, label, teacher = self.items[i]
        im = Image.open(path).convert('RGB').resize(SIZE, Image.BILINEAR)
        x = torch.from_numpy(np.asarray(im, dtype=np.float32)).permute(2, 0, 1)
        mean = torch.tensor(MEAN).view(3, 1, 1)
        std = torch.tensor(STD).view(3, 1, 1)
        x = (x - mean) / std
        y = torch.tensor([label], dtype=torch.float32)
        t = torch.tensor([teacher if teacher is not None else -1.0],
                         dtype=torch.float32)
        return x, y, t, path


class FeatureCacheDataset(Dataset):
    """Memory-mapped pooled SegFormer features created by precompute_det_features.py."""

    def __init__(self, cache_root: str, split_name: str, in_memory: bool = False):
        root = os.path.join(cache_root, split_name)
        mmap = None if in_memory else 'r'
        self.features = np.load(os.path.join(root, 'features.npy'), mmap_mode=mmap)
        self.labels = np.load(os.path.join(root, 'labels.npy'), mmap_mode=mmap)
        self.teachers = np.load(os.path.join(root, 'teachers.npy'), mmap_mode=mmap)
        if in_memory:
            self.features = np.asarray(self.features).copy()
            self.labels = np.asarray(self.labels).copy()
            self.teachers = np.asarray(self.teachers).copy()
        if not (len(self.features) == len(self.labels) == len(self.teachers)):
            raise ValueError(f'cache length mismatch: {root}')
        if self.features.ndim != 2 or self.features.shape[1] not in (1024, 2048):
            raise ValueError(f'expected cached feature shape (N,1024/2048), got {self.features.shape}')

    def __len__(self):
        return len(self.features)

    def __getitem__(self, i):
        x = torch.from_numpy(np.array(self.features[i], dtype=np.float32, copy=True))
        y = torch.from_numpy(np.array(self.labels[i], dtype=np.float32, copy=True))
        t = torch.from_numpy(np.array(self.teachers[i], dtype=np.float32, copy=True))
        return x, y, t, i


def collect_from_masks(img_root: str):
    """เก็บ (img, label จาก mask) จาก tree แบบ with_mask/<cat>/{images,annotations}/test."""
    items = []
    for cat in sorted(os.listdir(img_root)):
        img_d = os.path.join(img_root, cat, 'images', 'test')
        ann_d = os.path.join(img_root, cat, 'annotations', 'test')
        if not os.path.isdir(img_d):
            continue
        for f in sorted(os.listdir(img_d)):
            if not f.lower().endswith(('.jpg', '.jpeg', '.png')):
                continue
            m = os.path.join(ann_d, f)
            label = 0
            if os.path.isfile(m):
                g = Image.open(m).convert('L')
                lo, hi = g.getextrema()
                label = 1 if hi > 0 else 0
            items.append((os.path.join(img_d, f), label, None))
    return items


def load_csv(path: str):
    items = []
    with open(path) as f:
        for row in csv.DictReader(f):
            items.append((row['path'], int(row['label']),
                          float(row['teacher']) if row.get('teacher') else None))
    return items


def build_source_balanced_sampler(csv_path: str, seed: int,
                                  hard_csv: str | None = None,
                                  hard_boost: float = 1.0):
    """Source-balance within each label, optionally boosting Train hard examples."""
    rows = list(csv.DictReader(open(csv_path)))
    counts = {}
    for r in rows:
        key = (int(r['label']), r.get('dataset', 'unknown'))
        counts[key] = counts.get(key, 0) + 1
    hard_paths = set()
    if hard_csv:
        hard_paths = {r['path'] for r in csv.DictReader(open(hard_csv))}
    weights = []
    hard_matched = 0
    for r in rows:
        key = (int(r['label']), r.get('dataset', 'unknown'))
        w = 1.0 / (counts[key] ** 0.5)
        if r['path'] in hard_paths:
            w *= hard_boost
            hard_matched += 1
        weights.append(w)
    mass = {0: 0.0, 1: 0.0}
    for r, w in zip(rows, weights):
        mass[int(r['label'])] += w
    for i, r in enumerate(rows):
        y = int(r['label'])
        weights[i] *= 0.5 / max(mass[y], 1e-12)
    gen = torch.Generator()
    gen.manual_seed(seed)
    sampler = WeightedRandomSampler(
        torch.as_tensor(weights, dtype=torch.double),
        num_samples=len(rows), replacement=True, generator=gen)
    return sampler, counts, hard_matched


def split(items, val_ratio: float, seed: int):
    rnd = random.Random(seed)
    pos = [x for x in items if x[1] == 1]
    neg = [x for x in items if x[1] == 0]
    rnd.shuffle(pos)
    rnd.shuffle(neg)
    nvp, nvn = int(len(pos) * val_ratio), int(len(neg) * val_ratio)
    val = pos[:nvp] + neg[:nvn]
    train = pos[nvp:] + neg[nvn:]
    rnd.shuffle(train)
    return train, val


@torch.no_grad()
def evaluate(seg, det, loader, device, alpha: float):
    seg.eval()
    det.eval()
    tot = correct = 0
    loss_sum = 0.0
    bce = nn.BCEWithLogitsLoss()
    for x, y, t, _ in loader:
        x, y = x.to(device), y.to(device)
        feats = seg.extract_feat(x)
        logit = det(feats)
        loss = bce(logit, y)
        if alpha > 0 and (t[:, 0] >= 0).all():
            loss = loss + alpha * bce(logit, t.to(device))
        loss_sum += loss.item() * len(x)
        pred = (logit.sigmoid() >= 0.5).float()
        correct += (pred == y).sum().item()
        tot += len(x)
    return loss_sum / max(tot, 1), correct / max(tot, 1)


@torch.no_grad()
def evaluate_cached(det, loader, device, alpha: float):
    det.eval()
    tot = correct = 0
    loss_sum = 0.0
    bce = nn.BCEWithLogitsLoss()
    for x, y, t, _ in loader:
        x, y = x.to(device), y.to(device)
        logit = det.forward_pooled(x)
        loss = bce(logit, y)
        if alpha > 0:
            t_dev = t.to(device, non_blocking=True)
            mask = (t_dev[:, 0] >= 0)
            if mask.any():
                loss = loss + alpha * bce(logit[mask], t_dev[mask])
        loss_sum += loss.item() * len(x)
        pred = (logit.sigmoid() >= 0.5).float()
        correct += (pred == y).sum().item()
        tot += len(x)
    return loss_sum / max(tot, 1), correct / max(tot, 1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--config', required=True)
    ap.add_argument('--checkpoint', required=True)
    ap.add_argument('--work-dir', required=True)
    ap.add_argument('--csv', default=None, help='CSV path,label[,teacher]')
    ap.add_argument('--img-dir', default=None, help='with_mask tree + --derive-from-mask')
    ap.add_argument('--derive-from-mask', action='store_true')
    ap.add_argument('--teacher-csv', default=None, help='CSV path,score (soft target)')
    ap.add_argument('--feature-cache', default=None,
                    help='cache root from precompute_det_features.py; bypass SegFormer per epoch')
    ap.add_argument('--feature-batch-size', type=int, default=2048,
                    help='batch size when training from cached 1024-d features')
    ap.add_argument('--arch', choices=['linear', 'mlp', 'mlp_gapgmp'], default='linear')
    ap.add_argument('--dropout', type=float, default=0.2)
    ap.add_argument('--init-det-checkpoint', default=None,
                    help='warm-start Det Head from an existing checkpoint')
    ap.add_argument('--source-balanced', action='store_true',
                    help='sqrt source balancing within each label for cached mode')
    ap.add_argument('--hard-mining-csv', default=None,
                    help='Train-only hard examples CSV from hard_mine_det.py')
    ap.add_argument('--hard-boost', type=float, default=1.0,
                    help='multiply sampler weight for rows in --hard-mining-csv')
    ap.add_argument('--feature-in-ram', action='store_true',
                    help='load cached features into RAM before training (~0.5 GB here)')
    ap.add_argument('--alpha', type=float, default=0.0, help='น้ำหนัก distillation loss')
    ap.add_argument('--epochs', type=int, default=20)
    ap.add_argument('--lr', type=float, default=1e-4)
    ap.add_argument('--batch-size', type=int, default=8)
    ap.add_argument('--val-ratio', type=float, default=0.2)
    ap.add_argument('--patience', type=int, default=5)
    ap.add_argument('--seed', type=int, default=42)
    ap.add_argument('--device', default='cuda' if torch.cuda.is_available() else 'cpu')
    args = ap.parse_args()
    if args.hard_boost < 1.0:
        raise ValueError('--hard-boost must be >= 1.0')
    if args.hard_mining_csv and not args.source_balanced:
        raise ValueError('--hard-mining-csv currently requires --source-balanced')

    random.seed(args.seed)
    torch.manual_seed(args.seed)
    os.makedirs(args.work_dir, exist_ok=True)
    device = torch.device(args.device)
    checkpoint_sha1 = sha1_of_file(args.checkpoint)

    if args.init_det_checkpoint:
        det = load_det(args.init_det_checkpoint, str(device))
        if getattr(det, 'arch', None) != args.arch:
            raise ValueError('init Det Head architecture mismatch')
        print(f'warm start: {args.init_det_checkpoint}')
    else:
        det = build_det_head(args.arch, args.dropout).to(device)
    opt = torch.optim.AdamW(det.parameters(), lr=args.lr)
    bce = nn.BCEWithLogitsLoss()
    best_acc, best_state, bad = -1.0, None, 0
    history = []

    if args.feature_cache:
        meta_path = os.path.join(args.feature_cache, 'metadata.json')
        with open(meta_path) as f:
            cache_meta = json.load(f)
        cached_sha1 = cache_meta.get('checkpoint_sha1')
        if cached_sha1 != checkpoint_sha1:
            raise ValueError(
                'feature cache checkpoint mismatch: '
                f'cache={cached_sha1} requested={checkpoint_sha1}')

        train_ds = FeatureCacheDataset(args.feature_cache, 'train', args.feature_in_ram)
        val_ds = FeatureCacheDataset(args.feature_cache, 'val', args.feature_in_ram)
        sampler = None
        source_counts = None
        hard_matched = 0
        if args.source_balanced:
            train_csv = next(
                x['csv'] for x in cache_meta.get('splits', [])
                if x.get('split') == 'train')
            sampler, source_counts, hard_matched = build_source_balanced_sampler(
                train_csv, args.seed, args.hard_mining_csv, args.hard_boost)
            if len(sampler.weights) != len(train_ds):
                raise ValueError('source-balanced sampler length != feature cache length')
        train_loader = DataLoader(
            train_ds, batch_size=args.feature_batch_size,
            shuffle=(sampler is None), sampler=sampler, num_workers=0,
            pin_memory=(device.type == 'cuda'))
        val_loader = DataLoader(val_ds, batch_size=args.feature_batch_size,
                                shuffle=False, num_workers=0,
                                pin_memory=(device.type == 'cuda'))
        print(f'cached mode: train={len(train_ds)} val={len(val_ds)} '
              f'vector_dim={train_ds.features.shape[1]} device={device} '
              f'arch={args.arch} source_balanced={args.source_balanced} '
              f'feature_in_ram={args.feature_in_ram}')
        if source_counts is not None:
            print('source groups:', source_counts)
        if args.hard_mining_csv:
            print(f'hard mining: matched={hard_matched} boost={args.hard_boost}')

        for epoch in range(args.epochs):
            det.train()
            for x, y, t, _ in train_loader:
                x = x.to(device, non_blocking=True)
                y = y.to(device, non_blocking=True)
                logit = det.forward_pooled(x)
                loss = bce(logit, y)
                if args.alpha > 0:
                    t_dev = t.to(device, non_blocking=True)
                    mask = (t_dev[:, 0] >= 0)
                    if mask.any():
                        loss = loss + args.alpha * bce(logit[mask], t_dev[mask])
                opt.zero_grad()
                loss.backward()
                opt.step()

            vloss, vacc = evaluate_cached(det, val_loader, device, args.alpha)
            history.append({'epoch': epoch + 1, 'val_loss': vloss, 'val_acc': vacc})
            print(f'epoch {epoch + 1}/{args.epochs} val_loss={vloss:.4f} '
                  f'val_acc={vacc:.4f}', flush=True)
            if vacc > best_acc:
                best_acc = vacc
                best_state = {k: v.cpu().clone() for k, v in det.state_dict().items()}
                bad = 0
            else:
                bad += 1
                if bad >= args.patience:
                    print(f'early stop (best val_acc={best_acc:.4f})')
                    break

        data_hash = hashlib.sha1(
            json.dumps(cache_meta.get('splits', []), sort_keys=True).encode()
        ).hexdigest()
        n_train, n_val = len(train_ds), len(val_ds)
        mode_meta = {
            'training_mode': 'cached_features',
            'feature_cache': os.path.abspath(args.feature_cache),
            'feature_cache_meta': cache_meta,
            'feature_batch_size': args.feature_batch_size,
            'source_balanced': bool(args.source_balanced),
            'hard_mining_csv': (os.path.abspath(args.hard_mining_csv)
                                if args.hard_mining_csv else None),
            'hard_boost': float(args.hard_boost),
            'hard_matched': int(hard_matched),
            'init_det_checkpoint': (os.path.abspath(args.init_det_checkpoint)
                                    if args.init_det_checkpoint else None),
            'feature_in_ram': bool(args.feature_in_ram),
            'source_groups': ({f'{k[0]}:{k[1]}': v for k, v in source_counts.items()}
                              if source_counts is not None else None),
        }
    else:
        if args.derive_from_mask and args.img_dir:
            items = collect_from_masks(args.img_dir)
        elif args.csv:
            items = load_csv(args.csv)
        else:
            raise ValueError(
                'ต้องระบุ --feature-cache, --csv หรือ (--img-dir + --derive-from-mask)')

        if args.teacher_csv:
            teach = {}
            with open(args.teacher_csv) as f:
                for row in csv.DictReader(f):
                    teach[row['path']] = float(row['score'])
            items = [(p, y, teach.get(p)) for p, y, _ in items]

        train_items, val_items = split(items, args.val_ratio, args.seed)
        print(f'online mode: train={len(train_items)} val={len(val_items)} '
              f'(pos={sum(x[1] for x in items)}/{len(items)})')
        train_loader = DataLoader(ImgLabelDataset(train_items),
                                  batch_size=args.batch_size, shuffle=True,
                                  num_workers=4, pin_memory=(device.type == 'cuda'))
        val_loader = DataLoader(ImgLabelDataset(val_items),
                                batch_size=args.batch_size,
                                num_workers=2, pin_memory=(device.type == 'cuda'))

        seg = build_seg_model(args.config, args.checkpoint, 'cpu')
        seg.to(device).eval()
        freeze_seg(seg)

        for epoch in range(args.epochs):
            det.train()
            for x, y, t, _ in train_loader:
                x = x.to(device, non_blocking=True)
                y = y.to(device, non_blocking=True)
                with torch.no_grad():
                    feats = seg.extract_feat(x)
                logit = det([f.detach() for f in feats])
                loss = bce(logit, y)
                if args.alpha > 0:
                    t_dev = t.to(device, non_blocking=True)
                    mask = (t_dev[:, 0] >= 0)
                    if mask.any():
                        loss = loss + args.alpha * bce(logit[mask], t_dev[mask])
                opt.zero_grad()
                loss.backward()
                opt.step()

            vloss, vacc = evaluate(seg, det, val_loader, device, args.alpha)
            history.append({'epoch': epoch + 1, 'val_loss': vloss, 'val_acc': vacc})
            print(f'epoch {epoch + 1}/{args.epochs} val_loss={vloss:.4f} '
                  f'val_acc={vacc:.4f}', flush=True)
            if vacc > best_acc:
                best_acc = vacc
                best_state = {k: v.cpu().clone() for k, v in det.state_dict().items()}
                bad = 0
            else:
                bad += 1
                if bad >= args.patience:
                    print(f'early stop (best val_acc={best_acc:.4f})')
                    break

        data_hash = hashlib.sha1(
            ''.join(sorted(p for p, _, _ in items)).encode()).hexdigest()
        n_train, n_val = len(train_items), len(val_items)
        mode_meta = {'training_mode': 'online_features', 'batch_size': args.batch_size}

    if best_state is None:
        raise RuntimeError('training produced no checkpoint')
    det.load_state_dict(best_state)
    out = os.path.join(args.work_dir, 'det_head.pth')
    meta = {
        'seg_checkpoint': os.path.basename(args.checkpoint),
        'seg_checkpoint_sha1': checkpoint_sha1,
        'config': os.path.abspath(args.config),
        'data_hash': data_hash,
        'n_train': n_train,
        'n_val': n_val,
        'alpha': args.alpha,
        'lr': args.lr,
        'seed': args.seed,
        'det_arch': args.arch,
        'dropout': args.dropout,
        'best_val_acc': best_acc,
        'time': time.strftime('%Y-%m-%d %H:%M:%S'),
        **mode_meta,
    }
    torch.save({'state_dict': best_state, 'meta': meta}, out)
    with open(os.path.join(args.work_dir, 'train_log.json'), 'w') as f:
        json.dump({'meta': meta, 'history': history}, f, indent=2)
    print(f'saved {out} best_val_acc={best_acc:.4f}')


if __name__ == '__main__':
    main()
