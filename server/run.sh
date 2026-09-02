#!/bin/bash

# ONNX Runtime (CUDA 12) is isolated to a subprocess with its own LD_LIBRARY_PATH.
# Surya OCR (PyTorch) and Qwen2.5-1.5B (GGUF / XAI) run in the main process with GPU support.

echo "[Info] Starting ScamGuard API Server with GPU Support..."
echo "[Info] Surya OCR & Qwen2.5-1.5B (XAI) run in main process with GPU, ONNX worker uses isolated env."

# Free port 8000 if already in use by a previous instance
if command -v fuser >/dev/null 2>&1; then
    fuser -k 8000/tcp >/dev/null 2>&1
    sleep 0.5
fi

# รันเซิร์ฟเวอร์
source venv/bin/activate
export NVIDIA_LIBS=$(find "$VIRTUAL_ENV/lib/python3.10/site-packages/nvidia" -maxdepth 2 -name lib 2>/dev/null | tr '\n' ':')
export LD_LIBRARY_PATH="$VIRTUAL_ENV/lib64/python3.10/site-packages/llama_cpp_python.libs:$NVIDIA_LIBS$VIRTUAL_ENV/lib:$LD_LIBRARY_PATH"
export HF_HOME="/home/panuwat/project/model/surya"
export XAI_MODEL_PATH="/home/panuwat/project/model/Qwen2.5-1.5B/qwen2.5-1.5b-instruct-q4_k_m.gguf"
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

