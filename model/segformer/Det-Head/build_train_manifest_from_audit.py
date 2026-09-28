"""Build a new Train manifest from completed Label Audit decisions.

Never edits the source manifest or source images.
Default behavior refuses to run while any audit row is still pending.
"""
from __future__ import annotations

import argparse
import csv
import os
from collections import Counter

ALLOWED = {"keep", "relabel", "exclude", "uncertain"}


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base-csv", required=True)
    ap.add_argument("--audit-csv", required=True)
    ap.add_argument("--out-csv", required=True)
    ap.add_argument("--allow-pending", action="store_true")
    args = ap.parse_args()

    base = list(csv.DictReader(open(args.base_csv, newline="")))
    audit = list(csv.DictReader(open(args.audit_csv, newline="")))
    decisions = {r["path"]: r for r in audit}
    pending = [r for r in audit if r.get("review_decision", "").strip() not in ALLOWED]
    if pending and not args.allow_pending:
        raise RuntimeError(f"audit incomplete: {len(pending)} rows still pending")

    out = []
    stats = Counter()
    for row in base:
        a = decisions.get(row["path"])
        if not a:
            out.append(row)
            stats["not_in_audit"] += 1
            continue
        decision = a.get("review_decision", "").strip()
        if decision == "exclude":
            stats["excluded"] += 1
            continue
        if decision == "relabel":
            verified = a.get("verified_label", "").strip()
            if verified not in {"0", "1"}:
                raise ValueError(f"relabel without verified_label for {row['path']}")
            row = dict(row)
            row["label"] = verified
            stats["relabeled"] += 1
        elif decision == "keep":
            stats["kept"] += 1
        elif decision == "uncertain":
            stats["uncertain_excluded"] += 1
            continue
        else:
            stats["pending_unchanged"] += 1
        out.append(row)

    os.makedirs(os.path.dirname(os.path.abspath(args.out_csv)), exist_ok=True)
    with open(args.out_csv, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(base[0].keys()))
        w.writeheader(); w.writerows(out)
    print(f"wrote {len(out)} rows -> {args.out_csv}")
    print(dict(stats))


if __name__ == "__main__":
    main()
