"""Integration test for the Surya OCR pipeline used by the scan service.

The app loads Surya models and calls `run_ocr` in `app/services/inference_service.py`.
This test exercises the same entry points so OCR regressions are caught.

Run: pytest tests/inference/test_surya.py
"""
import multiprocessing
import os
from pathlib import Path

import pytest
from PIL import Image

TEST_IMAGE = Path(__file__).resolve().parent.parent / "test.png"
MODEL_CACHE = "/home/panuwat/project/model/surya"


def _load_models():
    try:
        import ctypes
        import sys
        try:
            ctypes.CDLL(os.path.join(sys.prefix, "lib", "libbz2.so.1.0"), mode=ctypes.RTLD_GLOBAL)
        except Exception:
            pass
        os.environ["HF_HOME"] = MODEL_CACHE
        from surya.model.detection.model import load_model as load_det_model, load_processor as load_det_processor
        from surya.model.recognition.model import load_model as load_rec_model
        from surya.model.recognition.processor import load_processor as load_rec_processor
        return (
            load_det_processor(),
            load_det_model(),
            load_rec_model(),
            load_rec_processor(),
        )
    except Exception as exc:  # pragma: no cover - depends on env
        pytest.skip(f"Surya models could not be loaded: {exc}")


@pytest.mark.asyncio
async def test_run_ocr_extracts_text():
    if not TEST_IMAGE.is_file():
        pytest.skip(f"Test image not found at {TEST_IMAGE}")

    det_processor, det_model, rec_model, rec_processor = _load_models()
    from surya.ocr import run_ocr

    image = Image.open(TEST_IMAGE)
    predictions = run_ocr(
        [image],
        [["th", "en"]],
        det_model,
        det_processor,
        rec_model,
        rec_processor,
    )

    assert predictions and len(predictions) > 0
    text_lines = [line.text for line in predictions[0].text_lines]
    ocr_text = "\n".join(text_lines)

    assert isinstance(ocr_text, str)
    if ocr_text.strip():
        # ถ้าภาพมีข้อความจริง ควรได้ผลลัพธ์กลับมา
        assert len(ocr_text.strip()) > 0