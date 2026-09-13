# OWASP Top 10 กับการทดสอบ — ทดสอบยังไง ทดสอบอะไร ส่วนไหน

เอกสารนี้อธิบายวิธีนำ OWASP Top 10 (2021) มาใช้กับการทดสอบอัตโนมัติของโปรเจกต์:
รันด้วย `python -m pytest tests/api tests/db -q --ignore=tests/api/test_scan_xai_live.py` ใน `server/`

## หลักการ

- ทุกเคส security ผูกกับหมวด OWASP ตรงตัว (ชื่อเคสขึ้นต้น `test_a01_...` ฯลฯ) อยู่ใน
  `server/tests/api/test_security_owasp.py` — เพิ่มเคสใหม่ให้ตั้งชื่อแบบเดียวกัน
- เทสใช้ mock DB/session (ไม่แตะข้อมูลจริง) ยกเว้น live verify บน PG จริงทำแยกเป็นสคริปต์ชั่วคราวแล้วลบ
- ผลรันล่าสุดดู `tests_report/server/pytest-api-db-2026-09-13.md`

## ตาราง mapping: หมวด → ทดสอบอะไร → ส่วนไหน

| หมวด OWASP | ทดสอบอะไร (คาดหวัง) | ไฟล์/เคส |
| :--- | :--- | :--- |
| A01 Access Control | เปิด scan ของคนอื่น → 403 (ownership check) | `test_security_owasp.py::test_a01_idor_other_user_scan_forbidden` |
| A01 | เรียก endpoint ต้อง auth ไม่มี token → 401 | `test_a01_scan_requires_auth`, `test_user_delete.py::test_delete_me_no_token` |
| A01 | ลบบัญชี: รหัสถูก → 200 + ปิดบัญชี, รหัสผิด → 401 + ไม่ปิด | `test_user_delete.py` (3 เคส) |
| A03 Injection | login ใส่ `' OR '1'='1` → 401 ไม่ใช่ 500 (parameterized) | `test_a03_login_sqli_returns_401_not_500` |
| A03/A04 | อัปโหลดไฟล์ไม่ใช่รูป → 400, ไฟล์เกิน → 413, ไฟล์ว่าง → 400 (validate ก่อนสร้าง record) | `test_scan.py` (invalid_file_type, oversize) + `test_a04_empty_file_rejected` |
| A07 Auth | สมัครรหัสสั้นกว่า 8 → 422 (policy: 8–128 ตัวอักษร) | `test_a07_weak_password_rejected` |
| A07 | login/refresh บัญชีถูกปิด → 403 | ผ่าน `is_active` check (คลุมโดย logic เดียวกับ delete test) |
| A04 Rate limit | ยิงเกินโควตา → 429 | ยังไม่มีเคสอัตโนมัติ (fixture reset limiter มีแล้วใน conftest — เพิ่มได้) |
| A09 Logging | audit append-only (ห้าม UPDATE/DELETE) | ตรวจระดับ DB ด้วย trigger ตรง (live verify, ไม่ใช่ pytest) |
| A02/A08/A10 | bcrypt/JWT/backup/SSRF | ตรวจด้วย code review + live verify (ไม่มีเคส pytest เพราะเป็นคุณสมบัติ config ไม่ใช่ behavior ต่อ request) |
| A05 Misconfig | CORS origins, error ไม่ leak | ต้องยืนค่าที่ deploy env (ตรวจอัตโนมัติไม่ได้) |
| A06 Components | `npm audit` / `pip audit` | ยังไม่เข้ารันเนอร์ — รันมือก่อน release |

## ส่วนที่เทสไม่ครอบ (ต้องตรวจมือ/เครื่องจริง)

- Mobile: cleartext HTTP, signing, backup rules, pinning (ต้อง build + ตรวจ device/emulator)
- Admin-portal: รหัสใน `.env`, token ใน WS URL (code review — รายละเอียดใน `10_OWASP_Audit_2026-09-13.md`)
- `test_scan_xai_live.py` + `test_scan_real_image`: ต้อง GPU/ไฟล์ภาพจริง (skip ใน CI)

## เพิ่มเคสใหม่ยังไง

1. สร้างเคสใน `test_security_owasp.py` ตั้งชื่อ `test_aXX_...` ตามหมวด
2. ใช้ mock session (`_mock_session` + `_empty_result`) ไม่เขียน DB จริง
3. รันไฟล์เดียวก่อน (`pytest tests/api/test_security_owasp.py -q`) แล้วรันทั้ง suite กัน regression
4. อัปเดตตารางข้างบน + `tests_report/server/` ตามกฎ repo (ผลเทสภาษาไทย)
