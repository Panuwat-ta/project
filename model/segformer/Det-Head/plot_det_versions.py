#!/usr/bin/env python3
"""Chart Det-Head version comparison from a diagnostics run.

Reads the ``diagnostics.json`` and per-set CSV files produced by
``eval_det_diagnostics.py`` and never re-runs inference, so every number in
the charts traces back to a stored result file.
"""
from __future__ import annotations

import argparse
import base64
import csv
import html
import json
from pathlib import Path
from statistics import mean
from typing import Any, Sequence

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
from matplotlib import font_manager
from matplotlib.figure import Figure


HERE = Path(__file__).resolve().parent
DEFAULT_DIAGNOSTICS = HERE / "diagnostics_det_versions_2026-10-02"
DEFAULT_OUTPUT = DEFAULT_DIAGNOSTICS / "charts"

HEAD_ORDER = (
    "det1", "det2a", "det2b", "det3a", "det3b", "det3c",
    "det4a", "det4b", "det4c", "det5a_pre", "det5a", "det5b",
    "det5c", "det5d", "det5e", "det5f", "det5g", "det6a",
    "det7a", "det7b",
)
TESTCASES_DATASETS = (
    "authentic", "casia", "copymove", "face", "imd2020",
    "inpainting", "splicing", "pairs",
)
LABEL_NAMES = {0: "authentic", 1: "manipulated"}
AUTHENTIC_COLOR = "#1d4ed8"
MANIPULATED_COLOR = "#b91c1c"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render Det-Head version comparison charts from stored diagnostics."
    )
    parser.add_argument("--diagnostics-dir", type=Path, default=DEFAULT_DIAGNOSTICS)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--threshold",
        type=float,
        default=None,
        help="Override the run threshold note (default: read from diagnostics.json).",
    )
    return parser.parse_args()


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


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def load_diagnostics(diagnostics_dir: Path) -> dict[str, Any]:
    path = diagnostics_dir / "diagnostics.json"
    return json.loads(path.read_text(encoding="utf-8"))


def ordered_heads(payload: dict[str, Any]) -> list[str]:
    available = set(payload["heads"])
    known = [head for head in HEAD_ORDER if head in available]
    extra = sorted(head for head in available if head not in HEAD_ORDER)
    if not known and not extra:
        raise ValueError("diagnostics.json has no heads")
    return known + extra


def fraction(value: Any) -> float | None:
    if value is None:
        return None
    return float(value)


def percent(value: Any) -> float | None:
    parsed = fraction(value)
    return None if parsed is None else parsed * 100.0


def score_means(diagnostics_dir: Path, set_name: str, head: str) -> dict[str, Any]:
    authentic: list[float] = []
    manipulated: list[float] = []
    by_dataset: dict[str, list[float]] = {}
    for row in read_rows(diagnostics_dir / f"{set_name}__{head}.csv"):
        score = float(row["score"])
        by_dataset.setdefault(row["dataset"], []).append(score)
        if int(row["label"]) == 0:
            authentic.append(score)
        else:
            manipulated.append(score)
    return {
        "head": head,
        "authentic_mean": mean(authentic) if authentic else None,
        "manipulated_mean": mean(manipulated) if manipulated else None,
        "n_authentic": len(authentic),
        "n_manipulated": len(manipulated),
        "dataset_mean": {name: mean(values) for name, values in by_dataset.items()},
    }


def save_figure(figure: Figure, path: Path) -> str:
    figure.savefig(path, dpi=140, bbox_inches="tight", facecolor="white")
    plt.close(figure)
    return path.name


