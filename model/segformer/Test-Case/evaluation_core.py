"""Shared primitives for SegFormer image regression and qualitative tests."""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

import cv2
import numpy as np
from PIL import Image


Confusion = dict[str, int]
IMAGENET_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
IMAGENET_STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


@dataclass(frozen=True)
class MaskCase:
    category: str
    case_id: str
    image_path: Path
    mask_path: Path


@dataclass(frozen=True)
class QualitativePair:
    pair_id: str
    original_path: Path
    manipulated_path: Path
    metadata: dict[str, str]


def discover_mask_cases(masked_root: Path) -> list[MaskCase]:
    """Discover matching ``images/test`` and ``annotations/test`` files."""
    if not masked_root.is_dir():
        raise FileNotFoundError(f"Masked Test-Case directory not found: {masked_root}")

    cases: list[MaskCase] = []
    for category_root in sorted(path for path in masked_root.iterdir() if path.is_dir()):
        image_root = category_root / "images" / "test"
        mask_root = category_root / "annotations" / "test"
        if not image_root.is_dir() or not mask_root.is_dir():
            raise ValueError(f"Incomplete masked category layout: {category_root}")
        for image_path in sorted(path for path in image_root.iterdir() if path.is_file()):
            mask_path = mask_root / image_path.name
            if not mask_path.is_file():
                raise ValueError(f"Missing mask for {image_path}: expected {mask_path}")
            cases.append(
                MaskCase(
                    category=category_root.name,
                    case_id=f"{category_root.name}/{image_path.stem}",
                    image_path=image_path,
                    mask_path=mask_path,
                )
            )

    if not cases:
        raise ValueError(f"No image/mask cases found below {masked_root}")
    return cases


def _one_matching_file(directory: Path, prefix: str) -> Path:
    matches = sorted(path for path in directory.glob(f"{prefix}.*") if path.is_file())
    if len(matches) != 1:
        raise ValueError(
            f"Expected exactly one file matching {directory / (prefix + '.*')}, "
            f"found {len(matches)}"
        )
    return matches[0]


def discover_qualitative_pairs(pairs_root: Path) -> list[QualitativePair]:
    """Discover the pairs declared by pairs.json and validate both images."""
    metadata_path = pairs_root / "pairs.json"
    if not metadata_path.is_file():
        raise FileNotFoundError(f"Pair metadata not found: {metadata_path}")
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    if not isinstance(metadata, dict) or not metadata:
        raise ValueError(f"Pair metadata must be a non-empty object: {metadata_path}")

    pairs: list[QualitativePair] = []
    for pair_id, pair_metadata in sorted(metadata.items()):
        if not isinstance(pair_metadata, dict):
            raise ValueError(f"Invalid metadata for {pair_id}")
        original = _one_matching_file(pairs_root / "originals", f"{pair_id}_orig")
        manipulated = _one_matching_file(
            pairs_root / "manipulated", f"{pair_id}_mani"
        )
        pairs.append(
            QualitativePair(
                pair_id=pair_id,
                original_path=original,
                manipulated_path=manipulated,
                metadata={str(key): str(value) for key, value in pair_metadata.items()},
            )
        )
    return pairs


