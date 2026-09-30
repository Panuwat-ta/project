#!/usr/bin/env python3
"""Evaluate every pinned SegFormer ONNX model against local image/mask cases."""
from __future__ import annotations

import argparse
import csv
import json
import sys
import time
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable

import numpy as np
import onnxruntime as ort
from PIL import Image

from evaluation_core import (
    MaskCase,
    OnnxSegmenter,
    binary_confusion,
    det_score_image,
    discover_mask_cases,
    metrics_from_confusion,
)


HERE = Path(__file__).resolve().parent
SEGFORMER_ROOT = HERE.parent
DEFAULT_DATA_ROOT = Path("/home/panuwat/Pictures/Test-Cases/with_mask")
DEFAULT_MANIFEST = SEGFORMER_ROOT / "tests_model" / "evaluation_manifest.json"
DEFAULT_OUTPUT = HERE / "output" / "quantitative"
COUNT_FIELDS = ("tp", "fp", "fn", "tn")
METRIC_FIELDS = (
    "mIoU",
    "mDice",
    "background_IoU",
    "background_Dice",
    "forgery_IoU",
    "forgery_Dice",
    "accuracy",
    "false_positive_rate",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run production-style tiled ONNX inference on image/mask cases."
    )
    parser.add_argument("--data-root", type=Path, default=DEFAULT_DATA_ROOT)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--versions",
        nargs="*",
        help="Versions to evaluate (default: every version in the manifest).",
    )
    parser.add_argument("--threshold", type=float, default=0.5)
    parser.add_argument("--tile-size", type=int, default=512)
    parser.add_argument("--tile-overlap", type=int, default=64)
    parser.add_argument("--release-version", default="v1.0.5")
    parser.add_argument(
        "--minimum-mdice",
        type=float,
        default=0.85,
        help="Release-gate minimum as a fraction (default: 0.85).",
    )
    parser.add_argument(
        "--no-release-gate",
        action="store_true",
        help="Generate results without returning failure when the release gate fails.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        help="Development-only: process the first N cases per version.",
    )
    return parser.parse_args()


def load_entries(manifest_path: Path, requested: list[str] | None) -> list[dict[str, Any]]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = manifest.get("versions")
    if not isinstance(entries, list) or not entries:
        raise ValueError(f"Manifest has no versions: {manifest_path}")
    by_version = {str(entry["version"]): entry for entry in entries}
    versions = requested or list(by_version)
    unknown = [version for version in versions if version not in by_version]
    if unknown:
        raise ValueError(f"Unknown version(s): {', '.join(unknown)}")
    return [by_version[version] for version in versions]


def add_confusion(total: dict[str, int], counts: dict[str, int]) -> None:
    for field in COUNT_FIELDS:
        total[field] += counts[field]


def percentage(value: float | None) -> float | None:
    return round(value * 100.0, 6) if value is not None else None


def result_row(
    *,
    version: str,
    group: str,
    sample_count: int,
    counts: dict[str, int],
) -> dict[str, Any]:
    metrics = metrics_from_confusion(counts)
    row: dict[str, Any] = {
        "version": version,
        "group": group,
        "sample_count": sample_count,
        **counts,
    }
    row.update({f"{field}_percent": percentage(metrics[field]) for field in METRIC_FIELDS})
    return row


def write_csv(path: Path, rows: Iterable[dict[str, Any]], fieldnames: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def read_case(case: MaskCase) -> tuple[Image.Image, np.ndarray]:
    image = Image.open(case.image_path).convert("RGB")
    mask_image = Image.open(case.mask_path).convert("L")
    if image.size != mask_image.size:
        raise ValueError(
            f"Image/mask size mismatch for {case.case_id}: {image.size} != {mask_image.size}"
        )
    return image, (np.asarray(mask_image, dtype=np.uint8) > 0).astype(np.uint8)


def evaluate_entry(
    entry: dict[str, Any],
    cases: list[MaskCase],
    args: argparse.Namespace,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], dict[str, Any]]:
    version = str(entry["version"])
    model_path = SEGFORMER_ROOT / str(entry["onnx_model"])
    if not model_path.is_file():
        raise FileNotFoundError(f"Missing ONNX model for {version}: {model_path}")
    print(f"[{version}] loading {model_path.name}", flush=True)
    session = ort.InferenceSession(str(model_path), providers=["CPUExecutionProvider"])
    segmenter = OnnxSegmenter(
        session,
        tile_size=args.tile_size,
        overlap=args.tile_overlap,
    )
    category_counts: dict[str, dict[str, int]] = defaultdict(
        lambda: {field: 0 for field in COUNT_FIELDS}
    )
    category_samples: dict[str, int] = defaultdict(int)
    category_det_ok: dict[str, int] = defaultdict(int)
    category_det_n: dict[str, int] = defaultdict(int)
    overall_counts = {field: 0 for field in COUNT_FIELDS}
    overall_det_ok = 0
    overall_det_n = 0
    per_image: list[dict[str, Any]] = []
    started = time.monotonic()
    has_det = len(session.get_outputs()) >= 2

    for index, case in enumerate(cases, start=1):
        image, target = read_case(case)
        probability = segmenter.probability_map(image)
        prediction = (probability >= args.threshold).astype(np.uint8)
        counts = binary_confusion(prediction, target)
        metrics = metrics_from_confusion(counts)
        add_confusion(category_counts[case.category], counts)
        add_confusion(overall_counts, counts)
        category_samples[case.category] += 1
        image_label = 1 if target.sum() > 0 else 0
        det_score = det_score_image(session, image) if has_det else None
        det_pred = None
        det_correct = None
        if det_score is not None:
            det_pred = 1 if det_score >= 0.5 else 0
            det_correct = 1 if det_pred == image_label else 0
            category_det_ok[case.category] += det_correct
            category_det_n[case.category] += 1
            overall_det_ok += det_correct
            overall_det_n += 1
        per_image.append(
            {
                "version": version,
                "category": case.category,
                "case_id": case.case_id,
                "image_path": str(case.image_path),
                "mask_path": str(case.mask_path),
                "width": image.width,
                "height": image.height,
                "threshold_percent": args.threshold * 100.0,
                **counts,
                **{
                    f"{field}_percent": percentage(metrics[field])
                    for field in METRIC_FIELDS
                },
                "det_score": det_score,
                "det_pred_label": det_pred,
                "det_correct": det_correct,
            }
        )
        if index == len(cases) or index % 10 == 0:
            print(f"[{version}] {index}/{len(cases)} cases", flush=True)

    category_rows = [
        result_row(
            version=version,
            group=category,
            sample_count=category_samples[category],
            counts=category_counts[category],
        )
        for category in sorted(category_counts)
    ]
    for row in category_rows:
        n = category_det_n[row["group"]]
        row["det_accuracy_percent"] = (
            round(category_det_ok[row["group"]] / n * 100.0, 6) if n else None
        )
    overall = result_row(
        version=version,
        group="all",
        sample_count=len(cases),
        counts=overall_counts,
    )
    overall["det_accuracy_percent"] = (
        round(overall_det_ok / overall_det_n * 100.0, 6) if overall_det_n else None
    )
    overall.update(
        {
            "onnx_model": str(model_path),
            "checkpoint": str(entry.get("checkpoint", "")),
            "elapsed_seconds": round(time.monotonic() - started, 3),
        }
    )
    return per_image, category_rows, overall


