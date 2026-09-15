#!/usr/bin/env python3
"""Generate reproducible SegFormer diagnostics and common-test plots.

The manifest pins every checkpoint and log. Validation plots are diagnostics
only because versions did not share one validation protocol. Only the locked
common-test plots may be used to rank model versions.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
import tempfile
import textwrap
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image

REPORT_ROOT = Path(__file__).resolve().parent
TESTS_ROOT = REPORT_ROOT.parent
SEGFORMER_ROOT = TESTS_ROOT.parent
PROJECT_ROOT = SEGFORMER_ROOT.parent.parent
DEFAULT_MANIFEST = TESTS_ROOT / "evaluation_manifest.json"
DEFAULT_FIGURES = REPORT_ROOT / "figs"

# Okabe-Ito-derived palette, distinguishable for common color-vision deficiencies.
VERSION_COLORS = {
    "v1.0.0": "#0072B2",
    "v1.0.1": "#E69F00",
    "v1.0.2": "#009E73",
    "v1.0.3": "#CC79A7",
    "v1.0.4": "#56B4E9",
    "v1.0.5": "#D55E00",
}
FALLBACK_VERSION_COLORS = (
    "#332288",
    "#88CCEE",
    "#44AA99",
    "#117733",
    "#999933",
    "#DDCC77",
    "#CC6677",
    "#882255",
    "#AA4499",
)
LINE_STYLES = ["-", "--", "-.", ":", (0, (5, 1)), (0, (3, 1, 1, 1))]
METRIC_COLORS = {
    "mIoU": "#0072B2",
    "mDice": "#E69F00",
    "mAcc": "#009E73",
    "aAcc": "#CC79A7",
    "IoU": "#0072B2",
    "Dice": "#E69F00",
    "Accuracy": "#009E73",
}

CLASS_ROW_RE = re.compile(
    r"\|\s*(background|forgery)\s*\|\s*([0-9.]+)\s*\|\s*([0-9.]+)\s*\|\s*([0-9.]+)\s*\|",
    re.IGNORECASE,
)
FINAL_TEST_RE = re.compile(
    r"Iter\(test\)\s*\[\s*(\d+)\s*/\s*(\d+)\s*\].*?"
    r"aAcc:\s*([0-9.]+)\s+mIoU:\s*([0-9.]+)\s+"
    r"mAcc:\s*([0-9.]+)\s+mDice:\s*([0-9.]+).*?"
    r"data_time:\s*([0-9.]+)\s+time:\s*([0-9.]+)"
)


class EvaluationDataError(ValueError):
    """Raised when a pinned evaluation artifact is incomplete or ambiguous."""


def version_color(version: str) -> str:
    """Return a stable color, including for versions added via the manifest."""
    if version in VERSION_COLORS:
        return VERSION_COLORS[version]
    numbers = [int(value) for value in re.findall(r"\d+", version)]
    color_index = sum((index + 1) * value for index, value in enumerate(numbers))
    return FALLBACK_VERSION_COLORS[color_index % len(FALLBACK_VERSION_COLORS)]


def compute_ema(values: list[float], weight: float = 0.9) -> list[float]:
    """Return a debiased exponential moving average."""
    if not values:
        return []
    ema: list[float] = []
    accumulator = 0.0
    for index, value in enumerate(values):
        accumulator = weight * accumulator + (1.0 - weight) * value
        debias = 1.0 - weight ** (index + 1)
        ema.append(accumulator / debias)
    return ema


def _resolve_artifact(root: Path, relative_path: str) -> Path:
    path = (root / relative_path).resolve()
    resolved_root = root.resolve()
    if not path.is_relative_to(resolved_root):
        raise EvaluationDataError(f"Artifact escapes SegFormer root: {relative_path}")
    return path


def validate_manifest_data(
    manifest: dict[str, Any], root: Path = SEGFORMER_ROOT, check_files: bool = True
) -> list[dict[str, Any]]:
    """Validate manifest shape, uniqueness, pinned paths, and metadata."""
    if manifest.get("schema_version") != 1:
        raise EvaluationDataError("evaluation_manifest.json must use schema_version 1")
    dataset = manifest.get("dataset") or {}
    if not dataset.get("id") or not isinstance(dataset.get("test_batches"), int):
        raise EvaluationDataError("Manifest dataset requires id and integer test_batches")
    if dataset["test_batches"] <= 0:
        raise EvaluationDataError("Manifest test_batches must be positive")

    entries = manifest.get("versions")
    if not isinstance(entries, list) or not entries:
        raise EvaluationDataError("Manifest requires at least one version entry")

    required = {
        "version",
        "checkpoint",
        "onnx_model",
        "training_log",
        "training_run_id",
        "test_log",
        "test_run_id",
        "expected_common_test",
    }
    seen_versions: set[str] = set()
    seen_paths: dict[str, str] = {}
    validated: list[dict[str, Any]] = []
    for raw in entries:
        missing = sorted(required - set(raw))
        if missing:
            raise EvaluationDataError(f"Manifest entry is missing: {', '.join(missing)}")
        version = str(raw["version"])
        if version in seen_versions:
            raise EvaluationDataError(f"Duplicate version in manifest: {version}")
        seen_versions.add(version)

        expected = raw["expected_common_test"]
        expected_fields = {"mIoU", "mDice", "forgery_IoU", "forgery_Dice"}
        if not isinstance(expected, dict) or set(expected) != expected_fields:
            raise EvaluationDataError(
                f"{version} expected_common_test must contain: "
                f"{', '.join(sorted(expected_fields))}"
            )
        if not all(isinstance(expected[field], (int, float)) for field in expected_fields):
            raise EvaluationDataError(f"{version} expected_common_test values must be numeric")

        entry = dict(raw)
        resolved: dict[str, Path] = {}
        for field in ("checkpoint", "onnx_model", "training_log", "test_log"):
            path_text = str(entry[field])
            if path_text in seen_paths:
                raise EvaluationDataError(
                    f"Duplicate artifact path for {field}: {path_text} "
                    f"({seen_paths[path_text]} and {version})"
                )
            seen_paths[path_text] = version
            path = _resolve_artifact(root, path_text)
            if check_files and not path.is_file():
                raise EvaluationDataError(f"Missing {field} for {version}: {path}")
            resolved[field] = path
        entry["resolved"] = resolved
        validated.append(entry)
    return validated


def load_manifest(
    path: Path = DEFAULT_MANIFEST,
    root: Path = SEGFORMER_ROOT,
    check_files: bool = True,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    with path.open(encoding="utf-8") as handle:
        manifest = json.load(handle)
    return manifest, validate_manifest_data(manifest, root=root, check_files=check_files)


def load_training_log(path: Path) -> dict[str, Any]:
    train = {"step": [], "loss": [], "ce": [], "dice": [], "lr": []}
    validation = {"step": [], "mIoU": [], "mDice": [], "mAcc": [], "aAcc": []}
    with path.open(encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise EvaluationDataError(f"Invalid JSONL at {path}:{line_number}: {error}") from error
            if "mIoU" in row:
                required = ("mIoU", "mDice", "mAcc", "aAcc")
                if any(row.get(metric) is None for metric in required):
                    raise EvaluationDataError(f"Incomplete validation row at {path}:{line_number}")
                validation["step"].append(row.get("step", row.get("iter", 0)))
                for metric in required:
                    validation[metric].append(float(row[metric]))
            elif "loss" in row:
                train["step"].append(row.get("iter", row.get("step", 0)))
                train["loss"].append(float(row["loss"]))
                train["ce"].append(row.get("decode.loss_ce"))
                train["dice"].append(row.get("decode.loss_dice"))
                train["lr"].append(row.get("lr"))
    if not train["loss"] or not validation["mIoU"]:
        raise EvaluationDataError(f"Training log lacks train or validation rows: {path}")
    return {"train": train, "validation": validation}


def parse_test_log_text(text: str, expected_batches: int) -> dict[str, Any]:
    """Parse final common-test metrics and reject partial runs."""
    classes: dict[str, dict[str, float]] = {}
    for match in CLASS_ROW_RE.finditer(text):
        classes[match.group(1).lower()] = {
            "IoU": float(match.group(2)),
            "Accuracy": float(match.group(3)),
            "Dice": float(match.group(4)),
        }
    if set(classes) != {"background", "forgery"}:
        raise EvaluationDataError("Test log does not contain complete background/forgery metrics")

    final_matches = list(FINAL_TEST_RE.finditer(text))
    if not final_matches:
        raise EvaluationDataError("Test log does not contain a final aggregate result")
    final = final_matches[-1]
    completed, total = int(final.group(1)), int(final.group(2))
    if completed != total or total != expected_batches:
        raise EvaluationDataError(
            f"Incomplete or unexpected test run: {completed}/{total}; "
            f"expected {expected_batches}/{expected_batches}"
        )
    return {
        "completed_batches": completed,
        "total_batches": total,
        "aAcc": float(final.group(3)),
        "mIoU": float(final.group(4)),
        "mAcc": float(final.group(5)),
        "mDice": float(final.group(6)),
        "data_time": float(final.group(7)),
        "time": float(final.group(8)),
        "classes": classes,
    }


def load_test_log(path: Path, expected_batches: int) -> dict[str, Any]:
    return parse_test_log_text(path.read_text(encoding="utf-8"), expected_batches)


def collect_evaluation_data(
    manifest_path: Path = DEFAULT_MANIFEST,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    manifest, entries = load_manifest(manifest_path)
    expected_batches = int(manifest["dataset"]["test_batches"])
    collected: list[dict[str, Any]] = []
    for entry in entries:
        training = load_training_log(entry["resolved"]["training_log"])
        test = load_test_log(entry["resolved"]["test_log"], expected_batches)
        expected = entry["expected_common_test"]
        actual_regression = {
            "mIoU": test["mIoU"],
            "mDice": test["mDice"],
            "forgery_IoU": test["classes"]["forgery"]["IoU"],
            "forgery_Dice": test["classes"]["forgery"]["Dice"],
        }
        for metric, expected_value in expected.items():
            if not np.isclose(actual_regression[metric], expected_value, atol=0.005):
                raise EvaluationDataError(
                    f"{entry['version']} {metric} changed: "
                    f"expected {expected_value:.2f}, got {actual_regression[metric]:.2f}"
                )
        validation = training["validation"]
        best_index = int(np.argmax(validation["mIoU"]))
        checkpoint_match = re.search(r"iter_(\d+)", Path(entry["checkpoint"]).name)
        checkpoint_iter = int(checkpoint_match.group(1)) if checkpoint_match else None
        best_iter = int(validation["step"][best_index])
        if checkpoint_iter is not None and checkpoint_iter != best_iter:
            raise EvaluationDataError(
                f"{entry['version']} checkpoint iter {checkpoint_iter} does not match "
                f"best validation iter {best_iter}"
            )
        collected.append(
            {
                **entry,
                "training": training,
                "best_validation": {
                    "iter": best_iter,
                    "mIoU": validation["mIoU"][best_index],
                    "mDice": validation["mDice"][best_index],
                    "mAcc": validation["mAcc"][best_index],
                    "aAcc": validation["aAcc"][best_index],
                },
                "test": test,
            }
        )
    return manifest, collected


def _style() -> None:
    plt.rcParams.update(
        {
            "figure.facecolor": "white",
            "axes.facecolor": "white",
            "axes.grid": True,
            "axes.axisbelow": True,
            "grid.alpha": 0.22,
            "font.size": 10,
            "axes.titlesize": 13,
            "axes.labelsize": 10,
            "legend.frameon": False,
            "svg.fonttype": "none",
        }
    )


def save_figure(fig: plt.Figure, base_path: Path) -> None:
    base_path.parent.mkdir(parents=True, exist_ok=True)
    # Model versions contain dots (for example, ``v1.0.5_loss``). Using
    # Path.with_suffix() would mistake ``.5_loss`` for a suffix and collapse
    # both per-version plots to ``v1.0.png``.
    fig.savefig(base_path.parent / f"{base_path.name}.png", dpi=200, bbox_inches="tight")
    fig.savefig(base_path.parent / f"{base_path.name}.svg", bbox_inches="tight")
    plt.close(fig)


def _checkpoint_iter(entry: dict[str, Any]) -> str:
    match = re.search(r"iter_(\d+)", Path(entry["checkpoint"]).name)
    return match.group(1) if match else "unknown"


def _test_footer(manifest: dict[str, Any], entries: list[dict[str, Any]]) -> str:
    dataset = manifest["dataset"]
    checkpoints = ", ".join(f"{e['version']}@{_checkpoint_iter(e)}" for e in entries)
    runs = ", ".join(f"{e['version']}:{e['test_run_id']}" for e in entries)
    return textwrap.fill(
        f"Dataset: {dataset['id']} | {dataset['test_batches']:,} batches | "
        f"Checkpoints: {checkpoints} | Test runs: {runs}",
        width=175,
    )


def plot_training_loss(entry: dict[str, Any]) -> None:
    version = entry["version"]
    train = entry["training"]["train"]
    steps, losses = train["step"], train["loss"]
    fig, axis = plt.subplots(figsize=(10, 5.5))
    axis.plot(steps, losses, color=version_color(version), alpha=0.22, linewidth=0.55, label="Total loss (raw)")
    axis.plot(steps, compute_ema(losses), color=version_color(version), linewidth=1.7, label="Total loss (EMA)")
    if any(value is not None for value in train["ce"]):
        axis.plot(steps, train["ce"], color="#009E73", alpha=0.55, linewidth=0.7, label="Cross-entropy loss")
    if any(value is not None for value in train["dice"]):
        axis.plot(steps, train["dice"], color="#E69F00", alpha=0.55, linewidth=0.7, label="Dice loss")
    axis.set(title=f"{version} Training Loss", xlabel="Training iteration", ylabel="Loss")
    axis.legend(loc="upper right")
    lr_axis = axis.twinx()
    lr_axis.grid(False)
    lr_axis.plot(steps, train["lr"], color="#CC79A7", linestyle="--", linewidth=1)
    lr_axis.set_ylabel("Learning rate", color="#CC79A7")
    lr_axis.tick_params(axis="y", labelcolor="#CC79A7")
    lr_axis.ticklabel_format(style="scientific", scilimits=(0, 0), axis="y")
    fig.text(
        0.5, 0.01,
        f"Training run: {entry['training_run_id']} | Checkpoint: {entry['checkpoint']}",
        ha="center", fontsize=8, color="#555555",
    )
    fig.tight_layout(rect=(0, 0.05, 1, 1))
    save_figure(fig, TESTS_ROOT / "v" / version / f"{version}_loss")


def plot_validation_metrics(entry: dict[str, Any]) -> None:
    version = entry["version"]
    validation = entry["training"]["validation"]
    steps, best = validation["step"], entry["best_validation"]
    marker_every = max(1, len(steps) // 12)
    fig, (quality_axis, accuracy_axis) = plt.subplots(1, 2, figsize=(12, 4.8), sharex=True)
    quality_axis.plot(steps, validation["mIoU"], color=METRIC_COLORS["mIoU"], marker="o", markevery=marker_every, markersize=3, label="mIoU")
    quality_axis.plot(steps, validation["mDice"], color=METRIC_COLORS["mDice"], linestyle="--", marker="s", markevery=marker_every, markersize=3, label="mDice")
    quality_axis.scatter([best["iter"]], [best["mIoU"]], color="#D55E00", zorder=5)
    quality_axis.annotate(f"Best mIoU {best['mIoU']:.2f}%\n@ {best['iter']:,}", (best["iter"], best["mIoU"]), xytext=(8, -28), textcoords="offset points", fontsize=8)
    quality_axis.set(title="Segmentation quality", xlabel="Training iteration", ylabel="Score (%)", ylim=(0, 100))
    quality_axis.legend()
    accuracy_axis.plot(steps, validation["mAcc"], color=METRIC_COLORS["mAcc"], label="mAcc")
    accuracy_axis.plot(steps, validation["aAcc"], color=METRIC_COLORS["aAcc"], linestyle="--", label="aAcc")
    accuracy_axis.set(title="Accuracy diagnostics", xlabel="Training iteration", ylabel="Accuracy (%)", ylim=(0, 100))
    accuracy_axis.legend()
    fig.suptitle(f"{version} Validation Metrics — Training Diagnostic Only", fontweight="bold")
    fig.text(
        0.5, 0.01,
        f"Training run: {entry['training_run_id']} | Checkpoint: {entry['checkpoint']} | "
        "Validation protocols differ across versions; do not use this plot for ranking.",
        ha="center", fontsize=8, color="#555555",
    )
    fig.tight_layout(rect=(0, 0.05, 1, 0.95))
    save_figure(fig, TESTS_ROOT / "v" / version / f"{version}_metrics")


def _normalized_progress(steps: list[int]) -> np.ndarray:
    values = np.asarray(steps, dtype=float)
    maximum = float(values.max()) if values.size else 1.0
    return values / maximum * 100.0


def plot_diagnostics(entries: list[dict[str, Any]], output_dir: Path) -> None:
    diagnostics = output_dir / "diagnostics"
    run_metadata = ", ".join(
        f"{entry['version']}:{entry['training_run_id']}@{_checkpoint_iter(entry)}"
        for entry in entries
    )
    for metric in ("mIoU", "mDice"):
        fig, axis = plt.subplots(figsize=(10.5, 5.5))
        for index, entry in enumerate(entries):
            validation = entry["training"]["validation"]
            marker_every = max(1, len(validation["step"]) // 10)
            axis.plot(
                _normalized_progress(validation["step"]), validation[metric],
                color=version_color(entry["version"]), linestyle=LINE_STYLES[index % len(LINE_STYLES)],
                marker="o", markevery=marker_every, markersize=2.5, label=entry["version"],
            )
        axis.set(title=f"Validation {metric} by Run — Not for Model Ranking", xlabel="Run progress (%)", ylabel=f"{metric} (%)", xlim=(0, 100), ylim=(0, 100))
        axis.legend(ncol=2)
        fig.text(
            0.5,
            0.01,
            textwrap.fill(
                "Validation sets and protocols differ across versions. "
                f"This diagnostic shows convergence shape only. Runs/checkpoints: {run_metadata}",
                width=170,
            ),
            ha="center",
            fontsize=7.5,
            color="#555555",
        )
        fig.tight_layout(rect=(0, 0.09, 1, 1))
        save_figure(fig, diagnostics / f"validation_{metric.lower()}_by_run")

    fig, axis = plt.subplots(figsize=(10.5, 5.5))
    for index, entry in enumerate(entries):
        train = entry["training"]["train"]
        axis.plot(_normalized_progress(train["step"]), compute_ema(train["loss"]), color=version_color(entry["version"]), linestyle=LINE_STYLES[index % len(LINE_STYLES)], linewidth=1.3, label=entry["version"])
    axis.set(title="Training Loss by Run — Not for Model Ranking", xlabel="Run progress (%)", ylabel="EMA-smoothed loss (log scale)", xlim=(0, 100), yscale="log")
    axis.legend(ncol=2)
    fig.text(
        0.5,
        0.01,
        textwrap.fill(
            "Datasets and loss configurations differ across versions. Absolute loss values are not directly comparable. "
            f"Runs/checkpoints: {run_metadata}",
            width=170,
        ),
        ha="center",
        fontsize=7.5,
        color="#555555",
    )
    fig.tight_layout(rect=(0, 0.09, 1, 1))
    save_figure(fig, diagnostics / "training_loss_by_run")


def _grouped_bars(entries: list[dict[str, Any]], metrics: list[tuple[str, list[float]]], title: str, ylabel: str, footer: str, output: Path) -> None:
    versions = [entry["version"] for entry in entries]
    x_positions = np.arange(len(versions))
    width = 0.78 / len(metrics)
    fig, axis = plt.subplots(figsize=(11, 6))
    for index, (label, values) in enumerate(metrics):
        offsets = x_positions + (index - (len(metrics) - 1) / 2) * width
        bars = axis.bar(offsets, values, width, label=label, color=METRIC_COLORS[label])
        axis.bar_label(bars, fmt="%.2f", padding=2, fontsize=8)
    axis.set(title=title, xlabel="Model version and selected checkpoint iteration", ylabel=ylabel, xticks=x_positions, xticklabels=[f"{entry['version']}\niter {_checkpoint_iter(entry)}" for entry in entries], ylim=(0, 100))
    axis.legend(ncol=len(metrics), loc="upper left")
    fig.text(0.5, 0.01, footer, ha="center", fontsize=7.4, color="#555555")
    fig.tight_layout(rect=(0, 0.13, 1, 1))
    save_figure(fig, output)


def plot_common_test(manifest: dict[str, Any], entries: list[dict[str, Any]], output_dir: Path) -> None:
    footer = _test_footer(manifest, entries)
    _grouped_bars(entries, [("mIoU", [e["test"]["mIoU"] for e in entries]), ("mDice", [e["test"]["mDice"] for e in entries])], "Locked Common Test Set — Overall Segmentation Metrics", "Score (%)", footer, output_dir / "common_test_overall_metrics")
    _grouped_bars(entries, [("IoU", [e["test"]["classes"]["forgery"]["IoU"] for e in entries]), ("Dice", [e["test"]["classes"]["forgery"]["Dice"] for e in entries]), ("Accuracy", [e["test"]["classes"]["forgery"]["Accuracy"] for e in entries])], "Locked Common Test Set — Forgery-Class Metrics (Primary)", "Forgery-class score (%)", footer, output_dir / "common_test_forgery_metrics")

    fig, axis = plt.subplots(figsize=(11, 6))
    x_positions = np.arange(len(entries))
    validation_values = [entry["best_validation"]["mIoU"] for entry in entries]
    test_values = [entry["test"]["mIoU"] for entry in entries]
    for x, validation, test in zip(x_positions, validation_values, test_values):
        axis.plot([x, x], [validation, test], color="#999999", linewidth=1.2, zorder=1)
    axis.scatter(x_positions, validation_values, color="#56B4E9", label="Best validation mIoU", s=55, zorder=2)
    axis.scatter(x_positions, test_values, color="#D55E00", label="Common-test mIoU", s=55, zorder=2)
    axis.set(title="Validation-to-Test mIoU — Domain-Shift Diagnostic", xlabel="Model version", ylabel="mIoU (%)", xticks=x_positions, xticklabels=[entry["version"] for entry in entries], ylim=(0, 100))
    axis.legend()
    fig.text(0.5, 0.01, textwrap.fill("Validation protocols differ across versions; validation values must not rank models. " + footer, width=175), ha="center", fontsize=7.4, color="#555555")
    fig.tight_layout(rect=(0, 0.14, 1, 1))
    save_figure(fig, output_dir / "validation_vs_test_miou")


def plot_qualitative_demo(output_dir: Path) -> None:
    scenarios = ["Photoshop Splicing", "Complex Montage", "Authentic Natural"]
    v100_scores, v104_scores = [98.47, 83.24, 2.75], [20.52, 43.07, 3.36]
    x_positions, width = np.arange(len(scenarios)), 0.36
    fig, axis = plt.subplots(figsize=(10.5, 6))
    bars_100 = axis.bar(x_positions - width / 2, v100_scores, width, label="v1.0.0", color=version_color("v1.0.0"))
    bars_104 = axis.bar(x_positions + width / 2, v104_scores, width, label="v1.0.4", color=version_color("v1.0.4"))
    axis.axhline(70, color="#D55E00", linestyle="--", alpha=0.7, label="Product high-risk threshold")
    axis.axhline(40, color="#E69F00", linestyle=":", alpha=0.8, label="Product medium-risk threshold")
    axis.bar_label(bars_100, fmt="%.2f", padding=2)
    axis.bar_label(bars_104, fmt="%.2f", padding=2)
    axis.set(title="Qualitative Demo (n=3)", xlabel="Demonstration image", ylabel="Maximum forgery probability / visual score (%)", xticks=x_positions, xticklabels=scenarios, ylim=(0, 100))
    axis.legend(ncol=2, fontsize=8)
    fig.text(
        0.5,
        0.01,
        "Dataset: qualitative-demo-v1 | n=3 hand-selected images | "
        "Checkpoints: v1.0.0@112000, v1.0.4@495000 | Run ID: not applicable (manual qualitative record).",
        ha="center",
        fontsize=8,
        color="#555555",
    )
    fig.tight_layout(rect=(0, 0.05, 1, 1))
    save_figure(fig, output_dir / "qualitative_demo")


def _onnx_heatmap(model_path: Path) -> tuple[Image.Image, np.ndarray] | None:
    image_path = TESTS_ROOT / "img" / "test1.jpg"
    if not image_path.is_file() or not model_path.is_file():
        return None
    image = Image.open(image_path).convert("RGB")
    width, height = image.size
    pixels = np.asarray(image, dtype=np.float32)
    normalized = (pixels - np.array([123.675, 116.28, 103.53], dtype=np.float32)) / np.array([58.395, 57.12, 57.375], dtype=np.float32)
    tensor = np.transpose(normalized, (2, 0, 1))[None].astype(np.float32)
    heatmap: np.ndarray | None = None
    try:
        import onnxruntime as ort
        session = ort.InferenceSession(str(model_path), providers=["CPUExecutionProvider"])
        logits = session.run(None, {session.get_inputs()[0].name: tensor})[0]
        exponent = np.exp(logits - np.max(logits, axis=1, keepdims=True))
        heatmap = (exponent / np.sum(exponent, axis=1, keepdims=True))[0, 1]
    except ImportError:
        server_python = PROJECT_ROOT / "server" / "venv" / "bin" / "python"
        if server_python.is_file():
            with tempfile.NamedTemporaryFile(suffix=".npy", delete=False) as output_file, tempfile.NamedTemporaryFile(suffix=".npy", delete=False) as tensor_file:
                output_path, tensor_path = Path(output_file.name), Path(tensor_file.name)
            np.save(tensor_path, tensor)
            code = (
                "import numpy as np, onnxruntime as ort, sys\n"
                "tensor=np.load(sys.argv[2])\n"
                "session=ort.InferenceSession(sys.argv[1], providers=['CPUExecutionProvider'])\n"
                "logits=session.run(None, {session.get_inputs()[0].name:tensor})[0]\n"
                "exponent=np.exp(logits-np.max(logits, axis=1, keepdims=True))\n"
                "np.save(sys.argv[3], (exponent/np.sum(exponent, axis=1, keepdims=True))[0,1])\n"
            )
            result = subprocess.run([str(server_python), "-c", code, str(model_path), str(tensor_path), str(output_path)], capture_output=True, check=False)
            tensor_path.unlink(missing_ok=True)
            if result.returncode == 0 and output_path.is_file():
                heatmap = np.load(output_path)
            output_path.unlink(missing_ok=True)
    if heatmap is None:
        return None
    heatmap_image = Image.fromarray(np.uint8(np.clip(heatmap, 0, 1) * 255))
    resized = np.asarray(heatmap_image.resize((width, height), Image.Resampling.BILINEAR), dtype=np.float32) / 255.0
    return image, resized


def plot_qualitative_onnx_example(entry: dict[str, Any]) -> None:
    version = entry["version"]
    result = _onnx_heatmap(entry["resolved"]["onnx_model"])
    if result is None:
        raise EvaluationDataError(f"Unable to run the pinned {version} ONNX qualitative example")
    image, heatmap = result
    image_array = np.asarray(image)
    heatmap_percent = heatmap * 100.0
    fig, axes = plt.subplots(1, 3, figsize=(14, 4.8))
    axes[0].imshow(image_array); axes[0].set_title("Input image"); axes[0].axis("off")
    heatmap_artist = axes[1].imshow(heatmap_percent, cmap="magma", vmin=0, vmax=100)
    axes[1].set_title(f"Forgery probability map\nPeak probability: {heatmap_percent.max():.2f}%"); axes[1].axis("off")
    colorbar = fig.colorbar(heatmap_artist, ax=axes[1], fraction=0.046, pad=0.04); colorbar.set_label("Forgery probability (%)")
    axes[2].imshow(image_array)
    axes[2].imshow(np.ma.masked_where(heatmap_percent <= 40, heatmap_percent), cmap="Reds", vmin=40, vmax=100, alpha=0.58)
    axes[2].set_title("Threshold overlay (> 40%)"); axes[2].axis("off")
    fig.suptitle(f"Qualitative ONNX Example — {version}", fontweight="bold")
    fig.text(
        0.5,
        0.01,
        f"Input: tests_model/img/test1.jpg | ONNX: {entry['onnx_model']} | "
        f"Checkpoint: {version}@{_checkpoint_iter(entry)} | Run ID: not applicable (single-image inference). "
        "No ground-truth mask; no IoU, Dice, or accuracy claim.",
        ha="center",
        fontsize=8,
        color="#555555",
    )
    fig.tight_layout(rect=(0, 0.05, 1, 0.95))
    save_figure(
        fig,
        TESTS_ROOT / "v" / version / f"{version}_qualitative_onnx_example",
    )


def render_qualitative_onnx_version(
    version: str,
    manifest_path: Path = DEFAULT_MANIFEST,
) -> tuple[Path, Path]:
    """Render one version's ONNX example for its dedicated test script."""
    _, entries = load_manifest(manifest_path)
    try:
        entry = next(item for item in entries if item["version"] == version)
    except StopIteration as error:
        raise EvaluationDataError(f"Version is not present in manifest: {version}") from error
    _style()
    plot_qualitative_onnx_example(entry)
    base = TESTS_ROOT / "v" / version / f"{version}_qualitative_onnx_example"
    return (
        base.parent / f"{base.name}.png",
        base.parent / f"{base.name}.svg",
    )


