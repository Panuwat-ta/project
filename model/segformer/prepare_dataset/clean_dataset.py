#!/usr/bin/env python3
"""Clean raw scam-image datasets (USB) into lossless train/val for SegFormer.

Sources (raw, never modified):
  <src>/Authentic, CASIA2/{Au,Tp,'CASIA 2 Groundtruth'},
  defacto-splicing/splicing_N_{img,annotations} (N=1..7),
  defacto-copymove/{copymove_img/img, copymove_annotations/{probe_mask,donor_mask}},
  defacto-inpainting/{inpainting_img/img, inpainting_annotations/{inpaint_mask,probe_mask}},
  (DEFACTODataset/DEFACTOdefacto-inpainting เก่าถูกลบแล้ว: คู่ซ้ำ recompress กัน),
  IMD2020/{IMD2020, IMD2020_Generative_Image_Inpainting_yu2018_0{1..7} + _mask}

Output (lossless PNG, stratified split, full manifest):
  <out>/images/{train,val}/<tag>_<name>.png
  <out>/annotations/{train,val}/<tag>_<name>.png   (0=background, 1=forgery)
  <out>/manifest.json   (every file + split + source)
  <out>/clean_log.json  (skipped/quarantined with reasons)

Fixes vs old prepare_dataset_*.py:
  1. PNG lossless (old code re-encoded JPG, destroying pixel traces)
  2. missing/unreadable mask -> SKIP + log (old code wrote all-zero = wrong label)
  3. tampered mask with zero forgery pixels -> quarantine + log
  4. exact-duplicate files (sha1) across sources -> keep first + log
  5. stratified split per (source-tag, label) so val covers every subtype
  6. manifest lists files, not just counts

Usage:
  python clean_dataset.py [--src DIR] [--out DIR] [--split 0.8] [--seed 42]
                          [--limit N] [--min-side 64]
  --limit N caps items per source-tag (smoke test).
"""
import argparse
import glob
import hashlib
import json
import os
import random
import sys

try:
    import cv2
    import numpy as np
except ImportError:
    sys.exit("need opencv + numpy in segformer venv")

IMG_EXTS = (".jpg", ".jpeg", ".png", ".tif", ".tiff", ".bmp", ".webp")


def sha1(path):
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def find_mask(mask_dirs, stem):
    """Try <stem> + common mask extensions in given dirs."""
    for d in mask_dirs:
        if os.path.isfile(os.path.join(d, stem)):
            return os.path.join(d, stem)
        for ext in (".png", ".jpg", ".jpeg", ".tif", ".bmp"):
            for cand in (stem + ext, stem + "_mask" + ext, stem + "_gt" + ext):
                p = os.path.join(d, cand)
                if os.path.isfile(p):
                    return p
    return None


class Collector:
    def __init__(self, max_per_tag=0):
        self.max_per_tag = max_per_tag
        self._tag_count = {}
        self.items = []          # (img, mask|None, label, tag, upstream)
        self.log = {"skipped": [], "quarantine": [], "duplicates": []}
        self._seen_hash = {}

    def add(self, img, mask, label, tag, upstream=None):
        if self.max_per_tag and self._tag_count.get(tag, 0) >= self.max_per_tag:
            return "capped"
        if not os.path.isfile(img):
            self.log["skipped"].append({"img": img, "reason": "not-a-file"})
            return
        try:
            digest = sha1(img)
        except OSError:
            self.log["skipped"].append({"img": img, "reason": "unreadable"})
            return
        if digest in self._seen_hash:
            self.log["duplicates"].append(
                {"img": img, "kept": self._seen_hash[digest]})
            return
        self._seen_hash[digest] = img
        if label == 1 and not (mask and os.path.isfile(mask)):
            self.log["skipped"].append({"img": img, "reason": "mask-missing"})
            return
        self._seen_hash[digest] = img
        self._tag_count[tag] = self._tag_count.get(tag, 0) + 1
        self.items.append((img, mask, label, tag, upstream))

    def authentic_dir(self, d, tag, exts=IMG_EXTS, recursive=True):
        if not os.path.isdir(d):
            self.log["skipped"].append({"img": d, "reason": "dir-missing"})
            return
        pat = "**/*" if recursive else "*"
        files = sorted(glob.glob(os.path.join(d, pat), recursive=recursive))
        for f in files:
            if f.lower().endswith(exts) and os.path.isfile(f):
                if self.add(f, None, 0, tag) == "capped":
                    break

    def paired(self, img_dir, mask_dirs, tag, upstream=None, exts=IMG_EXTS,
               empty_mask_as_authentic=False, recursive=False):
        if isinstance(mask_dirs, str):
            mask_dirs = [mask_dirs]
        if not os.path.isdir(img_dir):
            self.log["skipped"].append({"img": img_dir, "reason": "dir-missing"})
            return
        pat = "**/*" if recursive else "*"
        for f in sorted(glob.glob(os.path.join(img_dir, pat), recursive=recursive)):
            if not (os.path.isfile(f) and f.lower().endswith(exts)):
                continue
            stem = os.path.splitext(os.path.basename(f))[0]
            if stem.endswith("_mask"):
                continue
            mp = find_mask(mask_dirs, stem)
            if empty_mask_as_authentic and mp:
                m = cv2.imread(mp, cv2.IMREAD_GRAYSCALE)
                if m is not None and (m > 127).sum() == 0:
                    if self.add(f, None, 0, "au_" + tag, upstream) == "capped":
                        break
                    continue
            if self.add(f, mp, 1, tag, upstream) == "capped":
                break


