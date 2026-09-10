#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

source venv/bin/activate

# ==========================================
# กรุณาแก้ไขตัวแปรด้านล่างนี้ตามที่คุณต้องการ
# ==========================================

# 1. ไฟล์คอนฟิก (ต้องตรงกับ checkpoint: v1.0.0 ใช้ v2)
CONFIG="configs/segformer_mit-b2-v2.py"

# 2. ไฟล์โมเดลที่เทรนเสร็จแล้ว (ต้องมีอยู่จริงใน work_dirs)
CHECKPOINT="work_dirs/v1.0.0/best_mIoU_iter_112000.pth"

# 3. ภาพที่ต้องการตรวจสอบ (มีตัวอย่างใน tests_model/img/)
IMAGE="tests_model/img/test.jpg"

# 4. ชื่อไฟล์ผลลัพธ์
OUTPUT="result_scam.jpg"

# ==========================================

echo "========================================"
echo "  SegFormer Inference Test"
echo "  Config    : ${CONFIG}"
echo "  Checkpoint: ${CHECKPOINT}"
echo "  Input     : ${IMAGE}"
echo "  Output    : ${OUTPUT}"
echo "========================================"

python predict_test.py \
    --config "${CONFIG}" \
    --checkpoint "${CHECKPOINT}" \
    --image "${IMAGE}" \
    --output "${OUTPUT}"

echo "========================================"
echo "  Inference Done!"
echo "========================================"
