# แผนส่งมอบ Admin Portal ให้ใช้งานจริง — ScamGuard

## เป้าหมายและขอบเขต

Admin Portal นี้มีผู้ใช้เพียงบทบาทเดียวคือ **Super Admin** ผู้มีสิทธิ์เข้าถึงและดำเนินการทุกฟังก์ชันของระบบได้ โดยระบบต้องรองรับการทำงานจริงอย่างปลอดภัย ตรวจสอบย้อนหลังได้ และแสดงผลที่สัมพันธ์กับข้อมูลจาก Server จริง

ความสำเร็จของงานคือ Super Admin สามารถเข้าสู่ระบบ, ตรวจสอบภาพรวม, จัดการรายงานและผู้ใช้, ควบคุมโมเดล, ส่งออกชุดข้อมูล, ตรวจสอบ Audit Log และตั้งค่าโปรไฟล์ได้ครบ โดยทุกการเปลี่ยนแปลงสำคัญต้องมีการยืนยัน, บันทึกผู้กระทำ/เวลา/ข้อมูลก่อน–หลัง, และผ่านเกณฑ์ทดสอบด้านล่าง

## ผลการตรวจสอบสถานะปัจจุบัน

| ส่วนงาน | มีแล้ว | ช่องว่างก่อนใช้งานจริง |
|---|---|---|
| Login และ refresh token | มี `/admin/login`, `/admin/refresh`, JWT และหน้า Login | ยังเก็บ refresh token ใน `localStorage`; ไม่มีการเพิกถอน token, rate limit เฉพาะ login, password policy หรือ session management |
| Authorization | มี `get_current_admin` และ `admins.is_active` | ไม่ตรวจ claim `role=admin` และไม่บังคับ `is_superadmin=True` แม้ระบบระบุ Super Admin เท่านั้น |
| Dashboard | ดึง KPI, risk distribution, reports, trend และสถานะโมเดลจาก API | นิยาม `active_users_today` ใช้ `users.updated_at` ซึ่งไม่ใช่กิจกรรมจริง; ไม่มี model accuracy/health และไม่มี empty/error/retry ที่เป็นมาตรฐานเดียวกัน |
| Scam Reports | List/filter/search/pagination, detail, approve/reject และ audit บางส่วนมีแล้ว | ไม่มี validation query ที่เข้มงวด, transition ของสถานะ, optimistic locking, การเปิดงาน `reviewing`, reason taxonomy และ audit ก่อน–หลัง |
| Users | List และ ban/unban มีแล้ว | นับ `total_scans`/`total_reports` เป็น 0 เสมอ, ไม่มี search/filter/pagination ใน UI, ไม่มี user detail และไม่จำกัด role ที่แก้ไขได้ |
| AI Models | List และ deploy มีแล้ว | deploy สลับข้อมูลในฐานข้อมูลเท่านั้น ไม่ตรวจ artifact/compatibility/health หรือ rollout/rollback; เสี่ยง deploy ซ้ำพร้อมกัน |
| Dataset Export | filter, preview, ZIP และ Audit Log มีแล้ว | สร้าง ZIP ทั้งก้อนใน RAM, ไม่กำหนดขนาด/จำนวนสูงสุด, ไม่ตรวจรูปแบบ export/consent อย่างละเอียด, ไม่มี job/history ที่คงอยู่หรือดาวน์โหลดซ้ำ |
| Audit Log | บันทึก action หลักและแสดง list มีแล้ว | รายละเอียดเป็นข้อความอิสระ, ไม่มี filter/search/retention/immutable policy และหลาย action ยังไม่ถูกบันทึก |
| UI ส่วนกลาง | Sidebar, dark mode, responsive Reports มีแล้ว | Global search, notification และ Profile Settings เป็น UI ที่ยังไม่เชื่อมฟังก์ชัน; Users/Models/Audit ยังไม่เหมาะกับมือถือ |
| Test/operations | มี unit/API test สำหรับ auth และ report detail บางกรณี | ไม่มี test ครบเส้นทาง Super Admin, browser E2E, migration/backup/monitoring และ release gate |

