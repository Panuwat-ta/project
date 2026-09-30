# ผลทดสอบ Server Final Regression หลัง Admin Full-Page Debug

## 2026-09-21 21:55 +07 - Full server regression

- Target: `server/tests/`
- Command: `PYTHONDONTWRITEBYTECODE=1 ./venv/bin/python -m pytest -p no:cacheprovider -q`
- Result: PASS
- Summary: Total: 88 | Passed: 85 | Failed: 0 | Skipped: 3 | Duration: 11.98 s
- Requirement/TC mapping: regression ครอบคลุม backend requirements รวม Admin API/RBAC/WebSocket/Export ตาม RTM; ไม่ใช่การเพิ่ม coverage claim ใหม่
- Commit/Build/Env: commit `ca2a4bd0` + uncommitted working tree | env `dev` | Python 3.10 venv | local PostgreSQL/AI runtime

### 1. Passed Tests and Runtime Behavior (How it Passed)
- Admin API, auth policy, WebSocket security และ export pagination regression ผ่าน
- Full scan/inference suite ผ่านโดย GPU 4 GiB ใช้ deterministic XAI fallback ตาม guard ที่มีอยู่
- ไม่มี backend regression จาก Admin frontend fixes รอบนี้

### 2. Failed Tests and Root Cause (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)

### 3. Skipped / Warnings
- Skipped: 3 tests ตามเงื่อนไข suite เดิม
- Warnings: Surya Pydantic config deprecation, Hugging Face `resume_download` deprecation และ Starlette TestClient/httpx deprecation
- warnings เหล่านี้ไม่ทำให้ test fail และไม่มี warning ใหม่จาก Admin patch รอบนี้
