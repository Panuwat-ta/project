"""Shared tiling inference math (single truth for serving + evaluation).

Pure numpy/cv2/PIL only — importable from both the ONNX worker subprocess
(sibling import, free) and the model eval harness (explicit sys.path insert
in evaluation_core.py). Train-time preprocessing and report rendering are
deliberately NOT here (different concepts).
"""
import cv2
import numpy as np
from PIL import Image

IMAGENET_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
IMAGENET_STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


def normalize_patch(patch: np.ndarray, tile_size: int,
                    mean: np.ndarray = IMAGENET_MEAN,
                    std: np.ndarray = IMAGENET_STD) -> np.ndarray:
    """uint8 HxWx3 patch -> normalized NCHW float32 tensor at tile_size."""
    resized = cv2.resize(patch, (tile_size, tile_size), interpolation=cv2.INTER_LANCZOS4)
    pixels = resized.astype(np.float32) / 255.0
    normalized = (pixels - mean) / std
    tensor = np.transpose(normalized, (2, 0, 1))[None].astype(np.float32)
    return tensor


def softmax_forgery(logits: np.ndarray, *, strict: bool = True) -> np.ndarray:
    """[1,2,H,W] logits -> class-1 (tampered) probability map [H,W]."""
    logits = np.asarray(logits, dtype=np.float32)
    if logits.ndim != 4 or logits.shape[:2] != (1, 2):
        if strict:
            raise RuntimeError(f"Expected ONNX output [1,2,H,W], got {logits.shape}")
        return np.zeros(logits.shape[2:], dtype=np.float32)
    shifted = logits - np.max(logits, axis=1, keepdims=True)
    exponent = np.exp(shifted)
    probability = exponent / np.sum(exponent, axis=1, keepdims=True)
    return probability[0, 1]


def run_patch(session, input_name: str, patch: np.ndarray, tile_size: int,
              *, strict: bool = False) -> np.ndarray:
    """Single HxWx3 uint8 patch -> forgery prob map resized back to (h, w).

    strict=False (serving): empty outputs -> zeros. strict=True (eval): raise.
    """
    h, w = patch.shape[:2]
    tensor = normalize_patch(patch, tile_size)
    outputs = session.run(None, {input_name: tensor})
    if not outputs:
        if strict:
            raise RuntimeError("ONNX session returned no outputs")
        return np.zeros((h, w), dtype=np.float32)
    forgery_prob = softmax_forgery(outputs[0], strict=strict)
    return cv2.resize(forgery_prob, (w, h), interpolation=cv2.INTER_LINEAR)


def tile_inference(session, input_name: str, image: Image.Image,
                   tile_size: int, overlap: int, *, strict: bool = False) -> np.ndarray:
    """Full-resolution prob map via overlapping tiles with averaged overlaps.

    Edge tiles are zero-padded to tile_size; only the real region accumulates.
    """
    image_np = np.asarray(image.convert("RGB"), dtype=np.uint8)
    h, w = image_np.shape[:2]
    if h <= tile_size and w <= tile_size:
        return run_patch(session, input_name, image_np, tile_size, strict=strict)

    stride = tile_size - overlap
    acc = np.zeros((h, w), dtype=np.float64)
    weight = np.zeros((h, w), dtype=np.float64)

    for y0 in range(0, h, stride):
        for x0 in range(0, w, stride):
            y1 = min(y0 + tile_size, h)
            x1 = min(x0 + tile_size, w)
            tile_h, tile_w = y1 - y0, x1 - x0

            if tile_h < tile_size or tile_w < tile_size:
                tile = np.zeros((tile_size, tile_size, 3), dtype=np.uint8)
                tile[:tile_h, :tile_w] = image_np[y0:y1, x0:x1]
            else:
                tile = image_np[y0:y1, x0:x1]

            prob = run_patch(session, input_name, tile, tile_size, strict=strict)
            acc[y0:y1, x0:x1] += prob[:tile_h, :tile_w]
            weight[y0:y1, x0:x1] += 1.0

    weight = np.maximum(weight, 1e-8)
    return (acc / weight).astype(np.float32)


def det_score_image(session, image: Image.Image, tile_size: int = 512) -> float | None:
    """Track B det-head score 0-1 from whole image downscaled to tile_size.

    Returns None for single-output models (backward compatible) or on error.
    """
    try:
        if len(session.get_outputs()) < 2:
            return None
        small = image.convert("RGB").resize((tile_size, tile_size), Image.BILINEAR)
        arr = np.asarray(small).astype(np.float32) / 255.0
        norm = (arr - IMAGENET_MEAN) / IMAGENET_STD
        tensor = np.expand_dims(np.transpose(norm, (2, 0, 1)), axis=0)
        input_name = session.get_inputs()[0].name
        outputs = session.run(None, {input_name: tensor})
        if len(outputs) < 2:
            return None
        logit = float(np.asarray(outputs[1]).ravel()[0])
        return float(1.0 / (1.0 + np.exp(-logit)))
    except Exception:
        return None
