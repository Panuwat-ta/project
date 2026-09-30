"""Single seam for spawning the ONNX worker subprocess.

Both the serving path (inference_service.predict) and the admin dry-run path
cross this interface so env setup, result parsing, and timeout handling keep
locality in one place. Callers keep their own fallback/response shaping.
"""
import base64
import glob
import json
import os
import subprocess
import sys
import time
from typing import Any, Optional

from app.core.config import settings


def build_worker_env(model_path: str) -> dict:
    """Env for the worker: CUDA libs, model path, tiling geometry."""
    env = os.environ.copy()
    venv_lib_path = os.path.join(os.getcwd(), "venv/lib/python3.10/site-packages/nvidia")
    nvidia_lib_dirs = glob.glob(f"{venv_lib_path}/*/lib")
    if nvidia_lib_dirs:
        env["LD_LIBRARY_PATH"] = ":".join(nvidia_lib_dirs)
    env["ONNX_MODEL_PATH"] = model_path
    env["ONNX_TILE_SIZE"] = str(settings.ONNX_TILE_SIZE)
    env["ONNX_TILE_OVERLAP"] = str(settings.ONNX_TILE_OVERLAP)

    # Re-enable CUDA for ONNX worker
    if "CUDA_VISIBLE_DEVICES" in env and env["CUDA_VISIBLE_DEVICES"] == "":
        del env["CUDA_VISIBLE_DEVICES"]
    return env


def worker_path() -> str:
    return os.path.normpath(
        os.path.join(os.path.dirname(__file__), "..", "services", "onnx_worker.py")
    )


def run_onnx_worker(
    image_bytes: bytes,
    model_path: str,
    timeout: Optional[float] = None,
    popen_cls: Any = subprocess.Popen,
) -> dict:
    """Spawn onnx_worker.py with b64 stdin, parse last stdout line as JSON.

    timeout=None means no timeout (dry-run behavior). Always returns a dict:
    {returncode, stdout_json|None, stderr_text, latency_ms, timed_out}.
    Never raises on worker failure; raises only if the spawn itself fails.
    """
    env = build_worker_env(model_path)
    b64_image = base64.b64encode(image_bytes).decode("utf-8")

    start_time = time.time()
    process = popen_cls(
        [sys.executable, worker_path()],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
    )

    timed_out = False
    try:
        stdout, stderr = process.communicate(
            input=b64_image.encode("utf-8"),
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        process.kill()
        stdout, stderr = process.communicate()
        timed_out = True
    latency_ms = int((time.time() - start_time) * 1000)

    stdout_json = None
    stderr_text = stderr.decode("utf-8", errors="replace") if stderr else ""
    if process.returncode == 0 and not timed_out:
        stdout_text = stdout.decode("utf-8", errors="replace").strip()
        if not stdout_text:
            parse_error = "ONNX worker returned empty stdout"
            stderr_text = f"{stderr_text}\n{parse_error}".strip()
        else:
            try:
                parsed = json.loads(stdout_text.splitlines()[-1])
                if not isinstance(parsed, dict):
                    raise ValueError("ONNX worker JSON result must be an object")
                stdout_json = parsed
            except (json.JSONDecodeError, ValueError) as exc:
                parse_error = f"Invalid ONNX worker stdout: {exc}"
                stderr_text = f"{stderr_text}\n{parse_error}".strip()

    return {
        "returncode": process.returncode,
        "stdout_json": stdout_json,
        "stderr_text": stderr_text,
        "latency_ms": latency_ms,
        "timed_out": timed_out,
    }
