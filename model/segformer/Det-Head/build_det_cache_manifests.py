"""Build explicit train/val CSVs for cached Det Head feature extraction.

Combines Main-9 selection + PSBattles while preserving existing split assignments.
"""
from __future__ import annotations

import argparse
import csv
import os
from collections import Counter


def label_id(row: dict) -> int:
    raw = row.get('label_id')
    if raw not in (None, ''):
        return int(raw)
    raw = str(row.get('label', '')).strip().lower()
    if raw in {'1', 'manipulated'}:
        return 1
    if raw in {'0', 'authentic'}:
        return 0
    raise ValueError(f'unknown label: {row}')


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', default='/home/panuwat/Pictures/Det-Head')
    args = ap.parse_args()
    root = os.path.abspath(args.root)
    main9 = os.path.join(root, 'manifests', 'main9-v1.csv')
    psb = os.path.join(root, 'image-level', 'psbattles-v1',
                       'manifests', 'manifest.csv')
    for p in (main9, psb):
        if not os.path.isfile(p):
            raise FileNotFoundError(p)

    rows = {'train': [], 'val': []}
    with open(main9, newline='') as f:
        for r in csv.DictReader(f):
            split = r['split']
            if split not in rows:
                continue
            rows[split].append({
                'path': r['dest_file'],
                'label': label_id(r),
                'dataset': r.get('dataset', 'main9'),
                'source': 'main9-v1',
            })

    with open(psb, newline='') as f:
        for r in csv.DictReader(f):
            split = r['split']
            if split not in rows:
                continue
            rows[split].append({
                'path': r['dest_file'],
                'label': label_id(r),
                'dataset': 'psbattles',
                'source': 'psbattles-v1',
            })
    out_dir = os.path.join(root, 'manifests')
    os.makedirs(out_dir, exist_ok=True)
    for split in ('train', 'val'):
        missing = [r['path'] for r in rows[split] if not os.path.isfile(r['path'])]
        if missing:
            raise FileNotFoundError(
                f'{split}: {len(missing)} missing files; first={missing[0]}')
        counts = Counter(r['label'] for r in rows[split])
        out = os.path.join(out_dir, f'det-{split}-v1.csv')
        with open(out, 'w', newline='') as f:
            w = csv.DictWriter(f, fieldnames=['path', 'label', 'dataset', 'source'])
            w.writeheader()
            w.writerows(rows[split])
        print(f'{split}: {len(rows[split])} images '
              f'authentic={counts[0]} manipulated={counts[1]} -> {out}')


if __name__ == '__main__':
    main()
