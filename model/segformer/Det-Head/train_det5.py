"""Train Det5 patch/local image-level heads from cached SegFormer tokens."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import random
import time

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, Dataset

from det5_local import build_det5_head, save_det5
from train_det import build_source_balanced_sampler, sha1_of_file


class LocalTokenCacheDataset(Dataset):
    def __init__(self, cache_root: str, split_name: str):
        root = os.path.join(cache_root, split_name)
        self.features = np.load(os.path.join(root, "features.npy"), mmap_mode="r")
        self.labels = np.load(os.path.join(root, "labels.npy"), mmap_mode="r")
        self.teachers = np.load(os.path.join(root, "teachers.npy"), mmap_mode="r")
        if self.features.ndim != 3:
            raise ValueError(f"expected 3-D local token cache, got {self.features.shape}")
        if not (len(self.features) == len(self.labels) == len(self.teachers)):
            raise ValueError(f"cache length mismatch: {root}")

    def __len__(self):
        return len(self.features)

    def __getitem__(self, i):
        x = torch.from_numpy(np.array(self.features[i], dtype=np.float32, copy=True))
        y = torch.from_numpy(np.array(self.labels[i], dtype=np.float32, copy=True))
        t = torch.from_numpy(np.array(self.teachers[i], dtype=np.float32, copy=True))
        return x, y, t, i


@torch.no_grad()
def evaluate(head, loader, device):
    head.eval()
    bce = nn.BCEWithLogitsLoss()
    total = correct = 0
    loss_sum = 0.0
    scores = []
    labels = []
    for x, y, _, _ in loader:
        x = x.to(device, non_blocking=True)
        y = y.to(device, non_blocking=True)
        logit = head.forward_tokens(x)
        loss = bce(logit, y)
        prob = logit.sigmoid()
        pred = (prob >= 0.5).float()
        loss_sum += loss.item() * len(x)
        correct += (pred == y).sum().item()
        total += len(x)
        scores.append(prob.cpu())
        labels.append(y.cpu())
    return loss_sum / max(total, 1), correct / max(total, 1), \
        torch.cat(scores).numpy().reshape(-1), torch.cat(labels).numpy().reshape(-1)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--checkpoint", required=True)
    ap.add_argument("--feature-cache", required=True)
    ap.add_argument("--work-dir", required=True)
    ap.add_argument("--arch", choices=["patch_attention", "patch_topk"], required=True)
    ap.add_argument("--dropout", type=float, default=0.2)
    ap.add_argument("--topk", type=int, default=4)
    ap.add_argument("--source-balanced", action="store_true")
    ap.add_argument("--sample-weight-csv", default=None,
                    help="Optional CSV path,sample_weight; unspecified Train rows default to 1.0")
    ap.add_argument("--hard-mining-csv", default=None,
                    help="Optional Train-only CSV containing path rows to boost in source-balanced sampler")
    ap.add_argument("--hard-boost", type=float, default=1.0)
    ap.add_argument("--epochs", type=int, default=30)
    ap.add_argument("--lr", type=float, default=1e-4)
    ap.add_argument("--batch-size", type=int, default=256)
    ap.add_argument("--patience", type=int, default=6)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--device", default="cuda" if torch.cuda.is_available() else "cpu")
    args = ap.parse_args()

    random.seed(args.seed)
    np.random.seed(args.seed)
    torch.manual_seed(args.seed)
    device = torch.device(args.device)
    os.makedirs(args.work_dir, exist_ok=True)

    with open(os.path.join(args.feature_cache, "metadata.json")) as f:
        cache_meta = json.load(f)
    ckpt_sha1 = sha1_of_file(args.checkpoint)
    if cache_meta.get("checkpoint_sha1") != ckpt_sha1:
        raise ValueError("feature cache checkpoint mismatch")

    train_ds = LocalTokenCacheDataset(args.feature_cache, "train")
    val_ds = LocalTokenCacheDataset(args.feature_cache, "val")
    sampler = None
    source_counts = None
    sample_weights = np.ones(len(train_ds), dtype=np.float32)
    weighted_rows = 0
    if args.sample_weight_csv:
        weight_map = {}
        with open(args.sample_weight_csv, newline="") as f:
            for r in csv.DictReader(f):
                weight_map[r["path"]] = float(r["sample_weight"])
        paths_csv = os.path.join(args.feature_cache, "train", "paths.csv")
        with open(paths_csv, newline="") as f:
            cache_paths = list(csv.DictReader(f))
        if len(cache_paths) != len(train_ds):
            raise ValueError("Train paths.csv/cache length mismatch")
        for i, r in enumerate(cache_paths):
            w = weight_map.get(r["path"], 1.0)
            if not (0.0 <= w <= 5.0):
                raise ValueError(f"sample weight out of range [0,5] for {r['path']}: {w}")
            sample_weights[i] = w
            if w != 1.0:
                weighted_rows += 1
    if args.source_balanced:
        train_csv = next(x["csv"] for x in cache_meta["splits"] if x["split"] == "train")
        sampler, source_counts, hard_matched = build_source_balanced_sampler(
            train_csv, args.seed, hard_csv=args.hard_mining_csv, hard_boost=args.hard_boost)
        if len(sampler.weights) != len(train_ds):
            raise ValueError("source-balanced sampler length mismatch")

    train_loader = DataLoader(
        train_ds, batch_size=args.batch_size, shuffle=(sampler is None),
        sampler=sampler, num_workers=0, pin_memory=(device.type == "cuda"))
    val_loader = DataLoader(
        val_ds, batch_size=args.batch_size, shuffle=False,
        num_workers=0, pin_memory=(device.type == "cuda"))

    head = build_det5_head(args.arch, dropout=args.dropout, topk=args.topk).to(device)
    opt = torch.optim.AdamW(head.parameters(), lr=args.lr)
    bce = nn.BCEWithLogitsLoss()
    bce_none = nn.BCEWithLogitsLoss(reduction="none")
    best_acc = -1.0
    best_state = None
    best_epoch = 0
    bad = 0
    history = []
    print(f"Det5 cached mode train={len(train_ds)} val={len(val_ds)} "
          f"shape={train_ds.features.shape[1:]} arch={args.arch} "
          f"source_balanced={args.source_balanced} device={device} "
          f"weighted_rows={weighted_rows}")

    for epoch in range(args.epochs):
        head.train()
        for x, y, _, batch_idx in train_loader:
            x = x.to(device, non_blocking=True)
            y = y.to(device, non_blocking=True)
            logit = head.forward_tokens(x)
            if args.sample_weight_csv:
                w = torch.from_numpy(sample_weights[batch_idx.numpy()]).to(device=device, dtype=logit.dtype).reshape(-1)
                lv = bce_none(logit, y).reshape(-1)
                loss = (lv * w).sum() / w.sum().clamp_min(1e-8)
            else:
                loss = bce(logit, y)
            opt.zero_grad(set_to_none=True)
            loss.backward()
            opt.step()

        val_loss, val_acc, _, _ = evaluate(head, val_loader, device)
        history.append({"epoch": epoch + 1, "val_loss": val_loss, "val_acc": val_acc})
        print(f"epoch {epoch+1}/{args.epochs} val_loss={val_loss:.4f} "
              f"val_acc={val_acc:.4f}", flush=True)
        if val_acc > best_acc:
            best_acc = val_acc
            best_epoch = epoch + 1
            best_state = {k: v.detach().cpu().clone() for k, v in head.state_dict().items()}
            bad = 0
        else:
            bad += 1
            if bad >= args.patience:
                print(f"early stop best={best_acc:.4f} epoch={best_epoch}")
                break

    head.load_state_dict(best_state)
    val_loss, val_acc, val_scores, val_labels = evaluate(head, val_loader, device)

    try:
        from sklearn.metrics import roc_auc_score, average_precision_score, f1_score
        val_auc = float(roc_auc_score(val_labels, val_scores))
        val_ap = float(average_precision_score(val_labels, val_scores))
        val_f1 = float(f1_score(val_labels, val_scores >= 0.5))
    except Exception:
        val_auc = val_ap = val_f1 = None

    meta = {
        "det_arch": args.arch,
        "dropout": float(args.dropout),
        "topk": int(args.topk),
        "segformer_checkpoint": os.path.abspath(args.checkpoint),
        "segformer_checkpoint_sha1": ckpt_sha1,
        "feature_cache": os.path.abspath(args.feature_cache),
        "feature_cache_meta": cache_meta,
        "source_balanced": bool(args.source_balanced),
        "sample_weight_csv": os.path.abspath(args.sample_weight_csv) if args.sample_weight_csv else None,
        "weighted_rows": int(weighted_rows),
        "hard_mining_csv": os.path.abspath(args.hard_mining_csv) if args.hard_mining_csv else None,
        "hard_boost": float(args.hard_boost),
        "best_epoch": int(best_epoch),
        "best_val_acc": float(best_acc),
        "val_f1": val_f1,
        "val_roc_auc": val_auc,
        "val_average_precision": val_ap,
        "created_at": time.strftime("%Y-%m-%d %H:%M:%S"),
    }
    save_det5(head, os.path.join(args.work_dir, "det5_head.pth"), meta)
    np.save(os.path.join(args.work_dir, "val_scores.npy"), val_scores)
    np.save(os.path.join(args.work_dir, "val_labels.npy"), val_labels)
    with open(os.path.join(args.work_dir, "train_log.json"), "w") as f:
        json.dump({"meta": meta, "history": history,
                   "source_groups": ({f"{k[0]}:{k[1]}": v for k, v in source_counts.items()}
                                     if source_counts else None)}, f, indent=2)
    print(json.dumps({"best_val_acc": best_acc, "best_epoch": best_epoch,
                      "val_f1": val_f1, "val_roc_auc": val_auc,
                      "val_average_precision": val_ap}, indent=2))
    print(f"saved {args.work_dir}/det5_head.pth")


if __name__ == "__main__":
    main()
