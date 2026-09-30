"""Parity: serving path and eval harness share one tiling truth.

Compares onnx_worker wrappers against evaluation_core.OnnxSegmenter with a
fake ORT session. No model files, GPU, or datasets needed.
"""
import os
import sys

import numpy as np
import pytest
from PIL import Image

from app.services import onnx_worker
from app.services import tiling

sys.path.insert(
    0,
    os.path.join(
        os.path.dirname(__file__), "..", "..", "..", "model", "segformer", "Test-Case"
    ),
)
from evaluation_core import OnnxSegmenter


class FakeSession:
    """Deterministic logits: forgery prob ~0.88 everywhere, det logit 2.0."""

    def __init__(self, n_outputs=2):
        self._n = n_outputs

    def get_inputs(self):
        class In:
            name = "input"
        return [In()]

    def get_outputs(self):
        return [object()] * self._n

    def run(self, _a, _b):
        logits = np.zeros((1, 2, 8, 8), dtype=np.float32)
        logits[0, 1, :, :] = 2.0
        if self._n < 2:
            return [logits]
        return [logits, np.array([[2.0]], dtype=np.float32)]


def _image(w=700, h=500):
    rng = np.random.default_rng(7)
    return Image.fromarray(rng.integers(0, 256, (h, w, 3), dtype=np.uint8))


def test_worker_and_eval_agree_on_tiling():
    session = FakeSession()
    image = _image()
    worker_map = onnx_worker.tile_inference(session, "input", image)
    eval_map = OnnxSegmenter(session, tile_size=512, overlap=64).probability_map(image)
    assert worker_map.shape == (500, 700)
    np.testing.assert_allclose(worker_map, eval_map, rtol=1e-5, atol=1e-6)


def test_worker_and_eval_agree_on_small_image():
    session = FakeSession()
    image = _image(100, 80)
    worker_map = onnx_worker.tile_inference(session, "input", image)
    eval_map = OnnxSegmenter(session, tile_size=512, overlap=64).probability_map(image)
    np.testing.assert_allclose(worker_map, eval_map, rtol=1e-5, atol=1e-6)


def test_det_score_matches_and_none_without_head():
    image = _image(100, 80)
    expected = float(1.0 / (1.0 + np.exp(-2.0)))
    assert onnx_worker.run_det_image(FakeSession(n_outputs=2), "input", image) == pytest.approx(expected)
    assert onnx_worker.run_det_image(FakeSession(n_outputs=1), "input", image) is None


def test_shared_constants_single_truth():
    from evaluation_core import IMAGENET_MEAN, IMAGENET_STD

    np.testing.assert_array_equal(IMAGENET_MEAN, tiling.IMAGENET_MEAN)
    np.testing.assert_array_equal(IMAGENET_STD, tiling.IMAGENET_STD)
