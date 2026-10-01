"""Precompute frozen SegFormer local 4x4 tokens for Det5.

Cache shape per split: (N, 64, 1024), float16.
Only Train/Val should be generated during candidate development.
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

from det6_local import GRID_SIZE, NUM_TOKENS, TOKEN_DIM, local_stage_tokens
from det_head import build_seg_model, freeze_seg
from train_det import ImgLabelDataset, load_csv, sha1_of_file


def sha1_text(path: str) -> str:
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def amp_context(device: torch.device, enabled: bool):
    if enabled and device.type == "cuda":
        return torch.autocast(device_type="cuda", dtype=torch.float16)
    return nullcontext()


def write_paths(path: str, items) -> None:
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["index", "path", "label", "teacher"])
        for i, (img, label, teacher) in enumerate(items):
            w.writerow([i, img, label, "" if teacher is None else teacher])


def infer_resume_offset(features) -> int:
    chunk = 1024
    for start in range(0, len(features), chunk):
        block = np.asarray(features[start:start + chunk])
        written = np.any(block != 0, axis=(1, 2))
        if not written.all():
            return start + int(np.where(~written)[0][0])
    return len(features)


def extract_split(seg, split_name: str, csv_path: str, out_root: str,
                  device: torch.device, batch_size: int, workers: int,
                  use_amp: bool, limit: int | None, resume: bool) -> dict:
    items = load_csv(csv_path)
    if limit is not None:
        items = items[:limit]
    if not items:
        raise ValueError(f"{split_name}: no samples")

    split_dir = os.path.join(out_root, split_name)
    os.makedirs(split_dir, exist_ok=True)
    feature_path = os.path.join(split_dir, "features.npy")
    label_path = os.path.join(split_dir, "labels.npy")
    teacher_path = os.path.join(split_dir, "teachers.npy")
    expected_f = (len(items), NUM_TOKENS, TOKEN_DIM)
    expected_y = (len(items), 1)

    can_resume = resume and all(os.path.isfile(x) for x in
                                (feature_path, label_path, teacher_path))
    if can_resume:
        features = np.load(feature_path, mmap_mode="r+")
        labels = np.load(label_path, mmap_mode="r+")
        teachers = np.load(teacher_path, mmap_mode="r+")
        if features.shape != expected_f or labels.shape != expected_y:
            raise ValueError(f"{split_name}: cache shape mismatch")
        offset = infer_resume_offset(features)
        print(f"{split_name}: resume at {offset}/{len(items)}", flush=True)
    else:
        features = open_memmap(feature_path, mode="w+", dtype="float16", shape=expected_f)
        labels = open_memmap(label_path, mode="w+", dtype="float32", shape=expected_y)
        teachers = open_memmap(teacher_path, mode="w+", dtype="float32", shape=expected_y)
        offset = 0

    remaining = items[offset:]
    loader = DataLoader(
        ImgLabelDataset(remaining), batch_size=batch_size, shuffle=False,
        num_workers=workers, pin_memory=(device.type == "cuda"))
    started = time.time()
    with torch.inference_mode():
        for step, (x, y, t, _) in enumerate(loader, 1):
            x = x.to(device, non_blocking=True)
            with amp_context(device, use_amp):
                tokens = local_stage_tokens(seg.extract_feat(x))
            n = len(x)
            features[offset:offset + n] = tokens.float().cpu().numpy().astype(np.float16)
            labels[offset:offset + n] = y.numpy()
            teachers[offset:offset + n] = t.numpy()
            offset += n
            if step % 100 == 0 or offset == len(items):
                features.flush(); labels.flush(); teachers.flush()
                print(f"{split_name}: {offset}/{len(items)} "
                      f"({time.time()-started:.1f}s)", flush=True)

    features.flush(); labels.flush(); teachers.flush()
    write_paths(os.path.join(split_dir, "paths.csv"), items)
    return {
        "split": split_name,
        "csv": os.path.abspath(csv_path),
        "csv_sha1": sha1_text(csv_path),
        "samples": len(items),
        "features_shape": list(expected_f),
        "dtype": "float16",
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", required=True)
    ap.add_argument("--checkpoint", required=True)
    ap.add_argument("--train-csv", required=True)
    ap.add_argument("--val-csv", required=True)
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--batch-size", type=int, default=4)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--amp", action="store_true")
    ap.add_argument("--resume", action="store_true")
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--device", default="cuda" if torch.cuda.is_available() else "cpu")
    args = ap.parse_args()

    device = torch.device(args.device)
    os.makedirs(args.out_dir, exist_ok=True)
    ckpt_sha1 = sha1_of_file(args.checkpoint)
    print(f"loading SegFormer on {device}; checkpoint_sha1={ckpt_sha1}")
    seg = build_seg_model(args.config, args.checkpoint, "cpu")
    seg.to(device).eval()
    freeze_seg(seg)

    splits = []
    for name, csv_path in (("train", args.train_csv), ("val", args.val_csv)):
        splits.append(extract_split(seg, name, csv_path, args.out_dir, device,
                                    args.batch_size, args.workers, args.amp,
                                    args.limit, args.resume))

    meta = {
        "format_version": 6,
        "feature_type": "SegFormer MiT-B2 aligned local 8x8 patch tokens",
        "pooling": "adaptive_avg_grid",
        "grid_size": GRID_SIZE,
        "num_tokens": NUM_TOKENS,
        "token_dim": TOKEN_DIM,
        "config": os.path.abspath(args.config),
        "checkpoint": os.path.abspath(args.checkpoint),
        "checkpoint_sha1": ckpt_sha1,
        "input_size": [512, 512],
        "amp": bool(args.amp),
        "limit": args.limit,
        "splits": splits,
        "created_at": time.strftime("%Y-%m-%d %H:%M:%S"),
    }
    with open(os.path.join(args.out_dir, "metadata.json"), "w") as f:
        json.dump(meta, f, indent=2)
    print(f"Det6 local 8x8 feature cache ready: {args.out_dir}")


if __name__ == "__main__":
    main()
