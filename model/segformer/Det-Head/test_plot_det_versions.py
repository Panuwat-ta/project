"""Fast tests for the Det-Head version comparison chart data pipeline."""
from __future__ import annotations

import csv
import json
import tempfile
import unittest
from pathlib import Path

from plot_det_versions import HEAD_ORDER, ordered_heads, score_means


def write_diagnostics(root: Path, heads: list[str]) -> Path:
    diagnostics_dir = root / "diag"
    diagnostics_dir.mkdir(parents=True, exist_ok=True)
    payload = {
        "threshold": 0.5,
        "checkpoint": "work_dirs/v1.0.6/best_mIoU_iter_195000.pth",
        "heads": {head: f"/tmp/{head}.pth" for head in heads},
        "sets": {
            "testcases": {
                head: {"accuracy": 0.8, "specificity": 0.9, "recall": 0.7}
                for head in heads
            }
        },
    }
    (diagnostics_dir / "diagnostics.json").write_text(
        json.dumps(payload), encoding="utf-8"
    )
    return diagnostics_dir


def write_scores(diagnostics_dir: Path, set_name: str, head: str) -> None:
    with (diagnostics_dir / f"{set_name}__{head}.csv").open(
        "w", newline="", encoding="utf-8"
    ) as handle:
        writer = csv.DictWriter(
            handle, fieldnames=["name", "dataset", "label", "path", "score", "pred", "correct"]
        )
        writer.writeheader()
        writer.writerows(
            [
                {
                    "name": "au_1",
                    "dataset": "authentic",
                    "label": "0",
                    "path": "/tmp/au_1.png",
                    "score": "0.2",
                    "pred": "0",
                    "correct": "1",
                },
                {
                    "name": "ca_1",
                    "dataset": "casia",
                    "label": "1",
                    "path": "/tmp/ca_1.png",
                    "score": "0.8",
                    "pred": "1",
                    "correct": "1",
                },
            ]
        )


class TestOrderedHeads(unittest.TestCase):
    def test_known_heads_follow_head_order_and_unknown_heads_go_last(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            diagnostics_dir = write_diagnostics(Path(temporary), ["det7b", "det1", "zzz_custom"])
            payload = json.loads((diagnostics_dir / "diagnostics.json").read_text())

            heads = ordered_heads(payload)

            self.assertEqual(heads, ["det1", "det7b", "zzz_custom"])

    def test_empty_heads_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            diagnostics_dir = write_diagnostics(Path(temporary), [])

            with self.assertRaises(ValueError):
                ordered_heads(
                    json.loads((diagnostics_dir / "diagnostics.json").read_text())
                )


class TestScoreMeans(unittest.TestCase):
    def test_means_are_computed_per_label_and_per_dataset(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            diagnostics_dir = write_diagnostics(Path(temporary), ["det1"])
            write_scores(diagnostics_dir, "testcases", "det1")

            result = score_means(diagnostics_dir, "testcases", "det1")

            self.assertAlmostEqual(result["authentic_mean"], 0.2)
            self.assertAlmostEqual(result["manipulated_mean"], 0.8)
            self.assertEqual(result["n_authentic"], 1)
            self.assertEqual(result["n_manipulated"], 1)
            self.assertAlmostEqual(result["dataset_mean"]["authentic"], 0.2)
            self.assertAlmostEqual(result["dataset_mean"]["casia"], 0.8)

    def test_head_order_constant_covers_every_expected_variant(self) -> None:
        self.assertEqual(len(HEAD_ORDER), 20)
        self.assertEqual(HEAD_ORDER[0], "det1")
        self.assertEqual(HEAD_ORDER[-1], "det7b")


if __name__ == "__main__":
    unittest.main()
