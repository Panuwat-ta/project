# ผลทดสอบ Authenticated Admin Runtime Matrix

## 2026-09-21 - Attempt 1: CDP WebSocket observability harness

- Target: Admin Portal protected routes ผ่าน Chrome headless + CDP
- Command: `node /tmp/scamguard_admin_matrix.mjs`
- Result: FAIL (test harness false negative; ไม่ใช่ product failure)
- Summary: Total: 81 | Passed: 72 | Failed: 9 | Skipped: 0 | Duration: ไม่ได้บันทึกในผลรัน
- Requirement/TC mapping: `FR-ADM-01`, `NFR-A11Y-01`; supporting evidence สำหรับ `TC-ADM-DASH-01`; partial evidence สำหรับ `TC-ADM-UI-03`, `TC-ADM-COMP-01`
- Commit/Build/Env: commit `35085d8d` | Chrome `153.0.8010.47` | env `dev` | Vite `5173` | API `8000`

### 1. Passed Tests and Runtime Behavior (How it Passed)
- 72 เคส non-Dashboard ผ่าน route, theme, viewport, API/runtime error และ document-overflow assertions
- Report Detail และ User Detail ใช้ ID จริงที่ discover จาก list runtime ไม่ได้ hardcode
- Dashboard ทั้ง 9 เคสมี WebSocket handshake HTTP `101` จริง และไม่มี API/runtime/console error

### 2. Failed Tests and Root Cause (How & Why it Failed)
- 9 Dashboard cases ถูก harness ตีเป็น fail เพราะอ่าน URL จาก `Network.webSocketHandshakeResponseReceived` ซึ่ง Chrome event นี้ไม่ได้คืน URL
- ตรวจ evidence พบทั้ง 9 เคสมี status `101`; แก้ harness ให้ join URL จาก `Network.webSocketCreated` ด้วย `requestId` ก่อน retry

## 2026-09-21 - Attempt 2: corrected authenticated runtime matrix

- Target: 9 protected routes x 3 themes x 3 viewports ผ่าน Chrome headless + CDP
- Command: `node /tmp/scamguard_admin_matrix.mjs`
- Result: PASS
- Summary: Total: 81 | Passed: 81 | Failed: 0 | Skipped: 0 | Duration: ไม่ได้บันทึกในผลรัน
- Requirement/TC mapping: `FR-ADM-01`, `NFR-A11Y-01`; supporting evidence สำหรับ `TC-ADM-DASH-01`; partial evidence สำหรับ `TC-ADM-UI-03`, `TC-ADM-COMP-01`
- Commit/Build/Env: commit `35085d8d` | Chrome `153.0.8010.47` | env `dev` | Vite `5173` | API `8000`

### 1. Passed Tests and Runtime Behavior (How it Passed)
- Protected routes: Dashboard, Reports, Report Detail, Users, User Detail, Models, Dataset Export, Audit Log และ Profile โหลดหลัง login จริงครบ
- Themes: Light, Dark และ System โดย emulate OS Dark; ทุกเคสได้ rendered theme ตามคาด
- Viewports: `360x800`, `768x900`, `1440x1000`; document-level horizontal overflow = 0 ทุกเคส
- Network/runtime: API 4xx/5xx = 0, runtime exceptions = 0, console errors = 0, page load-error states = 0
- Dashboard WebSocket: handshake `101` ที่ `/ws/admin/dashboard` ครบ 9/9 Dashboard cases

### 2. Failed Tests and Root Cause (How & Why it Failed)
ไม่มีข้อผิดพลาดของ product ใน Attempt 2 (0 Failed)

### Scope / Teardown
- Login ใช้ Super Admin ทดสอบชั่วคราวที่สร้างเฉพาะรอบนี้; password อยู่ใน process memory และไม่ถูกบันทึกใน repo/report
- หลังจบ ลบ AdminSession และบัญชีทดสอบแล้ว; verification `TEMP_ADMIN_REMAINING=0`
- รอบนี้เป็น read-only page/runtime matrix; ไม่กด Deploy, Rollback, Ban, Approve/Reject หรือ Dataset Export submit
- ผลนี้ไม่แทน manual `TC-ADM-UI-03` ส่วน zoom 200%/interactive actions และไม่แทน `TC-ADM-COMP-01` ที่ต้อง Firefox/Safari

## Trend / Flaky Tracking
| รอบ | Suite | Pass/Fail/Skip | Flaky | หมายเหตุ |
| :--- | :--- | :--- | :--- | :--- |
| Attempt 1 | Auth runtime matrix | 72/9/0 | ไม่มี | 9 false negatives จาก harness observability defect |
| Attempt 2 | Auth runtime matrix | 81/0/0 | ไม่มี | harness corrected; product assertions ผ่านครบ |
