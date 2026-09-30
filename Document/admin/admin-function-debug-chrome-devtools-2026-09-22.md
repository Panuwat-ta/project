# รายงาน Debug ทุกฟังก์ชัน Admin + Chrome DevTools MCP

วันที่: 2026-09-22
Branch: `refactoring-admin`
Revision ที่ตรวจ: `98bbed8f`

## ขอบเขตและวิธีตรวจ
รอบนี้ตรวจ Admin Portal และ Server Admin backend แบบ function-by-function ต่อจาก full-page review เดิม โดยใช้ workflow `diagnosing-bugs`, `code-review` และ loop constraints ของ repo

วิธีตรวจหลักประกอบด้วย RED → fix → GREEN, self-review production diff, function-contract tests, full regression, coverage, Chrome DevTools MCP runtime validation และ `agy` independent read-only review

Chrome DevTools MCP เชื่อมตรงผ่าน MCP protocol กับ `chrome-devtools-mcp v1.9.0` และใช้งาน tools เช่น `take_snapshot`, `evaluate_script`, `list_console_messages`, `list_network_requests`, `resize_page` และ `navigate_page`

## ผล Final Acceptance
- Admin tests: **37/37 PASS**
- ESLint: **PASS**
- Vite production build: **PASS**, 2,485 modules, 470 ms
- Server full regression: **131 passed / 3 skipped / 0 failed**
- Admin backend coverage surface: **89% รวม**
- Chrome DevTools MCP authenticated matrix: **18/18 PASS**
- `git diff --check`: **PASS**
- production token/credential grep: **CLEAN**
- `agy` final verdict: **NO_CONFIRMED_P0_P2**
## Confirmed Bugs ที่แก้แล้ว
1. Admin refresh token ที่มี `sub` malformed เคยเกิด 500; เพิ่ม integer validation และคืน canonical 401
2. User Detail ใช้ all-time scan count แทน `scans_this_month`; เพิ่ม monthly query ตาม `TH_TIMEZONE` และเพิ่ม `recent_scans.status`
3. Model deploy ไม่มี row lock ตาม architecture; เพิ่ม `SELECT ... FOR UPDATE` สำหรับ target/active model rows
4. Dataset export ZIP เดิมไม่มีรูปภาพ; แก้ให้มี `images/<category>/...`, `metadata.json`, `README.md`, `manifest.json` และไม่รวม reporter PII
5. Export worker สามารถ overwrite `canceled` เป็น `succeeded`; เพิ่ม DB refresh ก่อน publish success และ cleanup archive เมื่อถูก cancel
6. Export failure ทิ้ง partial ZIP; เพิ่ม best-effort cleanup และ clear `file_path`
7. Admin health hardcode `queue=ok`; เปลี่ยนเป็น probe Redis จริงและ report `error` เมื่อ unavailable
8. Ban/Unban reason หายจาก AuditLog; เพิ่ม `reason` ลง audit record
9. SearchInput ไม่มี browser field identity; เพิ่ม React `useId()` และ render `id`
10. Dataset metadata checkbox ไม่มี explicit id/name และ category group ใช้ label ผิด semantic; เพิ่ม id/name/htmlFor และเปลี่ยนเป็น `fieldset/legend`
11. Admin media URL helper flatten nested upload path ทำให้ heatmap 404; แก้ให้ preserve relative subdirectory และ optional heatmap ที่ไม่มีจริงคืน `null`

## Chrome DevTools MCP Runtime Evidence
Authenticated matrix ใช้ temporary test-only Super Admin และ SPA navigation บน session จริง ตรวจ 9 protected routes × 2 viewport: mobile 390×844 และ desktop 1440×1000

Routes: Dashboard, Reports, Report Detail, Users, User Detail, Models, Dataset Export, Audit Log และ Profile

ทุก 18 cases ตรวจ path/heading, document overflow, load-error state, console `error/issue` และ network 4xx/5xx; ผลสุดท้าย **18/18 PASS**

Report Detail ใช้ข้อมูลจริง `/admin/reports/12` และ User Detail `/admin/users/100`
## Heatmap 404 Root Cause
Chrome DevTools MCP final matrix รอบก่อน fix พบ 404 เฉพาะ Report Detail เพราะ DB เก็บ heatmap เป็น `./uploads/heatmaps/<hash>_heatmap.jpg` แต่ `_to_media_url()` เดิมใช้ `basename()` จึงคืน `/uploads/<hash>_heatmap.jpg`

RED test ยืนยัน nested-path mismatch ก่อนแก้ หลังแก้ API คืน `/uploads/heatmaps/<hash>_heatmap.jpg` และ resource ตอบ 200 ทั้ง backend และ Vite proxy

Chrome DevTools MCP targeted retest ของ `/admin/reports/12` หลัง fix: path/heading ถูกต้อง, overflow=false, console issue/error=0 และ network 4xx/5xx=0

## Coverage
Final full Server run พร้อม coverage ของ Admin surface:
- `app/api/v1/admin.py`: **95%**
- `app/services/admin_access_policy.py`: **95%**
- `app/services/admin_service.py`: **85%**
- `app/services/export_service.py`: **89%**
- รวม: **89%**

Server full suite เดียวกันผ่าน **131 tests**, skipped 3, failed 0

## Independent Review เทียบกับ Self-review
`agy --print-timeout 0 --mode plan --effort high --sandbox` ตรวจ current working tree แบบ read-only จนจบใน ~351 วินาที และสรุปว่าไม่พบ confirmed P0–P2

ผล `agy` ตรงกับ self-review ใน 9 กลุ่มหลัก: malformed refresh, monthly stats/status, deployment row lock, export lifecycle, Redis health, audit reason, nested media URL/heatmap fallback, form semantics และ stale async guards
## Residual / P3 Observations
`agy` ระบุ 2 จุดที่ไม่ใช่ P0–P2:
- Export worker ตรวจ cancellation หลัง ZIP เขียนเสร็จ จึงอาจใช้ CPU/disk เกินจำเป็นเมื่อยกเลิกงานใหญ่มาก แต่ไม่ publish ไฟล์และไม่ทำให้ status/data integrity ผิด
- Backend ส่ง `recent_scans.status` แล้ว แต่ User Detail frontend ยังไม่แสดง field นี้ เป็น UI polish ไม่ใช่ contract failure

## Cleanup และข้อจำกัด
Temporary Super Admin และ AdminSession ถูกลบหลัง runtime matrix; verification `TEMP_TEST_ADMINS=0` และ `TEMP_TEST_SESSIONS=0`

Temporary preview ที่พอร์ต 4174 ถูกปิดแล้ว; Vite เดิมของผู้ใช้ที่ 5173 และ backend 8000 ไม่ถูกหยุด

`loop-context --check` ยังไม่มี binary ใน environment (RC=127) จึงไม่อ้างว่า gate นี้ผ่าน

ไม่มีการ commit, push, amend, reset, PR, merge หรือ deploy ในรอบนี้

## สรุป
หลัง RED/GREEN fixes, function-contract regression, full server/frontend gates, Chrome DevTools MCP authenticated runtime matrix และ independent `agy` review ไม่เหลือ confirmed P0–P2 ใน scope Admin ที่ตรวจรอบนี้