## ข้อกำหนดหลัก (Definition of Done)

1. ทุก API ฝั่ง `/admin/*` รับได้เฉพาะ access token ชนิด `access` ของบัญชี `admins` ที่ `is_active=true` และ `is_superadmin=true`; บัญชีทั่วไป, admin ที่ไม่ใช่ Super Admin, token ผิดชนิด/หมดอายุ และบัญชีถูกปิดต้องถูกปฏิเสธอย่างสม่ำเสมอ
2. ทุกคำสั่งที่เปลี่ยนข้อมูลหรือกระทบ production (อนุมัติ/ปฏิเสธรายงาน, ban/unban, deploy/rollback, export, แก้ไขโปรไฟล์/รหัสผ่าน) ต้องมี confirmation, loading state, error state, ป้องกันการกดซ้ำ และสร้าง Audit Log แบบ structured
3. ข้อมูลบนหน้าจอต้องมาจาก API จริง ไม่มีค่า mock/hardcode สำหรับรายการ, count หรือ status; หน้าใดไม่มีข้อมูลต้องมี empty state และปุ่ม retry เมื่อโหลดผิดพลาด
4. ทุก list รองรับ server-side pagination, filter, search, sort ตามที่หน้าใช้งาน และ URL query ต้องเก็บ filter/page เพื่อแชร์ลิงก์หรือกด Back ได้ถูกต้อง
5. ทุกเวลาจัดเก็บเป็น UTC และแสดงในเขตเวลา `Asia/Bangkok` พร้อมรูปแบบเดียวกัน; การทำ export ต้องบันทึก timezone/เงื่อนไขลง manifest
6. ผ่าน automated test, security checks, accessibility baseline และ UAT ตามรายการในเอกสารนี้ก่อนเปิดใช้งานจริง

## แผนดำเนินงานตามลำดับ

### Phase 0 — ทำสัญญาข้อมูลและสภาพแวดล้อมให้พร้อม

- กำหนด OpenAPI/response schema เป็นแหล่งอ้างอิงเดียวสำหรับทุก endpoint, validation error และ pagination (`items`, `total`, `page`, `limit`, `total_pages`)
- สร้าง environment แยก `development`, `staging`, `production`; secret ทุกค่าอยู่ใน secret manager/ตัวแปรแวดล้อม ห้ามใช้ค่า JWT ที่สุ่มใหม่ทุกครั้งใน production
- เพิ่ม migration และ index ที่จำเป็น: reports (`status`, `category`, `created_at`), scans (`user_id`, `created_at`), audit_log (`created_at`, `admin_id`, `action`) และตาราง/field ตาม phase ต่อไป
- กำหนด seed เฉพาะ development และคำสั่ง bootstrap Super Admin ที่บังคับเปลี่ยนรหัสผ่านครั้งแรก ไม่พิมพ์รหัสผ่านหรือ token ลง log

**เกณฑ์รับงาน:** รัน migration จากฐานข้อมูลว่างได้, rollback ที่ทดสอบแล้ว, OpenAPI ตรงกับ frontend และ production start ไม่ทำงานหาก secret หรือ origin ที่จำเป็นหายไป

### Phase 1 — Identity, Super Admin และความปลอดภัย

