#!/usr/bin/env python3
"""Test-case and chart per Det-Head version (no re-inference).

Reads the stored diagnostics produced by ``eval_det_diagnostics.py`` and
never re-runs inference, so every number traces back to a stored result file:

- ``diagnostics_det_versions_2026-10-02`` (20 main heads det1-det7b)
- ``diagnostics_det_seeds_2026-10-02`` (6 multiseed heads)

For each of the 26 versions it writes ``<out-dir>/<head>/`` containing:

- ``testcases__<head>.csv``, ``camera9__<head>.csv``,
  ``chatshot2__<head>.csv`` (copies of the stored per-set result rows)
- ``summary.json`` (confusion metrics of the 3 sets + weight/checkpoint
  provenance recorded in the source ``diagnostics.json``)
- ``<head>_scores.png`` (one overview chart: score histogram split by true
  label on testcases 165 images + per-dataset accuracy bars + key metrics)

Plus ``<out-dir>/index.json`` listing every version and its source run.
"""
from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt

from plot_det_versions import (
    AUTHENTIC_COLOR,
    MANIPULATED_COLOR,
    TESTCASES_DATASETS,
    read_rows,
    save_figure,
    setup_style,
)

HERE = Path(__file__).resolve().parent
DEFAULT_VERSIONS = HERE / "diagnostics_det_versions_2026-10-02"
DEFAULT_SEEDS = HERE / "diagnostics_det_seeds_2026-10-02"
DEFAULT_OUTPUT = HERE / "per_version_2026-10-02"

MAIN_ORDER = (
    "det1", "det2a", "det2b", "det3a", "det3b", "det3c",
    "det4a", "det4b", "det4c", "det5a_pre", "det5a", "det5b",
    "det5c", "det5d", "det5e", "det5f", "det5g", "det6a",
    "det7a", "det7b",
)
SEED_ORDER = (
    "det5a_seed123", "det5a_seed7",
    "det7a_seed123", "det7a_seed7",
    "det7b_seed123", "det7b_seed7",
)
HEAD_ORDER_ALL = MAIN_ORDER + SEED_ORDER

SETS = ("testcases", "camera9", "chatshot2")


def load_run(run_dir: Path) -> dict:
    return json.loads((run_dir / "diagnostics.json").read_text(encoding="utf-8"))


def locate_sources(version_dirs: list[Path]) -> dict[str, dict]:
    """Map head name to its source run directory, payload and weight path."""
    sources: dict[str, dict] = {}
    for run_dir in version_dirs:
        payload = load_run(run_dir)
        for head, weight in payload["heads"].items():
            if head in sources:
                raise ValueError(f"duplicate head {head} in {run_dir}")
            sources[head] = {
                "run_dir": run_dir,
                "payload": payload,
                "weight": weight,
            }
    if not sources:
        raise ValueError("no heads found in any diagnostics run")
    return sources


def ordered_all(sources: dict[str, dict]) -> list[str]:
    known = [head for head in HEAD_ORDER_ALL if head in sources]
    extra = sorted(head for head in sources if head not in HEAD_ORDER_ALL)
    if not known and not extra:
        raise ValueError("no heads to package")
    return known + extra


def build_summary(head: str, source: dict) -> dict:
    payload = source["payload"]
    return {
        "head": head,
        "weight_path": source["weight"],
        "source_run": str(source["run_dir"]),
        "checkpoint": payload.get("checkpoint"),
        "threshold": payload.get("threshold"),
        "sets": {
            set_name: payload["sets"][set_name][head] for set_name in SETS
        },
    }


