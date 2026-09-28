import argparse, csv, json, os
from collections import defaultdict
import numpy as np
import torch
from det_head import load_det


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--checkpoint', required=True)
    ap.add_argument('--feature-cache', required=True)
    ap.add_argument('--csv', required=True)
    ap.add_argument('--split', default='train')
    ap.add_argument('--out-dir', required=True)
    ap.add_argument('--auth-hard', type=float, default=0.35)
    ap.add_argument('--manip-hard', type=float, default=0.65)
    args = ap.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)
    rows = list(csv.DictReader(open(args.csv)))
    root = os.path.join(args.feature_cache, args.split)
    X = np.load(os.path.join(root, 'features.npy'), mmap_mode='r')
    y = np.load(os.path.join(root, 'labels.npy'), mmap_mode='r').reshape(-1).astype(int)
    if len(rows) != len(X):
        raise ValueError('CSV/cache length mismatch')
    model = load_det(args.checkpoint, 'cpu').eval()
    scores = []
    with torch.no_grad():
        for i in range(0, len(X), 4096):
            xx = torch.from_numpy(np.asarray(X[i:i + 4096]).copy()).float()
            scores.append(torch.sigmoid(model.forward_pooled(xx)).reshape(-1).numpy())
    score = np.concatenate(scores)
    pred = (score >= 0.5).astype(int)

    groups = defaultdict(list)
    for i, row in enumerate(rows):
        groups[(int(row['label']), row.get('dataset', 'unknown'))].append(i)

    by_group = {}
    for (label, dataset), idx in sorted(groups.items()):
        a = np.asarray(idx)
        ss = score[a]
        pp = pred[a]
        yy = y[a]
        hard = ss >= args.auth_hard if label == 0 else ss <= args.manip_hard
        by_group[f'{label}:{dataset}'] = {
            'label': label, 'dataset': dataset, 'n': int(len(a)),
            'mean_score': float(ss.mean()),
            'q05': float(np.quantile(ss, 0.05)),
            'q25': float(np.quantile(ss, 0.25)),
            'q50': float(np.quantile(ss, 0.50)),
            'q75': float(np.quantile(ss, 0.75)),
            'q95': float(np.quantile(ss, 0.95)),
            'error_count': int((pp != yy).sum()),
            'error_rate': float((pp != yy).mean()),
            'hard_count': int(hard.sum()),
            'hard_rate': float(hard.mean()),
        }

    hard_rows = []
    for i, (row, sc) in enumerate(zip(rows, score)):
        label = int(row['label'])
        is_hard = sc >= args.auth_hard if label == 0 else sc <= args.manip_hard
        if not is_hard:
            continue
        hard_rows.append({
            'index': i,
            'path': row['path'],
            'label': label,
            'dataset': row.get('dataset', ''),
            'source': row.get('source', ''),
            'score': float(sc),
            'hard_type': 'auth_high' if label == 0 else 'manip_low',
            'misclassified': int((sc >= 0.5) != bool(label)),
        })

    hard_csv = os.path.join(args.out_dir, 'hard_examples.csv')
    with open(hard_csv, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(hard_rows[0]))
        writer.writeheader()
        writer.writerows(hard_rows)
    summary = {
        'n': int(len(score)),
        'accuracy': float((pred == y).mean()),
        'fp': int(((pred == 1) & (y == 0)).sum()),
        'fn': int(((pred == 0) & (y == 1)).sum()),
        'hard_rule': f'auth>={args.auth_hard}; manip<={args.manip_hard}',
        'hard_n': int(len(hard_rows)),
        'by_dataset_label': by_group,
    }
    with open(os.path.join(args.out_dir, 'summary.json'), 'w') as f:
        json.dump(summary, f, indent=2)
    print(json.dumps(summary, indent=2))
    print('hard_csv', hard_csv)


if __name__ == '__main__':
    main()
