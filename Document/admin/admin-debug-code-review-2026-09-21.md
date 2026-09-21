# รายงาน Debug + Code Review: Admin — 2026-09-21

## 1. ขอบเขต

ตรวจเฉพาะ Admin ของ ScamGuard ได้แก่ `admin-portal/` และ Backend ที่รองรับ `/api/v1/admin/*` รวมถึง Admin WebSocket, auth/access-policy, reports, users, model management, dataset export, audit/search และ automated tests ที่เกี่ยวข้อง

Git fixed point สำหรับ `code-review` skill คือ `origin/develop` (`3975755e...`) เทียบกับ HEAD `ca2a4bd0`. Working tree ของ Mobile ที่มีอยู่ก่อนงานนี้ไม่ถูกแก้ไขในรอบ Admin นี้

Source of truth ที่ใช้ตรวจ spec: `wiki/architecture/admin-portal.md`, `wiki/architecture/backend-api.md`, `tests_all/rtm.md` และ source code ปัจจุบัน

## 2. วิธีตรวจ

ใช้ workflow จาก `diagnosing-bugs` เพื่อสร้าง red-capable regression ก่อนแก้, ใช้ `code-review` ตรวจ Standards/Spec จาก fixed point, ตรวจ source/runtime flow ซ้ำด้วย self-review และเรียก `agy` แบบ read-only independent review ก่อน patch โดยห้ามแก้ไฟล์/รัน test/ใช้ network/อ่าน credential

Baseline ก่อนแก้: Admin Node tests 12/12 PASS, ESLint PASS, Vite production build PASS และ Backend Admin targeted suite 23/23 PASS จึงต้องใช้ code review หา defect ที่ suite เดิมยังไม่ครอบคลุม

## 3. ผลสรุป

พบ defect ที่ยืนยันด้วย regression test 4 root causes รวมผลกระทบ 6 frontend assertions และ 4 backend pagination cases หลังแก้ tight regressions, full Admin suite และ full Server suite ผ่านทั้งหมด

ไม่พบ P0 ที่ยืนยันได้ใน scope นี้ และไม่มีการแก้ `.env`, credential, token contract, DB schema, risk threshold หรือ dependency

## 4. Confirmed findings และการแก้ไข

| ระดับ | Finding | หลักฐานก่อนแก้ | การแก้ |
| --- | --- | --- | --- |
| P1 | Dataset Export ดาวน์โหลด protected endpoint ด้วย direct `<a href>` จึงไม่มี Bearer access token จาก memory | Backend route ใช้ `Depends(require_super_admin)`; regression ยืนยันว่า helper authenticated download ยังไม่มีและ UI ยัง direct-navigation | เปลี่ยนเป็น `downloadExportJob()` ผ่าน unified `apiRequest(parse="raw")`, รับ Blob แล้ว trigger browser download; รองรับ refresh/retry path เดิมของ API layer |
| P2 | Success modal ไม่ปิดหลัง deploy model | `closeDeployModal()` ปฏิเสธเมื่อ `isDeploying=true` แต่ success path เรียกก่อน `finally` | แยก `resetDeployModal()` สำหรับ programmatic success close; user close ยังคงถูก guard ระหว่าง operation |
| P2 | Success modal ไม่ปิดหลัง ban/unban user | pattern เดียวกันกับ `isSubmitting` / `closeStatusModal()` | แยก `resetStatusModal()` และใช้ใน success path |
| P2 | Decision modal ไม่ปิดหลัง approve/reject report | pattern เดียวกันกับ `isSubmittingDecision` / `closeDecisionModal()` | แยก `resetDecisionModal()` และใช้ใน success path |
| P2 | ปุ่ม “ล้างตัวกรองทั้งหมด” ยังเก็บ category เดิม | desktop/mobile handlers reset search/status แต่ `handleTabChange("All")` ส่ง category เดิมกลับ URL | เพิ่ม `clearAllFilters()` ให้ reset status/category/page/search พร้อมกัน |
| P2 | Export jobs list ยอมรับ invalid `page/limit` | regression ได้ HTTP 200 สำหรับ `page=0`, `page=-1`, `limit=0`, `limit=101` | เพิ่ม HTTP 400 validation ให้สอดคล้องกับ `/reports`, `/users`, `/audit-logs` |

## 5. Red → Green evidence

Frontend regression ใหม่ `admin-workflow-regressions.test.mjs` หลังแก้ test harness แล้วเริ่มที่ 0/6 PASS, 6/6 FAIL จากอาการจริงข้างต้น จากนั้นหลัง patch เดิมชุดเดียวกันผ่าน 6/6

Backend regression ใหม่ `test_admin_export.py` เริ่มที่ 0/4 PASS โดยทุก invalid pagination case ได้ 200 แทน 400; หลังเพิ่ม validation ผ่าน 4/4 พร้อมตรวจทั้ง status code และ `detail`

## 6. Code-review skill: Standards axis

