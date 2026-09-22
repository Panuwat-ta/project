## 2026-09-22 - Admin Portal Regression หลังแก้ Session Device

- Target: `admin-portal/tests/*.test.mjs`
- Command: `npm test`
- Result: PASS
- Summary: Total 40 | Passed 40 | Failed 0 | Skipped 0 | Duration 2.61s

### 1. รายการที่ผ่านและพฤติกรรมที่ยืนยัน
- Profile/Session API wrappers ยังใช้ endpoint และ method เดิม
- Thai date formatter ยังคงใช้ `Asia/Bangkok`
- Profile/Admin UI regression tests เดิมทั้งหมดผ่าน
- WebMCP และ WebSocket controller tests ไม่ได้รับผลกระทบจาก session backend fixes

### 2. รายการที่ไม่ผ่าน
- ไม่มีข้อผิดพลาด (0 Failed)

### 3. Verification เพิ่มเติม
- `npm run lint`: PASS
- `npm run build`: PASS, Vite transform 2,485 modules, build 442 ms
## 2026-09-22 - Chrome/CDP + WebMCP Full-App Runtime Matrix

- Target: `admin-portal/tests/runtime/admin-all-pages-webmcp-matrix.mjs`
- Command: `node tests/runtime/admin-all-pages-webmcp-matrix.mjs`
- Result: PASS
- Summary: Total 40 | Passed 40 | Failed 0 | Skipped 0

### 1. รายการที่ผ่านและพฤติกรรมที่ยืนยัน
- 10 routes × mobile/desktop × dark/light ผ่านทั้งหมด
- `/admin/profile` ผ่าน 4/4 combinations
- Profile fixture มี current session และ active other session จึงตรวจได้ทั้ง badge `เซสชันปัจจุบัน` และ `เชื่อมต่ออยู่`
- ฟิลด์ `เข้าสู่ระบบล่าสุด` แสดงเวลาไทยจาก UTC fixture เป็น `21 ก.ย. 2569 19:00:00`
- Profile ไม่มี horizontal overflow และไม่มี console error
- WebMCP `get_admin_page_context` พบและ execute ได้ โดย path/theme/heading ตรงกับหน้า

### 2. รายการที่ไม่ผ่าน
- ไม่มีข้อผิดพลาด (0 Failed) ในรอบ final

### 3. Harness correction
- Attempt ก่อน final ได้ 0/40 จาก `ReferenceError: route is not defined` เพราะ assertion ใช้ตัวแปร Node ภายใน browser context
- แก้ harness ให้ใช้ `location.pathname`; rerun แล้ว 40/40 PASS จึงไม่นับ attempt แรกเป็น product failure