def write_training_summary(entries: list[dict[str, Any]], output_dir: Path) -> None:
    fields = ["version", "checkpoint", "training_run_id", "training_log_points", "validation_runs", "best_checkpoint_iter", "best_validation_mIoU", "best_validation_mDice", "best_validation_mAcc", "best_validation_aAcc", "minimum_training_loss", "final_training_loss"]
    with (output_dir / "training_validation_summary.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields); writer.writeheader()
        for entry in entries:
            train, validation, best = entry["training"]["train"], entry["training"]["validation"], entry["best_validation"]
            writer.writerow({"version": entry["version"], "checkpoint": entry["checkpoint"], "training_run_id": entry["training_run_id"], "training_log_points": len(train["loss"]), "validation_runs": len(validation["mIoU"]), "best_checkpoint_iter": best["iter"], "best_validation_mIoU": f"{best['mIoU']:.2f}", "best_validation_mDice": f"{best['mDice']:.2f}", "best_validation_mAcc": f"{best['mAcc']:.2f}", "best_validation_aAcc": f"{best['aAcc']:.2f}", "minimum_training_loss": f"{min(train['loss']):.4f}", "final_training_loss": f"{train['loss'][-1]:.4f}"})


def write_test_summary(manifest: dict[str, Any], entries: list[dict[str, Any]], output_dir: Path) -> None:
    fields = ["version", "checkpoint", "test_run_id", "dataset_id", "sample_count", "test_batches", "background_IoU", "background_Accuracy", "background_Dice", "forgery_IoU", "forgery_Accuracy", "forgery_Dice", "aAcc", "mIoU", "mAcc", "mDice", "data_time_per_batch_seconds", "time_per_batch_seconds"]
    dataset = manifest["dataset"]
    with (output_dir / "common_test_summary.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields); writer.writeheader()
        for entry in entries:
            test, background, forgery = entry["test"], entry["test"]["classes"]["background"], entry["test"]["classes"]["forgery"]
            writer.writerow({"version": entry["version"], "checkpoint": entry["checkpoint"], "test_run_id": entry["test_run_id"], "dataset_id": dataset["id"], "sample_count": dataset.get("sample_count") or "", "test_batches": test["total_batches"], "background_IoU": f"{background['IoU']:.2f}", "background_Accuracy": f"{background['Accuracy']:.2f}", "background_Dice": f"{background['Dice']:.2f}", "forgery_IoU": f"{forgery['IoU']:.2f}", "forgery_Accuracy": f"{forgery['Accuracy']:.2f}", "forgery_Dice": f"{forgery['Dice']:.2f}", "aAcc": f"{test['aAcc']:.2f}", "mIoU": f"{test['mIoU']:.2f}", "mAcc": f"{test['mAcc']:.2f}", "mDice": f"{test['mDice']:.2f}", "data_time_per_batch_seconds": f"{test['data_time']:.4f}", "time_per_batch_seconds": f"{test['time']:.4f}"})


def clean_generated_outputs(output_dir: Path, entries: list[dict[str, Any]]) -> None:
    stems = ("common_test_overall_metrics", "common_test_forgery_metrics", "validation_vs_test_miou", "qualitative_demo", "qualitative_onnx_example")
    legacy = ("best_mdice_bar.png", "best_miou_bar.png", "compare_loss.png", "compare_mdice.png", "compare_miou.png", "documented_benchmark.png", "test_benchmark_documented.png", "test_evaluation_onnx.png", "summary.csv")
    for stem in stems:
        for suffix in (".png", ".svg"):
            (output_dir / f"{stem}{suffix}").unlink(missing_ok=True)
    for name in legacy:
        (output_dir / name).unlink(missing_ok=True)
    for stem in ("validation_miou_by_run", "validation_mdice_by_run", "training_loss_by_run"):
        for suffix in (".png", ".svg"):
            (output_dir / "diagnostics" / f"{stem}{suffix}").unlink(missing_ok=True)
    for entry in entries:
        # Cleanup files produced by the pre-manifest generator and by the
        # historical dotted-version suffix bug.
        for legacy_name in ("loss_curve.png", "metrics_curve.png", "v1.0.png", "v1.0.svg"):
            (TESTS_ROOT / "v" / entry["version"] / legacy_name).unlink(missing_ok=True)
        for stem in (
            f"{entry['version']}_loss",
            f"{entry['version']}_metrics",
            f"{entry['version']}_qualitative_onnx_example",
        ):
            for suffix in (".png", ".svg"):
                (TESTS_ROOT / "v" / entry["version"] / f"{stem}{suffix}").unlink(missing_ok=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_FIGURES)
    parser.add_argument("--clean", action="store_true", help="Remove generator-owned outputs before rendering")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    manifest, entries = collect_evaluation_data(args.manifest)
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    if args.clean:
        clean_generated_outputs(output_dir, entries)
    _style()
    for entry in entries:
        plot_training_loss(entry)
        plot_validation_metrics(entry)
        plot_qualitative_onnx_example(entry)
    plot_diagnostics(entries, output_dir)
    plot_common_test(manifest, entries, output_dir)
    plot_qualitative_demo(output_dir)
    write_training_summary(entries, output_dir)
    write_test_summary(manifest, entries, output_dir)
    ranked = sorted(entries, key=lambda item: item["test"]["mIoU"], reverse=True)
    print(f"Validated {len(entries)} complete common-test runs from {args.manifest}")
    for entry in ranked:
        forgery = entry["test"]["classes"]["forgery"]
        print(f"{entry['version']}: test mIoU={entry['test']['mIoU']:.2f}, mDice={entry['test']['mDice']:.2f}, forgery IoU={forgery['IoU']:.2f}, forgery Dice={forgery['Dice']:.2f}")
    print(f"Figures and CSV summaries written to {output_dir}")


if __name__ == "__main__":
    main()
