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

FACE_DIR="${BASE_DIR}/defacto-face"
OUT_DIR="${BASE_DIR}/defacto-face-prepared"

# ============================================================

echo "============================================"
echo "  Dataset Preparation for Defacto Face"
echo "  Face Dir     : ${FACE_DIR}"
echo "  AU Dir       : ${AU_DIR}"
echo "  Out Dir      : ${OUT_DIR}"
echo "============================================"

python prepare_dataset_face.py \
    --face-dir "${FACE_DIR}" \
    --au-dir "${AU_DIR}" \
    --out-dir "${OUT_DIR}"

echo "============================================"
echo "  Dataset preparation complete!"
echo "============================================"
