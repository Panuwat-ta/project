#!/usr/bin/env bash
# ============================================================
# export.sh - Export SegFormer checkpoint to ONNX (dynamic size)
# แก้ path ด้านล่างนี้ก่อนรัน
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${SCRIPT_DIR}"

# Activate virtual environment
source venv/bin/activate

# ============================================================
# Path Configuration - แก้ path ตรงนี้ได้เลย
# ============================================================

CONFIG="./work_dirs/v1.0.0/segformer_mit-b2-v2.py"
CHECKPOINT="./work_dirs/v1.0.0/best_mIoU_iter_112000.pth"
OUTPUT="./work_dirs/v1.0.0/segformer_v1_dynamic.onnx"

# Export resolution (dummy input สำหรับ tracing, runtime รับ size อะไรก็ได้)
HEIGHT=1024
WIDTH=1024

# ============================================================

echo "============================================"
echo "  ONNX Export (Dynamic Size)"
echo "  Config    : ${CONFIG}"
echo "  Checkpoint: ${CHECKPOINT}"
echo "  Output    : ${OUTPUT}"
echo "  Resolution: ${HEIGHT}x${WIDTH}"
echo "============================================"

python export_onnx_dynamic.py \
    --config "${CONFIG}" \
    --checkpoint "${CHECKPOINT}" \
    --output "${OUTPUT}" \
    --height "${HEIGHT}" \
    --width "${WIDTH}"

echo "============================================"
echo "  Export complete: ${OUTPUT}"
echo "============================================"
