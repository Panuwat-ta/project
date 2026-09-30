# ผลการทดสอบ Admin Debug Regression — 2026-09-21

## 2026-09-21 20:37 +07 - Admin workflow regression (RED ก่อนแก้)

- Target: `admin-portal/tests/admin-workflow-regressions.test.mjs`
- Command: `node --test tests/admin-workflow-regressions.test.mjs`
- Result: FAIL
- Summary: Total: 6 | Passed: 0 | Failed: 6 | Skipped: 0 | Duration: 263.317737 ms
- Requirement/TC mapping: `TC-ADM-MOD-01/02`, `TC-ADM-USR-01`, `TC-ADM-REP-01/02`, `TC-ADM-EXP-01`, `TC-ADM-SRCH-01`, `TC-ADM-PAGE-01` | `FR-ADM-02/03/04/05`
- Commit/Build/Env: commit `ca2a4bd0` + working tree ก่อน fix | build N/A | model N/A | env local dev/test, Vite middleware test harness

### 1. รายการที่ผ่านและพฤติกรรมที่ผ่าน
- ไม่มีรายการผ่านในรอบ RED นี้ (0 Passed)

### 2. รายการที่ไม่ผ่านและสาเหตุ
- **successful model deploy bypasses the guarded user-close path**: success path ยังเรียก `closeDeployModal()` ขณะ `isDeploying=true` แทน reset path ที่ไม่ถูก guard
- **successful user status update bypasses the guarded user-close path**: success path ยังเรียก `closeStatusModal()` ขณะ `isSubmitting=true`
- **successful report decision bypasses the guarded user-close path**: success path ยังเรียก `closeDecisionModal()` ขณะ `isSubmittingDecision=true`
- **export download goes through authenticated API request**: `downloadExportJob` ยังไม่มี ทำให้ protected download ไม่ผ่าน unified authenticated request
- **dataset export UI does not navigate directly to protected download URL**: UI ยังใช้ direct URL / `<a href>` สำหรับ endpoint ที่ต้อง Bearer auth
- **clear-all reports filter resets status, category, page, and search**: ปุ่มล้างทั้งหมดไม่ได้ reset `category` เป็น `All`

## 2026-09-21 20:37 +07 - Admin workflow regression (GREEN หลังแก้)

- Target: `admin-portal/tests/admin-workflow-regressions.test.mjs`
- Command: `node --test tests/admin-workflow-regressions.test.mjs`
- Result: PASS
- Summary: Total: 6 | Passed: 6 | Failed: 0 | Skipped: 0 | Duration: 255.763238 ms
- Requirement/TC mapping: `TC-ADM-MOD-01/02`, `TC-ADM-USR-01`, `TC-ADM-REP-01/02`, `TC-ADM-EXP-01`, `TC-ADM-SRCH-01`, `TC-ADM-PAGE-01` | `FR-ADM-02/03/04/05`
- Commit/Build/Env: commit `ca2a4bd0` + working tree หลัง fix | build N/A | model N/A | env local dev/test, Vite middleware test harness

### 1. รายการที่ผ่านและพฤติกรรมที่ผ่าน
- **Model/User/Report modal workflow 3 เคส**: success path ใช้ unguarded reset function โดยตรง ขณะที่ user-triggered close ยังถูกป้องกันระหว่าง submit
- **Authenticated export download 2 เคส**: API helper เรียก protected endpoint ผ่าน `apiRequest` และ assertion ยืนยัน `Authorization: Bearer ...`; UI ไม่มี direct protected download URL แล้ว
- **Clear-all report filters**: assertion ยืนยัน reset status/category/page/search ด้วย `updateUrlParams("All", "All", 1, "")`

### 2. รายการที่ไม่ผ่านและสาเหตุ
- ไม่มีข้อผิดพลาด (0 Failed)

## 2026-09-21 20:37 +07 - Admin Portal full Node test suite

- Target: `admin-portal/tests/*.test.mjs`
- Command: `npm test`
- Result: PASS
- Summary: Total: 18 | Passed: 18 | Failed: 0 | Skipped: 0 | Duration: 1118.557462 ms
- Requirement/TC mapping: Admin regression coverage supporting `FR-ADM-01/02/03/04/05`, `NFR-SEC-03`; exact tests retain their mapped TCs from `tests_all/rtm.md`
- Commit/Build/Env: commit `ca2a4bd0` + working tree หลัง fix | build N/A | model N/A | env local dev/test, Node test runner + Vite middleware

### 1. รายการที่ผ่านและพฤติกรรมที่ผ่าน
- **6 workflow regressions ใหม่**: modal success lifecycle, authenticated export download และ clear-all filter ผ่าน assertions หลังแก้
- **5 component-state tests เดิม**: Risk/Operational/Evidence/Heatmap state ยังแยก unknown, degraded และ available evidence ได้ตาม contract
- **3 WebMCP tests เดิม**: page context ยังคงคืนเฉพาะ runtime state ที่ไม่อ่อนไหวและ graceful fallback ทำงาน
- **4 WebSocket security/runtime tests เดิม**: URL ไม่มี query token, subprotocol auth, single reconnect timer และ stale socket guard ยังผ่าน

### 2. รายการที่ไม่ผ่านและสาเหตุ
- ไม่มีข้อผิดพลาด (0 Failed)
- Test runner แสดงข้อความ `WebSocket server error: Port 24678 is already in use` จาก Vite middleware/HMR test harness ระหว่างไฟล์ทดสอบทำงานขนานกัน แต่ process จบด้วย exit code 0 และทั้ง 18 assertions ผ่าน จึงไม่ถูกนับเป็น test failure
