# ผลการทดสอบ Backend Admin Export Pagination — 2026-09-21

## 2026-09-21 20:37 +07 - Export job pagination regression (RED ก่อนแก้)

- Target: `server/tests/api/test_admin_export.py`
- Command: `PYTHONDONTWRITEBYTECODE=1 ./venv/bin/python -m pytest -p no:cacheprovider -q tests/api/test_admin_export.py`
- Result: FAIL
- Summary: Total: 4 | Passed: 0 | Failed: 4 | Skipped: 0 | Duration: 0.15 s
- Requirement/TC mapping: `TC-ADM-EXP-01` | `FR-ADM-03` (automated supporting regression; RTM ระบุ primary TC เป็น Manual)
- Commit/Build/Env: commit `ca2a4bd0` + working tree ก่อน fix | build N/A | model N/A | env local dev/test, FastAPI in-process ASGI

### 1. รายการที่ผ่านและพฤติกรรมที่ผ่าน
- ไม่มีรายการผ่านในรอบ RED นี้ (0 Passed)

### 2. รายการที่ไม่ผ่านและสาเหตุ
- **page=0**: Expected HTTP 400 แต่ Actual HTTP 200
- **page=-1**: Expected HTTP 400 แต่ Actual HTTP 200
- **limit=0**: Expected HTTP 400 แต่ Actual HTTP 200
- **limit=101**: Expected HTTP 400 แต่ Actual HTTP 200
- Root cause ที่ test จับได้: `GET /api/v1/admin/dataset/export-jobs` ไม่มี pagination validation แบบเดียวกับ Admin list endpoints อื่น

## 2026-09-21 20:37 +07 - Export job pagination regression (GREEN หลังแก้)

- Target: `server/tests/api/test_admin_export.py`
- Command: `PYTHONDONTWRITEBYTECODE=1 ./venv/bin/python -m pytest -p no:cacheprovider -q tests/api/test_admin_export.py`
- Result: PASS
- Summary: Total: 4 | Passed: 4 | Failed: 0 | Skipped: 0 | Duration: 0.11 s
- Requirement/TC mapping: `TC-ADM-EXP-01` | `FR-ADM-03`
- Commit/Build/Env: commit `ca2a4bd0` + working tree หลัง fix | build N/A | model N/A | env local dev/test, FastAPI in-process ASGI

### 1. รายการที่ผ่านและพฤติกรรมที่ผ่าน
- `page=0` และ `page=-1` ถูกปฏิเสธด้วย HTTP 400 และ `detail="page must be >= 1"`
- `limit=0` และ `limit=101` ถูกปฏิเสธด้วย HTTP 400 และ `detail="limit must be between 1 and 100"`
- Assertions ยืนยันทั้ง status code และ response detail ตรงตาม contract ที่ตั้งไว้

### 2. รายการที่ไม่ผ่านและสาเหตุ
- ไม่มีข้อผิดพลาด (0 Failed)

## 2026-09-21 20:37 +07 - Backend Admin targeted regression

- Target: Admin auth/report/WebSocket/export/access-policy/search suites
- Command: `PYTHONDONTWRITEBYTECODE=1 ./venv/bin/python -m pytest -p no:cacheprovider -q tests/api/test_admin_auth.py tests/api/test_admin_reports.py tests/api/test_admin_ws.py tests/api/test_admin_export.py tests/utils/test_admin_access_policy.py tests/utils/test_admin_service_search.py`
- Result: PASS
- Summary: Total: 27 | Passed: 27 | Failed: 0 | Skipped: 0 | Duration: 0.23 s
- Requirement/TC mapping: `FR-ADM-01/02/03`, `NFR-SEC-03` และ TCs ที่ map อยู่ใน `tests_all/rtm.md`
- Commit/Build/Env: commit `ca2a4bd0` + working tree หลัง fix | build N/A | model N/A | env local dev/test

### 1. รายการที่ผ่านและพฤติกรรมที่ผ่าน
- Admin authentication/session/RBAC, report detail contract, WebSocket policy, export pagination, shared admin access policy และ global search ผ่านทั้งหมด
- Regression ใหม่ไม่ทำให้ auth/session และ report/WebSocket behavior เดิมเปลี่ยน

### 2. รายการที่ไม่ผ่านและสาเหตุ
- ไม่มีข้อผิดพลาด (0 Failed)
- มี dependency warnings 3 รายการจาก Surya/Pydantic, Hugging Face และ Starlette TestClient/httpx; ไม่มี assertion failure

## 2026-09-21 20:37 +07 - Server full regression

- Target: `server/tests/` ทั้งชุด
- Command: `PYTHONDONTWRITEBYTECODE=1 timeout 300s ./venv/bin/python -m pytest -p no:cacheprovider -q`
- Result: PASS
- Summary: Total executed: 88 | Passed: 85 | Failed: 0 | Skipped: 3 | Duration: 14.23 s
- Requirement/TC mapping: full server regression ตาม mappings ปัจจุบันใน `tests_all/rtm.md`
- Commit/Build/Env: commit `ca2a4bd0` + working tree หลัง fix | build N/A | model runtime guard เดิม | env local dev/test

### 1. รายการที่ผ่านและพฤติกรรมที่ผ่าน
- ทั้ง Server suite ผ่าน 85 tests โดยไม่มี regression จาก pagination validation ใหม่
- ระหว่าง startup XAI GPU guard ตรวจพบ GPU 4096 MiB และเลือก deterministic fallback; Surya OCR models โหลดบน CUDA ได้ตาม log ของ test process
- Admin export regression รวมอยู่ใน full suite และยังผ่านหลังรวมกับ tests อื่น

### 2. รายการที่ไม่ผ่านและสาเหตุ
- ไม่มีข้อผิดพลาด (0 Failed)
- Skipped: 3 tests ตามเงื่อนไขเดิมของ suite
- Warnings: 3 dependency deprecation/future warnings เดิม ไม่มีผลต่อ verdict
