#!/bin/bash

echo "[Info] Starting Admin Portal..."

# ตรวจสอบและติดตั้ง dependencies หากยังไม่มี
if [ ! -d "node_modules" ]; then
    echo "[Info] Installing dependencies..."
    npm install
fi

# เริ่มการทำงานของ Vite development server
npm run dev
