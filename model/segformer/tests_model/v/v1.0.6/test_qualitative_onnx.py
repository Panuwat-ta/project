#!/usr/bin/env python3
"""Run the v1.0.6 qualitative ONNX example."""
from pathlib import Path
import sys

REPORT_ROOT = Path(__file__).resolve().parents[2] / "report"
sys.path.insert(0, str(REPORT_ROOT))

from plot_training import render_qualitative_onnx_version  # noqa: E402


if __name__ == "__main__":
    for output in render_qualitative_onnx_version("v1.0.6"):
        print(output)