- แก้ `get_current_admin` ให้ตรวจ `type=access`, `role=admin`, admin มีอยู่/active และ `is_superadmin`; แยก dependency `require_super_admin` ใช้กับทุก `/admin/*`
- เปลี่ยน refresh token เป็น rotating token: เก็บ token id/hash, expiry, revoked_at, replaced_by และเพิกถอน token เก่าทันทีเมื่อ refresh/logout; ส่ง refresh token ผ่าน `HttpOnly`, `Secure`, `SameSite` cookie ใน production และเก็บ access token ระยะสั้นใน memory
- เพิ่ม logout endpoint, session list/revoke, password policy, forced password change, rate limit ที่เข้มกว่าบน login/refresh และ generic login error เพื่อลด account enumeration
- ตั้ง CORS จาก allowlist ของ environment, ใช้ HTTPS/HSTS/cookie security headers, CSP ที่เหมาะกับ Vite build และจำกัด error detail ที่ส่งออกนอกระบบ
- เพิ่มหน้า Profile Settings: แสดงชื่อ/email, เปลี่ยนชื่อ/รหัสผ่าน, ดูและออกจาก session; แทนที่ `alert("coming soon")` ใน Sidebar และใช้ helper `clearAuth()` สำหรับ logout เพื่อเคลียร์ refresh token ด้วย

**เกณฑ์รับงาน:** ผู้ใช้ทั่วไป/บัญชี admin ที่ไม่ใช่ Super Admin เรียก admin API แล้วได้ 403; logout และการปิดบัญชีทำให้ refresh ต่อไม่ได้; login ผิดซ้ำตามเกณฑ์ถูก rate-limit; Profile ทุก action มี audit record

### Phase 2 — Reports moderation ที่ตัดสินใจได้อย่างถูกต้อง

- กำหนด state machine: `pending → reviewing → approved|rejected`; อนุญาต reopen เฉพาะเมื่อระบุเหตุผลและเก็บประวัติ โดย reject/reopen ต้องมี note ตาม policy
- เพิ่ม endpoint รับงาน/ปล่อยงาน review และ field `version` หรือ `updated_at` สำหรับ optimistic concurrency; แจ้งผล 409 เมื่อข้อมูลเปลี่ยนหลังหน้า detail โหลด
- Validate `page >= 1`, จำกัด `limit`, allowlist ค่า status/category/sort, trim/limit search และปรับ query ให้รองรับ PostgreSQL อย่างมี index; เพิ่ม search/filter/sort/pagination ใน Users และ Audit Logs
- ทำ User Detail: สถิติที่คำนวณจริง (scan/report/สถานะแยก), recent activity, ban/unban พร้อมเหตุผล; ห้ามแก้ role ผู้ใช้ผ่าน UI หากไม่มี business requirement เพราะระบบมีผู้ดูแลเพียง Super Admin
- บันทึก audit structured: `entity_type`, `entity_id`, `action`, `before`, `after`, `reason`, `request_id`, `ip`, `user_agent`, `created_at`; ห้ามแก้ไข/ลบจาก Admin UI

**เกณฑ์รับงาน:** list/detail แสดงข้อมูลสัมพันธ์จริง, รายงานที่ถูกเปลี่ยนโดยหน้าต่างอื่นไม่ถูกเขียนทับ, reject โดยไม่มีเหตุผลทำไม่ได้, และทุก transition ตรวจย้อนกลับได้จาก Audit Log

### Phase 3 — Dashboard, global UX และความพร้อมบนอุปกรณ์

- นิยาม KPI ใหม่ร่วมกับธุรกิจ: `active_users_today` ต้องมาจาก event/scan/login ในวันนั้น, ระบุ timezone และสูตรทุก card; เพิ่ม model accuracy/precision/recall เฉพาะเมื่อมีข้อมูล evaluation ที่เชื่อถือได้
- เพิ่ม endpoint health/status ของ worker, queue, database/storage และโมเดล; Dashboard แสดง last refresh, stale state, empty state และ retry
- ทำ global search ให้ค้นหา report/user/scan ID จริงผ่าน endpoint เดียวที่จำกัดสิทธิ์และ debounce/cancel request; ลิงก์ผลไปยังหน้า detail ที่ถูกต้อง
- Notification แสดงเฉพาะเหตุการณ์จาก backend (เช่น report รอ review, export สำเร็จ/ล้มเหลว) หรือซ่อนปุ่มจนกว่ามีระบบ notification จริง
- ทำ Users, Models และ Audit Logs เป็น responsive card/table ตาม breakpoint, รองรับ keyboard, focus management ของ modal, label/ARIA ที่ถูกต้อง และการแสดงผลภาษาไทย/อังกฤษที่ไม่ล้น

