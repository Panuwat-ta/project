#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEGFORMER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON="${SEGFORMER_ROOT}/venv/bin/python"

export MPLCONFIGDIR="${MPLCONFIGDIR:-/tmp/matplotlib-scamguard}"

echo "Generating SegFormer evaluation plots and reports..."
"${PYTHON}" "${SCRIPT_DIR}/report/plot_training.py" --clean
echo "SegFormer evaluation report generation completed successfully."
