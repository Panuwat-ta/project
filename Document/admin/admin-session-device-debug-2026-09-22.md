# รายงาน Debug: อุปกรณ์ที่เข้าสู่ระบบ (Admin Session Devices)

วันที่: 22 กันยายน 2569
Baseline: `fce13934` บน branch `refactoring-admin`
ขอบเขต: Admin Profile, `/admin/me`, `/admin/sessions`, Admin access policy, refresh rotation และ WebSocket admin auth

## สรุปผล

รอบนี้ยืนยันและแก้ confirmed P2 จำนวน 3 จุด โดยไม่เพิ่ม database migration และไม่เปลี่ยนรูปแบบ access/refresh token

1. `GET /admin/sessions` เดิมคืน revoked/expired session จน UI อาจแสดงว่า “เชื่อมต่ออยู่” ทั้งที่ใช้ต่อไม่ได้
2. `resolve_admin_access()` เดิมตั้ง `last_used_at` เฉพาะใน SQLAlchemy object แต่ไม่มี persistence owner ที่แน่นอนสำหรับ HTTP requests
3. Frontend แสดง “เข้าสู่ระบบล่าสุด” จาก `profile.last_login_at` แต่ Backend เดิมไม่มี field/source นี้

หลังแก้ targeted auth/session suite, WebSocket suite, full Server, Admin tests และ runtime integration ผ่านทั้งหมดตามรายละเอียดด้านล่าง
## Finding 1 — revoked/expired session ถูกแสดงเป็นอุปกรณ์ที่ยังเชื่อมต่อ

ก่อนแก้ query ของ `/api/v1/admin/sessions` กรองเพียง `admin_id` ทำให้ revoked และ expired rows ถูกส่งกลับไปด้วย ขณะที่ Frontend ใช้เพียง `is_current`; session อื่นทุกตัวจึงถูกแสดงเป็น “เชื่อมต่ออยู่” และมีปุ่ม revoke ซ้ำ

RED evidence:
- compiled SQL ไม่มี `REVOKED_AT IS NULL`
- compiled SQL ไม่มี `EXPIRES_AT > ...`

แก้ที่ `server/app/api/v1/admin.py` ให้ query เฉพาะ:
- `AdminSession.revoked_at IS NULL`
- `AdminSession.expires_at > datetime.now(TH_TIMEZONE)`

ผลคือ `items` และ `total` ของหน้า “อุปกรณ์ที่เข้าสู่ระบบ” หมายถึง active sessions จริง

## Finding 2 — `last_used_at` ไม่ persist แบบ deterministic

`resolve_admin_access()` เดิมทำ `session.last_used_at = now` แต่ `get_db()` เพียง yield `AsyncSession` และไม่ auto-commit จึงมี GET requests ที่ปิด transaction โดยไม่บันทึกเวลาล่าสุด

แก้ให้ `resolve_admin_access()` เป็น persistence owner และ commit หลัง validation สำเร็จ ทั้ง HTTP และ WebSocket จึงใช้ contract เดียวกัน
ระหว่าง full regression พบ WebSocket commit ซ้ำ 2 ครั้ง เพราะ `ws.py` ยัง commit หลัง `resolve_admin_access()` อีกชั้น จึงลบ duplicate commit และยืนยัน WebSocket targeted tests 5/5 PASS

## Finding 3 — “เข้าสู่ระบบล่าสุด” ไม่มี source จริงจาก Backend

Frontend ใช้ `profile.last_login_at` แต่ `/admin/me` เดิมส่งเพียง `id`, `email`, `full_name`, `role`, `is_superadmin`

เพื่อไม่เพิ่ม column ใหม่ใน `admins` ใช้ข้อมูลที่มีอยู่ใน `admin_sessions` เป็น source-of-truth:
- Login ใหม่สร้าง root session
- Refresh rotation ทำให้ predecessor ชี้ `replaced_by` ไป child session
- `get_admin_last_login_at()` เลือก `MAX(created_at)` ของ session id ที่ไม่ได้เป็น `replaced_by` ของ session ก่อนหน้า
- subquery กรอง `replaced_by IS NOT NULL` เพื่อหลีกเลี่ยง SQL `NOT IN (NULL)`

