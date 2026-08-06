#!/bin/bash

# ONNX Runtime (CUDA 12) is isolated to a subprocess with its own LD_LIBRARY_PATH.
# LLaMA-cpp (CUDA 13.3) runs in the main process using system libraries.

# กำหนด Path ให้ระบบเจอ CUDA 13.3 ของ LLaMA-cpp
export PATH="/usr/local/cuda-13.3/bin:$PATH"

echo "[Info] Starting ScamGuard API Server with GPU Support..."
echo "[Info] LLaMA runs on system CUDA, ONNX worker uses local CUDA 12 env."

# รันเซิร์ฟเวอร์
source venv/bin/activate
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
