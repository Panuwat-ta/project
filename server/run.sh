#!/bin/bash

# ONNX Runtime (CUDA 12) is isolated to a subprocess with its own LD_LIBRARY_PATH.
# Surya OCR (PyTorch) runs in the main process.

echo "[Info] Starting ScamGuard API Server with GPU Support..."
echo "[Info] Surya OCR runs in main process, ONNX worker uses isolated env."

# รันเซิร์ฟเวอร์
source venv/bin/activate
export LD_LIBRARY_PATH="$VIRTUAL_ENV/lib:$LD_LIBRARY_PATH"
export HF_HOME="/home/panuwat/project/model/surya"
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