def horizontal_bars(
    axis: plt.Axes,
    labels: Sequence[str],
    values: Sequence[float | None],
    *,
    xlabel: str,
    title: str,
    xlim: tuple[float, float] = (0, 100),
    color: str = "#0f766e",
) -> None:
    positions = list(range(len(labels)))
    clean = [0.0 if value is None else value for value in values]
    bars = axis.barh(positions, clean, color=color, height=0.62)
    for bar, value in zip(bars, values):
        if value is None:
            continue
        axis.text(
            value + 0.7,
            bar.get_y() + bar.get_height() / 2,
            f"{value:.1f}",
            va="center",
            fontsize=7.5,
            color="#0f172a",
        )
    axis.set_yticks(positions)
    axis.set_yticklabels(labels, fontsize=8.5)
    axis.set_xlabel(xlabel)
    axis.set_title(title, fontsize=11)
    axis.set_xlim(*xlim)
    axis.grid(True, axis="x", alpha=0.3, linewidth=0.7)
    axis.spines["top"].set_visible(False)
    axis.spines["right"].set_visible(False)


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
    axis.set_xticklabels(column_labels, rotation=45, ha="right", fontsize=8)
    axis.set_yticks(range(len(row_labels)))
    axis.set_yticklabels(row_labels, fontsize=8.5)
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
                f"{value:.0f}",
                ha="center",
                va="center",
                fontsize=7,
                color="white" if shade > 0.55 else "#0f172a",
            )
    colorbar = figure.colorbar(image, ax=axis, fraction=0.035, pad=0.02)
    colorbar.set_label(cbar_label, fontsize=9)
    colorbar.ax.tick_params(labelsize=8)


def chart_testcases_accuracy(
    payload: dict[str, Any], heads: Sequence[str], path: Path
) -> str:
    ranked = sorted(
        heads,
        key=lambda head: payload["sets"]["testcases"][head]["accuracy"] or -1.0,
        reverse=True,
    )
    values = [percent(payload["sets"]["testcases"][head]["accuracy"]) for head in ranked]
    figure = plt.figure(figsize=(10.5, 8.6))
    axis = figure.add_subplot(111)
    horizontal_bars(
        axis,
        ranked,
        values,
        xlabel="accuracy (%)",
        title="Det-Head รายเวอร์ชัน — accuracy บน testcases 165 ภาพ (threshold 0.5)",
    )
    figure.tight_layout()
    return save_figure(figure, path)


def chart_specificity_recall(
    payload: dict[str, Any], heads: Sequence[str], path: Path
) -> str:
    positions = list(range(len(heads)))
    width = 0.38
    specificity = [percent(payload["sets"]["testcases"][head]["specificity"]) for head in heads]
    recall = [percent(payload["sets"]["testcases"][head]["recall"]) for head in heads]
    figure = plt.figure(figsize=(11.5, 7.6))
    axis = figure.add_subplot(111)
    axis.bar(
        [x - width / 2 for x in positions],
        [0.0 if value is None else value for value in specificity],
        width=width,
        color=AUTHENTIC_COLOR,
        label="Specificity (ภาพจริง 45 ภาพ ถูกเป็นจริง)",
    )
    axis.bar(
        [x + width / 2 for x in positions],
        [0.0 if value is None else value for value in recall],
        width=width,
        color=MANIPULATED_COLOR,
        label="Recall (ภาพดัดแปลง 120 ภาพ จับได้)",
    )
    axis.set_xticks(positions)
    axis.set_xticklabels(heads, rotation=45, ha="right", fontsize=8)
    axis.set_ylabel("เปอร์เซ็นต์")
    axis.set_title(
        "Specificity เทียบ Recall รายเวอร์ชัน — testcases 165 ภาพ (threshold 0.5)", fontsize=11
    )
    axis.set_ylim(0, 108)
    axis.grid(True, axis="y", alpha=0.3, linewidth=0.7)
    axis.spines["top"].set_visible(False)
    axis.spines["right"].set_visible(False)
    axis.legend(frameon=False, fontsize=8.5, loc="lower left")
    figure.tight_layout()
    return save_figure(figure, path)


def chart_dataset_heatmap(
    payload: dict[str, Any],
    heads: Sequence[str],
    field: str,
    *,
    title: str,
    cbar_label: str,
    cmap: str,
    path: Path,
) -> str:
    matrix = [
        [
            percent(payload["sets"]["testcases"][head]["by_dataset"][dataset][field])
            for dataset in TESTCASES_DATASETS
        ]
        for head in heads
    ]
    figure = plt.figure(figsize=(11.5, 8.2))
    axis = figure.add_subplot(111)
    draw_heatmap(
        axis,
        figure,
        heads,
        TESTCASES_DATASETS,
        matrix,
        title=title,
        cbar_label=cbar_label,
        cmap=cmap,
    )
    figure.tight_layout()
    return save_figure(figure, path)