class OnnxSegmenter:
    """Run the same 512px overlapping-tile inference used by production."""

    def __init__(self, session: Any, *, tile_size: int = 512, overlap: int = 64):
        if tile_size <= 0:
            raise ValueError("tile_size must be positive")
        if overlap < 0 or overlap >= tile_size:
            raise ValueError("overlap must be in the range [0, tile_size)")
        self.session = session
        self.input_name = session.get_inputs()[0].name
        self.tile_size = tile_size
        self.overlap = overlap
        self.stride = tile_size - overlap

    def _run_patch(self, patch: np.ndarray) -> np.ndarray:
        height, width = patch.shape[:2]
        resized = cv2.resize(
            patch,
            (self.tile_size, self.tile_size),
            interpolation=cv2.INTER_LANCZOS4,
        )
        pixels = resized.astype(np.float32) / 255.0
        normalized = (pixels - IMAGENET_MEAN) / IMAGENET_STD
        tensor = np.transpose(normalized, (2, 0, 1))[None].astype(np.float32)
        outputs = self.session.run(None, {self.input_name: tensor})
        if not outputs:
            raise RuntimeError("ONNX session returned no outputs")
        logits = np.asarray(outputs[0], dtype=np.float32)
        if logits.ndim != 4 or logits.shape[:2] != (1, 2):
            raise RuntimeError(f"Expected ONNX output [1,2,H,W], got {logits.shape}")
        shifted = logits - np.max(logits, axis=1, keepdims=True)
        exponent = np.exp(shifted)
        probability = exponent / np.sum(exponent, axis=1, keepdims=True)
        return cv2.resize(
            probability[0, 1],
            (width, height),
            interpolation=cv2.INTER_LINEAR,
        )

    def probability_map(self, image: Image.Image) -> np.ndarray:
        image_array = np.asarray(image.convert("RGB"), dtype=np.uint8)
        height, width = image_array.shape[:2]
        if height <= self.tile_size and width <= self.tile_size:
            return self._run_patch(image_array)

        accumulated = np.zeros((height, width), dtype=np.float64)
        weights = np.zeros((height, width), dtype=np.float64)
        for y0 in range(0, height, self.stride):
            for x0 in range(0, width, self.stride):
                y1 = min(y0 + self.tile_size, height)
                x1 = min(x0 + self.tile_size, width)
                tile_height = y1 - y0
                tile_width = x1 - x0
                if tile_height < self.tile_size or tile_width < self.tile_size:
                    tile = np.zeros(
                        (self.tile_size, self.tile_size, 3), dtype=np.uint8
                    )
                    tile[:tile_height, :tile_width] = image_array[y0:y1, x0:x1]
                else:
                    tile = image_array[y0:y1, x0:x1]
                probability = self._run_patch(tile)
                accumulated[y0:y1, x0:x1] += probability[:tile_height, :tile_width]
                weights[y0:y1, x0:x1] += 1.0
        return (accumulated / np.maximum(weights, 1e-8)).astype(np.float32)


def binary_confusion(prediction: np.ndarray, target: np.ndarray) -> Confusion:
    """Return pixel-level confusion counts for class 1 (forgery)."""
    if prediction.shape != target.shape:
        raise ValueError(
            f"prediction and target shapes differ: {prediction.shape} != {target.shape}"
        )
    predicted_forgery = np.asarray(prediction).astype(bool)
    target_forgery = np.asarray(target).astype(bool)
    return {
        "tp": int(np.count_nonzero(predicted_forgery & target_forgery)),
        "fp": int(np.count_nonzero(predicted_forgery & ~target_forgery)),
        "fn": int(np.count_nonzero(~predicted_forgery & target_forgery)),
        "tn": int(np.count_nonzero(~predicted_forgery & ~target_forgery)),
    }


def _ratio(numerator: int, denominator: int) -> float | None:
    return numerator / denominator if denominator else None


def metrics_from_confusion(confusion: Mapping[str, int]) -> dict[str, float | None]:
    """Calculate class and mean segmentation metrics from accumulated counts."""
    tp = int(confusion["tp"])
    fp = int(confusion["fp"])
    fn = int(confusion["fn"])
    tn = int(confusion["tn"])

    forgery_iou = _ratio(tp, tp + fp + fn)
    background_iou = _ratio(tn, tn + fp + fn)
    forgery_dice = _ratio(2 * tp, 2 * tp + fp + fn)
    background_dice = _ratio(2 * tn, 2 * tn + fp + fn)

    valid_ious = [value for value in (background_iou, forgery_iou) if value is not None]
    valid_dices = [value for value in (background_dice, forgery_dice) if value is not None]
    return {
        "mIoU": sum(valid_ious) / len(valid_ious) if valid_ious else None,
        "mDice": sum(valid_dices) / len(valid_dices) if valid_dices else None,
        "background_IoU": background_iou,
        "background_Dice": background_dice,
        "forgery_IoU": forgery_iou,
        "forgery_Dice": forgery_dice,
        "accuracy": _ratio(tp + tn, tp + fp + fn + tn),
        "false_positive_rate": _ratio(fp, fp + tn),
    }
