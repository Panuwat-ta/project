#!/usr/bin/env python3
"""Chart stored Test-Case results for every SegFormer version.

Reads only artifacts that already exist on disk (manifest, quantitative CSV,
qualitative CSV) and never re-runs inference, so every number in the charts can
be traced back to a committed or generated result file.
"""
from __future__ import annotations

import argparse
import base64
import csv
import html
import json
from pathlib import Path
from statistics import mean, pstdev
from typing import Any, Sequence

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
from matplotlib import font_manager
from matplotlib.figure import Figure


HERE = Path(__file__).resolve().parent
SEGFORMER_ROOT = HERE.parent
PROJECT_ROOT = HERE.parents[2]
DEFAULT_MANIFEST = SEGFORMER_ROOT / "tests_model" / "evaluation_manifest.json"
DEFAULT_QUANTITATIVE = HERE / "output" / "quantitative"
DEFAULT_SPREADSHEETS = PROJECT_ROOT / "spreadsheets" / "quantitative"
DEFAULT_QUALITATIVE = HERE / "output" / "qualitative"
DEFAULT_OUTPUT = HERE / "output" / "charts"

LOCKED_METRICS = ("mIoU", "mDice", "forgery_IoU", "forgery_Dice")
LOCAL_METRICS = (
    "mIoU_percent",
    "mDice_percent",
    "forgery_IoU_percent",
    "forgery_Dice_percent",
    "accuracy_percent",
)
CATEGORY_METRICS = ("mIoU_percent", "mDice_percent", "forgery_Dice_percent")
CATEGORY_SERIES_FIELDS = (
    "mIoU_percent",
    "mDice_percent",
    "forgery_IoU_percent",
    "forgery_Dice_percent",
    "false_positive_rate_percent",
)
OVERALL_NUMERIC_FIELDS = (
    "sample_count",
    "tp",
    "fp",
    "fn",
    "tn",
    "mIoU_percent",
    "mDice_percent",
    "background_IoU_percent",
    "background_Dice_percent",
    "forgery_IoU_percent",
    "forgery_Dice_percent",
    "accuracy_percent",
    "false_positive_rate_percent",
    "det_accuracy_percent",
    "elapsed_seconds",
)
NO_FORGERY_CATEGORY = "authentic"
MATCH_TOLERANCE = 1e-6

METRIC_LABELS = {
    "mIoU": "mIoU",
    "mDice": "mDice",
    "forgery_IoU": "Forgery IoU",
    "forgery_Dice": "Forgery Dice",
    "mIoU_percent": "mIoU",
    "mDice_percent": "mDice",
    "forgery_IoU_percent": "Forgery IoU",
    "forgery_Dice_percent": "Forgery Dice",
    "accuracy_percent": "Accuracy",
    "false_positive_rate_percent": "False Positive Rate",
}

COLORS = {
    "mIoU": "#1d4ed8",
    "mDice": "#0f766e",
    "forgery_IoU": "#b45309",
    "forgery_Dice": "#b91c1c",
    "accuracy_percent": "#6d28d9",
    "false_positive_rate_percent": "#0e7490",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render version comparison charts from stored Test-Case results."
    )
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--quantitative-dir", type=Path, default=DEFAULT_QUANTITATIVE)
    parser.add_argument(
        "--spreadsheets-dir",
        type=Path,
        default=DEFAULT_SPREADSHEETS,
        help="Second snapshot used only to fill versions missing from the primary output.",
    )
    parser.add_argument("--qualitative-dir", type=Path, default=DEFAULT_QUALITATIVE)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def version_key(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.removeprefix("v").split("."))


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def as_float(value: Any) -> float | None:
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    return float(text)


def setup_style() -> list[str]:
    available = {entry.name for entry in font_manager.fontManager.ttflist}
    families = [
        name
        for name in ("Noto Sans Thai", "Droid Sans Thai", "Noto Serif Thai", "DejaVu Sans")
        if name in available
    ]
    if not families:
        return ["sans-serif"]
    plt.rcParams["font.family"] = families
    plt.rcParams["axes.unicode_minus"] = False
    return families


def data_uri(path: Path) -> str:
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:image/png;base64,{encoded}"


def save_figure(figure: Figure, path: Path) -> str:
    figure.savefig(path, dpi=140, bbox_inches="tight", facecolor="white")
    plt.close(figure)
    return path.name


