"""Fast tests for the version comparison chart data pipeline."""
from __future__ import annotations

import csv
import json
import tempfile
import unittest
from pathlib import Path

from plot_version_results import (
    category_matrix,
    load_locked_results,
    load_qualitative_results,
    merge_quantitative_categories,
    merge_quantitative_overall,
    version_key,
)


OVERALL_HEADER = [
    "version",
    "group",
    "sample_count",
    "tp",
    "fp",
    "fn",
    "tn",
    "mIoU_percent",
    "mDice_percent",
    "background_IoU_percent",
    "background_Dice_percent",
    "forgery_IoU_percent",
    "forgery_Dice_percent",
    "accuracy_percent",
    "false_positive_rate_percent",
    "det_accuracy_percent",
    "onnx_model",
    "checkpoint",
    "elapsed_seconds",
]

CATEGORY_HEADER = [
    "version",
    "group",
    "sample_count",
    "mIoU_percent",
    "mDice_percent",
    "forgery_IoU_percent",
    "forgery_Dice_percent",
    "false_positive_rate_percent",
]

QUALITATIVE_HEADER = [
    "version",
    "pair_id",
    "original_peak_percent",
    "manipulated_peak_percent",
    "original_area_above_threshold_percent",
    "manipulated_area_above_threshold_percent",
    "threshold_percent",
]


def write_csv(path: Path, header: list[str], rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=header)
        writer.writeheader()
        writer.writerows(rows)


def overall_row(version: str, mdice: float) -> dict[str, object]:
    return {
        "version": version,
        "group": "all",
        "sample_count": 105,
        "tp": 10,
        "fp": 1,
        "fn": 2,
        "tn": 20,
        "mIoU_percent": 80.0,
        "mDice_percent": mdice,
        "background_IoU_percent": 95.0,
        "background_Dice_percent": 97.0,
        "forgery_IoU_percent": 65.0,
        "forgery_Dice_percent": 70.0,
        "accuracy_percent": 96.0,
        "false_positive_rate_percent": 0.5,
        "det_accuracy_percent": "",
        "onnx_model": f"work_dirs/{version}/model.onnx",
        "checkpoint": f"work_dirs/{version}/best.pth",
        "elapsed_seconds": 90.0,
    }


class TestVersionOrdering(unittest.TestCase):
    def test_versions_sort_numerically_instead_of_lexicographically(self) -> None:
        versions = ["v1.0.10", "v1.0.9", "v1.0.2", "v1.0.0"]

        ordered = sorted(versions, key=version_key)

        self.assertEqual(ordered, ["v1.0.0", "v1.0.2", "v1.0.9", "v1.0.10"])


