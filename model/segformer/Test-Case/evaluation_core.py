"""Shared primitives for SegFormer image regression and qualitative tests."""
from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

import cv2
import numpy as np
from PIL import Image

# Single-truth tiling math lives next to the ONNX worker subprocess.
# Explicit path insert (not a hidden dependency): Test-Case -> segformer ->
# model -> project, then server/app/services/tiling.py.
_REPO_ROOT = Path(__file__).resolve().parents[3]
_SERVICES_DIR = str(_REPO_ROOT / "server" / "app" / "services")
if _SERVICES_DIR not in sys.path:
    sys.path.insert(0, _SERVICES_DIR)
from tiling import (  # noqa: E402
    IMAGENET_MEAN,
    IMAGENET_STD,
    det_score_image,
    tile_inference,
)

__all__ = [
    "IMAGENET_MEAN",
    "IMAGENET_STD",
    "det_score_image",
    "tile_inference",
]


Confusion = dict[str, int]


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
        from tiling import run_patch

        return run_patch(
            self.session, self.input_name, patch, self.tile_size, strict=True
        )

    def probability_map(self, image: Image.Image) -> np.ndarray:
        return tile_inference(
            self.session,
            self.input_name,
            image,
            self.tile_size,
            self.overlap,
            strict=True,
        )


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