def main() -> int:
    args = parse_args()
    if not 0.0 < args.threshold < 1.0:
        raise ValueError("threshold must be between 0 and 1")
    if not 0.0 <= args.minimum_mdice <= 1.0:
        raise ValueError("minimum-mdice must be between 0 and 1")

    entries = load_entries(args.manifest, args.versions)
    cases = discover_mask_cases(args.data_root)
    if args.limit is not None:
        if args.limit <= 0:
            raise ValueError("limit must be positive")
        cases = cases[: args.limit]
    args.output_dir.mkdir(parents=True, exist_ok=True)

    all_per_image: list[dict[str, Any]] = []
    all_categories: list[dict[str, Any]] = []
    all_overall: list[dict[str, Any]] = []
    for entry in entries:
        per_image, categories, overall = evaluate_entry(entry, cases, args)
        all_per_image.extend(per_image)
        all_categories.extend(categories)
        all_overall.append(overall)

    metric_columns = [f"{field}_percent" for field in METRIC_FIELDS]
    count_columns = list(COUNT_FIELDS)
    write_csv(
        args.output_dir / "per_image.csv",
        all_per_image,
        [
            "version",
            "category",
            "case_id",
            "image_path",
            "mask_path",
            "width",
            "height",
            "threshold_percent",
            *count_columns,
            *metric_columns,
            "det_score",
            "det_pred_label",
            "det_correct",
        ],
    )
    aggregate_columns = [
        "version",
        "group",
        "sample_count",
        *count_columns,
        *metric_columns,
        "det_accuracy_percent",
    ]
    write_csv(args.output_dir / "per_category.csv", all_categories, aggregate_columns)
    write_csv(
        args.output_dir / "overall.csv",
        all_overall,
        [*aggregate_columns, "onnx_model", "checkpoint", "elapsed_seconds"],
    )

    release_result = next(
        (row for row in all_overall if row["version"] == args.release_version), None
    )
    gate = {
        "version": args.release_version,
        "metric": "mDice_percent",
        "minimum_percent": args.minimum_mdice * 100.0,
        "actual_percent": release_result["mDice_percent"] if release_result else None,
        "passed": bool(
            release_result
            and release_result["mDice_percent"] is not None
            and release_result["mDice_percent"] >= args.minimum_mdice * 100.0
        ),
        "enforced": not args.no_release_gate,
    }
    summary = {
        "dataset_root": str(args.data_root.resolve()),
        "case_count": len(cases),
        "categories": sorted({case.category for case in cases}),
        "versions": [entry["version"] for entry in entries],
        "inference": {
            "strategy": "overlapping_tiles",
            "tile_size": args.tile_size,
            "tile_overlap": args.tile_overlap,
            "forgery_threshold_percent": args.threshold * 100.0,
            "provider": "CPUExecutionProvider",
        },
        "overall": all_overall,
        "release_gate": gate,
        "scope_note": (
            "This local image regression set does not replace the locked common test set "
            "used for official model ranking."
        ),
    }
    (args.output_dir / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Wrote quantitative results to {args.output_dir}", flush=True)
    if args.no_release_gate:
        return 0
    if release_result is None:
        print(
            f"Release gate not evaluated: {args.release_version} was not selected.",
            file=sys.stderr,
        )
        return 2
    if not gate["passed"]:
        print(
            f"Release gate failed: {args.release_version} mDice "
            f"{gate['actual_percent']:.2f}% < {gate['minimum_percent']:.2f}%",
            file=sys.stderr,
        )
        return 1
    print(
        f"Release gate passed: {args.release_version} mDice "
        f"{gate['actual_percent']:.2f}% >= {gate['minimum_percent']:.2f}%",
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
