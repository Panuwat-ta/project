"""Build the real-camera Authentic manifests for Det-Head from staged photos.

Input
-----
``image-level/real-camera-authentic-v1/incoming/`` holds the staged camera
files, and ``manifests/incoming_audit.csv`` is the output of
``validate_camera_authentic_incoming.py`` (byte SHA-256, decoded-pixel SHA-256,
dimensions, EXIF Make/Model, holdout overlap, duplicate flag).

Label semantics guardrail
-------------------------
Every row written here is Det label 0. These are direct camera photos with no
content manipulation, so any label 1 would teach the head to call untouched
photos manipulated. The assertion below fails loudly if that intent changes.

Holdout protection
------------------
``dataset_specs/real-camera-authentic-v1.md`` protects the 11 files under
``/home/panuwat/Pictures/Test-Cases/image-Authentic`` (the ``camera9`` real
camera set plus the ``chatshot2`` captures) from ever entering Train or
camera-Val. The audit CSV is re-checked here on ``holdout_overlap`` and
``duplicate_incoming`` even though the validator already applied it, because
this script is the thing that decides which rows reach a training manifest.

Split rule
----------
The spec requires splitting by device/session, not by random near-duplicate
frames, because consecutive frames from one burst are visually near-identical
and a random split would put the same scene on both sides of the boundary.
Sessions are taken from EXIF ``DateTimeOriginal`` (day granularity), whole
sessions are assigned to one split, and the assignment is deterministic:
sessions sorted by date, greedily placed into whichever split is furthest below
its target share. No randomness, so re-running reproduces the same split.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import shutil
import time
from collections import Counter, defaultdict
from pathlib import Path

from PIL import Image

DATASET_ROOT = Path("/home/panuwat/Pictures/Det-Head/image-level/real-camera-authentic-v1")
SOURCE_ROOT = Path("/home/panuwat/Pictures/inport")
HOLDOUT_DIR = Path("/home/panuwat/Pictures/Test-Cases/image-Authentic")

SPLIT_SHARE = {"train": 0.80, "camera-val": 0.10, "camera-test": 0.10}


def exif_datetime_original(path: Path) -> str:
    with Image.open(path) as im:
        exif = im.getexif()
        sub = exif.get_ifd(0x8769) if hasattr(exif, "get_ifd") else {}
        value = sub.get(36867) or exif.get(36867) or exif.get(306)
    return str(value).strip() if value else ""


def session_of(datetime_original: str, fallback: str) -> str:
    """Day-level session id. Falls back to the file stem when EXIF is absent."""
    if datetime_original:
        return datetime_original.split()[0]
    return f"no-exif:{fallback}"


def assign_splits(sessions: dict[str, list[str]], total: int) -> dict[str, str]:
    """Greedy whole-session assignment toward the target share per split."""
    target = {k: v * total for k, v in SPLIT_SHARE.items()}
    have = {k: 0 for k in SPLIT_SHARE}
    mapping: dict[str, str] = {}
    for session in sorted(sessions, key=lambda s: (len(sessions[s]), s), reverse=True):
        split = min(SPLIT_SHARE, key=lambda k: (have[k] - target[k], k))
        mapping[session] = split
        have[split] += len(sessions[session])
    return mapping


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset-root", type=Path, default=DATASET_ROOT)
    ap.add_argument("--source-root", type=Path, default=SOURCE_ROOT)
    ap.add_argument("--holdout-dir", type=Path, default=HOLDOUT_DIR)
    ap.add_argument("--audit-csv", type=Path, default=None)
    ap.add_argument("--dataset", default="real-camera-authentic-v1")
    ap.add_argument("--source", default="realme-gt-neo2-5g")
    ap.add_argument("--dry-run", action="store_true",
                    help="compute the split and report it without copying or writing")
    args = ap.parse_args()

    dataset_root = args.dataset_root
    staging = dataset_root / "incoming"
    audit_csv = args.audit_csv or (dataset_root / "manifests" / "incoming_audit.csv")
    manifests_dir = dataset_root / "manifests"

    audit = list(csv.DictReader(audit_csv.open(newline="")))
    if not audit:
        raise SystemExit(f"audit csv is empty: {audit_csv}")

    dropped: Counter[str] = Counter()
    rows: list[dict] = []
    for record in audit:
        if record["status"] != "ok":
            dropped[record["reason"]] += 1
            continue
        if int(record["holdout_overlap"]):
            raise SystemExit(
                f"holdout overlap survived the audit, refusing to write: {record['path']}")
        if int(record["duplicate_incoming"]):
            raise SystemExit(f"duplicate survived the audit, refusing to write: {record['path']}")
        staged = Path(record["path"])
        if not staged.is_file():
            raise SystemExit(f"staged file missing: {staged}")
        original = args.source_root / staged.name
        rows.append({
            "staged": staged,
            "original": original,
            "staged_name": staged.name,
            "sha256": record["sha256"],
            "decoded_sha256": record["decoded_sha256"],
            "width": record["width"],
            "height": record["height"],
            "megapixels": record["megapixels"],
            "exif_make": record["exif_make"],
            "exif_model": record["exif_model"],
        })

    # Match each staged file back to its pristine camera file in the source dir.
    by_size: dict[int, list[Path]] = defaultdict(list)
    if args.source_root.is_dir():
        for p in sorted(args.source_root.iterdir()):
            if p.is_file() and p.suffix.lower() in {".jpg", ".jpeg", ".png"}:
                by_size[p.stat().st_size].append(p)
    used: set[Path] = set()
    for row in rows:
        candidates = [p for p in by_size.get(row["staged"].stat().st_size, [])
                      if p not in used and p.stat().st_size == row["staged"].stat().st_size]
        row["original"] = candidates[0] if candidates else None
        if row["original"] is not None:
            used.add(row["original"])

    for row in rows:
        dt = exif_datetime_original(row["staged"])
        row["datetime_original"] = dt
        row["session"] = session_of(dt, row["staged_name"])

    if not rows:
        raise SystemExit(
            f"no accepted rows: audited={len(audit)} dropped={dict(dropped)}. "
            "Refusing to build an empty manifest; inspect the audit csv first.")

    sessions: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        sessions[row["session"]].append(row)
    mapping = assign_splits(sessions, len(rows))
    if not sessions:
        raise SystemExit("no sessions could be derived from the accepted rows")

    per_split: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        per_split[mapping[row["session"]]].append(row)

    print(f"files={len(rows)} sessions={len(sessions)}")
    for split in SPLIT_SHARE:
        got = per_split[split]
        print(f"  {split:12s} images={len(got):3d} sessions="
              f"{len({r['session'] for r in got}):2d} "
              f"({len(got) / len(rows) * 100:.1f}%)")
    print(f"  dropped: {dict(dropped) or '{}'}")

    if args.dry_run:
        print("\ndry-run: nothing copied, nothing written")
        return

    manifest_rows: list[dict] = []
    per_split_csv: dict[str, list[dict]] = defaultdict(list)
    for split in SPLIT_SHARE:
        for row in sorted(per_split[split], key=lambda r: r["staged_name"]):
            stem = Path(row["staged_name"]).stem
            dest_name = f"{stem}_auth.jpg"
            dest = dataset_root / split / "authentic" / dest_name
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(row["staged"], dest)
            if dest.stat().st_size != row["staged"].stat().st_size:
                raise SystemExit(f"copy size mismatch: {dest}")
            entry = {
                "dataset": args.dataset,
                "split": split,
                "label": "authentic",
                "label_id": 0,
                "file_name": row["original"].name if row["original"] else row["staged_name"],
                "source_file": str(row["original"]) if row["original"] else "",
                "dest_file": str(dest),
                "bytes": dest.stat().st_size,
                "tag": Path(row["exif_model"] or "unknown").stem.replace(" ", "_").lower(),
                "original_src": str(row["original"]) if row["original"] else "",
                "session": row["session"],
                "datetime_original": row["datetime_original"],
                "exif_make": row["exif_make"],
                "exif_model": row["exif_model"],
                "width": row["width"],
                "height": row["height"],
                "megapixels": row["megapixels"],
                "sha256": row["sha256"],
                "decoded_sha256": row["decoded_sha256"],
            }
            per_split_csv[split].append(entry)
            manifest_rows.append(entry)

    if any(r["label_id"] != 0 for r in manifest_rows):
        raise AssertionError("Det label must be 0 for every row in this manifest")
    if not manifest_rows:
        raise AssertionError("manifest would be empty")

    holdout_names = set()
    if args.holdout_dir.is_dir():
        for p in sorted(args.holdout_dir.iterdir()):
            if p.is_file() and p.suffix.lower() in {".jpg", ".jpeg", ".png"}:
                holdout_names.add(p.stem)
    leaked = [r for r in manifest_rows
              if Path(r["dest_file"]).stem.replace("_auth", "") in holdout_names]
    if leaked:
        raise AssertionError(f"holdout filename leaked into manifest: {leaked[:3]}")

    manifests_dir.mkdir(parents=True, exist_ok=True)
    det_dir = dataset_root.parent.parent / "manifests"

    def write(path: Path, rows_: list[dict]) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(rows_[0].keys()))
            w.writeheader()
            w.writerows(rows_)

    write(manifests_dir / "manifest.csv", manifest_rows)
    for split, rows_ in per_split_csv.items():
        write(manifests_dir / f"{split}.csv", rows_)

    det_files = {
        "det-train-v5-camera.csv": per_split_csv["train"],
        "det-camera-val-v1.csv": per_split_csv["camera-val"],
        "det-camera-test-v1.csv": per_split_csv["camera-test"],
    }
    det_counts = {}
    for name, rows_ in det_files.items():
        out = det_dir / name
        write(out, [{"path": r["dest_file"], "label": 0, "dataset": args.dataset,
                     "source": args.source, "session": r["session"]} for r in rows_])
        det_counts[name] = len(rows_)

    summary = {
        "dataset": args.dataset,
        "source": args.source,
        "incoming": str(staging),
        "audit_csv": str(audit_csv),
        "holdout_dir": str(args.holdout_dir),
        "holdout_dir_file_count": len(holdout_names),
        "files_audited": len(audit),
        "files_accepted": len(rows),
        "dropped": dict(dropped),
        "sessions": len(sessions),
        "split_share_target": SPLIT_SHARE,
        "split_counts": {k: len(per_split[k]) for k in SPLIT_SHARE},
        "split_sessions": {k: len({r["session"] for r in per_split[k]}) for k in SPLIT_SHARE},
        "det_label_distribution": dict(Counter(str(r["label_id"]) for r in manifest_rows)),
        "det_manifests": det_counts,
        "exif_devices": dict(Counter(f"{r['exif_make']} {r['exif_model']}" for r in rows)),
        "megapixels_median": round(sorted(float(r["megapixels"]) for r in rows)[len(rows) // 2], 3),
        "label_semantics": ("every row is Det label 0 because these are direct camera "
                            "photos with no content manipulation"),
        "split_semantics": ("whole EXIF DateTimeOriginal sessions were assigned to one "
                            "split, never random frames, so near-duplicate burst frames "
                            "cannot straddle the boundary"),
        "holdout_semantics": ("the 11 protected files under Pictures/Test-Cases/image-Authentic "
                              "are excluded from all three splits; the audit reported "
                              "holdout_overlap=0 and this script re-checks it before writing"),
        "known_limitations": [
            ("all files come from a single device (see exif_devices), while the spec "
             "prefers multiple devices to avoid learning one phone's pipeline"),
            (f"accepted {len(rows)} images, below the spec minimum useful pilot of 500 "
             "and far below the preferred 1000+"),
            ("camera-test here is a development split, NOT the Locked Test 44,031"),
        ],
        "created_at": time.strftime("%Y-%m-%d %H:%M:%S"),
    }
    summary_path = manifests_dir / "manifest_summary.json"
    with summary_path.open("w") as f:
        json.dump(summary, f, indent=2)
    print(json.dumps(summary, indent=2))
    print(f"\nmanifests: {manifests_dir}")
    print(f"summary   : {summary_path}")


if __name__ == "__main__":
    main()
