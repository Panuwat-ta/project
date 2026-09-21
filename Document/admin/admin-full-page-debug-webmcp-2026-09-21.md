# รายงาน Debug Code ทุกหน้า Admin + WebMCP

วันที่ตรวจ: 2026-09-21
Branch: `refactoring-admin`
Baseline commit: `ca2a4bd0`
สถานะ: ตรวจบน commit เดิมร่วมกับ uncommitted working-tree fixes; ไม่มี commit/push/merge/PR/deploy จากรอบนี้

## 1. ขอบเขต
ตรวจ Admin Portal ทุก route ที่ประกาศใน `App.jsx` ได้แก่:
1. `/login`
2. `/admin/dashboard`
3. `/admin/reports`
4. `/admin/reports/:id`
5. `/admin/users`
6. `/admin/users/:id`
7. `/admin/models`
8. `/admin/dataset`
9. `/admin/audit-log`
10. `/admin/profile`

ตรวจทั้ง frontend และ Server Admin endpoints ที่รองรับหน้าดังกล่าว โดยรักษา Mobile dirty changes เดิมไว้ไม่แตะ

## 2. วิธีตรวจ
- ใช้ skill `diagnosing-bugs`: สร้าง red-capable tight repro ก่อนแก้ bug
- ใช้ skill `code-review`: เทียบกับ `wiki/architecture/admin-portal.md` และ standards ของ repo
- ทำ self-review แยกจาก test results เพื่อหา async lifecycle, auth/download, pagination, modal และ URL-state risks
- ใช้ Chrome DevTools Protocol + WebMCP runtime จริงตรวจทุกหน้า
- เรียก `agy` แบบ sandbox/read-only เพื่อ independent review และนำผลมาเทียบ

## 3. Confirmed bugs ที่แก้แล้ว

### P1 — Dataset Export ดาวน์โหลดผ่าน direct `<a href>` ทั้งที่ endpoint ต้อง Bearer auth
- เดิม browser navigation ไม่สามารถเติม `Authorization` จาก token ใน memory ได้
- แก้เป็น `downloadExportJob()` ผ่าน `apiRequest(..., { parse: "raw" })` แล้วสร้าง Blob download
- regression test ยืนยันว่ามี Bearer header และไม่มี direct protected download URL ใน UI

### P2 — Success modal ปิดไม่ได้ 3 workflow
- `ModelsList`, `UsersList`, `ReportDetail` เรียก guarded close function ขณะที่ submission flag ยังเป็น `true`
- แยก `reset*Modal()` สำหรับ success path; user close ยังคงถูก block ระหว่าง request

### P2 — Reports “ล้างตัวกรองทั้งหมด” ยังเก็บ category เดิม
- แก้ให้ reset status/category/page/search พร้อมกัน

### P2 — Export Jobs backend pagination ไม่มี validation
- ก่อนแก้ `page=0/-1`, `limit=0/101` ตอบ 200
- หลังแก้คืน HTTP 400 ตาม contract ของ Admin list endpoints อื่น

### P2 — `useAdminQuery` stale-response race
- tight repro: request B จบก่อนและแสดง `B-result` แต่ request A ที่เริ่มก่อนและจบทีหลัง overwrite กลับเป็น `A-result`
- แก้ด้วย monotonically increasing request id; stale result/error/finally ไม่มีสิทธิ์แก้ state
- consumers ที่ใช้ return value จาก `reload()` guard `null` ก่อนทำ side effect ต่อ

### P2 — `CommandPalette` stale search race
- tight repro: ค้น `old` ด้วย request ช้า แล้วค้น `new` ด้วย request เร็ว; UI แสดง NEW ก่อน แต่ response เก่ากลับ overwrite เป็น OLD
- แก้ด้วย monotonically increasing `searchRequestIdRef`; stale success/error/finally ไม่แก้ state
- cleanup ยกเลิก debounce timer และ invalidate request id; focus timer ถูก cleanup เมื่อปิด/unmount

