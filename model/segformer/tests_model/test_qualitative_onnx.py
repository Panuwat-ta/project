#!/usr/bin/env python3
"""Run the qualitative ONNX example for one registered model version.

Usage:
    test_qualitative_onnx.py v1.0.6
"""
from pathlib import Path
import sys

REPORT_ROOT = Path(__file__).resolve().parent / "report"
sys.path.insert(0, str(REPORT_ROOT))

from plot_training import render_qualitative_onnx_version  # noqa: E402


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: test_qualitative_onnx.py <version> (e.g. v1.0.6)")
    for output in render_qualitative_onnx_version(sys.argv[1]):
        print(output)