def collect(src, limit=0):
    c = Collector(limit)
    # 1. Authentic pool (COCO-style jpgs)
    c.authentic_dir(os.path.join(src, "Authentic"), "au_usb")
    # 2. CASIA2: Au + Tp(tif) with *_gt.png masks
    c.authentic_dir(os.path.join(src, "CASIA2", "Au"), "au_casia")
    tp, gt = os.path.join(src, "CASIA2", "Tp"), os.path.join(src, "CASIA2", "CASIA 2 Groundtruth")
    if os.path.isdir(tp):
        for f in sorted(glob.glob(os.path.join(tp, "Tp_*"))):
            if os.path.isdir(f) or f.endswith("_gt.png"):
                continue
            stem = os.path.splitext(os.path.basename(f))[0]
            if c.add(f, find_mask([tp, gt], stem), 1, "tp_casia") == "capped":
                break
    else:
        c.log["skipped"].append({"img": tp, "reason": "dir-missing"})
    # 3. defacto splicing N=1..7 (img/img + probe/donor masks)
    for n in range(1, 8):
        c.paired(os.path.join(src, "defacto-splicing", f"splicing_{n}_img", "img"),
                 [os.path.join(src, "defacto-splicing", f"splicing_{n}_annotations", "probe_mask"),
                  os.path.join(src, "defacto-splicing", f"splicing_{n}_annotations", "donor_mask")],
                 f"tp_splice{n}")
    # 4. defacto copymove (probe mask primary, donor fallback)
    c.paired(os.path.join(src, "defacto-copymove", "copymove_img", "img"),
             [os.path.join(src, "defacto-copymove", "copymove_annotations", "probe_mask"),
              os.path.join(src, "defacto-copymove", "copymove_annotations", "donor_mask")],
             "tp_copymove")
    # 4b. defacto face: morphing + swapping (+ reference = authentic)
    base = os.path.join(src, "defacto-face")
    for sub, tag in (("morphing", "tp_face_morphing"),
                     ("swapping", "tp_face_swapping")):
        c.paired(os.path.join(base, f"{sub}_img", "img"),
                 [os.path.join(base, f"{sub}_annotations", "probe_mask"),
                  os.path.join(base, f"{sub}_annotations", "donor_mask")],
                 tag)
    c.authentic_dir(os.path.join(base, "reference", "reference"), "au_face")
    # 5. defacto-inpainting (img/img + inpaint/probe masks; แหล่งเดียว ไม่มีสำเนาซ้ำแล้ว)
    base = os.path.join(src, "defacto-inpainting")
    c.paired(os.path.join(base, "inpainting_img", "img"),
             [os.path.join(base, "inpainting_annotations", "inpaint_mask"),
              os.path.join(base, "inpainting_annotations", "probe_mask")],
             "tp_inpaint")
    # 6. DEFACTOdefacto-inpainting: SKIPPED — เป็นสำเนาแปลงไฟล์ของข้อ 5
    #    (ชื่อไฟล์ตรงกันแต่ md5 ต่าง = ถูก recompress มา ใช้แล้วจะได้ near-duplicate
    #    รั่วข้าม split แถมเสียร่องรอยพิกเซล ใช้ต้นฉบับข้อ 5 อย่างเดียว)
    # 7. IMD2020 original + generative inpainting 01..07
    base = os.path.join(src, "IMD2020", "IMD2020")
    if os.path.isdir(base):
        for mp in sorted(glob.glob(os.path.join(base, "*", "*_mask.png"))):
            ip = mp.replace("_mask.png", ".jpg")
            c.add(ip, mp, 1, "tp_imd2020")
    mdir = os.path.join(src, "IMD2020", "IMD2020_Generative_Image_Inpainting_yu2018_mask")
    for i in range(1, 8):
        idir = os.path.join(src, "IMD2020", f"IMD2020_Generative_Image_Inpainting_yu2018_0{i}")
        if not os.path.isdir(idir):
            continue
        for f in sorted(glob.glob(os.path.join(idir, "*.jpg"))):
            stem = os.path.splitext(os.path.basename(f))[0]
            c.add(f, find_mask([mdir], stem), 1, f"tp_imd_inpaint{i}")
    return c


def save_pair(img_path, mask, label, out_img, out_ann, min_side):
    img = cv2.imread(img_path)
    if img is None:
        return "img-unreadable"
    h, w = img.shape[:2]
    if min(h, w) < min_side:
        return "too-small"
    if label == 1:
        m = cv2.imread(mask, cv2.IMREAD_GRAYSCALE)
        if m is None:
            return "mask-unreadable"
        if m.shape != (h, w):
            m = cv2.resize(m, (w, h), interpolation=cv2.INTER_NEAREST)
        m = np.where(m > 127, 1, 0).astype(np.uint8)
        if m.sum() == 0:
            return "mask-empty"
    else:
        m = np.zeros((h, w), dtype=np.uint8)
    cv2.imwrite(out_img, img)                       # PNG lossless
    cv2.imwrite(out_ann, (m * 255).astype(np.uint8))
    return None


