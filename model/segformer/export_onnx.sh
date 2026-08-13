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

# Fix for missing libbz2.so.1.0 in Fedora
export LD_LIBRARY_PATH="${SCRIPT_DIR}/venv/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# ============================================================
# Path Configuration - แก้ path ตรงนี้ได้เลย
# ============================================================

# ระบุโฟลเดอร์เวอร์ชันที่ต้องการ export ระบบจะค้นหา config และ checkpoint ล่าสุดให้อัตโนมัติ
RUN_DIR="./work_dirs/v1.0.2"

# Export resolution (dummy input สำหรับ tracing, runtime รับ size อะไรก็ได้)
HEIGHT=1024
WIDTH=1024

# ============================================================

echo "============================================"
echo "  ONNX Export (Dynamic Size)"
echo "  Run Dir   : ${RUN_DIR}"
echo "  Resolution: ${HEIGHT}x${WIDTH}"
echo "============================================"

python export_onnx_dynamic.py \
    --run-dir "${RUN_DIR}" \
    --height "${HEIGHT}" \
    --width "${WIDTH}"

echo "============================================"
echo "  Export complete!"
echo "============================================"