def chart_real_world(
    payload: dict[str, Any], heads: Sequence[str], path: Path
) -> str:
    positions = list(range(len(heads)))
    width = 0.38
    camera = [percent(payload["sets"]["camera9"][head]["accuracy"]) for head in heads]
    chat = [percent(payload["sets"]["chatshot2"][head]["accuracy"]) for head in heads]
    figure = plt.figure(figsize=(11.5, 6.4))
    axis = figure.add_subplot(111)
    axis.bar(
        [x - width / 2 for x in positions],
        [0.0 if value is None else value for value in camera],
        width=width,
        color=AUTHENTIC_COLOR,
        label="camera9 (ภาพกล้องจริง 9 ภาพ ทั้งหมด label 0)",
    )
    axis.bar(
        [x + width / 2 for x in positions],
        [0.0 if value is None else value for value in chat],
        width=width,
        color="#b45309",
        label="chatshot2 (แชต/สกรีนช็อต 2 ภาพ ทั้งหมด label 0 — n เล็ก ดูแนวโน้มเท่านั้น)",
    )
    axis.set_xticks(positions)
    axis.set_xticklabels(heads, rotation=45, ha="right", fontsize=8)
    axis.set_ylabel("accuracy = specificity (%)")
    axis.set_title(
        "ภาพจริงนอกชุดเทรน รายเวอร์ชัน — ยิ่งสูงยิ่งไม่ false alarm (threshold 0.5)", fontsize=11
    )
    axis.set_ylim(0, 108)
    axis.grid(True, axis="y", alpha=0.3, linewidth=0.7)
    axis.spines["top"].set_visible(False)
    axis.spines["right"].set_visible(False)
    axis.legend(frameon=False, fontsize=8.5, loc="upper left")
    figure.tight_layout()
    return save_figure(figure, path)


def chart_score_separation(
    means: Sequence[dict[str, Any]], heads: Sequence[str], path: Path
) -> str:
    by_head = {item["head"]: item for item in means}
    positions = list(range(len(heads)))
    width = 0.38
    authentic = [(by_head[head]["authentic_mean"] or 0.0) * 100.0 for head in heads]
    manipulated = [(by_head[head]["manipulated_mean"] or 0.0) * 100.0 for head in heads]
    figure = plt.figure(figsize=(11.5, 6.4))
    axis = figure.add_subplot(111)
    axis.bar(
        [x - width / 2 for x in positions],
        authentic,
        width=width,
        color=AUTHENTIC_COLOR,
        label="คะแนนเฉลี่ยภาพจริง (45 ภาพ)",
    )
    axis.bar(
        [x + width / 2 for x in positions],
        manipulated,
        width=width,
        color=MANIPULATED_COLOR,
        label="คะแนนเฉลี่ยภาพดัดแปลง (120 ภาพ)",
    )
    axis.axhline(50.0, color="#0f172a", linestyle="--", linewidth=1.2, label="threshold 0.5")
    axis.set_xticks(positions)
    axis.set_xticklabels(heads, rotation=45, ha="right", fontsize=8)
    axis.set_ylabel("det score เฉลี่ย (%)")
    axis.set_title(
        "คะแนนเฉลี่ยแยกฝั่ง รายเวอร์ชัน — ช่องว่างยิ่งกว้างยิ่งแยกสองฝั่งได้ชัด", fontsize=11
    )
    axis.set_ylim(0, 100)
    axis.grid(True, axis="y", alpha=0.3, linewidth=0.7)
    axis.spines["top"].set_visible(False)
    axis.spines["right"].set_visible(False)
    axis.legend(frameon=False, fontsize=8.5, ncols=3)
    figure.tight_layout()
    return save_figure(figure, path)


