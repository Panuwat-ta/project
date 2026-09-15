#!/usr/bin/env python3
"""Render original/manipulated ONNX heatmaps for manual qualitative review."""
from __future__ import annotations

import argparse
import csv
import json
import time
from pathlib import Path
from typing import Any

import cv2
import numpy as np
import onnxruntime as ort
from PIL import Image, ImageDraw, ImageFont

from evaluation_core import OnnxSegmenter, QualitativePair, discover_qualitative_pairs


HERE = Path(__file__).resolve().parent
SEGFORMER_ROOT = HERE.parent
DEFAULT_DATA_ROOT = Path("/home/panuwat/Pictures/Test-Cases/pairs")
DEFAULT_MANIFEST = SEGFORMER_ROOT / "tests_model" / "evaluation_manifest.json"
DEFAULT_OUTPUT = HERE / "output" / "qualitative"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create manual-review heatmaps for original/manipulated pairs."
    )
    parser.add_argument("--data-root", type=Path, default=DEFAULT_DATA_ROOT)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--versions", nargs="*")
    parser.add_argument("--tile-size", type=int, default=512)
    parser.add_argument("--tile-overlap", type=int, default=64)
    parser.add_argument("--threshold", type=float, default=0.4)
    parser.add_argument(
        "--max-side",
        type=int,
        default=1024,
        help="Resize very large images for qualitative rendering only; 0 keeps full size.",
    )
    parser.add_argument("--limit", type=int)
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


def analysis_image(path: Path, max_side: int) -> Image.Image:
    image = Image.open(path).convert("RGB")
    if max_side > 0 and max(image.size) > max_side:
        image.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)
    return image


def heatmap_overlay(image: Image.Image, probability: np.ndarray) -> Image.Image:
    heatmap = cv2.applyColorMap(
        np.uint8(np.clip(probability, 0.0, 1.0) * 255.0),
        cv2.COLORMAP_MAGMA,
    )
    heatmap_rgb = cv2.cvtColor(heatmap, cv2.COLOR_BGR2RGB)
    return Image.blend(image, Image.fromarray(heatmap_rgb), 0.55)


def _font(size: int) -> ImageFont.ImageFont:
    font_path = Path("/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf")
    if not font_path.is_file():
        font_path = Path("/usr/share/fonts/TTF/DejaVuSans.ttf")
    if font_path.is_file():
        return ImageFont.truetype(str(font_path), size=size)
    return ImageFont.load_default()


