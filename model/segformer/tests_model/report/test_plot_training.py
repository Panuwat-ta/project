import copy
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("plot_training.py")
FIXTURE_ROOT = Path(__file__).with_name("fixtures")
SPEC = importlib.util.spec_from_file_location("segformer_plot_training", MODULE_PATH)
plot_training = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = plot_training
SPEC.loader.exec_module(plot_training)

class TestCommonTestParser(unittest.TestCase):
    def test_parses_complete_test_log(self):
        text = (FIXTURE_ROOT / "test_complete.log").read_text(encoding="utf-8")
        result = plot_training.parse_test_log_text(text, expected_batches=2504)
        self.assertEqual(result["total_batches"], 2504)
        self.assertEqual(result["mIoU"], 91.24)
        self.assertEqual(result["classes"]["forgery"]["IoU"], 83.51)
        self.assertEqual(result["classes"]["forgery"]["Dice"], 91.01)

    def test_rejects_incomplete_test_log(self):
        incomplete = (FIXTURE_ROOT / "test_incomplete.log").read_text(encoding="utf-8")
        with self.assertRaisesRegex(plot_training.EvaluationDataError, "Incomplete"):
            plot_training.parse_test_log_text(incomplete, expected_batches=2504)

    def test_rejects_missing_per_class_results(self):
        missing = (FIXTURE_ROOT / "test_missing_per_class.log").read_text(encoding="utf-8")
        with self.assertRaisesRegex(plot_training.EvaluationDataError, "background/forgery"):
            plot_training.parse_test_log_text(missing, expected_batches=2504)


class TestManifestValidation(unittest.TestCase):
    def test_rejects_duplicate_artifact_path(self):
        manifest = {
            "schema_version": 1,
            "dataset": {"id": "locked-test", "sample_count": None, "test_batches": 2504},
            "versions": [
                {"version": "v1.0.0", "checkpoint": "work_dirs/v1/model.pth", "onnx_model": "work_dirs/v1/model.onnx", "training_log": "work_dirs/v1/train.json", "training_run_id": "train-1", "test_log": "work_dirs/v1/test.log", "test_run_id": "test-1", "expected_common_test": {"mIoU": 1.0, "mDice": 2.0, "forgery_IoU": 3.0, "forgery_Dice": 4.0}},
                {"version": "v1.0.1", "checkpoint": "work_dirs/v2/model.pth", "onnx_model": "work_dirs/v2/model.onnx", "training_log": "work_dirs/v2/train.json", "training_run_id": "train-2", "test_log": "work_dirs/v1/test.log", "test_run_id": "test-2", "expected_common_test": {"mIoU": 1.0, "mDice": 2.0, "forgery_IoU": 3.0, "forgery_Dice": 4.0}},
            ],
        }
        with tempfile.TemporaryDirectory() as temporary:
            with self.assertRaisesRegex(plot_training.EvaluationDataError, "Duplicate artifact path"):
                plot_training.validate_manifest_data(copy.deepcopy(manifest), Path(temporary), check_files=False)


class TestRecordedResults(unittest.TestCase):
    def test_regression_values_and_ranking(self):
        _, entries = plot_training.collect_evaluation_data(plot_training.DEFAULT_MANIFEST)
        by_version = {entry["version"]: entry for entry in entries}
        manifest, _ = plot_training.load_manifest(plot_training.DEFAULT_MANIFEST)
        expected = {
            entry["version"]: entry["expected_common_test"]
            for entry in manifest["versions"]
        }
        self.assertEqual(set(by_version), set(expected))
        for version, metrics in expected.items():
            test = by_version[version]["test"]
            actual = (
                test["mIoU"],
                test["mDice"],
                test["classes"]["forgery"]["IoU"],
                test["classes"]["forgery"]["Dice"],
            )
            values = (
                metrics["mIoU"],
                metrics["mDice"],
                metrics["forgery_IoU"],
                metrics["forgery_Dice"],
            )
            self.assertEqual(actual, values, version)
        winner = max(entries, key=lambda entry: entry["test"]["mIoU"])
        expected_winner = max(expected, key=lambda version: expected[version]["mIoU"])
        self.assertEqual(winner["version"], expected_winner)


if __name__ == "__main__":
    unittest.main()
