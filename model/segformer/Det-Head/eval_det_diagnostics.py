"""Reproducible development diagnostics for SegFormer Det Head candidates.

Diagnostic sets are development-only. They are NOT the Locked Test 44,031 and
must never be used to tune a production threshold.

Sets (all derived from real files on disk, no synthetic rows):
  camera9   /home/panuwat/Pictures/Test-Cases/image-Authentic, 9 label0
            Direct mobile-camera photos. Provenance confirmed by the user on
            2026-09-29; each file carries 12 EXIF tags including GPS.
  chatshot2 the same folder, 2 label0
            to1 = a LINE chat capture, to11 = a screen capture. User-confirmed
            on 2026-09-29. NOT camera photos: both have zero EXIF tags.
            Reported separately and never used as a gate, because n=2 is too
            small to separate a real regression from noise. It exists to keep
            the chat/screenshot domain visible, not to judge a candidate.
  pilot11   9 authentic + 2 manipulated real user uploads in server/uploads
  testcases 105 with_mask images (7 datasets x 15) + 60 pairs (30+30) = 165

The camera9 / chatshot2 split matters because ScamGuard's stated user-facing
scope includes chat screenshots, while the training data contains no chat or
screenshot images at all. Keeping one mixed "camera11" gate hid that gap.

A candidate is only comparable across runs if scored with this script, because
the earlier ad-hoc inline runs are not reproducible.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import sys
import time
from pathlib import Path

import numpy as np
import torch
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from det_head import build_seg_model, freeze_seg, load_det
from train_det import MEAN, SIZE, STD


def load_any_det(path: str, device: str = "cpu"):
    """Load a Det head from any family: pooled, local-token, or variant.

    ``det_head.load_det`` only knows the pooled archs. Dispatch uses the
    ``det_arch`` recorded in the checkpoint meta, and for the local-token family
    the ``pos_embed`` row count stored in the checkpoint itself (16 rows = Det5
    4x4, 64 rows = Det6 8x8), so a renamed run directory cannot break it.
    """
    import torch as _torch

    from det_head_variants import ARCHS as VARIANT_ARCHS
    from det_head_variants import load_variant

    payload = _torch.load(path, map_location="cpu", weights_only=False)
    meta = payload.get("meta", {})
    arch = meta.get("det_arch", "linear")
    if arch in VARIANT_ARCHS:
        return load_variant(path, device)
    if arch.startswith("patch_attention") or arch.startswith("patch_topk"):
        num_tokens = payload["state_dict"]["pos_embed"].shape[1]
        from det5_local import GRID_SIZE as G5, load_det5
        from det6_local import GRID_SIZE as G6, load_det6
        table = {G5 * G5: load_det5, G6 * G6: load_det6}
        if num_tokens not in table:
            raise ValueError(f"{path}: unsupported local token count {num_tokens}")
        return table[num_tokens](path, device)
    return load_det(path, device)

PROJECT_ROOT = Path(__file__).resolve().parent.parent
TESTCASES = Path("/home/panuwat/Pictures/Test-Cases")
UPLOADS = Path("/home/panuwat/project/server/uploads")

# label 0 = authentic, label 1 = manipulated
PILOT11 = [
    ("Original1", "59570fd99fbaed7efb0403cb67257e7c5cfc947f4fbc08581b181cbed2e6c3f8.png", 0),
    ("Original2", "d8d1280abf0af51547c0460af742493e9afdc5fd614dec2bedc9bd03b373ff55.png", 0),
    ("Original3", "6cfc06e8cbda637726d282b0e8916f0920694514c02622857f131cbbe5623423.png", 0),
    ("Original4", "0a607b6d6b264a60838aef311520202083d0797bb0cf864cacc810a9ff8c9fca.png", 0),
    ("Original5", "da08fdad9a84ad66efbb6b7e3eae583ee5a9529abf242c0347610d68e8afb029.png", 0),
    ("Original6", "7fe8dfcda5da2f1afbe53a2f60211b731cd75501b82955beab41fc734b2099a6.png", 0),
    ("Original7", "7d8eaad635015eaae4e5b344fea40ea51d31640a420672c2d6aa911e3067bae3.png", 0),
    ("Original8", "926ecd62bd78e1487907fbd52ef2d9cd69d116c82a34082321f8408aea394776.png", 0),
    ("Original9", "3e9ef750f85d72c421cb0cb00f0db700308b0f136f784c7e4999585ae409f958.png", 0),
    ("Manipulated1", "81fd035e6bc71afbda1c3749c53dadfb01c590cf331199d6a763c031e9cebaca.png", 1),
    ("Manipulated2", "6126995e80c32ff10c3a6d2bd9f7412751a93c0c117d9dfc28fe509dad77514f.png", 1),
]

WITH_MASK_LABELS = {
    "authentic": 0, "casia": 1, "copymove": 1, "face": 1,
    "imd2020": 1, "inpainting": 1, "splicing": 1,
}

# Provenance of every file in Test-Cases/image-Authentic, confirmed by the user
# on 2026-09-29. "camera" = direct mobile-camera photo, "chatshot" = LINE chat
# capture or screen capture. The exif_tags column is what this script verifies
# at load time, so a re-saved or re-labelled file cannot silently change domain.
AUTHENTIC_PROVENANCE = {
    "to1": ("chatshot", "LINE chat capture", 0),
    "to11": ("chatshot", "screen capture", 0),
    "to2": ("camera", "mobile camera", 0),
    "to3": ("camera", "mobile camera", 0),
    "to4": ("camera", "mobile camera", 0),
    "to5": ("camera", "mobile camera", 0),
    "to6": ("camera", "mobile camera", 0),
    "to7": ("camera", "mobile camera", 0),
    "to8": ("camera", "mobile camera", 0),
    "to9": ("camera", "mobile camera", 0),
    "to10": ("camera", "mobile camera", 0),
}
# A file declared "camera" must carry EXIF; the chat captures carry none. This
# is the machine-checkable part of the provenance claim.
CAMERA_MIN_EXIF_TAGS = 8
CHATSHOT_MAX_EXIF_TAGS = 0


def _exif_tag_count(path: Path) -> int:
    with Image.open(path) as im:
        return len(im.getexif())


def _authentic_rows(domain: str) -> list[dict]:
    folder = TESTCASES / "image-Authentic"
    rows = []
    for p in sorted(folder.glob("*.jpg")):
        if p.stem not in AUTHENTIC_PROVENANCE:
            raise ValueError(f"{p.name} has no declared provenance in "
                             f"AUTHENTIC_PROVENANCE; add it before scoring")
        declared, note, label = AUTHENTIC_PROVENANCE[p.stem]
        n_exif = _exif_tag_count(p)
        if declared == "camera" and n_exif < CAMERA_MIN_EXIF_TAGS:
            raise ValueError(f"{p.name} is declared camera but has only "
                             f"{n_exif} EXIF tags")
        if declared == "chatshot" and n_exif > CHATSHOT_MAX_EXIF_TAGS:
            raise ValueError(f"{p.name} is declared chatshot but has {n_exif} "
                             f"EXIF tags, expected {CHATSHOT_MAX_EXIF_TAGS}")
        if declared != domain:
            continue
        rows.append({"name": p.stem, "path": str(p), "label": label,
                     "dataset": domain, "domain": declared,
                     "exif_tags": n_exif, "note": note})
    return rows


def load_manifest(name: str) -> list[dict]:
    """Return a deterministic diagnostic manifest, or raise if files are missing."""
    if name == "camera9":
        rows = _authentic_rows("camera")
        if len(rows) != 9:
            raise ValueError(f"camera9 expected 9 images, found {len(rows)}")
        return rows

    if name == "chatshot2":
        rows = _authentic_rows("chatshot")
        if len(rows) != 2:
            raise ValueError(f"chatshot2 expected 2 images, found {len(rows)}")
        return rows

    if name == "cameraval16":
        # Held-out real-camera validation from real-camera-authentic-v1. Report
        # only, never gated: 16 images means one image is worth 6.25 points.
        import csv as _csv
        manifest = Path("/home/panuwat/Pictures/Det-Head/manifests/det-camera-val-v1.csv")
        if not manifest.is_file():
            raise FileNotFoundError(f"cameraval16 manifest missing: {manifest}")
        rows = []
        with open(manifest, newline="") as f:
            for r in _csv.DictReader(f):
                p = Path(r["path"])
                if not p.is_file():
                    raise FileNotFoundError(f"cameraval16 file missing: {p}")
                rows.append({"name": p.stem, "path": str(p), "label": int(r["label"]),
                             "dataset": "cameraval16", "device": r.get("source", ""),
                             "session": r.get("session", "")})
        if len(rows) != 16:
            raise ValueError(f"cameraval16 expected 16 images, found {len(rows)}")
        return rows

    if name == "cameraxdev104":
        # Cross-device real-camera holdout from a second capture pipeline
        # (12.58 MP) than the 15.93 MP realme collection used for training.
        # Never trained on. n=104 means one image is worth 0.96 points, which
        # makes this a far less fragile real-camera signal than camera9 (n=9).
        import csv as _csv
        manifest = Path("/home/panuwat/Pictures/Det-Head/manifests/det-camera-xdev-v1.csv")
        if not manifest.is_file():
            raise FileNotFoundError(f"cameraxdev104 manifest missing: {manifest}")
        rows = []
        with open(manifest, newline="") as f:
            for r in _csv.DictReader(f):
                p = Path(r["path"])
                if not p.is_file():
                    raise FileNotFoundError(f"cameraxdev104 file missing: {p}")
                rows.append({"name": p.stem, "path": str(p), "label": int(r["label"]),
                             "dataset": "cameraxdev104", "device": r.get("source", ""),
                             "session": r.get("session", "")})
        if len(rows) != 104:
            raise ValueError(f"cameraxdev104 expected 104 images, found {len(rows)}")
        return rows

    if name == "pilot11":
        rows = []
        for title, fname, label in PILOT11:
            p = UPLOADS / fname
            if not p.is_file():
                raise FileNotFoundError(f"pilot11 file missing: {p}")
            rows.append({"name": title, "path": str(p), "label": label, "dataset": "pilot11"})
        return rows

    if name == "testcases":
        rows = []
        for dataset, label in sorted(WITH_MASK_LABELS.items()):
            img_dir = TESTCASES / "with_mask" / dataset / "images" / "test"
            found = sorted(img_dir.glob("*.png")) + sorted(img_dir.glob("*.jpg"))
            if not found:
                raise FileNotFoundError(f"testcases dataset empty: {img_dir}")
            for p in found:
                rows.append({"name": p.stem, "path": str(p), "label": label, "dataset": dataset})
        for sub, label in (("originals", 0), ("manipulated", 1)):
            folder = TESTCASES / "pairs" / sub
            for p in sorted(folder.glob("*.jpg")) + sorted(folder.glob("*.png")):
                rows.append({"name": p.stem, "path": str(p), "label": label, "dataset": "pairs"})
        if len(rows) != 165:
            raise ValueError(f"testcases expected 165 images, found {len(rows)}")
        return rows

    raise ValueError(f"unknown diagnostic set: {name}")


def image_tensor(path: str) -> torch.Tensor:
    im = Image.open(path).convert("RGB").resize(SIZE, Image.BILINEAR)
    arr = np.asarray(im, dtype=np.float32)
    mean = np.asarray(MEAN, dtype=np.float32).reshape(1, 1, 3)
    std = np.asarray(STD, dtype=np.float32).reshape(1, 1, 3)
    arr = (arr - mean) / std
    return torch.from_numpy(arr.transpose(2, 0, 1))


@torch.inference_mode()
def score_images(seg, heads: dict, manifest: list[dict], device, batch_size: int = 8):
    """Score one manifest with several heads in a single SegFormer pass."""
    rows = []
    buf_x, buf_feats = [], []

    def flush():
        if not buf_x:
            return
        x = torch.stack(buf_x).to(device, non_blocking=True)
        feats = seg.extract_feat(x)
        for name, head in heads.items():
            head.eval()
            logits = head(feats).squeeze(-1).float().cpu().numpy()
            for i, score in zip(range(len(buf_x)), logits):
                rows[-len(buf_x) + i]["scores"][name] = float(1.0 / (1.0 + np.exp(-score)))
        buf_x.clear()
        buf_feats.clear()

    for row in manifest:
        row["scores"] = {}
        rows.append(row)
        buf_x.append(image_tensor(row["path"]))
        if len(buf_x) >= batch_size:
            flush()
    flush()
    return rows


def confusion(rows: list[dict], head_name: str, threshold: float) -> dict:
    tp = tn = fp = fn = 0
    for r in rows:
        pred = 1 if r["scores"][head_name] >= threshold else 0
        if r["label"] == 1 and pred == 1:
            tp += 1
        elif r["label"] == 0 and pred == 0:
            tn += 1
        elif r["label"] == 0 and pred == 1:
            fp += 1
        else:
            fn += 1
    n = tp + tn + fp + fn
    acc = (tp + tn) / n if n else None
    precision = tp / (tp + fp) if (tp + fp) else None
    recall = tp / (tp + fn) if (tp + fn) else None
    specificity = tn / (tn + fp) if (tn + fp) else None
    f1 = (2 * precision * recall / (precision + recall)) if (precision and recall) else None
    return {"n": n, "tp": tp, "tn": tn, "fp": fp, "fn": fn,
            "accuracy": acc, "precision": precision, "recall": recall,
            "specificity": specificity, "f1": f1,
            "mean_score": float(np.mean([r["scores"][head_name] for r in rows]))}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default=str(PROJECT_ROOT / "configs/segformer_mit-b2-v11.py"))
    ap.add_argument("--checkpoint", default=str(PROJECT_ROOT / "work_dirs/v1.0.6/best_mIoU_iter_195000.pth"))
    ap.add_argument("--head", action="append", required=True,
                    help="NAME=PATH/det_head.pth, repeatable")
    ap.add_argument("--sets", default="camera9,chatshot2,pilot11,testcases")
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--threshold", type=float, default=0.5)
    ap.add_argument("--batch-size", type=int, default=8)
    ap.add_argument("--device", default="cuda" if torch.cuda.is_available() else "cpu")
    args = ap.parse_args()

    heads = {}
    for spec in args.head:
        name, _, path = spec.partition("=")
        if not path:
            raise ValueError(f"--head must be NAME=PATH, got {spec}")
        heads[name] = load_any_det(path, "cpu")

    device = torch.device(args.device)
    seg = build_seg_model(args.config, args.checkpoint, "cpu").to(device).eval()
    freeze_seg(seg)
    for name, head in heads.items():
        head.to(device)

    os.makedirs(args.out_dir, exist_ok=True)
    result = {"checkpoint": os.path.abspath(args.checkpoint),
              "threshold": args.threshold,
              "heads": {n: os.path.abspath(p) for n, p in
                        (s.partition("=")[::2] for s in args.head)},
              "sets": {}, "created_at": time.strftime("%Y-%m-%d %H:%M:%S")}

    for set_name in args.sets.split(","):
        manifest = load_manifest(set_name)
        started = time.time()
        rows = score_images(seg, heads, manifest, device, args.batch_size)
        set_result = {}
        for head_name in heads:
            summary = confusion(rows, head_name, args.threshold)
            if set_name == "testcases":
                by_dataset = {}
                for dataset in sorted({r["dataset"] for r in rows}):
                    subset = [r for r in rows if r["dataset"] == dataset]
                    by_dataset[dataset] = confusion(subset, head_name, args.threshold)
                summary["by_dataset"] = by_dataset
            set_result[head_name] = summary
            csv_path = os.path.join(args.out_dir, f"{set_name}__{head_name}.csv")
            with open(csv_path, "w", newline="") as f:
                w = csv.writer(f)
                w.writerow(["name", "dataset", "label", "path", "score", "pred", "correct"])
                for r in rows:
                    pred = 1 if r["scores"][head_name] >= args.threshold else 0
                    w.writerow([r["name"], r["dataset"], r["label"], r["path"],
                                f"{r['scores'][head_name]:.6f}", pred, int(pred == r["label"])])
        set_result["elapsed_s"] = round(time.time() - started, 2)
        result["sets"][set_name] = set_result
        for head_name, s in set_result.items():
            if head_name == "elapsed_s":
                continue
            print(f"[{set_name}] {head_name}: n={s['n']} acc={s['accuracy']} "
                  f"spec={s['specificity']} rec={s['recall']} mean={s['mean_score']:.4f}")

    with open(os.path.join(args.out_dir, "diagnostics.json"), "w") as f:
        json.dump(result, f, indent=2)
    print(f"saved {args.out_dir}/diagnostics.json")


if __name__ == "__main__":
    main()
