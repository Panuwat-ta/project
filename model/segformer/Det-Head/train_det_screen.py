"""Fast screening trainer for Det Head variants on an existing local-token cache.

Purpose: the full-data protocol (95,635 rows, 12.5 GB cache) costs ~2.3 h per
candidate, which is too slow to explore anything. This trainer keeps the loss,
optimizer and metric definitions identical to ``train_det6.py`` but trains on a
fixed-seed subsample so the whole subset fits in page cache.

Screening only ranks candidates. Any candidate that survives the gates is
re-trained with the full-data protocol before its numbers are trusted.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import random
import time

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, Dataset, Subset

from det5_local import build_det5_head
from det6_local import build_det6_head
from det_head_variants import build_variant, save_variant
from train_det import build_source_balanced_sampler, sha1_of_file

ARCH_BUILDERS = {
    "patch_attention": lambda d, t: build_det5_head("patch_attention", d, t),
    "patch_topk": lambda d, t: build_det5_head("patch_topk", d, t),
    "patch_attention_8x8": lambda d, t: build_det6_head("patch_attention", d, t),
    "patch_topk_8x8": lambda d, t: build_det6_head("patch_topk", d, t),
    "token_stats": lambda d, t: build_variant("token_stats", d, t),
    "token_stats_topk": lambda d, t: build_variant("token_stats_topk", d, t),
    "spatial_pyramid": lambda d, t: build_variant("spatial_pyramid", d, t),
    "token_stats_coarse": lambda d, t: build_variant("token_stats_coarse", d, t),
}


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


class ConcatTokenCacheDataset(Dataset):
    """Concatenate two local-token caches so a new domain can be added without
    recomputing the existing multi-gigabyte cache.

    Indices are positional across the concatenation, so the extra cache starts at
    ``len(first)``. Sample weights and manifests are concatenated in the same
    order, which keeps the three aligned.
    """

    def __init__(self, first: Dataset, second: Dataset) -> None:
        self.first = first
        self.second = second
        self.first_len = len(first)

    def __len__(self) -> int:
        return self.first_len + len(self.second)

    def __getitem__(self, i: int):
        if i < self.first_len:
            return self.first[i]
        return self.second[i - self.first_len]


def _cache_paths(cache_root: str, limit: int | None) -> list[dict]:
    with open(os.path.join(cache_root, "train", "paths.csv"), newline="") as f:
        rows = list(csv.DictReader(f))
    return rows if limit is None else rows[:limit]


def _concat_manifests(first: str, second: str) -> str:
    """Write first+second to a temp manifest and return its path.

    ``build_source_balanced_sampler`` reads a path, and the two manifests have
    different column sets (the webshot manifest carries ``source_label``,
    ``page_type``, ``width``/``height``), so the second file's rows are
    projected onto the first file's columns. Columns unique to the second file
    are dropped, not an error; only ``label`` and ``dataset`` are load-bearing
    for the sampler and they are required to exist in both.
    """
    import tempfile
    with open(first, newline="") as f:
        first_rows = list(csv.DictReader(f))
    with open(second, newline="") as f:
        second_rows = list(csv.DictReader(f))
    fields = list(first_rows[0].keys())
    for required in ("label", "dataset", "path"):
        if required not in fields:
            raise ValueError(f"base manifest is missing required column {required!r}")
        if any(required not in r for r in second_rows):
            raise ValueError(f"extra manifest is missing required column {required!r}")
    handle = tempfile.NamedTemporaryFile("w", newline="", suffix=".csv", delete=False)
    with handle as out:
        w = csv.DictWriter(out, fieldnames=fields, extrasaction="ignore")
        w.writeheader()
        w.writerows(first_rows)
        for r in second_rows:
            w.writerow(r)
    return handle.name


def _write_subset_rows(manifest_csv: str, subset_idx: list[int]) -> str:
    """Write only the rows at ``subset_idx`` (in that order) to a temp manifest.

    Returned positions line up 1:1 with the Subset's indices, so sampler weights
    built from this file address the right rows.
    """
    import tempfile
    with open(manifest_csv, newline="") as f:
        rows = list(csv.DictReader(f))
    if max(subset_idx) >= len(rows):
        raise ValueError(f"subset index {max(subset_idx)} out of range for "
                         f"{manifest_csv} ({len(rows)} rows)")
    picked = [rows[i] for i in subset_idx]
    handle = tempfile.NamedTemporaryFile("w", newline="", suffix=".csv", delete=False)
    with handle as out:
        w = csv.DictWriter(out, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(picked)
    return handle.name


@torch.no_grad()
def evaluate(head, loader, device):
    head.eval()
    bce = nn.BCEWithLogitsLoss()
    total = correct = 0
    loss_sum = 0.0
    scores, labels = [], []
    for x, y, _, _ in loader:
        x = x.to(device, non_blocking=True)
        y = y.to(device, non_blocking=True)
        logit = head.forward_tokens(x)
        loss = bce(logit, y)
        prob = logit.sigmoid()
        loss_sum += loss.item() * len(x)
        correct += ((prob >= 0.5).float() == y).sum().item()
        total += len(x)
        scores.append(prob.cpu())
        labels.append(y.cpu())
    return (loss_sum / max(total, 1), correct / max(total, 1),
            torch.cat(scores).numpy().reshape(-1),
            torch.cat(labels).numpy().reshape(-1))


def binary_ranking_metrics(labels: np.ndarray, scores: np.ndarray) -> tuple:
    """Return (f1, roc_auc, average_precision) without a sklearn dependency.

    sklearn is not in this repo's requirements, and the previous bare
    ``except Exception`` silently dropped these three metrics to null.
    """
    pred = scores >= 0.5
    tp = int(((pred == 1) & (labels == 1)).sum())
    fp = int(((pred == 1) & (labels == 0)).sum())
    fn = int(((pred == 0) & (labels == 1)).sum())
    precision = tp / (tp + fp) if (tp + fp) else 0.0
    recall = tp / (tp + fn) if (tp + fn) else 0.0
    f1 = (2 * precision * recall / (precision + recall)) if (precision + recall) else 0.0

    pos, neg = scores[labels == 1], scores[labels == 0]
    if len(pos) == 0 or len(neg) == 0:
        return f1, None, None
    # AUC via rank statistic, ties averaged
    order = np.argsort(np.concatenate([pos, neg]), kind="mergesort")
    ranks = np.empty(len(order), dtype=np.float64)
    allv = np.concatenate([pos, neg])[order]
    i = 0
    while i < len(allv):
        j = i
        while j + 1 < len(allv) and allv[j + 1] == allv[i]:
            j += 1
        ranks[order[i:j + 1]] = (i + j) / 2.0 + 1.0
        i = j + 1
    auc = (ranks[:len(pos)].sum() - len(pos) * (len(pos) + 1) / 2) / (len(pos) * len(neg))
    # average precision = step-wise sum of precision over decreasing score
    idx = np.argsort(-scores, kind="mergesort")
    y = labels[idx]
    cum_tp = np.cumsum(y == 1)
    precision_at = cum_tp / np.arange(1, len(y) + 1)
    ap = float((precision_at * (y == 1)).sum() / max(int((labels == 1).sum()), 1))
    return f1, float(auc), ap


def stratified_subsample(manifest_csv: str, n_target: int, seed: int) -> list[int]:
    """Sample rows keeping the per-(label, dataset) mix, deterministic by seed.

    Reads the Train manifest rather than the cache ``paths.csv`` because only the
    manifest carries the ``dataset`` column needed to preserve source diversity.
    """
    with open(manifest_csv, newline="") as f:
        rows = list(csv.DictReader(f))
    by_group: dict[tuple[str, str], list[int]] = {}
    for i, r in enumerate(rows):
        by_group.setdefault((r.get("label", ""), r.get("dataset", "")), []).append(i)
    groups = sorted(by_group)
    rng = np.random.default_rng(seed)
    total = len(rows)
    picked: list[int] = []
    for g in groups:
        idx = by_group[g]
        quota = max(1, round(n_target * len(idx) / total))
        if quota >= len(idx):
            picked.extend(idx)
        else:
            picked.extend(rng.choice(idx, quota, replace=False).tolist())
    rng.shuffle(picked)
    return sorted(picked)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--checkpoint", required=True)
    ap.add_argument("--feature-cache", required=True)
    ap.add_argument("--extra-cache", default=None,
                    help="comma-separated extra caches whose train splits are "
                         "appended to Train; used to add new domains without "
                         "recomputing the existing 12.5 GB cache")
    ap.add_argument("--work-dir", required=True)
    ap.add_argument("--arch", required=True, choices=sorted(ARCH_BUILDERS))
    ap.add_argument("--dropout", type=float, default=0.2)
    ap.add_argument("--topk", type=int, default=4)
    ap.add_argument("--source-balanced", action="store_true")
    ap.add_argument("--sample-weight-csv", default=None)
    ap.add_argument("--subsample", type=int, default=25000,
                    help="0 or negative trains on the full cache (slow but exact)")
    ap.add_argument("--epochs", type=int, default=12)
    ap.add_argument("--lr", type=float, default=1e-4)
    ap.add_argument("--batch-size", type=int, default=256)
    ap.add_argument("--patience", type=int, default=4)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--device", default="cuda" if torch.cuda.is_available() else "cpu")
    args = ap.parse_args()

    if args.arch not in ARCH_BUILDERS:
        raise ValueError(f"unknown arch {args.arch}")

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
    num_tokens = cache_meta["num_tokens"]

    full_train = LocalTokenCacheDataset(args.feature_cache, "train")
    val_ds = LocalTokenCacheDataset(args.feature_cache, "val")
    train_manifest = next(x["csv"] for x in cache_meta["splits"] if x["split"] == "train")
    base_rows = sum(1 for _ in open(train_manifest, newline="")) - 1

    extra_caches = [c for c in (args.extra_cache or "").split(",") if c]
    extra_parts: list[tuple[str, str, int]] = []  # (root, manifest, rows)
    for extra_root in extra_caches:
        with open(os.path.join(extra_root, "metadata.json")) as f:
            extra_meta = json.load(f)
        if extra_meta.get("checkpoint_sha1") != ckpt_sha1:
            raise ValueError(f"extra cache checkpoint mismatch: {extra_root}")
        if extra_meta["num_tokens"] != num_tokens:
            raise ValueError(f"extra cache token count {extra_meta['num_tokens']} "
                             f"!= {num_tokens}")
        extra_train = LocalTokenCacheDataset(extra_root, "train")
        full_train = ConcatTokenCacheDataset(full_train, extra_train)
        manifest = next(x["csv"] for x in extra_meta["splits"] if x["split"] == "train")
        extra_parts.append((extra_root, manifest, len(extra_train)))
        print(f"extra cache: +{len(extra_train)} rows from {manifest}", flush=True)

    n_base = len(full_train) - sum(p[2] for p in extra_parts)

    if args.subsample and args.subsample > 0 and args.subsample < len(full_train):
        quota = args.subsample - (len(full_train) - n_base)
        if quota < 0:
            raise ValueError("--subsample is smaller than the extra caches alone; "
                             "raise it or drop --extra-cache")
        subset_idx = stratified_subsample(train_manifest, quota, args.seed)
        offset = n_base
        for _, manifest, rows in extra_parts:
            take = min(args.subsample - len(subset_idx), rows)
            if take <= 0:
                break
            extra_idx = stratified_subsample(manifest, take, args.seed)
            subset_idx = sorted(subset_idx + [offset + i for i in extra_idx])
            offset += rows
        train_ds = Subset(full_train, subset_idx)
        screening = True
    else:
        train_ds = full_train
        subset_idx = None
        screening = False

    sample_weights = np.ones(len(full_train), dtype=np.float32)
    weighted_rows = 0
    if args.sample_weight_csv:
        with open(args.sample_weight_csv, newline="") as f:
            weight_map = {r["path"]: float(r["sample_weight"])
                          for r in csv.DictReader(f)}
        cache_paths = _cache_paths(args.feature_cache, n_base)
        for root, _, _ in extra_parts:
            cache_paths = cache_paths + _cache_paths(root, None)
        if len(cache_paths) != len(full_train):
            raise ValueError("Train paths.csv/cache length mismatch")
        for i, r in enumerate(cache_paths):
            w = weight_map.get(r["path"], 1.0)
            if not (0.0 <= w <= 5.0):
                raise ValueError(f"sample weight out of range [0,5]: {r['path']}: {w}")
            sample_weights[i] = w
            if w != 1.0:
                weighted_rows += 1

    sampler = None
    source_counts = None
    if args.source_balanced:
        # Applied in screening mode too. The webshot domain added 7,394 label0
        # rows, and plain random sampling let it pull the model toward "authentic"
        # enough to cost sparse-manipulation recall on testcases. Balancing by
        # source keeps each dataset from dominating.
        sampler_csv = train_manifest
        for _, manifest, _ in extra_parts:
            sampler_csv = _concat_manifests(sampler_csv, manifest)
        if subset_idx is not None:
            # Sampler weights are positional over the manifest, so they must be
            # restricted to the rows this run actually trains on. Using the full
            # manifest would emit indices the Subset never returns.
            sampler_csv = _write_subset_rows(sampler_csv, subset_idx)
        sampler, source_counts, _ = build_source_balanced_sampler(sampler_csv, args.seed)

    train_loader = DataLoader(
        train_ds, batch_size=args.batch_size, shuffle=(sampler is None),
        sampler=sampler, num_workers=args.workers,
        pin_memory=(device.type == "cuda"))
    val_loader = DataLoader(
        val_ds, batch_size=args.batch_size, shuffle=False,
        num_workers=args.workers, pin_memory=(device.type == "cuda"))

    head = ARCH_BUILDERS[args.arch](args.dropout, args.topk).to(device)
    n_params = sum(p.numel() for p in head.parameters())
    opt = torch.optim.AdamW(head.parameters(), lr=args.lr)
    bce = nn.BCEWithLogitsLoss()
    bce_none = nn.BCEWithLogitsLoss(reduction="none")
    best_acc, best_state, best_epoch, bad, history = -1.0, None, 0, 0, []

    print(f"arch={args.arch} params={n_params} tokens={num_tokens} "
          f"train={len(train_ds)}{' (subsample)' if screening else ' (full)'} "
          f"val={len(val_ds)} screening={screening} device={device}", flush=True)

    started = time.time()
    for epoch in range(args.epochs):
        head.train()
        for x, y, _, batch_idx in train_loader:
            x = x.to(device, non_blocking=True)
            y = y.to(device, non_blocking=True)
            logit = head.forward_tokens(x)
            if args.sample_weight_csv:
                # Subset yields indices into the *full* cache, which is exactly
                # the axis sample_weights is indexed by, so no remapping is needed.
                rows = batch_idx.numpy()
                w = torch.from_numpy(sample_weights[rows]).to(
                    device=device, dtype=logit.dtype).reshape(-1)
                loss = (bce_none(logit, y).reshape(-1) * w).sum() / w.sum().clamp_min(1e-8)
            else:
                loss = bce(logit, y)
            opt.zero_grad(set_to_none=True)
            loss.backward()
            opt.step()

        val_loss, val_acc, _, _ = evaluate(head, val_loader, device)
        history.append({"epoch": epoch + 1, "val_loss": val_loss, "val_acc": val_acc})
        print(f"epoch {epoch+1}/{args.epochs} val_loss={val_loss:.4f} "
              f"val_acc={val_acc:.4f} ({time.time()-started:.0f}s)", flush=True)
        if val_acc > best_acc:
            best_acc, best_epoch, bad = val_acc, epoch + 1, 0
            best_state = {k: v.detach().cpu().clone() for k, v in head.state_dict().items()}
        else:
            bad += 1
            if bad >= args.patience:
                print(f"early stop best={best_acc:.4f} epoch={best_epoch}", flush=True)
                break

    head.load_state_dict(best_state)
    val_loss, val_acc, val_scores, val_labels = evaluate(head, val_loader, device)
    val_f1, val_auc, val_ap = binary_ranking_metrics(val_labels, val_scores)

    meta = {
        # det_arch stays the canonical name the det5/det6/variant loaders expect,
        # so eval_det_diagnostics.load_any_det can rebuild the head unchanged.
        # The grid is recorded separately instead of being encoded in the name.
        "det_arch": args.arch.removesuffix("_8x8"),
        "screen_arch": args.arch,
        "n_params": n_params,
        "dropout": float(args.dropout),
        "topk": int(args.topk),
        "num_tokens": int(num_tokens),
        "segformer_checkpoint": os.path.abspath(args.checkpoint),
        "segformer_checkpoint_sha1": ckpt_sha1,
        "feature_cache": os.path.abspath(args.feature_cache),
        "feature_cache_meta": cache_meta,
        "screening": bool(screening),
        "subsample": args.subsample if screening else None,
        "n_train": len(train_ds),
        "n_val": len(val_ds),
        "source_balanced": bool(args.source_balanced),
        "sample_weight_csv": os.path.abspath(args.sample_weight_csv) if args.sample_weight_csv else None,
        "weighted_rows": int(weighted_rows),
        "lr": float(args.lr),
        "batch_size": int(args.batch_size),
        "seed": int(args.seed),
        "best_epoch": int(best_epoch),
        "best_val_acc": float(best_acc),
        "val_f1": val_f1,
        "val_roc_auc": val_auc,
        "val_average_precision": val_ap,
        "created_at": time.strftime("%Y-%m-%d %H:%M:%S"),
    }
    save_variant(head, os.path.join(args.work_dir, "head.pth"), meta)
    np.save(os.path.join(args.work_dir, "val_scores.npy"), val_scores)
    np.save(os.path.join(args.work_dir, "val_labels.npy"), val_labels)
    with open(os.path.join(args.work_dir, "train_log.json"), "w") as f:
        json.dump({
            "meta": meta,
            "history": history,
            # Recorded so a source-balanced run can be audited after the fact.
            "source_groups": ({f"{k[0]}:{k[1]}": v for k, v in source_counts.items()}
                              if source_counts else None),
        }, f, indent=2)
    print(json.dumps({"best_val_acc": best_acc, "best_epoch": best_epoch,
                      "val_f1": val_f1, "val_roc_auc": val_auc,
                      "val_average_precision": val_ap}, indent=2))


if __name__ == "__main__":
    main()