class TestMergeQuantitativeOverall(unittest.TestCase):
    def test_second_snapshot_fills_versions_missing_from_the_first(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            primary = root / "primary"
            secondary = root / "secondary"
            write_csv(
                primary / "overall.csv",
                OVERALL_HEADER,
                [overall_row("v1.0.8", 87.0)],
            )
            write_csv(
                secondary / "overall.csv",
                OVERALL_HEADER,
                [overall_row("v1.0.7", 88.0), overall_row("v1.0.8", 87.0)],
            )

            rows, sources, notes = merge_quantitative_overall(
                [(primary, "primary"), (secondary, "secondary")]
            )

            self.assertEqual([row["version"] for row in rows], ["v1.0.7", "v1.0.8"])
            self.assertEqual(sources["v1.0.8"]["label"], "primary")
            self.assertEqual(sources["v1.0.7"]["label"], "secondary")
            self.assertEqual(rows[0]["mDice_percent"], 88.0)
            self.assertTrue(any(item["status"] == "verified" for item in notes))

    def test_conflicting_metric_values_between_snapshots_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            primary = root / "primary"
            secondary = root / "secondary"
            write_csv(
                primary / "overall.csv",
                OVERALL_HEADER,
                [overall_row("v1.0.8", 87.0)],
            )
            write_csv(
                secondary / "overall.csv",
                OVERALL_HEADER,
                [overall_row("v1.0.8", 91.0)],
            )

            with self.assertRaises(ValueError) as context:
                merge_quantitative_overall([(primary, "primary"), (secondary, "secondary")])

            self.assertIn("mDice_percent", str(context.exception))

    def test_missing_snapshot_is_reported_instead_of_raising(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            primary = root / "primary"
            write_csv(
                primary / "overall.csv",
                OVERALL_HEADER,
                [overall_row("v1.0.8", 87.0)],
            )

            rows, _sources, notes = merge_quantitative_overall(
                [(primary, "primary"), (root / "absent", "absent")]
            )

            self.assertEqual(len(rows), 1)
            self.assertTrue(any(item["status"] == "skipped" for item in notes))


class TestCategoryMatrix(unittest.TestCase):
    def test_matrix_has_one_row_per_category_and_one_column_per_version(self) -> None:
        rows = [
            {
                "version": "v1.0.0",
                "group": "casia",
                "mIoU_percent": 10.0,
                "mDice_percent": 20.0,
                "forgery_Dice_percent": 30.0,
                "false_positive_rate_percent": 1.0,
            },
            {
                "version": "v1.0.1",
                "group": "casia",
                "mIoU_percent": 11.0,
                "mDice_percent": 21.0,
                "forgery_Dice_percent": 31.0,
                "false_positive_rate_percent": 2.0,
            },
            {
                "version": "v1.0.0",
                "group": "authentic",
                "mIoU_percent": 50.0,
                "mDice_percent": 50.0,
                "forgery_Dice_percent": 0.0,
                "false_positive_rate_percent": 0.1,
            },
            {
                "version": "v1.0.1",
                "group": "authentic",
                "mIoU_percent": 50.0,
                "mDice_percent": 50.0,
                "forgery_Dice_percent": 0.0,
                "false_positive_rate_percent": 0.2,
            },
        ]
        versions = ["v1.0.0", "v1.0.1"]

        groups, matrix = category_matrix(
            rows, versions, "forgery_Dice_percent", exclude_authentic=True
        )

        self.assertEqual(groups, ["casia"])
        self.assertEqual(matrix, [[30.0, 31.0]])

        all_groups, fpr_matrix = category_matrix(
            rows, versions, "false_positive_rate_percent", exclude_authentic=False
        )

        self.assertEqual(all_groups, ["authentic", "casia"])
        self.assertEqual(fpr_matrix, [[0.1, 0.2], [1.0, 2.0]])


class TestMergeQuantitativeCategories(unittest.TestCase):
    def test_categories_from_both_snapshots_are_merged_per_version(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            primary = root / "primary"
            secondary = root / "secondary"
            write_csv(
                primary / "per_category.csv",
                CATEGORY_HEADER,
                [
                    {
                        "version": "v1.0.8",
                        "group": "casia",
                        "sample_count": 15,
                        "mIoU_percent": 67.4,
                        "mDice_percent": 80.3,
                        "forgery_IoU_percent": 60.3,
                        "forgery_Dice_percent": 75.3,
                        "false_positive_rate_percent": 7.5,
                    }
                ],
            )
            write_csv(
                secondary / "per_category.csv",
                CATEGORY_HEADER,
                [
                    {
                        "version": "v1.0.7",
                        "group": "casia",
                        "sample_count": 15,
                        "mIoU_percent": 65.4,
                        "mDice_percent": 78.8,
                        "forgery_IoU_percent": 56.9,
                        "forgery_Dice_percent": 72.6,
                        "false_positive_rate_percent": 5.4,
                    }
                ],
            )

            rows = merge_quantitative_categories(
                [(primary, "primary"), (secondary, "secondary")]
            )

            self.assertEqual(
                [(row["version"], row["group"]) for row in rows],
                [("v1.0.7", "casia"), ("v1.0.8", "casia")],
            )
            self.assertEqual(rows[1]["forgery_Dice_percent"], 75.3)


class TestLoadQualitativeResults(unittest.TestCase):
    def test_per_version_statistics_are_derived_from_the_pair_rows(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write_csv(
                root / "v1.0.0" / "qualitative_pair_scores_v1.0.0.csv",
                QUALITATIVE_HEADER,
                [
                    {
                        "version": "v1.0.0",
                        "pair_id": "pair001",
                        "original_peak_percent": 10.0,
                        "manipulated_peak_percent": 90.0,
                        "original_area_above_threshold_percent": 0.0,
                        "manipulated_area_above_threshold_percent": 5.0,
                        "threshold_percent": 40.0,
                    },
                    {
                        "version": "v1.0.0",
                        "pair_id": "pair002",
                        "original_peak_percent": 20.0,
                        "manipulated_peak_percent": 70.0,
                        "original_area_above_threshold_percent": 0.5,
                        "manipulated_area_above_threshold_percent": 0.0,
                        "threshold_percent": 40.0,
                    },
                ],
            )

            rows, warnings = load_qualitative_results(root)

            self.assertEqual(warnings, [])
            self.assertEqual(len(rows), 1)
            self.assertEqual(rows[0]["pair_count"], 2)
            self.assertAlmostEqual(rows[0]["manipulated_peak_mean"], 80.0)
            self.assertAlmostEqual(rows[0]["original_peak_mean"], 15.0)
            self.assertAlmostEqual(rows[0]["original_peak_max"], 20.0)
            self.assertAlmostEqual(rows[0]["manipulated_peak_min"], 70.0)
            self.assertEqual(rows[0]["manipulated_pairs_with_area"], 1)
            self.assertEqual(rows[0]["original_pairs_with_area"], 1)

    def test_file_whose_version_column_disagrees_with_the_folder_is_skipped(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            write_csv(
                root / "v1.0.0" / "qualitative_pair_scores_v1.0.0.csv",
                QUALITATIVE_HEADER,
                [
                    {
                        "version": "v1.0.9",
                        "pair_id": "pair001",
                        "original_peak_percent": 10.0,
                        "manipulated_peak_percent": 90.0,
                        "original_area_above_threshold_percent": 0.0,
                        "manipulated_area_above_threshold_percent": 5.0,
                        "threshold_percent": 40.0,
                    }
                ],
            )

            with self.assertRaises(ValueError):
                load_qualitative_results(root)


class TestLoadLockedResults(unittest.TestCase):
    def test_locked_rows_come_from_the_manifest_expected_common_test(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "evaluation_manifest.json"
            path.write_text(
                json.dumps(
                    {
                        "dataset": {"id": "locked-set", "test_batches": 2504},
                        "versions": [
                            {
                                "version": "v1.0.1",
                                "checkpoint": "work_dirs/v1.0.1/best.pth",
                                "test_run_id": "20260915_091531",
                                "expected_common_test": {
                                    "mIoU": 47.8,
                                    "mDice": 49.69,
                                    "forgery_IoU": 1.12,
                                    "forgery_Dice": 2.22,
                                },
                            },
                            {
                                "version": "v1.0.0",
                                "checkpoint": "work_dirs/v1.0.0/best.pth",
                                "test_run_id": "20260915_101330",
                                "expected_common_test": {
                                    "mIoU": 48.7,
                                    "mDice": 51.42,
                                    "forgery_IoU": 2.92,
                                    "forgery_Dice": 5.67,
                                },
                            },
                        ],
                    }
                ),
                encoding="utf-8",
            )

            dataset, rows = load_locked_results(path)

            self.assertEqual(dataset["id"], "locked-set")
            self.assertEqual([row["version"] for row in rows], ["v1.0.0", "v1.0.1"])
            self.assertEqual(rows[0]["mDice_percent"], 51.42)
            self.assertEqual(rows[1]["forgery_Dice_percent"], 2.22)


if __name__ == "__main__":
    unittest.main()