เพิ่ม `last_login_at: Optional[datetime]` เฉพาะ `AdminProfileResponse` และใช้ `_profile_payload()` สำหรับ `/admin/me`; Login/Refresh response เดิมไม่ถูกขยาย

## RED → GREEN

RED ที่ยืนยัน product bug:
- session query test FAIL เพราะไม่มี revoked/expired filters
- access policy test FAIL เพราะ `commit_count == 0`
- last-login test FAIL ด้วย `AttributeError` เพราะ helper ยังไม่มี

GREEN หลังแก้:
- auth/session targeted: 48/48 PASS
- WebSocket targeted: 5/5 PASS
## PostgreSQL + ASGI Runtime Integration

ทดสอบกับ PostgreSQL จริงโดยสร้าง temporary Admin/session chain ภายใน process โดยไม่สร้าง password สำหรับ login จากนั้นเรียก FastAPI ผ่าน ASGI ด้วย signed access token ชั่วคราว

Fixture มี root session ที่ถูก rotate, current active session และ expired session ที่เก่ากว่า root login ล่าสุด

ผลที่ยืนยัน:
- `RUNTIME_ACTIVE_SESSION_COUNT=1`
- `RUNTIME_REVOKED_FILTERED=1`
- `RUNTIME_EXPIRED_FILTERED=1`
- `RUNTIME_LAST_USED_PERSISTED=1`
- `RUNTIME_LAST_LOGIN_ROOT_MATCH=1`
- Cleanup: `RUNTIME_CLEANUP_SESSIONS=0`, `RUNTIME_CLEANUP_ADMIN=0`

## Browser / WebMCP Runtime

ใช้ full-App runtime matrix บน Chrome/CDP + WebMCP testing mode โดย mock เฉพาะ Admin API/WebSocket แบบ read-only เพื่อทดสอบ UI โดยไม่ใช้ credential จริง

Matrix 10 routes × 2 viewports × 2 themes = 40 cases; รอบ final PASS 40/40

เฉพาะ `/admin/profile` ผ่าน 4/4 combinations (390x844/1440x1000 × dark/light):
- เห็น `เซสชันปัจจุบัน`
- เห็น active session อื่นเป็น `เชื่อมต่ออยู่`
- เห็น `เข้าสู่ระบบล่าสุด` เป็นเวลาไทย `Asia/Bangkok`
- horizontal overflow = false
- console error = 0
- WebMCP `get_admin_page_context` ทำงานและ path/theme ตรง
Credential-backed Chrome DevTools MCP attempt ในรอบนี้ถูก safety layer บล็อกก่อน execute จึงไม่ถูกนับเป็น PASS/FAIL และไม่มี browser state/credential ถูกเปลี่ยนจาก attempt นั้น

## Final Automated Verification

- Admin `npm test`: 40/40 PASS
- Admin `npm run lint`: PASS
- Admin `npm run build`: PASS, 2,485 modules, 442 ms
- Auth/session targeted: 48/48 PASS
- WebSocket targeted: 5/5 PASS
- Server full pytest: 133 passed / 3 skipped / 0 failed, 13.12 s
- WebMCP/CDP full-App matrix: 40/40 PASS
- `git diff --check`: PASS ก่อน close-out documentation

## Independent Review (`agy`)

เรียก read-only final review บน current diff ด้วย `agy --print-timeout 0 --mode plan --effort high --sandbox`

ผลจบสมบูรณ์ใน 339.40 s: **`NO_CONFIRMED_P0_P1_P2_P3`**

`agy` ตรวจยืนยัน active-session filtering, transaction ownership, root-session derivation, HTTP/WebSocket auth compatibility, `NOT IN (NULL)` protection และ frontend runtime assertions ตรงกับ self-review

Residual P4 ที่ยังไม่จัดเป็น confirmed bug:
- การ commit `last_used_at` ทุก authenticated request เพิ่ม write rate; หากโหลดสูงค่อยพิจารณา throttling แยกจาก correctness
- การเก็บ IP ใช้ `request.client.host`; ความแม่นยำหลัง reverse proxy ขึ้นกับ trusted proxy configuration
- `NOT EXISTS` สามารถใช้แทน `NOT IN` เพื่อ future-proof เพิ่มได้ แต่ implementation ปัจจุบันปลอด `NULL` แล้ว

ไม่มี commit/push/PR/merge/deploy จากงานรอบนี้
