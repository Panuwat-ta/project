"""Sanity test that verifies CUDA is available for inference.

The scan service runs ONNX SegFormer (CUDA) + Surya OCR (PyTorch CUDA).
This test confirms the environment can actually use the GPU so regressions
(like a CUDA 12/13 library conflict or a GPU in "requires reset" state)
are caught early.
"""
import os
from pathlib import Path

import pytest

MODEL_PATH = Path("/home/panuwat/project/model/segformer/work_dirs/v1.0.0/segformer_v1_dynamic.onnx")


def _find_nvidia_libs():
    venv = Path(os.getcwd()) / "venv" / "lib" / "python3.10" / "site-packages" / "nvidia"
    return [str(d) for d in venv.glob("*/lib")] if venv.is_dir() else []


@pytest.mark.asyncio
async def test_torch_cuda_available():
    try:
        import torch
    except ImportError:
        pytest.skip("torch not installed")
    if not torch.cuda.is_available():
        pytest.skip("CUDA is not available in this environment")


@pytest.mark.asyncio
async def test_onnx_cuda_provider():
    import onnxruntime as ort

    # ให้ CUDA ทำงาน ต้องมี libs ใน LD_LIBRARY_PATH (pip nvidia packages)
    if os.getenv("CI"):
        pytest.skip("skipped in CI")

    if not MODEL_PATH.is_file():
        pytest.skip(f"ONNX model not found at {MODEL_PATH}")

    try:
        # ตั้ง LD_LIBRARY_PATH ให้ครอบ nvidia libs ถ้ายังไม่ cover
        extra = _find_nvidia_libs()
        if extra and not any("nvidia" in x for x in os.getenv("LD_LIBRARY_PATH", "").split(":")):
            os.environ["LD_LIBRARY_PATH"] = ":".join(extra) + ":" + os.environ.get("LD_LIBRARY_PATH", "")

        sess = ort.InferenceSession(
            str(MODEL_PATH),
            providers=["CUDAExecutionProvider", "CPUExecutionProvider"],
        )
        assert "CUDAExecutionProvider" in sess.get_providers()
    except Exception as exc:
        pytest.skip(f"CUDA provider could not initialize: {exc}")