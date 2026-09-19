"""Train SegFormer DetHead standalone (Track B, plan.md หัวข้อ 32-36).

ไม่ผ่าน mmseg Runner เพราะ feedback มีแค่ image tag ไม่มี mask:
- backbone + seg head แช่แข็ง เทรนแค่ DetHead (~1K params)
- input: CSV `path,label` (label 1=ตัดต่อ 0=จริง) หรือ derive จาก mask ด้วย --mask-dir
- loss: BCE(hard) + [ออปชัน] α*BCE(soft teacher score จาก --teacher-csv)
- output: work_dir/det_head.pth + train_log.json (config/data hash, metrics)

ตัวอย่าง bootstrap จาก with_mask:
  python train_det.py --config work_dirs/v1.0.6/segformer_mit-b2-v11.py \\
      --checkpoint work_dirs/v1.0.6/best_mIoU_iter_195000.pth \\
      --img-dir /home/panuwat/Pictures/Test-Cases/with_mask \\
      --derive-from-mask --work-dir work_dirs/det_bootstrap --epochs 20
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
from torch.utils.data import DataLoader, Dataset

from det_head import DetHead, build_seg_model, freeze_seg

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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--config', required=True)
    ap.add_argument('--checkpoint', required=True)
    ap.add_argument('--work-dir', required=True)
    ap.add_argument('--csv', default=None, help='CSV path,label[,teacher]')
    ap.add_argument('--img-dir', default=None, help='with_mask tree + --derive-from-mask')
    ap.add_argument('--derive-from-mask', action='store_true')
    ap.add_argument('--teacher-csv', default=None, help='CSV path,score (soft target)')
    ap.add_argument('--alpha', type=float, default=0.0, help='น้ำหนัก distillation loss')
    ap.add_argument('--epochs', type=int, default=20)
    ap.add_argument('--lr', type=float, default=1e-4)
    ap.add_argument('--batch-size', type=int, default=8)
    ap.add_argument('--val-ratio', type=float, default=0.2)
    ap.add_argument('--patience', type=int, default=5)
    ap.add_argument('--seed', type=int, default=42)
    ap.add_argument('--device', default='cuda' if torch.cuda.is_available() else 'cpu')
    args = ap.parse_args()

    random.seed(args.seed)
    torch.manual_seed(args.seed)
    os.makedirs(args.work_dir, exist_ok=True)

    if args.derive_from_mask and args.img_dir:
        items = collect_from_masks(args.img_dir)
    elif args.csv:
        items = load_csv(args.csv)
    else:
        raise ValueError('ต้องระบุ --csv หรือ (--img-dir + --derive-from-mask)')

    if args.teacher_csv:
        teach = {}
        with open(args.teacher_csv) as f:
            for row in csv.DictReader(f):
                teach[row['path']] = float(row['score'])
        items = [(p, y, teach.get(p)) for p, y, _ in items]

    train_items, val_items = split(items, args.val_ratio, args.seed)
    print(f'train={len(train_items)} val={len(val_items)} '
          f'(pos={sum(x[1] for x in items)}/{len(items)})')
    train_loader = DataLoader(ImgLabelDataset(train_items),
                              batch_size=args.batch_size, shuffle=True)
    val_loader = DataLoader(ImgLabelDataset(val_items),
                            batch_size=args.batch_size)

    device = torch.device(args.device)
    seg = build_seg_model(args.config, args.checkpoint, 'cpu')
    seg.to(device).eval()
    freeze_seg(seg)
    det = DetHead().to(device)
    opt = torch.optim.AdamW(det.parameters(), lr=args.lr)
    bce = nn.BCEWithLogitsLoss()

    best_acc, best_state, bad = -1.0, None, 0
    history = []
    for epoch in range(args.epochs):
        det.train()
        for x, y, t, _ in train_loader:
            x, y = x.to(device), y.to(device)
            with torch.no_grad():
                feats = seg.extract_feat(x)
            logit = det([f.detach() for f in feats])
            loss = bce(logit, y)
            if args.alpha > 0:
                mask = (t[:, 0] >= 0)
                if mask.any():
                    loss = loss + args.alpha * bce(
                        logit[mask], t.to(device)[mask])
            opt.zero_grad()
            loss.backward()
            opt.step()
        vloss, vacc = evaluate(seg, det, val_loader, device, args.alpha)
        history.append({'epoch': epoch + 1, 'val_loss': vloss, 'val_acc': vacc})
        print(f'epoch {epoch + 1}/{args.epochs} val_loss={vloss:.4f} val_acc={vacc:.4f}',
              flush=True)
        if vacc > best_acc:
            best_acc = vacc
            best_state = {k: v.cpu().clone() for k, v in det.state_dict().items()}
            bad = 0
        else:
            bad += 1
            if bad >= args.patience:
                print(f'early stop (best val_acc={best_acc:.4f})')
                break

    det.load_state_dict(best_state)
    out = os.path.join(args.work_dir, 'det_head.pth')
    data_hash = hashlib.sha1(
        ''.join(sorted(p for p, _, _ in items)).encode()).hexdigest()
    torch.save({'state_dict': best_state,
                'meta': {'seg_checkpoint': os.path.basename(args.checkpoint),
                         'seg_checkpoint_sha1': sha1_of_file(args.checkpoint),
                         'data_hash': data_hash,
                         'n_train': len(train_items), 'n_val': len(val_items),
                         'alpha': args.alpha, 'lr': args.lr, 'seed': args.seed,
                         'best_val_acc': best_acc,
                         'time': time.strftime('%Y-%m-%d %H:%M:%S')}}, out)
    with open(os.path.join(args.work_dir, 'train_log.json'), 'w') as f:
        json.dump(history, f, indent=1)
    print(f'saved {out} best_val_acc={best_acc:.4f}')


if __name__ == '__main__':
    main()
