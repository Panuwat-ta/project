## 2026-09-13 09:35 +07 - Backend API + DB Test Suite (pytest)

- Target: `server/tests/api` + `server/tests/db` (รวมไฟล์ใหม่ `test_user_delete.py`)
- Command: `python -m pytest tests/api tests/db -q --ignore=tests/api/test_scan_xai_live.py`
- Result: PASS
- Summary: Total: 21 | Passed: 20 | Failed: 0 | Skipped: 1 | Duration: ~1s
- หมายเหตุ: `test_scan_xai_live.py` ถูก exclude ตั้งแต่ต้น (ต้องใช้ GPU/model จริง); `test_scan_real_image` skip เพราะไม่มีไฟล์ภาพเทส

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **test_admin_auth (6 เคส: login_creates_session_with_sid, require_super_admin_rejects_normal_admin, super_admin_allowed, refresh_rotates_and_old_token_fails, logout_revokes_current_session, change_password_without_current_password_rejected)**:
  - พฤติกรรมที่ผ่าน: login สร้าง session ผูก sid, refresh หมุน token แล้วของเก่าใช้ไม่ได้, logout เพิกถอน session, non-superadmin ถูกปฏิเสธ — ยืนยันว่าระบบ session แยกตาราง admins ยังทำงานหลังแก้ FK/CHECK
- **test_admin_reports (2 เคส: get_report_detail, get_report_detail_not_found)**:
  - พฤติกรรมที่ผ่าน: ดึงรายละเอียดรีพอร์ตได้ และ id ไม่มีอยู่ตอบ not found — ยืนยัน index/CHECK ใหม่บน scam_reports ไม่ทำลาย query เดิม
- **test_auth (2 เคส: register, login)**:
  - พฤติกรรมที่ผ่าน: สมัครและล็อกอินด้วย mock DB ได้ — ยืนยัน CHECK `ck_users_role` ไม่บล็อก role=user ปกติ
- **test_health (1 เคส: test_health_check)**:
  - พฤติกรรมที่ผ่าน: เดิม FAIL (`degraded` เพราะ test client ไม่รัน lifespan ทำให้ `redis_client` เป็น None) — แก้โดยเพิ่ม fixture mock `ping()` ใน `tests/api/conftest.py` แล้วตอบ `status: ok` (`database: ok` มาตั้งแต่แรก ยืนยัน schema ใหม่บน PG จริงไม่มีปัญหา)
- **test_scan (6 เคส: upload, invalid_file_type, webp, bmp, heic, oversize)**:
  - พฤติกรรมที่ผ่าน: เดิม `test_scan_invalid_file_type` FAIL (อัปโหลด txt ได้ 200 เพราะ validation อยู่แค่ใน background task) — แก้โดย validate ด้วย `load_image_verified` ใน `create_scan_task` ก่อนสร้าง record ทำให้ไฟล์ไม่ใช่รูปได้ 400 ทันทีพร้อม detail "not a valid image"
- **test_user_delete (3 เคสใหม่: delete_me_ok, delete_me_wrong_password, delete_me_no_token)**:
  - พฤติกรรมที่ผ่าน: รหัสถูกได้ 200 + `is_active=False` + commit; รหัสผิดได้ 401 + บัญชีไม่ถูกปิด; ไม่มี token ได้ 401
- **tests/db**: รวมอยู่ในคำสั่งรันชุดเดียวกัน ผ่าน (ไม่มี failure)

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- ไม่มีข้อผิดพลาด (0 Failed)