def panel(image: Image.Image, title: str, *, width: int = 400, height: int = 340) -> Image.Image:
    panel_image = Image.new("RGB", (width, height), "white")
    preview = image.copy()
    preview.thumbnail((width - 20, height - 60), Image.Resampling.LANCZOS)
    x = (width - preview.width) // 2
    y = 50 + (height - 50 - preview.height) // 2
    panel_image.paste(preview, (x, y))
    draw = ImageDraw.Draw(panel_image)
    draw.text((width // 2, 24), title, fill="black", font=_font(17), anchor="mm")
    return panel_image


def render_pair(
    *,
    pair: QualitativePair,
    version: str,
    original: Image.Image,
    manipulated: Image.Image,
    original_probability: np.ndarray,
    manipulated_probability: np.ndarray,
    threshold: float,
    model_name: str,
    max_side: int,
) -> Image.Image:
    original_peak = float(original_probability.max()) * 100.0
    manipulated_peak = float(manipulated_probability.max()) * 100.0
    original_area = float(np.mean(original_probability >= threshold)) * 100.0
    manipulated_area = float(np.mean(manipulated_probability >= threshold)) * 100.0
    panels = [
        panel(original, "Original image"),
        panel(
            heatmap_overlay(original, original_probability),
            f"Original heatmap | peak {original_peak:.1f}% | area {original_area:.1f}%",
        ),
        panel(manipulated, "Manipulated image"),
        panel(
            heatmap_overlay(manipulated, manipulated_probability),
            f"Manipulated heatmap | peak {manipulated_peak:.1f}% | area {manipulated_area:.1f}%",
        ),
    ]
    margin = 10
    header = 58
    footer = 48
    canvas = Image.new(
        "RGB",
        (sum(item.width for item in panels) + margin * 2, panels[0].height + header + footer),
        "white",
    )
    draw = ImageDraw.Draw(canvas)
    draw.text(
        (canvas.width // 2, 25),
        f"Qualitative ONNX Pair — {version} — {pair.pair_id}",
        fill="black",
        font=_font(22),
        anchor="mm",
    )
    x = margin
    for item in panels:
        canvas.paste(item, (x, header))
        x += item.width
    resize_note = f"max side {max_side}px" if max_side > 0 else "full resolution"
    footer_text = (
        f"ONNX: {model_name} | Production-style 512px overlapping tiles | "
        f"Display threshold: {threshold * 100:.0f}% | Qualitative only ({resize_note}); no mask, no accuracy claim."
    )
    draw.text(
        (canvas.width // 2, canvas.height - 22),
        footer_text,
        fill=(70, 70, 70),
        font=_font(13),
        anchor="mm",
    )
    return canvas


def main() -> int:
    args = parse_args()
    if not 0.0 < args.threshold < 1.0:
        raise ValueError("threshold must be between 0 and 1")
    if args.max_side < 0:
        raise ValueError("max-side cannot be negative")
    pairs = discover_qualitative_pairs(args.data_root)
    if args.limit is not None:
        if args.limit <= 0:
            raise ValueError("limit must be positive")
        pairs = pairs[: args.limit]
    entries = load_entries(args.manifest, args.versions)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    rows: list[dict[str, Any]] = []

    for entry in entries:
        version = str(entry["version"])
        model_path = SEGFORMER_ROOT / str(entry["onnx_model"])
        if not model_path.is_file():
            raise FileNotFoundError(f"Missing ONNX model for {version}: {model_path}")
        version_output = args.output_dir / version
        version_output.mkdir(parents=True, exist_ok=True)
        print(f"[{version}] loading {model_path.name}", flush=True)
        session = ort.InferenceSession(str(model_path), providers=["CPUExecutionProvider"])
        segmenter = OnnxSegmenter(
            session, tile_size=args.tile_size, overlap=args.tile_overlap
        )
        for index, pair in enumerate(pairs, start=1):
            started = time.monotonic()
            original = analysis_image(pair.original_path, args.max_side)
            manipulated = analysis_image(pair.manipulated_path, args.max_side)
            original_probability = segmenter.probability_map(original)
            manipulated_probability = segmenter.probability_map(manipulated)
            original_peak = float(original_probability.max()) * 100.0
            manipulated_peak = float(manipulated_probability.max()) * 100.0
            original_area = float(np.mean(original_probability >= args.threshold)) * 100.0
            manipulated_area = float(
                np.mean(manipulated_probability >= args.threshold)
            ) * 100.0
            figure = render_pair(
                pair=pair,
                version=version,
                original=original,
                manipulated=manipulated,
                original_probability=original_probability,
                manipulated_probability=manipulated_probability,
                threshold=args.threshold,
                model_name=model_path.name,
                max_side=args.max_side,
            )
            figure.save(version_output / f"{pair.pair_id}.png", optimize=True)
            rows.append(
                {
                    "version": version,
                    "pair_id": pair.pair_id,
                    "original_path": str(pair.original_path),
                    "manipulated_path": str(pair.manipulated_path),
                    "original_analysis_width": original.width,
                    "original_analysis_height": original.height,
                    "manipulated_analysis_width": manipulated.width,
                    "manipulated_analysis_height": manipulated.height,
                    "original_peak_percent": round(original_peak, 6),
                    "manipulated_peak_percent": round(manipulated_peak, 6),
                    "original_area_above_threshold_percent": round(original_area, 6),
                    "manipulated_area_above_threshold_percent": round(
                        manipulated_area, 6
                    ),
                    "threshold_percent": args.threshold * 100.0,
                    "elapsed_seconds": round(time.monotonic() - started, 3),
                    "original_url": pair.metadata.get("original_url", ""),
                    "photoshop_url": pair.metadata.get("photoshop_url", ""),
                }
            )
            print(f"[{version}] {index}/{len(pairs)} pairs", flush=True)

    fieldnames = list(rows[0]) if rows else []
    with (args.output_dir / "qualitative_pair_scores.csv").open(
        "w", newline="", encoding="utf-8"
    ) as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    summary = {
        "dataset_root": str(args.data_root.resolve()),
        "pair_count": len(pairs),
        "versions": [entry["version"] for entry in entries],
        "artifacts_per_version": len(pairs),
        "analysis_max_side": args.max_side or None,
        "threshold_percent": args.threshold * 100.0,
        "interpretation": (
            "Manual qualitative comparison only. Original/manipulated pairs have no "
            "ground-truth masks, so these scores are not IoU, Dice, or accuracy."
        ),
    }
    (args.output_dir / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Wrote qualitative results to {args.output_dir}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