def chart_score_dataset_heatmap(
    means: Sequence[dict[str, Any]], heads: Sequence[str], path: Path
) -> str:
    by_head = {item["head"]: item for item in means}
    matrix = [
        [
            (by_head[head]["dataset_mean"].get(dataset) or 0.0) * 100.0
            for dataset in TESTCASES_DATASETS
        ]
        for head in heads
    ]
    figure = plt.figure(figsize=(11.5, 8.2))
    axis = figure.add_subplot(111)
    draw_heatmap(
        axis,
        figure,
        heads,
        TESTCASES_DATASETS,
        matrix,
        title="det score เฉลี่ย รายหมวด รายเวอร์ชัน — เห็นว่า head ไหนยิงหมวดไหนแรง",
        cbar_label="det score เฉลี่ย (%)",
        cmap="YlOrRd",
    )
    figure.tight_layout()
    return save_figure(figure, path)


def number(value: Any, digits: int = 2) -> str:
    parsed = fraction(value)
    if parsed is None:
        return "-"
    return f"{parsed:.{digits}f}"


def table(headers: Sequence[str], rows: Sequence[Sequence[str]]) -> str:
    head = "".join(f"<th>{html.escape(str(header))}</th>" for header in headers)
    body = "".join(
        "<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>" for row in rows
    )
    return f"<table><thead><tr>{head}</tr></thead><tbody>{body}</tbody></table>"