**เกณฑ์รับงาน:** Dashboard มีนิยาม KPI ตรวจสอบได้, global search ไม่มีผลลวง, ทุกหน้าหลักใช้งานที่ความกว้าง 320px และ desktop ได้, และ keyboard ใช้ modal/เมนู/ตารางได้ครบ

### Phase 4 — Model operations ที่ปลอดภัย

- ขยาย `ModelVersion` ด้วย artifact checksum, framework/runtime compatibility, metrics, training/evaluation dataset reference, created_by, status และ deployment history
- เพิ่มขั้นตอน deploy: ตรวจ artifact อยู่จริงและ checksum ถูกต้อง → validate compatibility → warm-up/inference health check → ยืนยันการสลับ active model แบบ transaction/lock → monitor หลัง deploy; ห้ามมี active model มากกว่าหนึ่ง
- มี dry run, rollback ไป version ก่อนหน้า, deploy reason และผล health check ที่แสดงใน UI; บันทึกทุกขั้นใน Audit Log
- ปิดปุ่ม deploy ระหว่างงานกำลังทำ, แสดงผลลัพธ์/ข้อผิดพลาดที่ actionable และใช้ background job หาก warm-up นาน

**เกณฑ์รับงาน:** deploy artifact ที่หาย/ไม่ผ่าน health check ไม่เปลี่ยน active model; deploy พร้อมกันไม่ทำให้สถานะเสีย; rollback สำเร็จและมีประวัติครบ

### Phase 5 — Dataset export ที่ควบคุมได้และขยายได้

- ยืนยัน policy ก่อน export: export ได้เฉพาะรายงาน `approved` ที่ `allow_research_use=true`; กรองช่วงวันแบบ inclusive และตรวจ `from_date <= to_date`; reject `format` ที่ไม่รองรับ
- แทนการเก็บ ZIP ทั้งก้อนใน RAM ด้วย export job: `queued/running/succeeded/failed/expired`, progress, จำนวน/ขนาดจริง, error ที่ปลอดภัย และไฟล์ใน private object storage พร้อม signed URL อายุสั้น
- กำหนด maximum rows/file size/concurrent jobs, pagination สำหรับ preview, content-type/extension ที่ตรวจจริง และ manifest ที่มี schema version, filter, checksum และรายการไฟล์ที่ export ได้จริง
- เพิ่ม Export History ที่ดึงจากฐานข้อมูล, ดาวน์โหลดซ้ำได้ระหว่าง retention, ยกเลิก job ได้, และทำ cleanup ไฟล์ตาม retention; audit ต้องบันทึก filter, จำนวนผลลัพธ์, job id และผลลัพธ์

**เกณฑ์รับงาน:** ไฟล์ที่ไม่มี consent ไม่อยู่ใน ZIP, dataset ใหญ่ไม่ทำให้ API worker memory สูงผิดปกติ, signed URL หมดอายุตามกำหนด และ manifest ตรงกับเนื้อหา ZIP ทุกไฟล์

### Phase 6 — Audit, observability และการปฏิบัติการ

- ทำ Audit Log เป็น append-only (DB permission/trigger หรือแยก audit store), แยก PII ออกจาก details และกำหนด retention/การเข้าถึงตามนโยบาย
- เพิ่ม request/correlation ID, structured application log, metrics (latency/error/DB pool/export/model deploy), health/readiness endpoint และ alert สำหรับ login ผิดปกติ, export fail, deploy fail, queue ค้าง และ disk/storage ใกล้เต็ม
- จัดทำ runbook สำหรับ: ปิด Super Admin, revoke session, rollback model, export fail, database restore และ incident response
- สร้าง backup/restore ที่เข้ารหัสและทดสอบ restore บน staging, พร้อม monitoring ของ migration และ storage lifecycle