- Guarded-close logic ซ้ำ 3 หน้าเป็น duplicated workflow pattern และทำให้ success path ใช้ user-interaction guard ผิดบริบท; patch แยก reset function ที่มีหน้าที่ชัดเจนโดยไม่ refactor เกิน scope
- Direct protected download ข้าม `src/lib/api.js` ซึ่งขัดกับ architecture ที่กำหนด API/token/global error handling รวมศูนย์; patch กลับมาใช้ unified API layer
- Pagination validation ของ Export Jobs ไม่สม่ำเสมอกับ Admin list routes อื่น; patch ใช้ contract เดียวกันโดยไม่เปลี่ยน valid requests
- หลัง patch `git diff --check` PASS และไม่พบ `[DEBUG-*]` instrumentation ค้าง

## 7. Code-review skill: Spec axis

`wiki/architecture/admin-portal.md` ระบุว่า Admin API calls ใช้ `fetch` wrapper รวมศูนย์พร้อม token management และ `/admin/*` เป็น privileged workflow; authenticated download fix จึงทำให้ implementation กลับมาตรง architecture นี้

`FR-ADM-02` รองรับ report moderation, `FR-ADM-03` dataset export, `FR-ADM-04` model management และ `FR-ADM-05` user management. Fix ทั้งหมดรักษา behavior/API contract เดิมและแก้เฉพาะ client workflow/validation ที่ทำให้ function เหล่านี้ไม่สมบูรณ์

ไม่มี requirement ใหม่, API endpoint ใหม่, DB schema change หรือ permission expansion ใน patch นี้

## 8. Self-review เทียบกับ `agy`

| แหล่งตรวจ | ผล |
| --- | --- |
| Skill + self-review | ยืนยัน 4 root causes และสร้าง red-capable tests ก่อนแก้ |
| `agy` independent review | เรียกแบบ read-only ด้วย timeout 120s แต่จบด้วย `[agy] print timeout after 2m0s with turn in progress; returning partial output`; ไม่มี finding หรือ verdict ส่งกลับ |
| Comparison | ไม่มี independent verdict ที่นำมา corroborate/contradict ได้ จึงไม่อ้าง `agy PASS` หรือ `NO_CONFIRMED_P0_P2`; verdict รอบนี้ยึด deterministic regression evidence เท่านั้น |

## 9. Final verification

| Gate | ผลจริง |
| --- | --- |
| Admin tight regression | 6/6 PASS |
| Admin full `npm test` | 18/18 PASS, 0 failed |
| Admin ESLint | PASS, exit code 0 |
| Admin production build | PASS, 2485 modules, 391 ms |
| Backend Admin targeted | 27/27 PASS, 0 failed, 3 dependency warnings |
| Server full regression | 85 passed, 3 skipped, 0 failed, 3 warnings, 14.23 s |
| `git diff --check` | PASS |
| leftover direct export URL pattern | ไม่พบ `getExportDownloadUrl` หรือ `href={downloadUrl}` ใน `admin-portal/src` |
| debug instrumentation | ไม่พบ `[DEBUG-*]` ใน Admin source/backend route ที่แก้ |

Admin `npm test` มี nonfatal test-harness message `WebSocket server error: Port 24678 is already in use` จาก Vite middleware/HMR ขณะ test files ทำงานขนานกัน แต่ runner exit code 0 และ 18 assertions ผ่าน จึงยังไม่ยกระดับเป็น product defect โดยไม่มี repro ที่กระทบ behavior

## 10. Finding ที่ยังไม่ยืนยัน

`useAdminQuery` ไม่มี AbortController/request-generation guard จึงมีความเป็นไปได้เชิงสถาปัตยกรรมที่ response เก่าจาก request ช้าจะเขียนทับ response ใหม่เมื่อเปลี่ยน filter เร็วมาก แต่รอบนี้ยังไม่มี tight red-capable repro ที่ยืนยันอาการ จึงไม่ได้แก้และไม่จัดเป็น confirmed bug

Authenticated browser matrix หลัง patch รอบนี้ไม่ได้ rerun เพราะไม่มี valid Admin browser session/credential ที่ได้รับอนุญาตให้สร้างใหม่ในงานนี้ หลักฐาน matrix 81/81 ก่อนหน้าเป็น historical result ของ revision ก่อน patch และไม่ได้ถูกนำมาอ้างเป็น current runtime PASS

## 11. ไฟล์ที่แก้ในรอบนี้

- `admin-portal/src/lib/api.js`
- `admin-portal/src/pages/DatasetExport.jsx`
- `admin-portal/src/pages/ModelsList.jsx`
- `admin-portal/src/pages/ReportDetail.jsx`
- `admin-portal/src/pages/ReportsList.jsx`
- `admin-portal/src/pages/UsersList.jsx`
- `admin-portal/tests/admin-workflow-regressions.test.mjs` (ใหม่)
- `server/app/api/v1/admin.py`
- `server/tests/api/test_admin_export.py` (ใหม่)

ไม่มี commit, push, PR, merge หรือ deploy ในรอบนี้