def chart_version(run_dir: Path, head: str, summary: dict, out_png: Path) -> str:
    rows = read_rows(run_dir / f"testcases__{head}.csv")
    authentic = [float(r["score"]) for r in rows if int(r["label"]) == 0]
    manipulated = [float(r["score"]) for r in rows if int(r["label"]) == 1]
    threshold = float(summary["threshold"])
    overall = summary["sets"]["testcases"]
    by_dataset = overall.get("by_dataset", {})

    figure = plt.figure(figsize=(15, 8))
    left = figure.add_subplot(121)
    bins = [i / 25 for i in range(26)]
    left.hist(authentic, bins=bins, color=AUTHENTIC_COLOR, alpha=0.70,
              label=f"ภาพจริง ({len(authentic)} ภาพ)")
    left.hist(manipulated, bins=bins, color=MANIPULATED_COLOR, alpha=0.70,
              label=f"ภาพดัดแปลง ({len(manipulated)} ภาพ)")
    left.axvline(threshold, color="#0f172a", linestyle="--", linewidth=1.4,
                 label=f"threshold {threshold:g}")
    left.set_xlabel("det score")
    left.set_ylabel("จำนวนภาพ")
    left.set_title("การกระจายคะแนน testcases 165 ภาพ แยกตามป้ายจริง", fontsize=11)
    left.set_xlim(0, 1)
    left.legend(frameon=False, fontsize=9)
    left.grid(True, axis="y", alpha=0.3, linewidth=0.7)
    left.spines["top"].set_visible(False)
    left.spines["right"].set_visible(False)

    right = figure.add_subplot(122)
    datasets = [ds for ds in TESTCASES_DATASETS if ds in by_dataset]
    values = [((by_dataset[ds].get("accuracy") or 0.0) * 100.0) for ds in datasets]
    positions = list(range(len(datasets)))
    bars = right.barh(positions, values, color="#0f766e", height=0.62)
    for bar, value in zip(bars, values):
        right.text(value + 0.7, bar.get_y() + bar.get_height() / 2,
                   f"{value:.1f}", va="center", fontsize=9, color="#0f172a")
    right.set_yticks(positions)
    right.set_yticklabels(datasets, fontsize=9)
    right.set_xlabel("accuracy (%)")
    right.set_title("accuracy รายหมวดของเวอร์ชันนี้", fontsize=11)
    right.set_xlim(0, 108)
    right.grid(True, axis="x", alpha=0.3, linewidth=0.7)
    right.spines["top"].set_visible(False)
    right.spines["right"].set_visible(False)

    camera = summary["sets"]["camera9"]
    chat = summary["sets"]["chatshot2"]
    figure.suptitle(
        f"{head} — testcases accuracy {overall['accuracy']:.4f} "
        f"(specificity {overall['specificity']:.4f}, recall {overall['recall']:.4f})",
        fontsize=13,
    )
    figure.text(
        0.5, 0.01,
        f"camera9 (ภาพกล้องจริง 9 ภาพ): {camera['accuracy']:.4f}   "
        f"chatshot2 (แชต 2 ภาพ ดูแนวโน้มเท่านั้น): {chat['accuracy']:.4f}   "
        f"threshold {threshold:g}",
        ha="center", fontsize=9, color="#475569",
    )
    figure.tight_layout(rect=(0, 0.04, 1, 0.94))
    return save_figure(figure, out_png)


def build_version(head: str, source: dict, out_root: Path) -> dict:
    run_dir: Path = source["run_dir"]
    version_dir = out_root / head
    version_dir.mkdir(parents=True, exist_ok=True)
    for set_name in SETS:
        shutil.copy2(run_dir / f"{set_name}__{head}.csv",
                     version_dir / f"{set_name}__{head}.csv")
    summary = build_summary(head, source)
    chart_version(run_dir, head, summary, version_dir / f"{head}_scores.png")
    (version_dir / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return summary


def build_all(version_dirs: list[Path], out_root: Path) -> list[str]:
    setup_style()
    sources = locate_sources(version_dirs)
    heads = ordered_all(sources)
    out_root.mkdir(parents=True, exist_ok=True)
    index = {"sources": [str(d) for d in version_dirs], "versions": {}}
    for head in heads:
        summary = build_version(head, sources[head], out_root)
        index["versions"][head] = {
            "dir": head,
            "weight_path": summary["weight_path"],
            "testcases_accuracy": summary["sets"]["testcases"]["accuracy"],
        }
    (out_root / "index.json").write_text(
        json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"packaged {len(heads)} versions to {out_root}", flush=True)
    return heads


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Package per-version Det-Head test-cases and charts "
                    "from stored diagnostics (no re-inference)."
    )
    parser.add_argument("--versions-dir", type=Path, default=DEFAULT_VERSIONS)
    parser.add_argument("--seeds-dir", type=Path, default=DEFAULT_SEEDS)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    build_all([args.versions_dir, args.seeds_dir], args.output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
