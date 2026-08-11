#!/usr/bin/env bash
# ============================================================
# train.sh - SegFormer MiT-B2 Training Script
# Usage:
#   ./train.sh                        # fine-tune จาก LOAD_FROM ด้านล่าง
#   ./train.sh --load-from <path>     # override LOAD_FROM ด้วย path ที่ระบุ
#   ./train.sh --no-load              # train ใหม่ตั้งแต่ต้น ไม่โหลด checkpoint
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/configs/segformer_mit-b2-v6.py"
WORK_DIR_BASE="${SCRIPT_DIR}/work_dirs"

# ============================================================
# Auto-versioning: หา version ล่าสุดใน work_dirs แล้วเพิ่ม patch
# ============================================================
get_next_version() {
    local major=1 minor=0 patch=0

    if [ -d "${WORK_DIR_BASE}" ]; then
        local latest
        latest=$(ls -d "${WORK_DIR_BASE}"/v[0-9]*.[0-9]*.[0-9]* 2>/dev/null \
            | sort -t. -k1,1V -k2,2n -k3,3n \
            | tail -n 1)

        if [ -n "${latest}" ]; then
            local ver
            ver=$(basename "${latest}") 
            major=$(echo "${ver}" | cut -d. -f1 | tr -d 'v')
            minor=$(echo "${ver}" | cut -d. -f2)
            patch=$(echo "${ver}" | cut -d. -f3)

            patch=$((patch + 1))
            if [ "${patch}" -ge 10 ]; then
                patch=0
                minor=$((minor + 1))
            fi
            if [ "${minor}" -ge 10 ]; then
                minor=0
                major=$((major + 1))
            fi
        fi
    fi

    echo "v${major}.${minor}.${patch}"
}

VERSION=$(get_next_version)
WORK_DIR="${WORK_DIR_BASE}/${VERSION}"

echo "============================================"
echo "  SegFormer Training"
echo "  Config  : ${CONFIG}"
echo "  Work Dir: ${WORK_DIR}"
echo "============================================"

mkdir -p "${WORK_DIR}"

# ============================================================
# Load From - แก้ path ด้านล่างนี้ก่อนรัน หรือส่ง --load-from ผ่าน CLI
# ตั้งค่าเป็น "" เพื่อ train ใหม่ตั้งแต่ต้น
# ============================================================
LOAD_FROM=""

# ============================================================
# Build extra args
# ============================================================
EXTRA_ARGS=()

# รับ argument จาก CLI (override ค่า LOAD_FROM ด้านบน)
while [[ $# -gt 0 ]]; do
    case "$1" in
        --load-from)
            if [ -z "${2:-}" ]; then
                echo "Error: --load-from requires a path argument."
                exit 1
            fi
            LOAD_FROM="$2"
            shift 2
            ;;
        --no-load)
            LOAD_FROM=""
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: ./train.sh [--load-from <path>] [--no-load]"
            exit 1
            ;;
    esac
done

# ตรวจสอบ LOAD_FROM ว่าไฟล์มีอยู่จริง
if [ -n "${LOAD_FROM}" ]; then
    if [ ! -f "${LOAD_FROM}" ]; then
        echo "Error: checkpoint file not found: ${LOAD_FROM}"
        echo "แก้ LOAD_FROM ใน train.sh หรือใช้ --no-load เพื่อ train ใหม่"
        exit 1
    fi
    EXTRA_ARGS+=(--cfg-options "load_from=${LOAD_FROM}")
    echo "  Load From: ${LOAD_FROM}"
else
    echo "  Load From: (none - training from scratch)"
fi

# ============================================================
# Run training
# ============================================================
cd "${SCRIPT_DIR}"

# Activate virtual environment
source venv/bin/activate

python library/mmsegmentation/tools/train.py \
    "${CONFIG}" \
    --work-dir "${WORK_DIR}" \
    "${EXTRA_ARGS[@]}"

echo "============================================"
echo "  Training complete: ${WORK_DIR}"
echo "============================================"
