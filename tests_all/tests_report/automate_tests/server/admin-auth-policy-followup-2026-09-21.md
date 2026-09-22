# ผลทดสอบ Shared Admin Authentication Policy Follow-up

## 2026-09-21 19:16 +07 - Admin auth policy targeted regression

- Target: `server/tests/utils/test_admin_access_policy.py`, `server/tests/api/test_admin_ws.py`, `server/tests/api/test_admin_auth.py`
- Command: `PYTHONDONTWRITEBYTECODE=1 timeout 240s ./venv/bin/python -m pytest -p no:cacheprovider tests/utils/test_admin_access_policy.py tests/api/test_admin_ws.py tests/api/test_admin_auth.py -q`
- Result: PASS
- Summary: Total: 20 | Passed: 20 | Failed: 0 | Skipped: 0 | Warnings: 3 | Duration: 0.18 s
- Requirement/TC mapping: TC IDs: `TC-ADM-AUTH-03`, `TC-ADM-WS-01` | Requirement IDs: `FR-ADM-01`
- Commit/Build/Env: commit `d9ee7cb8` + working-tree changes | build N/A (pytest) | env `dev`; pytest in-process

### 1. Passed Tests and Runtime Behavior (How it Passed)
- **shared admin access policy**:
  - Verification & Runtime Behavior: valid active session ผ่าน; malformed subject, wrong role, revoked/expired session และ invalid ownership ถูกปฏิเสธตาม policy
- **HTTP dependency mapping**:
  - Verification & Runtime Behavior: malformed `sub` map เป็น HTTP 401 และ inactive Admin map เป็น HTTP 403 โดยคงข้อความ contract เดิม
- **WebSocket authorization**:
  - Verification & Runtime Behavior: active Super Admin เชื่อมต่อได้ ส่วน revoked/expired/non-Super Admin และ legacy query-token ถูกปฏิเสธด้วย close code 1008

### 2. Failed Tests and Root Cause (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)

## 2026-09-21 19:16 +07 - Full server regression หลังรวม auth policy

- Target: `server/tests/`
- Command: `PYTHONDONTWRITEBYTECODE=1 timeout 300s ./venv/bin/python -m pytest -p no:cacheprovider -q`
- Result: PASS
- Summary: Total: 84 | Passed: 81 | Failed: 0 | Skipped: 3 | Warnings: 3 | Duration: 12.27 s
- Requirement/TC mapping: หลาย Requirement/TC ตาม `tests_all/rtm.md`; gate นี้เป็น full regression ไม่ใช่ TC เดี่ยว
- Commit/Build/Env: commit `d9ee7cb8` + working-tree changes | build N/A (pytest) | model runtime: XAI GPU deferred by preflight, Surya CUDA loaded | env `dev`

### 1. Passed Tests and Runtime Behavior (How it Passed)
- **Full server regression**:
  - Verification & Runtime Behavior: pytest จบครบ suite โดยไม่มี failed test; shared auth policy ไม่ทำให้ API, WebSocket, scan หรือ inference tests ถดถอย
- **Inference startup**:
  - Verification & Runtime Behavior: XAI GPU guard เลือก deterministic fallback บน visible GPU 4096 MiB และ Surya models โหลดบน CUDA ได้จน suite จบ

### 2. Failed Tests and Root Cause (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)
