"""Build an Authentic-screen-shot Train manifest from the phishing-screenshots tree.

Label semantics guardrail
-------------------------
`dataset_raw/phishing-screenshots` labels each row ``phishing`` (1) or
``legitimate`` (0). That is a *phishing-site* label, NOT a *content-manipulated*
label. A screenshot of a phishing website is still an unmodified image, so
mapping label 1 to Det label 1 would teach the head to call untouched
screenshots manipulated and would make the measured chatshot2 false positives
worse, not better.

Every row written here is therefore Det label 0. The source label is kept in
``source_label`` for provenance and for future phishing-site work, and the
assertion below fails loudly if that intent ever changes.

Why this domain
---------------
Measured 2026-09-29 with the deployed det2b head: 45.5% (91/200) and 48.4%
(31/64) of these authentic screenshots were flagged as manipulated at threshold
0.5, mean score ~0.48. They are unmodified, so every flag is a false positive.
The same 336 phishing-site screenshots, which are also unmodified images, were
flagged 32% of the time. The head has no usable representation of the
screenshot/UI domain.

Caveat kept explicit
--------------------
These are desktop full-page web captures at a uniform 1920x1080. The known
real-world false positives (`Test-Cases/image-Authentic/to1`, `to11`) are mobile
LINE and screen captures. This source covers the desktop part of the screenshot
domain only; it does not substitute for collected mobile chat captures.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import time
from collections import Counter
from pathlib import Path

SOURCE_ROOT = Path("/home/panuwat/Pictures/dataset_raw/phishing-screenshots")
PROJECT_ROOT = Path(__file__).resolve().parent.parent


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--source-root", type=Path, default=SOURCE_ROOT)
    ap.add_argument("--audit-csv", type=Path, required=True,
                    help="output of validate_camera_authentic_incoming.py")
    ap.add_argument("--out-csv", type=Path, required=True)
    ap.add_argument("--dataset", default="webshot-v1")
    ap.add_argument("--source", default="phishing-screenshots-v1")
    args = ap.parse_args()

    metadata = {r["file_name"]: r
                for r in csv.DictReader(open(args.source_root / "metadata.csv"))}
    audit = list(csv.DictReader(open(args.audit_csv)))

    rows = []
    dropped = Counter()
    for record in audit:
        if record["status"] != "ok":
            dropped[record["reason"]] += 1
            continue
        key = record["path"].split(f"{args.source_root.name}/")[-1]
        meta = metadata.get(key)
        if meta is None:
            dropped["missing_metadata"] += 1
            continue
        if meta["is_blank"] != "false":
            # blank / captcha / error pages are not representative screenshots
            dropped["blank_or_error_page"] += 1
            continue
        rows.append({
            "path": record["path"],
            "label": 0,
            "dataset": args.dataset,
            "source": args.source,
            "source_label": meta["label"],
            "source_label_name": meta["label_name"],
            "page_type": meta["page_type"],
            "image_hash": meta["image_hash"],
            "width": record["width"],
            "height": record["height"],
        })

    if any(r["label"] != 0 for r in rows):
        raise AssertionError("Det label must be 0 for every row in this manifest")

    args.out_csv.parent.mkdir(parents=True, exist_ok=True)
    with args.out_csv.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    summary = {
        "out_csv": str(args.out_csv),
        "rows": len(rows),
        "det_label_distribution": dict(Counter(str(r["label"]) for r in rows)),
        "source_label_distribution": dict(Counter(r["source_label_name"] for r in rows)),
        "dropped": dict(dropped),
        "label_semantics": ("all rows are Det label 0 because a screenshot of a "
                            "phishing site is still an unmodified image; the "
                            "phishing/legitimate distinction is preserved in "
                            "source_label and is not a manipulation label"),
        "coverage_caveat": ("desktop full-page web captures at a uniform "
                            "1920x1080 only; does not cover mobile LINE or "
                            "screen captures"),
        "created_at": time.strftime("%Y-%m-%d %H:%M:%S"),
    }
    summary_path = args.out_csv.with_suffix(".summary.json")
    with open(summary_path, "w") as f:
        json.dump(summary, f, indent=2)
    print(json.dumps(summary, indent=2))
    print(f"\nmanifest: {args.out_csv}")
    print(f"summary : {summary_path}")


if __name__ == "__main__":
    main()