def source_of(tag):
    """Map item tag -> per-source output folder."""
    if tag.startswith("tp_splice"):
        return "splicing"
    if tag.startswith("tp_imd"):
        return "imd2020"
    if tag == "tp_copymove":
        return "copymove"
    if tag.startswith("tp_face"):
        return "face"
    if tag == "au_face":
        return "face"
    if tag == "tp_inpaint":
        return "inpainting"
    if tag.endswith("_casia"):
        return "casia"
    if tag == "au_usb":
        return "authentic"
    return "other"


def main():
    ap = argparse.ArgumentParser(description="Clean USB datasets to lossless train/val")
    ap.add_argument("--src", default="/run/media/panuwat/USB/data")
    ap.add_argument("--out", default="/home/panuwat/Pictures/dataset")
    ap.add_argument("--split", type=float, default=0.8,
                    help="train fraction of non-test (val gets the rest)")
    ap.add_argument("--test", type=float, default=0.1,
                    help="held-out test fraction (never touched in training)")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--limit", type=int, default=0, help="cap items per tag (smoke test)")
    ap.add_argument("--min-side", type=int, default=64)
    a = ap.parse_args()
    rng = random.Random(a.seed)

    print("Collecting (read-only on src)...")
    c = collect(a.src, a.limit)
    print(f"collected={len(c.items)} skipped={len(c.log['skipped'])} "
          f"dupes={len(c.log['duplicates'])}")

    # group by (tag, label); honour upstream split; cap per tag if --limit
    groups = {}
    for it in c.items:
        groups.setdefault((it[3], it[2], it[4]), []).append(it)
    # stem-grouped split: same base photo (shared stem across sources, e.g.
    # one COCO image tampered as copymove AND inpainting) must land wholly in
    # train or val, never both -> prevents scene leakage across the split.
    stem_groups = {}
    for it in c.items:
        stem = os.path.splitext(os.path.basename(it[0]))[0]
        stem_groups.setdefault(stem, []).append(it)
    stems = sorted(stem_groups)
    rng.shuffle(stems)
    train, val, test = [], [], []
    for s in stems:
        # held-out test first (final unbiased eval, e.g. Jira 7.2 metrics),
        # then train/val from the rest — whole stem-groups stay together.
        r = rng.random()
        if r < a.test:
            test.extend(stem_groups[s])
        elif r < a.test + (1 - a.test) * a.split:
            train.extend(stem_groups[s])
        else:
            val.extend(stem_groups[s])
    from collections import Counter
    for name, lst in (("train", train), ("val", val), ("test", test)):
        print(f"  {name} tags:", dict(sorted(Counter(i[3] for i in lst).items())))
    print(f"train={len(train)} val={len(val)} test={len(test)}")

    for s in ("train", "val", "test"):
        for _src in {source_of(t) for t, _, _ in groups}:
            os.makedirs(os.path.join(a.out, _src, "images", s), exist_ok=True)
            os.makedirs(os.path.join(a.out, _src, "annotations", s), exist_ok=True)
    manifest, per_src, counts = {"train": [], "val": [], "test": []}, {}, {"saved": 0}
    for split, lst in (("train", train), ("val", val), ("test", test)):
        for img, mask, label, tag, _ in lst:
            stem = os.path.splitext(os.path.basename(img))[0]
            srcext = os.path.splitext(img)[1].lower().lstrip(".") or "img"
            base = f"{tag}_{stem}_{srcext}"
            srcdir = os.path.join(a.out, source_of(tag))
            oi = os.path.join(srcdir, "images", split, base + ".png")
            oa = os.path.join(srcdir, "annotations", split, base + ".png")
            err = save_pair(img, mask, label, oi, oa, a.min_side)
            if err:
                c.log["quarantine"].append({"img": img, "reason": err})
                continue
            rec = {"image": oi, "mask": oa, "label": label,
                   "tag": tag, "src": img}
            manifest[split].append(rec)
            per_src.setdefault(source_of(tag), {"train": [], "val": [], "test": []})[split].append(rec)
            counts["saved"] += 1
    with open(os.path.join(a.out, "manifest.json"), "w") as f:
        json.dump({"seed": a.seed, "split": a.split, **manifest}, f, indent=1)
    for _src, m in per_src.items():
        with open(os.path.join(a.out, _src, "manifest.json"), "w") as f:
            json.dump({"seed": a.seed, "split": a.split, **m}, f, indent=1)
    with open(os.path.join(a.out, "clean_log.json"), "w") as f:
        json.dump(c.log, f, indent=1)
    nq = len(c.log["quarantine"])
    print(f"saved={counts['saved']} quarantined={nq} "
          f"manifest + clean_log written to {a.out}")


if __name__ == "__main__":
    main()