def build_report(
    *,
    path: Path,
    charts: Sequence[tuple[str, str, str]],
    payload: dict[str, Any],
    heads: Sequence[str],
    means: Sequence[dict[str, Any]],
) -> None:
    chart_sections = "".join(
        f"""
        <section class="card">
          <h2>{index}. {html.escape(title)}</h2>
          <p class="note">{html.escape(caption)}</p>
          <img alt="{html.escape(title)}" src="data:image/png;base64,{base64.b64encode((path.parent / filename).read_bytes()).decode('ascii')}">
        </section>
        """
        for index, (filename, title, caption) in enumerate(charts, start=1)
    )

    testcases = payload["sets"]["testcases"]
    overall_table = table(
        ["Version", "Accuracy", "Specificity", "Recall", "Precision", "F1", "TP/TN/FP/FN", "Mean score"],
        [
            [
                head,
                number(testcases[head]["accuracy"], 4),
                number(testcases[head]["specificity"], 4),
                number(testcases[head]["recall"], 4),
                number(testcases[head]["precision"], 4),
                number(testcases[head]["f1"], 4),
                f"{testcases[head]['tp']}/{testcases[head]['tn']}/{testcases[head]['fp']}/{testcases[head]['fn']}",
                number(testcases[head]["mean_score"], 4),
            ]
            for head in heads
        ],
    )

    dataset_tables = "".join(
        f"""
        <h3>หมวด {html.escape(dataset)}</h3>
        <div class="scroll">{table(
            ["Version", "Accuracy", "Specificity", "Recall", "TP/TN/FP/FN"],
            [
                [
                    head,
                    number(testcases[head]["by_dataset"][dataset]["accuracy"], 4),
                    number(testcases[head]["by_dataset"][dataset]["specificity"], 4),
                    number(testcases[head]["by_dataset"][dataset]["recall"], 4),
                    f"{testcases[head]['by_dataset'][dataset]['tp']}/"
                    f"{testcases[head]['by_dataset'][dataset]['tn']}/"
                    f"{testcases[head]['by_dataset'][dataset]['fp']}/"
                    f"{testcases[head]['by_dataset'][dataset]['fn']}",
                ]
                for head in heads
            ],
        )}</div>
        """
        for dataset in TESTCASES_DATASETS
    )

    real_table = table(
        ["Version", "camera9 (n=9)", "chatshot2 (n=2)"],
        [
            [
                head,
                number(payload["sets"]["camera9"][head]["accuracy"], 4),
                number(payload["sets"]["chatshot2"][head]["accuracy"], 4),
            ]
            for head in heads
        ],
    )

    by_head = {item["head"]: item for item in means}
    separation_table = table(
        ["Version", "คะแนนเฉลี่ยภาพจริง", "คะแนนเฉลี่ยภาพดัดแปลง", "ช่องว่าง"],
        [
            [
                head,
                number(by_head[head]["authentic_mean"], 4),
                number(by_head[head]["manipulated_mean"], 4),
                number(
                    (by_head[head]["manipulated_mean"] or 0.0)
                    - (by_head[head]["authentic_mean"] or 0.0),
                    4,
                ),
            ]
            for head in heads
        ],
    )

    report = f"""<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>ScamGuard Det-Head — ผล test-case รายเวอร์ชัน</title>
<style>
  :root {{ color-scheme: light; --ink: #0f172a; --muted: #475569; --line: #e2e8f0; --bg: #f8fafc; --card: #ffffff; }}
  * {{ box-sizing: border-box; }}
  body {{ margin: 0; padding: 32px 20px 64px; background: var(--bg); color: var(--ink);
    font-family: "Noto Sans Thai", "IBM Plex Sans Thai", "Segoe UI", system-ui, sans-serif; line-height: 1.6; }}
  main {{ max-width: 1180px; margin: 0 auto; }}
  h1 {{ font-size: 1.7rem; margin: 0 0 6px; }}
  h2 {{ font-size: 1.15rem; margin: 0 0 6px; }}
  h3 {{ font-size: 1rem; margin: 14px 0 6px; }}
  p.note {{ color: var(--muted); font-size: 0.92rem; margin: 0 0 14px; }}
  .card {{ background: var(--card); border: 1px solid var(--line); border-radius: 12px; padding: 20px 22px; margin: 18px 0; }}
  .card img {{ width: 100%; height: auto; display: block; margin-top: 10px; border-radius: 8px; }}
  table {{ border-collapse: collapse; width: 100%; font-size: 0.86rem; }}
  th, td {{ border-bottom: 1px solid var(--line); padding: 7px 9px; text-align: right; white-space: nowrap; }}
  th:first-child, td:first-child {{ text-align: left; }}
  thead th {{ background: #f1f5f9; font-weight: 600; }}
  tbody tr:hover {{ background: #f8fafc; }}
  code {{ font-size: 0.8rem; color: var(--muted); }}
  ul {{ margin: 6px 0 0; padding-left: 20px; font-size: 0.88rem; color: var(--muted); }}
  .scroll {{ overflow-x: auto; }}
</style>
</head>
<body>
<main>
  <h1>Det-Head — ผล test-case รายเวอร์ชัน</h1>
  <p class="note">
    ทุกเวอร์ชันถูกรันใหม่พร้อมกันด้วย <code>eval_det_diagnostics.py</code> บนภาพชุดเดียวกัน
    ({len(heads)} heads, seg backbone {html.escape(str(payload.get('checkpoint', '')))},
    threshold {html.escape(str(payload.get('threshold', '')))}) —
    ไม่ใช้ผลเก่าจากคนละรอบมาปนกัน
  </p>

  <section class="card">
    <h2>ขอบเขตของข้อมูล</h2>
    <ul>
      <li>testcases 165 ภาพ: with_mask 105 ภาพ (authentic 15 ภาพ label 0, อีก 6 หมวด 90 ภาพ label 1)
        บวก pairs 60 ภาพ (originals 30 ภาพ label 0, manipulated 30 ภาพ label 1) รวมภาพจริง 45 ภาพ
        และภาพดัดแปลง 120 ภาพ ไฟล์ทั้งหมดอยู่ใน <code>/home/panuwat/Pictures/Test-Cases</code></li>
      <li>camera9: ภาพถ่ายจากกล้องมือถือจริง 9 ภาพ label 0 ทั้งหมด — specificity ที่นี่คืออัตราที่ไม่ false alarm</li>
      <li>chatshot2: แชต/สกรีนช็อต 2 ภาพ label 0 ทั้งหมด n เล็กมาก ใช้ดูแนวโน้มเท่านั้น ห้ามใช้ตัดสิน</li>
      <li>คะแนนคือ det score 0–1 จาก seg backbone เดียวกันทุก head (extract_feat ครั้งเดียวต่อภาพ)</li>
      <li>ชุดนี้เป็น development diagnostics ตามหัวไฟล์ <code>eval_det_diagnostics.py</code>
        ไม่ใช่ชุดตัดสิน production threshold</li>
    </ul>
  </section>

  {chart_sections}

  <section class="card">
    <h2>ตาราง testcases overall (threshold {html.escape(str(payload.get('threshold', '')))})</h2>
    <div class="scroll">{overall_table}</div>
  </section>

  <section class="card">
    <h2>ตาราง testcases รายหมวด</h2>
    {dataset_tables}
  </section>

  <section class="card">
    <h2>ตารางภาพจริงนอกชุดเทรน</h2>
    <div class="scroll">{real_table}</div>
  </section>

  <section class="card">
    <h2>ตารางช่องว่างคะแนน (manipulated − authentic)</h2>
    <div class="scroll">{separation_table}</div>
  </section>
</main>
</body>
</html>
"""
    path.write_text(report, encoding="utf-8")


