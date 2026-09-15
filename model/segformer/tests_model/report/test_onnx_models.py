"""Contract tests for every SegFormer ONNX model in the manifest.

These tests verify model packaging and inference behavior. They do not replace
locked-dataset evaluation, PyTorch/ONNX parity, or performance benchmarks.
"""
from __future__ import annotations

import json
import unittest
from pathlib import Path

import numpy as np

try:
    import onnxruntime as ort
except ImportError as error:  # pragma: no cover - environment error path
    raise RuntimeError(
        "onnxruntime is required; run this test with server/venv/bin/python"
    ) from error


SEGFORMER_ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = SEGFORMER_ROOT / "tests_model" / "evaluation_manifest.json"
DYNAMIC_TEST_SHAPES = ((256, 256), (320, 448))


class TestOnnxModels(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        cls.entries = manifest["versions"]
        if not cls.entries:
            raise AssertionError("evaluation_manifest.json contains no model versions")

    def test_model_and_external_weights_exist(self) -> None:
        for entry in self.entries:
            with self.subTest(version=entry["version"]):
                model_path = SEGFORMER_ROOT / entry["onnx_model"]
                weights_path = Path(f"{model_path}.data")
                self.assertTrue(model_path.is_file(), f"Missing ONNX: {model_path}")
                self.assertGreater(model_path.stat().st_size, 0, f"Empty ONNX: {model_path}")
                self.assertTrue(
                    weights_path.is_file(),
                    f"Missing external ONNX weights: {weights_path}",
                )
                self.assertGreater(
                    weights_path.stat().st_size,
                    0,
                    f"Empty external ONNX weights: {weights_path}",
                )

    def test_input_and_output_metadata_contract(self) -> None:
        for entry in self.entries:
            with self.subTest(version=entry["version"]):
                session = self._create_session(entry)
                inputs = session.get_inputs()
                outputs = session.get_outputs()
                self.assertEqual(len(inputs), 1)
                self.assertEqual(len(outputs), 1)
                self.assertEqual(inputs[0].type, "tensor(float)")
                self.assertEqual(inputs[0].shape[:2], [1, 3])
                self.assertEqual(outputs[0].type, "tensor(float)")
                self.assertEqual(outputs[0].shape[:2], [1, 2])
                self.assertFalse(isinstance(inputs[0].shape[2], int))
                self.assertFalse(isinstance(inputs[0].shape[3], int))

    def test_dynamic_inference_is_finite_deterministic_and_normalized(self) -> None:
        random = np.random.default_rng(20260915)
        for entry in self.entries:
            session = self._create_session(entry)
            input_name = session.get_inputs()[0].name
            for height, width in DYNAMIC_TEST_SHAPES:
                with self.subTest(
                    version=entry["version"],
                    height=height,
                    width=width,
                ):
                    tensor = random.normal(
                        loc=0.0,
                        scale=1.0,
                        size=(1, 3, height, width),
                    ).astype(np.float32)
                    logits = session.run(None, {input_name: tensor})[0]
                    expected_shape = (1, 2, (height + 3) // 4, (width + 3) // 4)
                    self.assertEqual(logits.shape, expected_shape)
                    self.assertTrue(np.isfinite(logits).all())

                    shifted = logits - np.max(logits, axis=1, keepdims=True)
                    exponent = np.exp(shifted)
                    probabilities = exponent / np.sum(exponent, axis=1, keepdims=True)
                    self.assertGreaterEqual(float(probabilities.min()), 0.0)
                    self.assertLessEqual(float(probabilities.max()), 1.0)
                    np.testing.assert_allclose(
                        probabilities.sum(axis=1),
                        1.0,
                        rtol=1e-5,
                        atol=1e-6,
                    )

                    if (height, width) == DYNAMIC_TEST_SHAPES[0]:
                        repeated = session.run(None, {input_name: tensor})[0]
                        np.testing.assert_allclose(
                            repeated,
                            logits,
                            rtol=1e-5,
                            atol=1e-6,
                        )

    def _create_session(self, entry: dict[str, object]) -> ort.InferenceSession:
        model_path = SEGFORMER_ROOT / str(entry["onnx_model"])
        return ort.InferenceSession(
            str(model_path),
            providers=["CPUExecutionProvider"],
        )


if __name__ == "__main__":
    unittest.main()
