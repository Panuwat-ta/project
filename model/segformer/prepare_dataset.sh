#!/usr/bin/env bash
# ============================================================
# prepare_dataset.sh - Script สำหรับจัดเตรียม Dataset
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${SCRIPT_DIR}"

# Activate virtual environment
source venv/bin/activate

# ============================================================
# Path Configuration
# ============================================================

BASE_DIR="/run/media/panuwat/USB/dataset"
AU_DIR="${BASE_DIR}/Authentic"

IMD_DIR="${BASE_DIR}/IMD2020"
IMD_AU_DIR="${BASE_DIR}/IMD"
OUT_DIR="${BASE_DIR}/IMD2020-prepared"

# ============================================================

echo "============================================"
echo "  Dataset Preparation for IMD2020"
echo "  IMD Dir      : ${IMD_DIR}"
echo "  AU Dir       : ${IMD_AU_DIR}"
echo "  Out Dir      : ${OUT_DIR}"
echo "============================================"

python prepare_dataset_imd2020.py \
    --imd-dir "${IMD_DIR}" \
    --au-dir "${IMD_AU_DIR}" \
    --out-dir "${OUT_DIR}"

echo "============================================"
echo "  Dataset preparation complete!"
echo "============================================"