**เกณฑ์รับงาน:** สามารถตามหนึ่ง action จาก UI → request ID → audit/log ได้, alert ทดสอบส่งถึงช่องทางที่กำหนด, และ restore backup บน staging ผ่านตาม RPO/RTO ที่ตกลง

## แผนทดสอบและ Release Gate

| ระดับ | สิ่งที่ต้องทดสอบ | เกณฑ์ผ่าน |
|---|---|---|
| Unit | JWT/role/superadmin, validation, state transition, export policy, deploy validation | ครอบคลุม success/failure/boundary ทุกกฎธุรกิจสำคัญ |
| API integration (PostgreSQL จริง) | ทุก `/admin/*`, pagination/filter/search, transaction, migration, storage adapter | 200/400/401/403/404/409/429 ถูกต้อง และ schema ไม่เปลี่ยนโดยไม่ตั้งใจ |
| Frontend component | loading/error/empty/success, debounce/cancel, modal focus, token refresh/logout | ไม่มี console error; text/action เข้าถึงได้ด้วย keyboard |
| E2E browser | Login → Dashboard → review report → audit; ban/unban; deploy/rollback; export job/download; profile/logout | ผ่านบน Chromium desktop และ mobile viewport อย่างน้อย 320px |
| Security | auth bypass, revoked refresh reuse, CORS, rate limit, IDOR, XSS/unsafe URL, dependency scan | ไม่มี high/critical ที่ยังไม่ยอมรับความเสี่ยงเป็นลายลักษณ์อักษร |
| Performance | report/audit list, search, large export, deploy lock | หน้า list/search อยู่ใน SLO ที่ตกลง; งานหนักทำผ่าน job และไม่ block API |
| UAT | Super Admin ทำตาม scenario จริงพร้อมข้อมูลทดสอบ | ทุก acceptance criterion ของแต่ละ phase ผ่านและมีหลักฐานผลทดสอบ |

ก่อน release ต้องผ่าน `npm run lint` และ `npm run build` สำหรับ `admin-portal`, รัน `pytest` สำหรับ Server, รัน E2E และ migration test ใน CI. CI ต้อง block การ merge เมื่อ test/lint/build/security scan ล้มเหลว

## ลำดับการส่งมอบที่แนะนำ

1. Phase 0–1 ก่อน: เป็นเงื่อนไขความปลอดภัยที่ต้องมี ก่อนเปิด admin ให้ผู้ใช้จริง
2. Phase 2 และ Phase 3: ทำให้ workflow รายงานและการใช้งานรายวันถูกต้องและตรวจสอบได้
3. Phase 4 และ Phase 5: เปิดใช้งาน model deployment และ dataset export หลังมี guardrail ครบ
4. Phase 6 และ Release Gate: ทำ observability, runbook, backup/restore, UAT และ production rollout แบบ staging → production พร้อมแผน rollback

## สิ่งที่ตั้งใจไม่ทำในขอบเขตนี้

- ไม่เพิ่มบทบาท Moderator/Analyst หรือระบบจัดการสิทธิ์หลายระดับ เพราะขอบเขตที่ยืนยันคือ Super Admin เท่านั้น
- ไม่เปิด export สาธารณะ, ไม่ export ข้อมูลที่ไม่ได้ให้ consent เพื่อการวิจัย, และไม่ให้ frontend ตัดสินสิทธิ์แทน backend
- ไม่แสดง metric ความแม่นยำของโมเดลจนกว่าจะมี evaluation data และนิยาม metric ที่ตรวจสอบย้อนกลับได้
