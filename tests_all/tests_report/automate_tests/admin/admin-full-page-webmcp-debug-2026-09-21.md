# ผลทดสอบ Admin Full-Page + WebMCP Debug

## 2026-09-21 21:55 +07 - Admin Portal automated regression

- Target: `admin-portal/tests/*.test.mjs`
- Command: `npm test`
- Result: PASS
- Summary: Total: 23 | Passed: 23 | Failed: 0 | Skipped: 0 | Duration: 1.10 s
- Requirement/TC mapping: supporting evidence for `FR-ADM-01..05`, `FR-AUDIT-01`, `NFR-A11Y-01`; ครอบคลุม regression ของ `TC-ADM-*` ที่เกี่ยวข้อง แต่ไม่ใช้แทน Manual/Cross-browser TC
- Commit/Build/Env: commit `ca2a4bd0` + uncommitted working tree | env `dev` | Node 26.8.1 | Admin Portal local source

### 1. Passed Tests and Runtime Behavior (How it Passed)
- **Async state regression 5 tests**:
  - `useAdminQuery` ปฏิเสธ stale response ก่อนแก้ shared state
  - `CommandPalette` ไม่ให้ผลค้นหาเก่า overwrite ผลใหม่
  - Reports ใช้ URL เป็น applied state, normalize/canonicalize `page` query ที่ผิด และไม่ให้ clear-all ถูก stale effect overwrite
  - consumers ของ `reload()` guard ค่า `null` จาก stale/cancelled request
  - shared debounce ใช้ value-ref guard ที่ปลอดภัยกับ React StrictMode
- **Workflow regression 6 tests**:
  - deploy/user-status/report-decision modal ปิดหลัง success ได้
  - Dataset Export ดาวน์โหลดผ่าน authenticated API request
  - clear-all filter ล้าง status/category/page/search ครบ
- **Existing component/WebMCP/WebSocket tests 12 tests** ผ่านทั้งหมด

### 2. Failed Tests and Root Cause (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)

## 2026-09-21 21:55 +07 - WebMCP full-page runtime matrix

- Target: `admin-portal/tests/runtime/admin-all-pages-webmcp-matrix.mjs`
- Command: `ADMIN_APP_URL=http://127.0.0.1:5174 DEVTOOLS_URL=http://127.0.0.1:9223 node admin-portal/tests/runtime/admin-all-pages-webmcp-matrix.mjs`
- Result: PASS
- Summary: Total: 40 | Passed: 40 | Failed: 0 | Skipped: 0 | Duration: 29.33 s
- Requirement/TC mapping: supporting evidence for `FR-ADM-01..05`, `FR-AUDIT-01`, `NFR-A11Y-01`; ไม่ใช้แทน credential-backed E2E หรือ manual zoom/cross-browser TC
- Commit/Build/Env: commit `ca2a4bd0` + uncommitted working tree | Vite `5174` | Chrome 153 headless | CDP `9223` | WebMCP testing flags enabled

### 1. Passed Tests and Runtime Behavior (How it Passed)
- Matrix = 10 routes × 2 viewports (`390×844`, `1440×1000`) × 2 themes (Dark/Light)
- Routes: Login, Dashboard, Reports, Report Detail, Users, User Detail, Models, Dataset Export, Audit Log, Profile
- ทุกเคสตรวจ path, heading, theme, document overflow, runtime exception, console error และ page load-error state
- WebMCP discover `get_admin_page_context` และ execute สำเร็จทุกเคส; output จำกัดอยู่ที่ title/path/heading/theme/online
- Backend Admin API และ WebSocket ใน matrix นี้ถูก mock แบบ read-only เพื่อไม่สร้าง credential หรือเปลี่ยน DB

### 2. Failed Tests and Root Cause (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)

## 2026-09-21 22:26 +07 - Static/build acceptance

- Target: `admin-portal`
- Commands: `npm run lint` และ `npm run build`
- Result: PASS
- Summary: ESLint 0 errors | Vite production build 2485 modules | Duration: 423 ms
- Commit/Build/Env: commit `ca2a4bd0` + uncommitted working tree | env `dev` | Node 26.8.1

### 1. Passed Tests and Runtime Behavior (How it Passed)
- ไม่มี lint error จาก production/test changes รอบนี้
- production build สร้าง assets ครบ; `ReportsList` bundle build สำเร็จหลัง URL-state refactor

### 2. Failed Tests and Root Cause (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)
