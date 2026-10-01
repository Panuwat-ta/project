"""Det Head search loop: train -> diagnose -> gate -> leaderboard.

Why this loop selects on diagnostics instead of Val accuracy
------------------------------------------------------------
Measured on 2026-09-29 (Det-Head/diagnostics_baseline_2026-09-29):

    head                        Val acc   camera9 spec   pilot11 acc   testcases acc
    det2b (production/shadow)    85.93%       33.33%         54.55%        86.06%
    det5a (16 local tokens)      86.38%       11.11%         27.27%        86.67%
    det6a (64 local tokens)      86.18%       22.22%         45.45%        87.27%

Every rejected candidate from det3 to det6g had a *higher* Val accuracy than
det2b and a *worse* real-camera specificity. Ranking by Val would have selected
det6a over det2b, which is the opposite of what the real-world diagnostic says.
So the gate here is the external diagnostic set, and Val is recorded but never
used to accept a candidate.

Diagnostic domains
------------------
``camera9`` is 9 direct mobile-camera photos. The 11 files in
``Test-Cases/image-Authentic`` are not one domain: the user confirmed on
2026-09-29 that ``to1`` is a LINE chat capture and ``to11`` is a screen
capture, and both carry zero EXIF tags while the other 9 carry 12 each. They are
split here so a camera number and a chat/screenshot number are never mixed.

``chatshot2`` is scored for visibility but never gated (n=2). All three
existing heads score 0/2 on it with mean scores 0.71-0.86, i.e. every deployed
head currently calls both authentic chat captures manipulated. That domain is a
stated product use case with zero representation in the training data.

Guardrails enforced here
------------------------
* the production det2b baseline is never overwritten
* the Locked Test 44,031 is never touched by this loop
* every candidate's score is written to the leaderboard even when it fails, so
  a failed run still leaves evidence
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import subprocess
import sys
import time
from pathlib import Path

DET_HEAD = Path(__file__).resolve().parent
PROJECT_ROOT = DET_HEAD.parent
VENV_PY = PROJECT_ROOT / "venv" / "bin" / "python"
SEG_CHECKPOINT = PROJECT_ROOT / "work_dirs" / "v1.0.6" / "best_mIoU_iter_195000.pth"

# Production/shadow baseline, measured with eval_det_diagnostics.py on
# 2026-09-29 after the camera9/chatshot2 split. det2b is the deployed head.
PRODUCTION_BASELINE = {
    "name": "det2b_mlp_source_balanced",
    "head": DET_HEAD / "det_v1.0.6_det2b_mlp_source_balanced" / "det_head.pth",
    "val_accuracy": 0.85925492816572,
    "camera9_specificity": 0.3333333333333333,
    "pilot11_accuracy": 0.5454545454545454,
    "testcases_accuracy": 0.8606060606060606,
    "cameraxdev104_specificity": 0.2980769230769231,
}

# chatshot2 is reported but never gated. It holds 2 images (one LINE chat capture,
# one screen capture) and all three existing heads score 0/2 on it, so a gate
# would only measure noise at n=2. Its purpose is to keep the chat/screenshot
# domain visible, which is a stated product use case with zero representation in
# the training data.
GATED_METRICS = (
    ("camera9_specificity", "camera9 specificity"),
    ("pilot11_accuracy", "pilot11 accuracy"),
    ("testcases_accuracy", "testcases accuracy"),
    # n=104 from a capture pipeline that was never trained on, so one image is
    # worth 0.96 points instead of camera9's 11.1. This is the real-camera signal
    # that is statistically usable, and it measures cross-device generalisation
    # rather than memorisation of the single 15.93 MP training device.
    ("cameraxdev104_specificity", "cameraxdev104 specificity"),
)
REPORT_ONLY_METRICS = (
    ("chatshot2_accuracy", "chatshot2 accuracy"),
    ("chatshot2_mean_score", "chatshot2 mean score"),
)

# Screening subsample Val accuracies are NOT comparable to full-data Val
# accuracies, so this floor only guards against a candidate that failed to train.
VAL_SCREENING_FLOOR = 0.80


def run(cmd: list[str], log_path: Path) -> tuple[int, str]:
    with open(log_path, "w") as log:
        proc = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, cwd=PROJECT_ROOT)
    with open(log_path) as f:
        return proc.returncode, f.read()


def read_diagnostics(out_dir: Path, head_name: str) -> dict:
    with open(out_dir / "diagnostics.json") as f:
        data = json.load(f)
    sets = data["sets"]
    metrics = {
        "camera9_specificity": sets["camera9"][head_name]["specificity"],
        "camera9_mean_score": sets["camera9"][head_name]["mean_score"],
        "chatshot2_accuracy": sets["chatshot2"][head_name]["accuracy"],
        "chatshot2_specificity": sets["chatshot2"][head_name]["specificity"],
        "chatshot2_mean_score": sets["chatshot2"][head_name]["mean_score"],
        "pilot11_accuracy": sets["pilot11"][head_name]["accuracy"],
        "pilot11_specificity": sets["pilot11"][head_name]["specificity"],
        "testcases_accuracy": sets["testcases"][head_name]["accuracy"],
        "testcases_specificity": sets["testcases"][head_name]["specificity"],
        "testcases_recall": sets["testcases"][head_name]["recall"],
    }
    if "cameraxdev104" in sets:
        metrics["cameraxdev104_specificity"] = sets["cameraxdev104"][head_name]["specificity"]
        metrics["cameraxdev104_mean_score"] = sets["cameraxdev104"][head_name]["mean_score"]
    if "cameraval16" in sets:
        metrics["cameraval16_specificity"] = sets["cameraval16"][head_name]["specificity"]
    return metrics


def gate(metrics: dict, val_accuracy: float) -> tuple[bool, list[str]]:
    """Hard gates are all 'must be at least the production level'.

    chatshot2 is intentionally absent: n=2 cannot separate a regression from
    noise. It is scored and reported on every candidate so the chat/screenshot
    domain stays visible, but it never accepts or rejects a candidate.
    """
    failures = []
    if val_accuracy < VAL_SCREENING_FLOOR:
        failures.append(f"val_accuracy {val_accuracy:.4f} < screening floor {VAL_SCREENING_FLOOR}")
    for key, label in GATED_METRICS:
        got = metrics[key]
        need = PRODUCTION_BASELINE[key]
        if got is None or got < need:
            failures.append(f"{label} {got} < production {need:.4f}")
    return (not failures), failures


def leaderboard_row(entry: dict) -> dict:
    """Flatten one entry; failed runs stay visible instead of being dropped."""
    diagnostics = entry.get("diagnostics", {})
    return {
        "candidate": entry["candidate"],
        "arch": entry.get("arch"),
        "is_baseline": bool(entry.get("is_baseline")),
        "screening": entry.get("screening"),
        "n_train": entry.get("n_train"),
        "best_epoch": entry.get("best_epoch"),
        "val_accuracy": entry.get("val_accuracy"),
        "val_roc_auc": entry.get("val_roc_auc"),
        "camera9_specificity": diagnostics.get("camera9_specificity"),
        "cameraxdev104_specificity": diagnostics.get("cameraxdev104_specificity"),
        "chatshot2_accuracy": diagnostics.get("chatshot2_accuracy"),
        "chatshot2_mean_score": diagnostics.get("chatshot2_mean_score"),
        "pilot11_accuracy": diagnostics.get("pilot11_accuracy"),
        "testcases_accuracy": diagnostics.get("testcases_accuracy"),
        "gate_passed": entry.get("gate_passed"),
        "gate_failures": "; ".join(entry.get("gate_failures", [])),
        "error": entry.get("error"),
    }


def write_leaderboard(path: Path, entries: list[dict]) -> None:
    rows = [leaderboard_row(e) for e in entries]
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--feature-cache", required=True)
    ap.add_argument("--plan", required=True, help="JSON file with the candidate list")
    ap.add_argument("--out-root", required=True)
    ap.add_argument("--subsample", type=int, default=25000)
    ap.add_argument("--epochs", type=int, default=12)
    ap.add_argument("--patience", type=int, default=4)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--extra-cache", default=None,
                    help="default value for a candidate's extra_cache=auto")
    ap.add_argument("--only", default=None, help="comma-separated candidate names to run")
    ap.add_argument("--baseline-dir", default=None,
                    help="existing diagnostics dir for the production head; "
                         "skips the extra baseline pass when given")
    args = ap.parse_args()

    with open(args.plan) as f:
        plan = json.load(f)
    candidates = plan["candidates"]
    if args.only:
        wanted = {x.strip() for x in args.only.split(",")}
        candidates = [c for c in candidates if c["name"] in wanted]

    out_root = Path(args.out_root)
    out_root.mkdir(parents=True, exist_ok=True)
    leaderboard_path = out_root / "leaderboard.csv"
    state_path = out_root / "results.json"
    if state_path.is_file():
        with open(state_path) as f:
            entries = json.load(f)
    else:
        entries = []

    done = {e["candidate"] for e in entries}
    if not args.baseline_dir and not any(e.get("is_baseline") for e in entries):
        print("=== scoring production baseline det2b ===", flush=True)
        base_out = out_root / "baseline_det2b"
        base_out.mkdir(parents=True, exist_ok=True)
        rc, tail = run([str(VENV_PY), "-u", "Det-Head/eval_det_diagnostics.py",
                        "--head", f"det2b={PRODUCTION_BASELINE['head']}",
                        "--out-dir", str(base_out)],
                       out_root / "baseline_det2b.log")
        if rc != 0:
            raise SystemExit(f"baseline diagnostics failed:\n{tail[-2000:]}")
        entries.append({
            "candidate": "BASELINE_det2b_production", "arch": "mlp",
            "is_baseline": True, "screening": False, "n_train": 95770,
            "best_epoch": None,
            "val_accuracy": PRODUCTION_BASELINE["val_accuracy"],
            "val_roc_auc": 0.9404922255384209,
            "diagnostics": read_diagnostics(base_out, "det2b"),
            "gate_passed": True, "gate_failures": [],
        })
        write_leaderboard(leaderboard_path, entries)
        with open(state_path, "w") as f:
            json.dump(entries, f, indent=2)

    print(f"{'candidate':38} {'val':>7} {'cam9':>7} {'pilot':>7} {'tc165':>7}  gate", flush=True)
    for c in candidates:
        if c["name"] in done:
            print(f"{c['name']:38} (skipped, already in leaderboard)", flush=True)
            continue
        started = time.time()
        work_dir = out_root / c["name"]
        work_dir.mkdir(parents=True, exist_ok=True)
        cmd = [str(VENV_PY), "-u", "Det-Head/train_det_screen.py",
               "--checkpoint", str(SEG_CHECKPOINT),
               "--feature-cache", args.feature_cache,
               "--work-dir", str(work_dir),
               "--arch", c["arch"],
               "--dropout", str(c.get("dropout", 0.2)),
               "--topk", str(c.get("topk", 4)),
               "--lr", str(c.get("lr", 1e-4)),
               "--seed", str(c.get("seed", 42)),
               "--subsample", str(args.subsample),
               "--epochs", str(c.get("epochs", args.epochs)),
               "--patience", str(args.patience),
               "--workers", str(args.workers)]
        if c.get("source_balanced"):
            cmd += ["--source-balanced"]
        if c.get("sample_weight_csv"):
            cmd += ["--sample-weight-csv", c["sample_weight_csv"]]
        extra = c.get("extra_cache")
        if extra == "auto":
            extra = args.extra_cache
        if extra:
            if not extra or not os.path.isdir(extra):
                print(f"{c['name']:38} SKIPPED: extra cache missing: {extra!r}", flush=True)
                continue
            cmd += ["--extra-cache", extra]
        print(f"--- training {c['name']} (arch={c['arch']}"
              f"{', +extra cache' if extra else ''})", flush=True)
        rc, tail = run(cmd, work_dir / "train.log")
        if rc != 0:
            print(f"{c['name']:38} TRAIN FAILED\n{tail[-1500:]}", flush=True)
            entries.append({
                "candidate": c["name"], "arch": c["arch"], "error": "train_failed",
                "gate_passed": False, "gate_failures": ["train_failed"],
            })
            write_leaderboard(leaderboard_path, entries)
            with open(state_path, "w") as f:
                json.dump(entries, f, indent=2)
            continue

        with open(work_dir / "train_log.json") as f:
            tlog = json.load(f)["meta"]
        diag_dir = work_dir / "diagnostics"
        rc, tail = run([str(VENV_PY), "-u", "Det-Head/eval_det_diagnostics.py",
                        "--head", f"cand={work_dir / 'head.pth'}",
                        "--out-dir", str(diag_dir)], work_dir / "diagnostics.log")
        if rc != 0:
            print(f"{c['name']:38} DIAGNOSTICS FAILED\n{tail[-1500:]}", flush=True)
            entries.append({
                "candidate": c["name"], "arch": c["arch"], "error": "diagnostics_failed",
                "gate_passed": False, "gate_failures": ["diagnostics_failed"],
            })
            write_leaderboard(leaderboard_path, entries)
            with open(state_path, "w") as f:
                json.dump(entries, f, indent=2)
            continue

        metrics = read_diagnostics(diag_dir, "cand")
        passed, failures = gate(metrics, tlog["best_val_acc"])
        entries.append({
            "candidate": c["name"], "arch": c["arch"],
            "screening": tlog["screening"], "n_train": tlog["n_train"],
            "best_epoch": tlog["best_epoch"],
            "val_accuracy": tlog["best_val_acc"],
            "val_roc_auc": tlog["val_roc_auc"],
            "diagnostics": metrics,
            "gate_passed": passed, "gate_failures": failures,
            "elapsed_s": round(time.time() - started, 1),
        })
        write_leaderboard(leaderboard_path, entries)
        with open(state_path, "w") as f:
            json.dump(entries, f, indent=2)

        mark = "PASS" if passed else "fail"
        print(f"{c['name']:38} {tlog['best_val_acc']:.4f} "
              f"{metrics['camera9_specificity']:.4f} "
              f"{metrics['pilot11_accuracy']:.4f} "
              f"{metrics['testcases_accuracy']:.4f}  {mark}  "
              f"(chatshot2 {metrics['chatshot2_accuracy']:.2f} "
              f"mean={metrics['chatshot2_mean_score']:.3f} report-only)", flush=True)
        for f_ in failures:
            print(f"{'':38}   - {f_}", flush=True)

    write_leaderboard(leaderboard_path, entries)
    print(f"\nleaderboard: {leaderboard_path}")


if __name__ == "__main__":
    main()
