#!/bin/bash

# ย้ายเข้าไปที่โฟลเดอร์ server หลักเสมอ ไม่ว่าจะรันสคริปต์นี้จากที่ไหน
cd "$(dirname "$0")/.."

# เปิดใช้งาน venv ที่อยู่ในโฟลเดอร์ server
source venv/bin/activate

# โหลดค่า Environment Variables จาก .env.local หรือ .env
if [ -f .env.local ]; then
    set -a
    source .env.local
    set +a
elif [ -f .env ]; then
    set -a
    source .env
    set +a
fi

ADMIN_EMAIL="${1:-$EMAIL}"
ADMIN_PASSWORD="${2:-$PASSWORD}"
ADMIN_FULL_NAME="${3:-${ADMIN_NAME:-"System Admin"}}"

if [ -z "$ADMIN_EMAIL" ] || [ -z "$ADMIN_PASSWORD" ]; then
    echo "Error: EMAIL and PASSWORD must be provided via arguments or .env/.env.local file"
    echo "Usage: ./scripts/admin.sh [email] [password] [full_name]"
    exit 1
fi

# รันโค้ดด้วย python ของ venv
python scripts/create_admin.py "$ADMIN_EMAIL" "$ADMIN_PASSWORD" "$ADMIN_FULL_NAME"