def load_locked_results(manifest_path: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    dataset = dict(manifest.get("dataset") or {})
    rows: list[dict[str, Any]] = []
    for entry in manifest.get("versions") or []:
        expected = entry.get("expected_common_test") or {}
        row: dict[str, Any] = {
            "version": str(entry["version"]),
            "checkpoint": str(entry.get("checkpoint", "")),
            "test_run_id": str(entry.get("test_run_id", "")),
        }
        for metric in LOCKED_METRICS:
            row[f"{metric}_percent"] = as_float(expected.get(metric))
        rows.append(row)
    if not rows:
        raise ValueError(f"Manifest has no versions: {manifest_path}")
    rows.sort(key=lambda item: version_key(item["version"]))
    return dataset, rows


def merge_quantitative_overall(
    snapshots: Sequence[tuple[Path, str]],
) -> tuple[list[dict[str, Any]], dict[str, dict[str, str]], list[dict[str, str]]]:
    merged: dict[str, dict[str, Any]] = {}
    sources: dict[str, dict[str, str]] = {}
    notes: list[dict[str, str]] = []
    for directory, label in snapshots:
        path = directory / "overall.csv"
        if not path.is_file():
            notes.append({"status": "skipped", "detail": f"{label}: ไม่พบ {path}"})
            continue
        for row in read_csv(path):
            version = row["version"].strip()
            candidate: dict[str, Any] = {
                field: as_float(row.get(field)) for field in OVERALL_NUMERIC_FIELDS
            }
            candidate["version"] = version
            candidate["group"] = row.get("group", "").strip()
            candidate["onnx_model"] = row.get("onnx_model", "").strip()
            candidate["checkpoint"] = row.get("checkpoint", "").strip()
            existing = merged.get(version)
            if existing is None:
                merged[version] = candidate
                sources[version] = {"label": label, "path": str(path)}
                continue
            differences = [
                f"{field}: {existing[field]} vs {candidate[field]}"
                for field in LOCAL_METRICS + ("false_positive_rate_percent",)
                if existing.get(field) is None
                or candidate.get(field) is None
                or abs(existing[field] - candidate[field]) > MATCH_TOLERANCE
            ]
            if differences:
                raise ValueError(
                    "Conflicting quantitative snapshots for "
                    f"{version} between {sources[version]['label']} and {label}: "
                    + "; ".join(differences)
                )
            notes.append(
                {
                    "status": "verified",
                    "detail": f"{label}: ค่า {version} ตรงกับ {sources[version]['label']} ทุกเมตริก",
                }
            )
        notes.append({"status": "loaded", "detail": f"{label}: อ่าน {path}"})
    rows = sorted(merged.values(), key=lambda item: version_key(item["version"]))
    if not rows:
        raise ValueError("No quantitative overall.csv found in any snapshot")
    return rows, sources, notes


def merge_quantitative_categories(
    snapshots: Sequence[tuple[Path, str]],
) -> list[dict[str, Any]]:
    merged: dict[tuple[str, str], dict[str, Any]] = {}
    for directory, _label in snapshots:
        path = directory / "per_category.csv"
        if not path.is_file():
            continue
        for row in read_csv(path):
            version = row["version"].strip()
            key = (version, row["group"].strip())
            candidate: dict[str, Any] = {"version": version, "group": row["group"].strip()}
            for field in CATEGORY_SERIES_FIELDS:
                candidate[field] = as_float(row.get(field))
            candidate["sample_count"] = int(as_float(row["sample_count"]) or 0)
            merged[key] = candidate
    if not merged:
        raise ValueError("No per_category.csv found in any snapshot")
    return [merged[key] for key in sorted(merged, key=lambda item: (version_key(item[0]), item[1]))]


def required_floats(records: Sequence[dict[str, str]], field: str, path: Path) -> list[float]:
    values: list[float] = []
    for record in records:
        value = as_float(record.get(field))
        if value is None:
            raise ValueError(f"Missing numeric value for {field} in {path}")
        values.append(value)
    return values


def load_qualitative_results(
    qualitative_dir: Path,
) -> tuple[list[dict[str, Any]], list[str]]:
    rows: list[dict[str, Any]] = []
    warnings: list[str] = []
    files = sorted(qualitative_dir.glob("v*/qualitative_pair_scores_v*.csv"))
    for path in files:
        version = path.stem.removeprefix("qualitative_pair_scores_")
        records = read_csv(path)
        if not records:
            warnings.append(f"ข้าม {path}: ไฟล์ไม่มีแถวข้อมูล")
            continue
        threshold = as_float(records[0].get("threshold_percent"))
        if threshold is None:
            warnings.append(f"ข้าม {path}: ไม่พบ threshold_percent")
            continue
        declared = {row["version"].strip() for row in records}
        if declared != {version}:
            warnings.append(f"ข้าม {path}: คอลัมน์ version ไม่ตรงกับชื่อโฟลเดอร์")
            continue
        try:
            original_peaks = required_floats(records, "original_peak_percent", path)
            manipulated_peaks = required_floats(records, "manipulated_peak_percent", path)
            original_areas = required_floats(
                records, "original_area_above_threshold_percent", path
            )
            manipulated_areas = required_floats(
                records, "manipulated_area_above_threshold_percent", path
            )
        except ValueError as error:
            warnings.append(f"ข้าม {path}: {error}")
            continue
        rows.append(
            {
                "version": version,
                "pair_count": len(records),
                "threshold_percent": threshold,
                "original_peak_mean": mean(original_peaks),
                "original_peak_stdev": pstdev(original_peaks) if len(original_peaks) > 1 else 0.0,
                "manipulated_peak_mean": mean(manipulated_peaks),
                "manipulated_peak_stdev": (
                    pstdev(manipulated_peaks) if len(manipulated_peaks) > 1 else 0.0
                ),
                "original_peak_max": max(original_peaks),
                "manipulated_peak_min": min(manipulated_peaks),
                "original_area_mean": mean(original_areas),
                "manipulated_area_mean": mean(manipulated_areas),
                "manipulated_pairs_with_area": sum(1 for value in manipulated_areas if value > 0),
                "original_pairs_with_area": sum(1 for value in original_areas if value > 0),
            }
        )
    rows.sort(key=lambda item: version_key(item["version"]))
    if not rows:
        raise ValueError(f"No per-version qualitative CSV found below {qualitative_dir}")
    return rows, warnings


def draw_line_chart(
    axis: plt.Axes,
    versions: Sequence[str],
    series: Sequence[tuple[str, Sequence[float | None]]],
    *,
    ylabel: str,
    title: str,
    annotate: bool = False,
    ylim: tuple[float, float] | None = None,
    marker_size: float = 6.0,
    annotate_offset: int | None = None,
) -> None:
    positions = list(range(len(versions)))
    offsets = (-15, 11, -26, 22)
    for series_index, (label, values) in enumerate(series):
        points = [(x, value) for x, value in zip(positions, values) if value is not None]
        if not points:
            continue
        xs, ys = zip(*points)
        color = COLORS.get(label, None)
        axis.plot(
            xs,
            ys,
            marker="o",
            markersize=marker_size,
            linewidth=2.0,
            label=METRIC_LABELS.get(label, label),
            color=color,
        )
        if annotate:
            offset = (
                annotate_offset
                if annotate_offset is not None
                else offsets[series_index % len(offsets)]
            )
            for x, y in points:
                axis.annotate(
                    f"{y:.2f}",
                    (x, y),
                    textcoords="offset points",
                    xytext=(0, offset),
                    ha="center",
                    fontsize=7.5,
                    color=color or "#334155",
                )
    axis.set_xticks(positions)
    axis.set_xticklabels(versions, rotation=45, ha="right")
    axis.set_ylabel(ylabel)
    axis.set_title(title, fontsize=11)
    axis.grid(True, axis="y", alpha=0.3, linewidth=0.7)
    axis.spines["top"].set_visible(False)
    axis.spines["right"].set_visible(False)
    if ylim is not None:
        axis.set_ylim(*ylim)
    axis.legend(frameon=False, fontsize=8.5, ncols=2)


def draw_heatmap(
    axis: plt.Axes,
    figure: Figure,
    row_labels: Sequence[str],
    column_labels: Sequence[str],
    matrix: Sequence[Sequence[float | None]],
    *,
    title: str,
    cbar_label: str,
    cmap: str,
) -> None:
    grid = [[float("nan") if value is None else value for value in row] for row in matrix]
    image = axis.imshow(grid, cmap=cmap, aspect="auto")
    axis.set_xticks(range(len(column_labels)))
    axis.set_xticklabels(column_labels, rotation=45, ha="right")
    axis.set_yticks(range(len(row_labels)))
    axis.set_yticklabels(row_labels)
    axis.set_title(title, fontsize=11)
    finite = [value for row in grid for value in row if value == value]
    low, high = (min(finite), max(finite)) if finite else (0.0, 1.0)
    if high <= low:
        high = low + 1.0
    for row_index, row in enumerate(grid):
        for column_index, value in enumerate(row):
            if value != value:
                continue
            shade = (value - low) / (high - low)
            axis.text(
                column_index,
                row_index,
                f"{value:.1f}",
                ha="center",
                va="center",
                fontsize=7.5,
                color="white" if shade > 0.55 else "#0f172a",
            )
    colorbar = figure.colorbar(image, ax=axis, fraction=0.035, pad=0.02)
    colorbar.set_label(cbar_label, fontsize=9)
    colorbar.ax.tick_params(labelsize=8)


def new_figure(width: float, height: float) -> Figure:
    figure = plt.figure(figsize=(width, height))
    return figure


def chart_locked(
    rows: Sequence[dict[str, Any]], dataset: dict[str, Any], path: Path
) -> str:
    versions = [row["version"] for row in rows]
    figure = new_figure(11, 8)
    top = figure.add_subplot(211)
    bottom = figure.add_subplot(212)
    draw_line_chart(
        top,
        versions,
        [
            (metric, [row[f"{metric}_percent"] for row in rows])
            for metric in ("mIoU", "mDice")
        ],
        ylabel="เปอร์เซ็นต์",
        title=(
            "Locked common test — "
            f"{dataset.get('id', 'unknown')} "
            f"({dataset.get('test_batches', '?')} batches): mIoU และ mDice"
        ),
        annotate=True,
        ylim=(0, 108),
    )
    draw_line_chart(
        bottom,
        versions,
        [
            (metric, [row[f"{metric}_percent"] for row in rows])
            for metric in ("forgery_IoU", "forgery_Dice")
        ],
        ylabel="เปอร์เซ็นต์",
        title="Locked common test: Forgery IoU และ Forgery Dice",
        annotate=True,
        ylim=(-6, 108),
    )
    figure.tight_layout()
    name = save_figure(figure, path)
    plt.close(figure)
    return name


def chart_local_overall(rows: Sequence[dict[str, Any]], path: Path) -> str:
    versions = [row["version"] for row in rows]
    figure = new_figure(11, 8.4)
    top = figure.add_subplot(211)
    bottom = figure.add_subplot(212)
    draw_line_chart(
        top,
        versions,
        [(metric, [row.get(metric) for row in rows]) for metric in LOCAL_METRICS],
        ylabel="เปอร์เซ็นต์",
        title="Local masked Test-Case (105 ภาพ, 7 หมวด) — ค่าสูงขึ้นดีขึ้น",
        ylim=(0, 100),
    )
    fpr_values = [row.get("false_positive_rate_percent") for row in rows]
    finite_fpr = [value for value in fpr_values if value is not None]
    ceiling = max(finite_fpr) * 1.35 if finite_fpr else 1.0
    draw_line_chart(
        bottom,
        versions,
        [("false_positive_rate_percent", fpr_values)],
        ylabel="เปอร์เซ็นต์",
        title="False Positive Rate (ค่าต่ำกว่าดีกว่า)",
        annotate=True,
        annotate_offset=11,
        ylim=(0, ceiling),
    )
    figure.tight_layout()
    name = save_figure(figure, path)
    plt.close(figure)
    return name


def category_matrix(
    category_rows: Sequence[dict[str, Any]],
    versions: Sequence[str],
    field: str,
    *,
    exclude_authentic: bool,
) -> tuple[list[str], list[list[float | None]]]:
    groups = sorted(
        {row["group"] for row in category_rows if not (exclude_authentic and row["group"] == NO_FORGERY_CATEGORY)}
    )
    index = {(row["version"], row["group"]): row.get(field) for row in category_rows}
    matrix = [[index.get((version, group)) for version in versions] for group in groups]
    return groups, matrix


def chart_category_heatmap(
    category_rows: Sequence[dict[str, Any]],
    versions: Sequence[str],
    field: str,
    *,
    title: str,
    cbar_label: str,
    cmap: str,
    exclude_authentic: bool,
    path: Path,
    figure_size: tuple[float, float] = (11, 5),
) -> str:
    groups, matrix = category_matrix(
        category_rows, versions, field, exclude_authentic=exclude_authentic
    )
    figure = new_figure(*figure_size)
    axis = figure.add_subplot(111)
    draw_heatmap(
        axis,
        figure,
        groups,
        versions,
        matrix,
        title=title,
        cbar_label=cbar_label,
        cmap=cmap,
    )
    figure.tight_layout()
    name = save_figure(figure, path)
    plt.close(figure)
    return name


def chart_category_lines(
    category_rows: Sequence[dict[str, Any]],
    versions: Sequence[str],
    field: str,
    *,
    path: Path,
) -> str:
    groups, matrix = category_matrix(
        category_rows, versions, field, exclude_authentic=True
    )
    figure = new_figure(11, 5.6)
    axis = figure.add_subplot(111)
    for group_index, group in enumerate(groups):
        axis.plot(
            versions,
            matrix[group_index],
            marker="o",
            markersize=5,
            linewidth=1.8,
            label=group,
        )
    axis.set_ylabel("เปอร์เซ็นต์")
    axis.set_title(
        f"Local masked Test-Case — {METRIC_LABELS.get(field, field)} รายหมวด "
        "(ไม่รวมหมวด authentic)",
        fontsize=11,
    )
    axis.grid(True, axis="y", alpha=0.3, linewidth=0.7)
    axis.spines["top"].set_visible(False)
    axis.spines["right"].set_visible(False)
    axis.legend(frameon=False, fontsize=8.5, ncols=4)
    axis.tick_params(axis="x", labelrotation=45)
    name = save_figure(figure, path)
    plt.close(figure)
    return name


def chart_qualitative(rows: Sequence[dict[str, Any]], path: Path) -> str:
    versions = [row["version"] for row in rows]
    positions = list(range(len(versions)))
    width = 0.38
    manipulated_means = [row["manipulated_peak_mean"] for row in rows]
    manipulated_errors = [row["manipulated_peak_stdev"] for row in rows]
    original_means = [row["original_peak_mean"] for row in rows]
    original_errors = [row["original_peak_stdev"] for row in rows]
    threshold = rows[0]["threshold_percent"]

    figure = new_figure(11, 6.2)
    top = figure.add_subplot(211)
    bottom = figure.add_subplot(212)

    top.bar(
        [x - width / 2 for x in positions],
        manipulated_means,
        width=width,
        yerr=manipulated_errors,
        capsize=3,
        color="#b91c1c",
        label="Manipulated (ค่าเฉลี่ย ± SD)",
    )
    top.bar(
        [x + width / 2 for x in positions],
        original_means,
        width=width,
        yerr=original_errors,
        capsize=3,
        color="#1d4ed8",
        label="Original (ค่าเฉลี่ย ± SD)",
    )
    top.axhline(
        threshold,
        color="#0f172a",
        linestyle="--",
        linewidth=1.2,
        label=f"threshold {threshold:.0f}%",
    )
    top.set_xticks(positions)
    top.set_xticklabels(versions, rotation=45, ha="right")
    top.set_ylabel("peak probability (%)")
    top.grid(True, axis="y", alpha=0.3, linewidth=0.7)
    top.spines["top"].set_visible(False)
    top.spines["right"].set_visible(False)
    top.set_ylim(0, max(manipulated_means) + max(manipulated_errors) * 1.12)
    top.set_title(
        f"Qualitative pairs — peak probability ต่อคู่ภาพ ({rows[0]['pair_count']} คู่ต่อรุ่น)",
        fontsize=11,
        pad=26,
    )
    top.legend(
        loc="lower left",
        bbox_to_anchor=(0.0, 1.0),
        frameon=False,
        fontsize=8.5,
        ncols=3,
    )

    flagged = [row["manipulated_pairs_with_area"] for row in rows]
    false_alarm = [row["original_pairs_with_area"] for row in rows]
    bottom.bar(
        [x - width / 2 for x in positions],
        flagged,
        width=width,
        color="#b91c1c",
        label="คู่ที่ภาพดัดแปลงมีพิกเซลเกิน threshold",
    )
    bottom.bar(
        [x + width / 2 for x in positions],
        false_alarm,
        width=width,
        color="#1d4ed8",
        label="คู่ที่ภาพต้นฉบับมีพิกเซลเกิน threshold",
    )
    for x, value in zip(positions, flagged):
        bottom.annotate(
            str(value), (x - width / 2, value), textcoords="offset points",
            xytext=(0, 3), ha="center", fontsize=8,
        )
    for x, value in zip(positions, false_alarm):
        bottom.annotate(
            str(value), (x + width / 2, value), textcoords="offset points",
            xytext=(0, 3), ha="center", fontsize=8,
        )
    bottom.set_xticks(positions)
    bottom.set_xticklabels(versions, rotation=45, ha="right")
    bottom.set_ylabel(f"จำนวนคู่ (จาก {rows[0]['pair_count']} คู่)")
    bottom.set_title(
        "จำนวนคู่ที่มีพิกเซลเกิน threshold (ไม่ใช่ accuracy: คู่ภาพไม่มี ground-truth mask)",
        fontsize=11,
        pad=26,
    )
    bottom.grid(True, axis="y", alpha=0.3, linewidth=0.7)
    bottom.spines["top"].set_visible(False)
    bottom.spines["right"].set_visible(False)
    bottom.set_ylim(0, max(flagged + false_alarm) * 1.18)
    bottom.legend(
        loc="lower left",
        bbox_to_anchor=(0.0, 1.0),
        frameon=False,
        fontsize=8.5,
        ncols=2,
    )
    figure.tight_layout()
    name = save_figure(figure, path)
    plt.close(figure)
    return name


def chart_runtime(
    rows: Sequence[dict[str, Any]],
    sources: dict[str, dict[str, str]],
    path: Path,
) -> str:
    versions = [row["version"] for row in rows]
    labels = sorted({sources[row["version"]]["label"] for row in rows})
    palette = {label: color for label, color in zip(labels, ("#0f766e", "#b45309", "#6d28d9"))}
    per_image = [
        (row["elapsed_seconds"] / row["sample_count"])
        if row.get("elapsed_seconds") is not None and row["sample_count"]
        else None
        for row in rows
    ]
    colors = [palette[sources[row["version"]]["label"]] for row in rows]

    figure = new_figure(11, 5.2)
    axis = figure.add_subplot(111)
    bars = axis.bar(versions, per_image, color=colors)
    for bar, value in zip(bars, per_image):
        if value is None:
            continue
        axis.annotate(
            f"{value:.2f}s",
            (bar.get_x() + bar.get_width() / 2, value),
            textcoords="offset points",
            xytext=(0, 3),
            ha="center",
            fontsize=8,
        )
    axis.set_ylabel("วินาทีต่อภาพ")
    axis.set_title(
        "เวลา inference เฉลี่ยต่อภาพ (CPUExecutionProvider, tile 512 overlap 64) — "
        "ค่ามาจากคนละ snapshot การรัน จึงเปรียบเทียบข้ามรุ่นได้คร่าว ๆ",
        fontsize=10.5,
    )
    axis.grid(True, axis="y", alpha=0.3, linewidth=0.7)
    axis.legend(
        handles=[
            plt.Rectangle((0, 0), 1, 1, color=palette[label], label=label)
            for label in labels
        ],
        frameon=False,
        fontsize=8.5,
    )
    name = save_figure(figure, path)
    plt.close(figure)
    return name


def number(value: Any, digits: int = 2) -> str:
    parsed = as_float(value)
    if parsed is None:
        return "-"
    return f"{parsed:.{digits}f}"


def table(headers: Sequence[str], rows: Sequence[Sequence[str]], *, css_class: str = "") -> str:
    head = "".join(f"<th>{html.escape(str(header))}</th>" for header in headers)
    body = "".join(
        "<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>" for row in rows
    )
    class_attribute = f' class="{css_class}"' if css_class else ""
    return f"<table{class_attribute}><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table>"


def build_report(
    *,
    path: Path,
    charts: Sequence[tuple[str, str, str]],
    dataset: dict[str, Any],
    locked_rows: Sequence[dict[str, Any]],
    local_rows: Sequence[dict[str, Any]],
    sources: dict[str, dict[str, str]],
    category_rows: Sequence[dict[str, Any]],
    qualitative_rows: Sequence[dict[str, Any]],
    notes: Sequence[dict[str, str]],
    warnings: Sequence[str],
    payload: dict[str, Any],
) -> str:
    version_count = len({row["version"] for row in locked_rows})
    chart_sections = "".join(
        f"""
        <section class="card">
          <h2>{index}. {html.escape(title)}</h2>
          <p class="note">{html.escape(caption)}</p>
          <img alt="{html.escape(title)}" src="{data_uri(path.parent / filename)}">
        </section>
        """
        for index, (filename, title, caption) in enumerate(charts, start=1)
    )

    locked_table = table(
        ["Version", "mIoU", "mDice", "Forgery IoU", "Forgery Dice", "Test run", "Checkpoint"],
        [
            [
                row["version"],
                number(row["mIoU_percent"]),
                number(row["mDice_percent"]),
                number(row["forgery_IoU_percent"]),
                number(row["forgery_Dice_percent"]),
                html.escape(row["test_run_id"]),
                f"<code>{html.escape(row['checkpoint'])}</code>",
            ]
            for row in locked_rows
        ],
    )

    local_table = table(
        [
            "Version",
            "mIoU",
            "mDice",
            "Forgery IoU",
            "Forgery Dice",
            "Accuracy",
            "FPR",
            "elapsed (s)",
            "แหล่งข้อมูล",
        ],
        [
            [
                row["version"],
                number(row.get("mIoU_percent")),
                number(row.get("mDice_percent")),
                number(row.get("forgery_IoU_percent")),
                number(row.get("forgery_Dice_percent")),
                number(row.get("accuracy_percent")),
                number(row.get("false_positive_rate_percent")),
                number(row.get("elapsed_seconds"), 3),
                html.escape(sources[row["version"]]["label"]),
            ]
            for row in local_rows
        ],
    )

    local_versions = [row["version"] for row in local_rows]
    forgery_groups, forgery_matrix = category_matrix(
        category_rows, local_versions, "forgery_Dice_percent", exclude_authentic=True
    )
    _, fpr_matrix = category_matrix(
        category_rows, local_versions, "false_positive_rate_percent", exclude_authentic=False
    )
    _, miou_matrix = category_matrix(
        category_rows, local_versions, "mIoU_percent", exclude_authentic=True
    )
    category_table = table(
        ["หมวด / เมตริก", *local_versions],
        [
            [group, *[number(value) for value in row]]
            for group, row in zip(forgery_groups, forgery_matrix)
        ],
    )
    category_miou_table = table(
        ["หมวด (mIoU)", *local_versions],
        [
            [group, *[number(value) for value in row]]
            for group, row in zip(forgery_groups, miou_matrix)
        ],
    )
    fpr_groups, _ = category_matrix(
        category_rows, local_versions, "false_positive_rate_percent", exclude_authentic=False
    )
    fpr_table = table(
        ["หมวด (FPR %)", *local_versions],
        [
            [group, *[number(value) for value in row]]
            for group, row in zip(fpr_groups, fpr_matrix)
        ],
    )

    qualitative_table = table(
        [
            "Version",
            "จำนวนคู่",
            "peak เฉลี่ย (manipulated)",
            "peak เฉลี่ย (original)",
            "peak สูงสุด (original)",
            "peak ต่ำสุด (manipulated)",
            "manipulated เกิน thr.",
            "original เกิน thr.",
        ],
        [
            [
                row["version"],
                str(row["pair_count"]),
                f"{row['manipulated_peak_mean']:.2f} ± {row['manipulated_peak_stdev']:.2f}",
                f"{row['original_peak_mean']:.2f} ± {row['original_peak_stdev']:.2f}",
                number(row["original_peak_max"]),
                number(row["manipulated_peak_min"]),
                str(row["manipulated_pairs_with_area"]),
                str(row["original_pairs_with_area"]),
            ]
            for row in qualitative_rows
        ],
    )

    note_items = "".join(
        f"<li><span class=\"tag\">{html.escape(item['status'])}</span> {html.escape(item['detail'])}</li>"
        for item in notes
    )
    warning_items = "".join(f"<li>{html.escape(item)}</li>" for item in warnings)

    return f"""<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ScamGuard SegFormer — ผล Test-Case ทุกเวอร์ชัน</title>
<style>
  :root {{
    color-scheme: light;
    --ink: #0f172a;
    --muted: #475569;
    --line: #e2e8f0;
    --bg: #f8fafc;
    --card: #ffffff;
  }}
  * {{ box-sizing: border-box; }}
  body {{
    margin: 0;
    padding: 32px 20px 64px;
    background: var(--bg);
    color: var(--ink);
    font-family: "Noto Sans Thai", "IBM Plex Sans Thai", "Segoe UI", system-ui, sans-serif;
    line-height: 1.6;
  }}
  main {{ max-width: 1180px; margin: 0 auto; }}
  h1 {{ font-size: 1.7rem; margin: 0 0 6px; }}
  h2 {{ font-size: 1.15rem; margin: 0 0 6px; }}
  p.note {{ color: var(--muted); font-size: 0.92rem; margin: 0 0 14px; }}
  .card {{
    background: var(--card);
    border: 1px solid var(--line);
    border-radius: 12px;
    padding: 20px 22px;
    margin: 18px 0;
  }}
  .card img {{ width: 100%; height: auto; display: block; margin-top: 10px; border-radius: 8px; }}
  table {{ border-collapse: collapse; width: 100%; font-size: 0.86rem; }}
  th, td {{
    border-bottom: 1px solid var(--line);
    padding: 7px 9px;
    text-align: right;
    white-space: nowrap;
  }}
  th:first-child, td:first-child {{ text-align: left; }}
  thead th {{ background: #f1f5f9; font-weight: 600; }}
  tbody tr:hover {{ background: #f8fafc; }}
  code {{ font-size: 0.8rem; color: var(--muted); }}
  ul {{ margin: 6px 0 0; padding-left: 20px; font-size: 0.88rem; color: var(--muted); }}
  .tag {{
    display: inline-block;
    font-size: 0.72rem;
    padding: 1px 7px;
    border-radius: 999px;
    background: #e2e8f0;
    color: #334155;
    margin-right: 6px;
  }}
  .scroll {{ overflow-x: auto; }}
</style>
</head>
<body>
<main>
  <h1>ผลการทดสอบ SegFormer — ทุกเวอร์ชัน</h1>
  <p class="note">
    สร้างจากไฟล์ผลลัพธ์ที่มีอยู่แล้วในเครื่อง ไม่มีการรัน inference ใหม่
    (มี {version_count} เวอร์ชันใน manifest, {len(local_rows)} เวอร์ชันใน local masked Test-Case,
    {len(qualitative_rows)} เวอร์ชันใน qualitative pairs)
  </p>

  <section class="card">
    <h2>ขอบเขตของข้อมูล</h2>
    <ul>
      <li>Locked common test: <code>{html.escape(str(dataset.get("id", "unknown")))}</code>
        ({dataset.get("test_batches", "?")} batches) — ใช้จัดอันดับโมเดลอย่างเป็นทางการ
        ค่ามาจาก <code>tests_model/evaluation_manifest.json</code> ฟิลด์ <code>expected_common_test</code></li>
      <li>Local masked Test-Case: 105 ภาพ 7 หมวด (authentic, casia, copymove, face, imd2020,
        inpainting, splicing) ใช้ regression ในเครื่อง ไม่แทน locked common test</li>
      <li>Qualitative pairs: 30 คู่ original/manipulated ต่อรุ่น ไม่มี ground-truth mask
        จึงไม่ใช่ accuracy, IoU หรือ Dice — ใช้ดูด้วยตาเท่านั้น</li>
      <li>หมวด <code>authentic</code> ไม่มีพิกเซล forged จริง ค่า Forgery Dice จึงเป็น 0 โดยโครงสร้าง
        กราฟ Forgery Dice จึงไม่รวมหมวดนี้ ส่วน FPR ใช้ได้ทุกหมวดรวม authentic</li>
    </ul>
  </section>

  {chart_sections}

  <section class="card">
    <h2>ตาราง Locked common test</h2>
    <div class="scroll">{locked_table}</div>
  </section>

  <section class="card">
    <h2>ตาราง Local masked Test-Case (overall)</h2>
    <div class="scroll">{local_table}</div>
  </section>

  <section class="card">
    <h2>ตาราง Forgery Dice รายหมวด (%)</h2>
    <div class="scroll">{category_table}</div>
  </section>

  <section class="card">
    <h2>ตาราง mIoU รายหมวด (%)</h2>
    <div class="scroll">{category_miou_table}</div>
  </section>

  <section class="card">
    <h2>ตาราง False Positive Rate รายหมวด (%)</h2>
    <div class="scroll">{fpr_table}</div>
  </section>

  <section class="card">
    <h2>ตาราง Qualitative pairs</h2>
    <p class="note">สองคอลัมน์สุดท้ายคือจำนวนคู่ที่มีพิกเซลความน่าจะเป็นสูงกว่า threshold
      {qualitative_rows[0]['threshold_percent']:.0f}% (ไม่ใช่ accuracy เพราะคู่ภาพไม่มี ground-truth mask)</p>
    <div class="scroll">{qualitative_table}</div>
  </section>

  <section class="card">
    <h2>ที่มาของข้อมูล</h2>
    <ul>{note_items}</ul>
    {f"<ul>{warning_items}</ul>" if warning_items else ""}
  </section>
</main>
</body>
</html>
"""


def main() -> int:
    args = parse_args()
    font_used = setup_style()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    dataset, locked_rows = load_locked_results(args.manifest)
    snapshots = [
        (args.quantitative_dir, "Test-Case/output/quantitative"),
        (args.spreadsheets_dir, "spreadsheets/quantitative"),
    ]
    local_rows, sources, notes = merge_quantitative_overall(snapshots)
    category_rows = merge_quantitative_categories(snapshots)
    qualitative_rows, warnings = load_qualitative_results(args.qualitative_dir)
    local_versions = [row["version"] for row in local_rows]

    charts: list[tuple[str, str, str]] = []
    charts.append(
        (
            chart_locked(locked_rows, dataset, args.output_dir / "01_locked_common_test.png"),
            "Locked common test ทุกเวอร์ชัน",
            f"ชุด {dataset.get('id', 'unknown')} ({dataset.get('test_batches', '?')} batches) "
            "ใช้จัดอันดับโมเดลอย่างเป็นทางการ",
        )
    )
    charts.append(
        (
            chart_local_overall(local_rows, args.output_dir / "02_local_overall.png"),
            "Local masked Test-Case overall ทุกเวอร์ชัน",
            "105 ภาพ 7 หมวด เป็น regression set ในเครื่อง ไม่ใช่ locked common test",
        )
    )
    charts.append(
        (
            chart_category_heatmap(
                category_rows,
                local_versions,
                "forgery_Dice_percent",
                title="Local masked Test-Case — Forgery Dice รายหมวด (%)",
                cbar_label="Forgery Dice (%)",
                cmap="YlGn",
                exclude_authentic=True,
                path=args.output_dir / "03_local_category_forgery_dice.png",
            ),
            "Forgery Dice รายหมวด",
            "ไม่รวมหมวด authentic เพราะไม่มีพิกเซล forged ใน ground truth",
        )
    )
    charts.append(
        (
            chart_category_heatmap(
                category_rows,
                local_versions,
                "mIoU_percent",
                title="Local masked Test-Case — mIoU รายหมวด (%)",
                cbar_label="mIoU (%)",
                cmap="YlGnBu",
                exclude_authentic=True,
                path=args.output_dir / "04_local_category_miou_heatmap.png",
            ),
            "mIoU รายหมวด",
            "ไม่รวมหมวด authentic เพราะไม่มีพิกเซล forged ใน ground truth",
        )
    )
    charts.append(
        (
            chart_category_heatmap(
                category_rows,
                local_versions,
                "false_positive_rate_percent",
                title="Local masked Test-Case — False Positive Rate รายหมวด (%)",
                cbar_label="FPR (%)",
                cmap="YlOrRd",
                exclude_authentic=False,
                path=args.output_dir / "05_local_category_fpr.png",
                figure_size=(11, 5.4),
            ),
            "False Positive Rate รายหมวด",
            "รวมหมวด authentic เพราะ FPR ของภาพ authentic คือ false alarm ที่วัดได้จริง",
        )
    )
    charts.append(
        (
            chart_category_lines(
                category_rows,
                local_versions,
                "mDice_percent",
                path=args.output_dir / "06_local_category_mdice_lines.png",
            ),
            "mDice รายหมวดแนวเวลา",
            "เส้นหนึ่งเส้นต่อหนึ่งหมวด ใช้ดูทิศทางการเปลี่ยนแปลงของแต่ละหมวด",
        )
    )
    charts.append(
        (
            chart_qualitative(qualitative_rows, args.output_dir / "07_qualitative_peaks.png"),
            "Qualitative pairs ทุกเวอร์ชัน",
            "peak probability เฉลี่ยของภาพดัดแปลงเทียบภาพต้นฉบับ และจำนวนคู่ที่มีพิกเซลเกิน "
            "threshold — ไม่ใช่ accuracy เพราะคู่ภาพไม่มี ground-truth mask",
        )
    )
    charts.append(
        (
            chart_runtime(local_rows, sources, args.output_dir / "08_local_runtime.png"),
            "เวลา inference เฉลี่ยต่อภาพ",
            "คำนวณจาก elapsed_seconds ของแต่ละ snapshot ที่มีอยู่ จึงเปรียบเทียบข้ามรุ่นได้คร่าว ๆ",
        )
    )

    payload = {
        "font_used": font_used,
        "manifest": str(args.manifest),
        "locked_dataset": dataset,
        "locked_results": locked_rows,
        "local_results": local_rows,
        "local_sources": sources,
        "local_categories": category_rows,
        "qualitative_results": qualitative_rows,
        "charts": [filename for filename, _title, _caption in charts],
    }
    (args.output_dir / "charts_data.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    report = build_report(
        path=args.output_dir / "report.html",
        charts=charts,
        dataset=dataset,
        locked_rows=locked_rows,
        local_rows=local_rows,
        sources=sources,
        category_rows=category_rows,
        qualitative_rows=qualitative_rows,
        notes=notes,
        warnings=warnings,
        payload=payload,
    )
    (args.output_dir / "report.html").write_text(report, encoding="utf-8")

    print(f"Wrote {len(charts)} charts and report.html to {args.output_dir}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
