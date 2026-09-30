# ผลทดสอบ Runtime Inference Hardening

## 2026-09-21 - Live scan pipeline หลัง hardening

- Target: `server/tests/api/test_scan_xai_live.py`
- Command: ไม่ได้บันทึกในผลรันเดิม
- Result: PASS
- Summary: Total: 1 | Passed: 1 | Failed: 0 | Skipped: 0 | Duration: ประมาณ 6 s
- Requirement/TC mapping: TC IDs: `TC-AI-XAI-01`, `TC-AI-XAI-02` | Requirement IDs: `FR-SYS-11`
- Commit/Build/Env: ไม่ได้บันทึกในผลรันเดิม ห้ามอนุมานย้อนหลัง

### 1. Passed Tests and Runtime Behavior (How it Passed)
- **live scan pipeline**:
  - Verification & Runtime Behavior: scan สิ้นสุดสถานะ `completed` และผลลัพธ์มี `visual_score`, `ai_gen_probability` และ `xai_explanation` ตาม assertions ของ test

### 2. Failed Tests and Root Cause (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)

## 2026-09-21 - Full server regression suite

- Target: `server/tests/`
- Command: `server/venv/bin/python -m pytest -q`
- Result: PASS
- Summary: Total: 69 | Passed: 66 | Failed: 0 | Skipped: 3 | Warnings: 3 | Duration: 11.96 s
- Requirement/TC mapping: หลาย Requirement/TC ตาม `tests_all/rtm.md`; ผลรันเดิมไม่ได้บันทึกรายการ mapping ราย test
- Commit/Build/Env: ไม่ได้บันทึกในผลรันเดิม ห้ามอนุมานย้อนหลัง

### 1. Passed Tests and Runtime Behavior (How it Passed)
- **Full server suite**:
  - Verification & Runtime Behavior: test runner จบครบ suite โดยไม่มี failed test; 66 tests ผ่านและ 3 tests ถูก skip ตามเงื่อนไขของ suite
- **Inference startup ภายใน test process**:
  - Verification & Runtime Behavior: process เริ่ม inference dependencies และ test suite ดำเนินต่อจนจบโดยไม่เกิด native process abort ในรอบนี้

### 2. Failed Tests and Root Cause (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)
