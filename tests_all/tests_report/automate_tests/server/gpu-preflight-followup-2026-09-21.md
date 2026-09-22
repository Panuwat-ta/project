# ผลทดสอบ Server GPU Preflight Follow-up

## 2026-09-21 18:06 +07 - XAI GPU safety preflight

- Target: `server/tests/utils/test_gpu_safety.py`
- Command: `PYTHONDONTWRITEBYTECODE=1 ./venv/bin/python -m pytest -p no:cacheprovider tests/utils/test_gpu_safety.py -q`
- Result: PASS
- Summary: Total: 7 | Passed: 7 | Failed: 0 | Skipped: 0 | Duration: 0.04 s
- Requirement/TC mapping: TC IDs: `TC-AI-XAI-02` | Requirement IDs: `FR-SYS-11`
- Commit/Build/Env: ไม่ได้บันทึก metadata ครบในผลรันเดิม; ห้ามอนุมานย้อนหลัง

### 1. Passed Tests and Runtime Behavior (How it Passed)
- **unsafe capacity/telemetry cases**:
  - Verification & Runtime Behavior: GPU 4096 MiB, free VRAM ต่ำกว่า 1500 MiB และ telemetry ที่ใช้ไม่ได้เลือก deterministic fallback
- **multi-GPU safety**:
  - Verification & Runtime Behavior: ถ้า GPU ใด GPU หนึ่งไม่ปลอดภัย preflight จะ defer GPU XAI แทนการปล่อย fail-open
- **verified headroom / explicit CPU mode**:
  - Verification & Runtime Behavior: GPU 8192/4000 MiB ผ่าน guard และ `XAI_GPU_LAYERS=0` ข้าม GPU probe ตาม contract
- **nvidia-smi parser**:
  - Verification & Runtime Behavior: parse memory ของทุก visible GPU และ reject output ว่าง/ไม่ใช่ตัวเลข/ค่า free VRAM ที่ใช้ไม่ได้

### 2. Failed Tests and Root Cause (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)

## 2026-09-21 19:06 +07 - Full server regression หลัง GPU preflight follow-up

- Target: `server/tests/`
- Command: `PYTHONDONTWRITEBYTECODE=1 timeout 300s ./venv/bin/python -m pytest -p no:cacheprovider -q`
- Result: PASS
- Summary: Total: 75 | Passed: 72 | Failed: 0 | Skipped: 3 | Warnings: 3 | Duration: 15.51 s
- Requirement/TC mapping: หลาย Requirement/TC ตาม `tests_all/rtm.md`; gate นี้เป็น full regression ไม่ใช่ TC เดี่ยว
- Commit/Build/Env: commit `d9ee7cb8` + working-tree changes | build N/A (pytest) | model runtime: XAI GPU deferred by preflight, Surya CUDA loaded | env `dev`; pytest in-process ไม่เปิด service port ใหม่

### 1. Passed Tests and Runtime Behavior (How it Passed)
- **Full server regression**:
  - Verification & Runtime Behavior: pytest จบครบ suite โดยไม่มี failed test; startup ระบุ `Deferring GPU XAI model to deterministic fallback` สำหรับ visible GPU 4096 MiB และ suite ดำเนินต่อจนจบ
- **Inference dependencies**:
  - Verification & Runtime Behavior: Surya detection/recognition โหลดบน CUDA และไม่มี native abort ระหว่างรอบ regression นี้

### 2. Failed Tests and Root Cause (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)