def main() -> int:
    args = parse_args()
    setup_style()
    payload = load_diagnostics(args.diagnostics_dir)
    heads = ordered_heads(payload)
    if args.threshold is not None:
        payload["threshold"] = args.threshold
    threshold = payload.get("threshold", 0.5)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    means = [score_means(args.diagnostics_dir, "testcases", head) for head in heads]

    charts: list[tuple[str, str, str]] = []
    charts.append(
        (
            chart_testcases_accuracy(
                payload, heads, args.output_dir / "01_det_testcases_accuracy.png"
            ),
            "Accuracy รายเวอร์ชันบน testcases 165 ภาพ",
            f"เรียงจากดีไปแย่ (threshold {threshold}) ภาพจริง 45 + ภาพดัดแปลง 120",
        )
    )
    charts.append(
        (
            chart_specificity_recall(
                payload, heads, args.output_dir / "02_det_specificity_recall.png"
            ),
            "Specificity เทียบ Recall รายเวอร์ชัน",
            "specificity = ไม่ false alarm บนภาพจริง, recall = จับภาพดัดแปลงได้",
        )
    )
    charts.append(
        (
            chart_dataset_heatmap(
                payload,
                heads,
                "accuracy",
                title="Accuracy รายหมวด รายเวอร์ชัน (%)",
                cbar_label="accuracy (%)",
                cmap="YlGn",
                path=args.output_dir / "03_det_dataset_accuracy.png",
            ),
            "Accuracy รายหมวด",
            "เห็นว่าหมวดไหนเป็นจุดอ่อนของแต่ละ head (หมวด authentic คือภาพจริง 15 ภาพ)",
        )
    )
    charts.append(
        (
            chart_real_world(
                payload, heads, args.output_dir / "04_det_real_world.png"
            ),
            "ภาพจริงนอกชุดเทรน รายเวอร์ชัน",
            "camera9 คือสัญญาณหลัก (n=9) ส่วน chatshot2 มีแค่ 2 ภาพ ดูแนวโน้มเท่านั้น",
        )
    )
    charts.append(
        (
            chart_score_separation(
                means, heads, args.output_dir / "05_det_score_separation.png"
            ),
            "คะแนนเฉลี่ยแยกฝั่ง รายเวอร์ชัน",
            "คำนวณจากคะแนนรายภาพจริงใน CSV ไม่ใช่ค่าประมาณ",
        )
    )
    charts.append(
        (
            chart_score_dataset_heatmap(
                means, heads, args.output_dir / "06_det_score_by_dataset.png"
            ),
            "det score เฉลี่ย รายหมวด",
            "หมวด authentic ควรต่ำ (น้ำเงิน) หมวดดัดแปลงควรสูง (แดง)",
        )
    )

    charts_payload = {
        "diagnostics_dir": str(args.diagnostics_dir),
        "threshold": threshold,
        "checkpoint": payload.get("checkpoint"),
        "heads": heads,
        "charts": [filename for filename, _title, _caption in charts],
        "score_means": means,
        "summaries": {
            set_name: {
                head: payload["sets"][set_name][head] for head in heads
            }
            for set_name in payload["sets"]
            if set_name != "elapsed_s"
        },
    }
    (args.output_dir / "charts_data.json").write_text(
        json.dumps(charts_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    build_report(
        path=args.output_dir / "report.html",
        charts=charts,
        payload=payload,
        heads=heads,
        means=means,
    )
    print(f"Wrote {len(charts)} charts and report.html to {args.output_dir}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
