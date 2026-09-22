## 2026-09-22 - Admin Session/Auth Targeted Regression

- Target: `server/tests/api/test_admin_auth.py`, `test_admin_route_function_calls.py`, `test_admin_access_policy.py`, `test_admin_service_contracts.py`
- Command: targeted `pytest -q`
- Result: PASS
- Summary: Total 48 | Passed 48 | Failed 0 | Skipped 0 | Duration 0.42s

### 1. รายการที่ผ่านและพฤติกรรมที่ยืนยัน
- `/admin/sessions` query มี `revoked_at IS NULL` และ `expires_at > now`
- `resolve_admin_access()` persist `last_used_at` และ commit หลัง session validation สำเร็จ
- `get_admin_last_login_at()` หา root login timestamp โดยไม่ถือ refresh child เป็น Login ใหม่
- `/admin/me` ส่ง optional `last_login_at` โดย Login/Refresh response contract เดิมไม่ถูกขยาย
- malformed/revoked/expired/disabled auth cases เดิมยังถูกปฏิเสธตาม contract

### 2. รายการที่ไม่ผ่าน
- ไม่มีข้อผิดพลาด (0 Failed)
## 2026-09-22 - WebSocket Auth Regression

- Target: `server/tests/api/test_admin_ws.py`
- Command: targeted `pytest -q`
- Result: PASS
- Summary: Total 5 | Passed 5 | Failed 0 | Skipped 0

### พฤติกรรมที่ยืนยัน
- active Super Admin session เปิด WebSocket ได้
- invalid/revoked/expired session ถูกปฏิเสธ
- commit ownership เหลือจุดเดียวใน `resolve_admin_access()`; ไม่มี double commit

## 2026-09-22 - Full Server Regression

- Target: Server test suite ทั้งหมด
- Command: `pytest -p no:cacheprovider -q`
- Result: PASS
- Summary: Total 136 | Passed 133 | Failed 0 | Skipped 3 | Duration 13.12s

### รายการที่ไม่ผ่าน
- ไม่มีข้อผิดพลาด (0 Failed)
- Skipped 3 รายการเป็นรายการ skip เดิมของ suite
## 2026-09-22 - PostgreSQL + ASGI Runtime Integration

- Target: `/api/v1/admin/me` และ `/api/v1/admin/sessions` กับ temporary session chain ใน PostgreSQL จริง
- Result: PASS

### พฤติกรรมที่ยืนยัน
- `RUNTIME_ACTIVE_SESSION_COUNT=1`
- `RUNTIME_REVOKED_SESSION_VISIBLE=0`
- `RUNTIME_EXPIRED_SESSION_VISIBLE=0`
- `RUNTIME_LAST_USED_PERSISTED=1`
- `RUNTIME_LAST_LOGIN_ROOT_MATCH=1`
- Cleanup หลังทดสอบ: `RUNTIME_CLEANUP_SESSIONS=0`, `RUNTIME_CLEANUP_ADMIN=0`

### RED → GREEN History
- RED: session SQL ไม่มี revoked/expiry filters
- RED: `last_used_at` ถูก set แต่ `commit_count == 0`
- RED: helper `get_admin_last_login_at` ยังไม่มี
- Regression ระหว่าง fix: WebSocket expected commit=1 แต่ actual=2; ลบ duplicate commit ใน `ws.py`
- GREEN: targeted 48/48, WS 5/5, full Server 133 passed / 3 skipped / 0 failed

## 2026-09-22 09:47 +07 - PostgreSQL + ASGI Final Re-run

- Target: `/api/v1/admin/me` และ `/api/v1/admin/sessions` บน PostgreSQL จริงผ่าน ASGI transport
- Result: PASS

### 1. รายการที่ผ่านและพฤติกรรมที่ยืนยัน
- active session ที่คืนจาก API = 1
- revoked session visible = 0 และ expired session visible = 0
- `last_used_at` ถูก persist ลงฐานข้อมูลจริง
- `last_login_at` ตรงกับ root Login session ไม่เลื่อนตาม refresh child session
- cleanup temporary Admin/AdminSession หลังทดสอบ = 0/0

### 2. รายการที่ไม่ผ่าน
- ไม่มีข้อผิดพลาด (0 Failed)

## 2026-09-22 09:56 +07 - Final Server regression re-run

- Target: Admin auth/session/service/API tests + full Server suite
- Command: targeted `pytest` ชุด Admin session/auth และ full `pytest -q`
- Result: PASS
- Summary targeted: Total 53 | Passed 53 | Failed 0 | Skipped 0
- Summary full: Total 136 | Passed 133 | Failed 0 | Skipped 3 | Duration 13.05 s

### 1. รายการที่ผ่านและพฤติกรรมที่ยืนยัน
- active-session filtering, `last_used_at` persistence, `last_login_at` root-session derivation และ WebSocket auth/session paths ผ่าน
- Full Server ไม่มี regression เพิ่มจาก session-device fixes
- `git diff --check` และ staged diff check ผ่านหลัง test execution

### 2. รายการที่ไม่ผ่าน
- ไม่มีข้อผิดพลาด (0 Failed)
- มี dependency warnings เดิม 3 รายการจาก Surya/Pydantic, HuggingFace และ Starlette/httpx ซึ่งไม่ทำให้ test fail