### P2 — shared debounce reset pagination ใน React StrictMode
- `useDebouncedValue` เดิมรับ callback inline เป็น effect dependency ทำให้ re-arm timer บ่อยและ callback reset หน้า 1 ถูกเรียกหลัง mount
- fix รอบแรกที่ข้าม effect invocation แรกยังไม่พอ เพราะ React StrictMode ทำ setup/cleanup/setup
- fix สุดท้ายเทียบค่าที่ normalize แล้วกับ `debouncedRef.current`; ไม่ยิง callback ถ้าค่า applied ไม่ได้เปลี่ยนจริง
- runtime ยืนยัน Users และ Audit Log เปลี่ยนหน้า 1 → 2 แล้วคงหน้า 2 หลังรอเกิน debounce window

### P2 — Reports query/page state และ clear-all stale overwrite
- invalid `?page=0`, `?page=-1`, `?page=abc` เคยทำให้ request ผิด (`0/-1/NaN`); แก้ให้ strict-parse integer >= 1 และ canonicalize malformed URL
- independent review ชี้ความไม่แน่นอนว่า clear-all อาจมี search เก่ากลับเข้ามาชั่วคราว; self tight repro ยืนยันว่ารุนแรงกว่านั้น: generic URL-sync effect นำ status/category/search เก่ากลับมาหลัง clear
- แก้ให้ URL เป็น source of truth ของ applied status/category/page/search ส่วน local state เก็บเฉพาะ search draft
- clear-all หลัง fix คง URL `/admin/reports` ตลอดช่วง 0–450 ms; ไม่มี stale status/category/search กลับมา
- pagination runtime: หน้า 2 → 3 ใช้ URL `?page=3` และยิง API page 3 เท่านั้น
- malformed page runtime: `0/-1/abc` ถูก canonicalize เป็น `/admin/reports` และ backend request ใช้ page 1

## 4. WebMCP + Full-Page Runtime Matrix
Chrome 153 เปิด WebMCP testing flags และ discover `get_admin_page_context` ได้จริง; tool มี `readOnlyHint` และคืนเฉพาะ `title`, `path`, `heading`, `theme`, `online`

Matrix สุดท้าย: **40/40 PASS** = 10 routes × 2 viewports (`390×844`, `1440×1000`) × 2 themes (Dark/Light)

ตรวจในแต่ละเคส:
- route/path และ heading
- rendered theme
- document horizontal overflow
- JavaScript runtime exception
- `console.error`
- page load-error state
- WebMCP discovery + execution

Backend Admin API/WebSocket ใน matrix นี้ mock แบบ read-only เพื่อทดสอบ App/Router/page components จริงโดยไม่สร้าง credential หรือ mutate DB; จึงเป็น supporting runtime evidence ไม่ใช่ credential-backed E2E แทน matrix 81/81 ที่เคยทำก่อนหน้า

## 5. Final deterministic verification
- Admin `npm test`: **23/23 PASS**, 0 failed, 0 skipped; default runner ใช้ `--test-concurrency=1` เพื่อกำจัด Vite test-harness port collision
- Admin ESLint: **PASS**
- Admin production build: **PASS**, 2485 modules, 423 ms
- WebMCP full-page runtime matrix: **40/40 PASS**
- Server full regression: **85 passed, 3 skipped, 0 failed**, 3 dependency-deprecation warnings, 11.98 s
- `git diff --check`: **PASS** หลังปิดเอกสาร/log/ledger

## 6. เปรียบเทียบ Self-review กับ `agy`
การเรียก `agy` รอบสุดท้ายใช้ syntax ตาม CLI จริง:
`agy --print-timeout 0 --mode plan --effort high --sandbox --print='...'`
และรอจน turn จบโดยไม่ใช้ timeout ตัดผลกลาง

