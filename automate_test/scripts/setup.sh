#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# สร้าง venv ถ้ายังไม่มี
if [ ! -d venv ]; then
  echo "[setup] creating venv..."
  python3 -m venv venv
fi
source venv/bin/activate
pip install -q -r requirements.txt 2>&1 | tail -n 5
# ถ้ารันแบบ ASGI ต้องมี deps ของ server ด้วย
if [ -f ../server/requirements.txt ]; then
  echo "[setup] installing server deps (for ASGI mode)..."
  pip install -q -r ../server/requirements.txt 2>&1 | tail -n 5 || true
fi
# link รูปทดสอบ
if [ ! -e fixtures/images/test1.jpg ] && [ -d ../server/tests/test_img ]; then
  ln -sfn ../../server/tests/test_img/* fixtures/images/ 2>/dev/null || cp -r ../server/tests/test_img/* fixtures/images/ 2>/dev/null || true
fi
mkdir -p reports/html reports/coverage
cp -n .env.example .env 2>/dev/null || true
echo "[setup] done. venv=./venv  env=.env"
