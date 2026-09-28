"""Precompute frozen SegFormer features for Det Head training.

Creates NumPy memmaps per split so SegFormer forward runs once, not every epoch.
Input CSV columns: path,label[,teacher]. Labels: 0=authentic, 1=manipulated.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import time
from contextlib import nullcontext

import numpy as np
import torch
from numpy.lib.format import open_memmap
from torch.utils.data import DataLoader

from det_head import STAGE_CHANNELS, build_seg_model, freeze_seg, pool_stage_features
from train_det import ImgLabelDataset, load_csv, sha1_of_file

VECTOR_DIM = sum(STAGE_CHANNELS)


def sha1_text(path: str) -> str:
    h = hashlib.sha1()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def amp_context(device: torch.device, enabled: bool):
    if enabled and device.type == 'cuda':
        return torch.autocast(device_type='cuda', dtype=torch.float16)
    return nullcontext()


def write_paths(path: str, items) -> None:
    with open(path, 'w', newline='') as f:
        w = csv.writer(f)
        w.writerow(['index', 'path', 'label', 'teacher'])
        for i, (img, label, teacher) in enumerate(items):
            w.writerow([i, img, label, '' if teacher is None else teacher])


def extract_split(seg, split_name: str, csv_path: str, out_root: str,
                  device: torch.device, batch_size: int, workers: int,
                  use_amp: bool, limit: int | None = None) -> dict:
    items = load_csv(csv_path)
    if limit is not None:
        items = items[:limit]
    if not items:
        raise ValueError(f'{split_name}: no samples in {csv_path}')

    split_dir = os.path.join(out_root, split_name)
    os.makedirs(split_dir, exist_ok=True)
    features = open_memmap(os.path.join(split_dir, 'features.npy'), mode='w+',
                           dtype='float32', shape=(len(items), VECTOR_DIM))
    labels = open_memmap(os.path.join(split_dir, 'labels.npy'), mode='w+',
                         dtype='float32', shape=(len(items), 1))
    teachers = open_memmap(os.path.join(split_dir, 'teachers.npy'), mode='w+',
                           dtype='float32', shape=(len(items), 1))
    loader = DataLoader(ImgLabelDataset(items), batch_size=batch_size,
                        shuffle=False, num_workers=workers,
                        pin_memory=(device.type == 'cuda'))

    offset = 0
    started = time.time()
    with torch.inference_mode():
        for step, (x, y, t, _) in enumerate(loader, 1):
            x = x.to(device, non_blocking=True)
            with amp_context(device, use_amp):
                pooled = pool_stage_features(seg.extract_feat(x))
            n = len(x)
            features[offset:offset+n] = pooled.float().cpu().numpy()
            labels[offset:offset+n] = y.numpy()
            teachers[offset:offset+n] = t.numpy()
            offset += n
            if step % 100 == 0 or offset == len(items):
                elapsed = time.time() - started
                print(f'{split_name}: {offset}/{len(items)} '
                      f'({elapsed:.1f}s)', flush=True)

    features.flush(); labels.flush(); teachers.flush()
    write_paths(os.path.join(split_dir, 'paths.csv'), items)
    return {
        'split': split_name,
        'csv': os.path.abspath(csv_path),
        'csv_sha1': sha1_text(csv_path),
        'samples': len(items),
        'features_shape': [len(items), VECTOR_DIM],
        'dtype': 'float32',
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--config', required=True)
    ap.add_argument('--checkpoint', required=True)
    ap.add_argument('--train-csv', required=True)
    ap.add_argument('--val-csv', required=True)
    ap.add_argument('--out-dir', required=True)
    ap.add_argument('--batch-size', type=int, default=4)
    ap.add_argument('--workers', type=int, default=4)
    ap.add_argument('--amp', action='store_true')
    ap.add_argument('--limit', type=int, default=None,
                    help='smoke-test only: limit each split to N samples')
    ap.add_argument('--device', default='cuda' if torch.cuda.is_available() else 'cpu')
    args = ap.parse_args()

    device = torch.device(args.device)
    os.makedirs(args.out_dir, exist_ok=True)
    ckpt_sha1 = sha1_of_file(args.checkpoint)
    print(f'loading SegFormer on {device}; checkpoint_sha1={ckpt_sha1}')
    seg = build_seg_model(args.config, args.checkpoint, 'cpu')
    seg.to(device).eval()
    freeze_seg(seg)

    splits = []
    for name, csv_path in [('train', args.train_csv), ('val', args.val_csv)]:
        splits.append(extract_split(
            seg, name, csv_path, args.out_dir, device,
            args.batch_size, args.workers, args.amp, args.limit))

    meta = {
        'format_version': 1,
        'feature_type': 'SegFormer MiT-B2 pooled 4-stage features',
        'vector_dim': VECTOR_DIM,
        'config': os.path.abspath(args.config),
        'checkpoint': os.path.abspath(args.checkpoint),
        'checkpoint_sha1': ckpt_sha1,
        'input_size': [512, 512],
        'amp': bool(args.amp),
        'limit': args.limit,
        'splits': splits,
        'created_at': time.strftime('%Y-%m-%d %H:%M:%S'),
    }
    with open(os.path.join(args.out_dir, 'metadata.json'), 'w') as f:
        json.dump(meta, f, indent=2)
    print(f'feature cache ready: {args.out_dir}')


if __name__ == '__main__':
    main()
