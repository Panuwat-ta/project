#!/bin/bash

# ย้ายเข้าไปที่โฟลเดอร์ server หลักเสมอ ไม่ว่าจะรันสคริปต์นี้จากที่ไหน
cd "$(dirname "$0")/.."

# เปิดใช้งาน venv ที่อยู่ในโฟลเดอร์ server
source venv/bin/activate

# รันโค้ดด้วย python ของ venv
python scripts/create_admin.py admin@gmail.local password123 "System Admin"