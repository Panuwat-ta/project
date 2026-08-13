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

SPLICING_DIR="${BASE_DIR}/defacto-splicing"
OUT_DIR="${BASE_DIR}/defacto-splicing-prepared"

# ============================================================

echo "============================================"
echo "  Dataset Preparation for Defacto Splicing"
echo "  Splicing Dir : ${SPLICING_DIR}"
echo "  AU Dir       : ${AU_DIR}"
echo "  Out Dir      : ${OUT_DIR}"
echo "============================================"

python prepare_dataset_splicing.py \
    --splicing-dir "${SPLICING_DIR}" \
    --au-dir "${AU_DIR}" \
    --out-dir "${OUT_DIR}"

echo "============================================"
echo "  Dataset preparation complete!"
echo "============================================"
