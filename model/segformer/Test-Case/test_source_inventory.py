"""Integration tests for the local Test-Case data inventory."""
from __future__ import annotations

import unittest
from pathlib import Path

from PIL import Image

from evaluation_core import discover_mask_cases, discover_qualitative_pairs


DATA_ROOT = Path("/home/panuwat/Pictures/Test-Cases")


class TestSourceInventory(unittest.TestCase):
    def test_masked_dataset_has_105_complete_pairs_in_seven_categories(self) -> None:
        cases = discover_mask_cases(DATA_ROOT / "with_mask")

        self.assertEqual(len(cases), 105)
        self.assertEqual(
            sorted({case.category for case in cases}),
            [
                "authentic",
                "casia",
                "copymove",
                "face",
                "imd2020",
                "inpainting",
                "splicing",
            ],
        )
        self.assertTrue(all(case.image_path.is_file() for case in cases))
        self.assertTrue(all(case.mask_path.is_file() for case in cases))

    def test_all_masks_are_binary_and_match_their_image_dimensions(self) -> None:
        for case in discover_mask_cases(DATA_ROOT / "with_mask"):
            with self.subTest(case_id=case.case_id):
                with Image.open(case.image_path) as image, Image.open(case.mask_path) as mask:
                    self.assertEqual(image.size, mask.size)
                    mask_values = {
                        value for _count, value in mask.convert("L").getcolors() or []
                    }
                    self.assertTrue(mask_values)
                    self.assertLessEqual(mask_values, {0, 1})

    def test_qualitative_dataset_has_30_complete_original_manipulated_pairs(self) -> None:
        pairs = discover_qualitative_pairs(DATA_ROOT / "pairs")

        self.assertEqual(len(pairs), 30)
        self.assertEqual(pairs[0].pair_id, "pair001")
        self.assertEqual(pairs[-1].pair_id, "pair030")
        self.assertTrue(all(pair.original_path.is_file() for pair in pairs))
        self.assertTrue(all(pair.manipulated_path.is_file() for pair in pairs))


if __name__ == "__main__":
    unittest.main()