### Independent review รอบก่อน final patch
- Verdict: `NO_CONFIRMED_P0_P2`
- `agy` ชี้ residual uncertainty เรื่อง Reports clear-all/search URL sync
- self-review ไม่รับข้อสรุปทันที แต่สร้าง CDP tight repro และยืนยันเป็น P2 จริง: old status/category/search ถูก effect เก่าเขียนกลับหลัง clear
- จึงแก้ URL-state architecture เพิ่มก่อนขอ final verdict

### Independent review บน final current diff
- Verdict: **`NO_CONFIRMED_P0_P2`**
- ยืนยัน URL-as-source-of-truth ของ Reports, clear-all, invalid page canonicalization, pagination, StrictMode debounce, stale-response guards, authenticated export, modal success-close, backend pagination และ WebMCP safe exposure
- `agy` rerun Admin tests ได้ 23/23, lint/build ผ่าน และ targeted Admin backend tests 27/27
- ผล independent review จึงสอดคล้องกับ self-review และ deterministic gates หลัง patch สุดท้าย

## 7. สิ่งที่ไม่จัดเป็น product bug / ข้อจำกัด
- Dashboard 36/40 ใน matrix รอบแรกเกิดจาก Vite dependency optimizer คืน `504` สำหรับ `recharts`; หลัง `vite --force` matrix เดิมผ่าน 40/40 จึงจัดเป็น dev-harness/environment issue ไม่แก้ Dashboard code
- Node tests เคยมี `Port 24678 is already in use`; serial runner ยืนยัน warning หาย จึงกำหนด `--test-concurrency=1` ให้ default test gate deterministic
- WebMCP/CDP matrix ต้องใช้ Chrome DevTools loopback port 9223 และ Vite 5174; sandboxed reviewer ไม่สามารถเปิด socket นี้เอง จึง inspect code/report แทน
- Dataset Export ใช้ browser Blob จึงยังมี memory-risk เชิงสถาปัตยกรรมหากไฟล์ใหญ่มากผิดปกติ; ไม่พบ failure ใน scope ปัจจุบันและ streaming sink อยู่นอก SPA contract รอบนี้
- รอบนี้ไม่ได้สร้าง credential หรือ rerun credential-backed 81-case matrix; ใช้ mock read-only full-App matrix 40/40 ส่วน authenticated matrix 81/81 เป็นหลักฐานจากรอบก่อนหน้า
- working tree มี partial staging จากภายนอก/รอบก่อนหน้า และ Mobile dirty changes เดิม; รอบนี้ไม่แก้ index และต้องระวังไม่รวม Mobile ใน Admin commit

## 8. สรุป
หลัง debug ทุกหน้า + WebMCP + skill review + self-review + independent `agy` review ไม่เหลือ confirmed P0–P2 ใน current Admin diff ตามหลักฐานที่รันได้

Final acceptance:
- Admin tests **23/23 PASS**
- ESLint **PASS**
- Production build **PASS**
- WebMCP full-page matrix **40/40 PASS**
- Server **85 passed / 3 skipped / 0 failed**
- `agy`: **NO_CONFIRMED_P0_P2**

ไม่มี commit, push, merge, PR หรือ deploy จากรอบนี้

## 9. Final integrity / cleanup
- `.agents/loop-ledger.json` parse ผ่าน (`python3 -m json.tool`)
- production token-query scan: `TOKEN_QUERY_CLEAN`
- WebMCP secret-access scan (`Authorization`, token storage, cookie, password, query string): `WEBMCP_SECRET_ACCESS_CLEAN`
- `git diff --check` และ `git diff --cached --check`: PASS
- harness Chrome/CDP `9223` และ Vite `5174` ถูกหยุดหลังทดสอบ
- Vite เดิมของผู้ใช้ที่ `localhost:5173` ยังคงทำงานและไม่ได้ถูกแตะ
- HEAD และ `origin/refactoring-admin` ยังเป็น `ca2a4bd0`; ไม่มี Git history mutation จากรอบนี้
