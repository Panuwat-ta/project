"""Fast tests for the per-version Det-Head packaging pipeline."""
from __future__ import annotations

import csv
import json
import tempfile
import unittest
from pathlib import Path

from plot_det_per_version import (
    HEAD_ORDER_ALL,
    SETS,
    build_all,
    locate_sources,
    ordered_all,
)


def write_run(root: Path, name: str, heads: list[str]) -> Path:
    run_dir = root / name
    run_dir.mkdir(parents=True, exist_ok=True)
    payload = {
        "threshold": 0.5,
        "checkpoint": "work_dirs/v1.0.6/best_mIoU_iter_195000.pth",
        "heads": {head: f"/tmp/{head}.pth" for head in heads},
        "sets": {
            set_name: {
                head: {
                    "n": 2,
                    "accuracy": 0.8,
                    "specificity": 0.9,
                    "recall": 0.7,
                    "by_dataset": {} if set_name != "testcases" else {
                        "authentic": {"accuracy": 1.0},
                        "casia": {"accuracy": 0.6},
                    },
                }
                for head in heads
            }
            for set_name in SETS
        },
    }
    (run_dir / "diagnostics.json").write_text(
        json.dumps(payload), encoding="utf-8"
    )
    for head in heads:
        for set_name in SETS:
            with (run_dir / f"{set_name}__{head}.csv").open(
                "w", newline="", encoding="utf-8"
            ) as handle:
                writer = csv.DictWriter(
                    handle,
                    fieldnames=["name", "dataset", "label", "path",
                                "score", "pred", "correct"],
                )
                writer.writeheader()
                writer.writerows(
                    [
                        {"name": "au_1", "dataset": "authentic", "label": "0",
                         "path": "/tmp/au_1.png", "score": "0.2",
                         "pred": "0", "correct": "1"},
                        {"name": "ca_1", "dataset": "casia", "label": "1",
                         "path": "/tmp/ca_1.png", "score": "0.8",
                         "pred": "1", "correct": "1"},
                    ]
                )
    return run_dir


class TestLocateSources(unittest.TestCase):
    def test_two_runs_merge_without_overlap(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            run_a = write_run(root, "run_a", ["det1", "det2a"])
            run_b = write_run(root, "run_b", ["det5a_seed7"])

            sources = locate_sources([run_a, run_b])

            self.assertEqual(
                sorted(sources),
                ["det1", "det2a", "det5a_seed7"],
            )
            self.assertEqual(sources["det1"]["run_dir"], run_a)
            self.assertEqual(sources["det5a_seed7"]["run_dir"], run_b)

    def test_duplicate_head_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            run_a = write_run(root, "run_a", ["det1"])
            run_b = write_run(root, "run_b", ["det1"])

            with self.assertRaises(ValueError):
                locate_sources([run_a, run_b])

    def test_empty_runs_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            run_dir = root / "empty"
            run_dir.mkdir()
            (run_dir / "diagnostics.json").write_text(
                json.dumps({"heads": {}, "sets": {}}), encoding="utf-8"
            )

            with self.assertRaises(ValueError):
                locate_sources([run_dir])


class TestOrderedAll(unittest.TestCase):
    def test_main_heads_first_then_seeds_then_unknown(self) -> None:
        sources = {head: {} for head in
                   ["zzz_custom", "det7b_seed7", "det7b", "det1"]}

        self.assertEqual(
            ordered_all(sources),
            ["det1", "det7b", "det7b_seed7", "zzz_custom"],
        )

    def test_order_constant_covers_all_26_versions(self) -> None:
        self.assertEqual(len(HEAD_ORDER_ALL), 26)
        self.assertEqual(HEAD_ORDER_ALL[0], "det1")
        self.assertEqual(HEAD_ORDER_ALL[19], "det7b")
        self.assertEqual(HEAD_ORDER_ALL[-6:], (
            "det5a_seed123", "det5a_seed7",
            "det7a_seed123", "det7a_seed7",
            "det7b_seed123", "det7b_seed7",
        ))


class TestBuildAll(unittest.TestCase):
    def test_each_version_gets_csvs_summary_and_chart(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            run_a = write_run(root, "run_a", ["det1"])
            run_b = write_run(root, "run_b", ["det7b_seed7"])
            out_root = root / "per_version"

            heads = build_all([run_a, run_b], out_root)

            self.assertEqual(heads, ["det1", "det7b_seed7"])
            for head in heads:
                version_dir = out_root / head
                for set_name in SETS:
                    self.assertTrue(
                        (version_dir / f"{set_name}__{head}.csv").is_file()
                    )
                summary = json.loads(
                    (version_dir / "summary.json").read_text(encoding="utf-8")
                )
                self.assertEqual(summary["head"], head)
                self.assertEqual(summary["weight_path"], f"/tmp/{head}.pth")
                self.assertAlmostEqual(
                    summary["sets"]["testcases"]["accuracy"], 0.8
                )
                chart = version_dir / f"{head}_scores.png"
                self.assertTrue(chart.is_file())
                self.assertGreater(chart.stat().st_size, 0)
            index = json.loads(
                (out_root / "index.json").read_text(encoding="utf-8")
            )
            self.assertEqual(sorted(index["versions"]), ["det1", "det7b_seed7"])


if __name__ == "__main__":
    unittest.main()
