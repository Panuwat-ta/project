"""Fast tests for the reusable Test-Case evaluation primitives."""
from __future__ import annotations

import unittest

import numpy as np
from PIL import Image

from evaluation_core import (
    binary_confusion,
    metrics_from_confusion,
    OnnxSegmenter,
)


class TestBinaryMetrics(unittest.TestCase):
    def test_metrics_are_derived_from_pixel_confusion_counts(self) -> None:
        target = np.array([[0, 0], [1, 1]], dtype=np.uint8)
        prediction = np.array([[0, 1], [1, 0]], dtype=np.uint8)

        confusion = binary_confusion(prediction, target)
        metrics = metrics_from_confusion(confusion)

        self.assertEqual(confusion, {"tp": 1, "fp": 1, "fn": 1, "tn": 1})
        self.assertAlmostEqual(metrics["mIoU"], 1 / 3)
        self.assertAlmostEqual(metrics["mDice"], 1 / 2)
        self.assertAlmostEqual(metrics["forgery_IoU"], 1 / 3)
        self.assertAlmostEqual(metrics["forgery_Dice"], 1 / 2)
        self.assertAlmostEqual(metrics["accuracy"], 1 / 2)
        self.assertAlmostEqual(metrics["false_positive_rate"], 1 / 2)

    def test_absent_forgery_class_is_not_invented_when_both_masks_are_empty(self) -> None:
        empty = np.zeros((2, 2), dtype=np.uint8)

        metrics = metrics_from_confusion(binary_confusion(empty, empty))

        self.assertIsNone(metrics["forgery_IoU"])
        self.assertIsNone(metrics["forgery_Dice"])
        self.assertEqual(metrics["mIoU"], 1.0)
        self.assertEqual(metrics["mDice"], 1.0)


class _FakeInput:
    name = "input"


class _ConstantForgerySession:
    def __init__(self) -> None:
        self.input_shapes: list[tuple[int, ...]] = []

    def get_inputs(self) -> list[_FakeInput]:
        return [_FakeInput()]

    def run(self, _outputs: object, feeds: dict[str, np.ndarray]) -> list[np.ndarray]:
        tensor = feeds["input"]
        self.input_shapes.append(tensor.shape)
        _, _, height, width = tensor.shape
        logits = np.zeros((1, 2, (height + 3) // 4, (width + 3) // 4), dtype=np.float32)
        logits[:, 1] = np.log(9.0)  # softmax forgery probability = 0.9
        return [logits]


class TestProductionStyleTiling(unittest.TestCase):
    def test_large_image_is_tiled_and_reassembled_at_original_resolution(self) -> None:
        session = _ConstantForgerySession()
        segmenter = OnnxSegmenter(session, tile_size=512, overlap=64)
        image = Image.new("RGB", (750, 700), color=(128, 128, 128))

        probability = segmenter.probability_map(image)

        self.assertEqual(probability.shape, (700, 750))
        self.assertEqual(session.input_shapes, [(1, 3, 512, 512)] * 4)
        np.testing.assert_allclose(probability, 0.9, rtol=1e-5, atol=1e-5)


if __name__ == "__main__":
    unittest.main()
