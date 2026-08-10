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

BASE_DIR="/home/panuwat/project/model/segformer/dataset"
AU_DIR="${BASE_DIR}/Authentic"

TP_DIR="${BASE_DIR}/defacto-inpainting/inpainting_img/img"
MASK1_DIR="${BASE_DIR}/defacto-inpainting/inpainting_annotations/inpaint_mask"
MASK2_DIR="${BASE_DIR}/defacto-inpainting/inpainting_annotations/probe_mask"
OUT_DIR="${BASE_DIR}/defacto-inpainting"

# ============================================================

echo "============================================"
echo "  Dataset Preparation"
echo "  TP Dir  : ${TP_DIR}"
echo "  Mask1   : ${MASK1_DIR}"
echo "  Mask2   : ${MASK2_DIR}"
echo "  AU Dir  : ${AU_DIR}"
echo "  Out Dir : ${OUT_DIR}"
echo "============================================"

python prepare_dataset1.py \
    --base-dir "${BASE_DIR}" \
    --tp-dir "${TP_DIR}" \
    --mask1-dir "${MASK1_DIR}" \
    --mask2-dir "${MASK2_DIR}" \
    --au-dir "${AU_DIR}" \
    --out-dir "${OUT_DIR}"

echo "============================================"
echo "  Dataset preparation complete!"
echo "============================================"
