# Admin API Automated Test Reports

## 2026-09-04 15:15 +07 - Admin Auth & Reports API Test Suite

- Target: `server/tests/api/test_admin_auth.py`, `server/tests/api/test_admin_reports.py`
- Command: `server/venv/bin/pytest server/tests/api/test_admin_auth.py server/tests/api/test_admin_reports.py -v`
- Result: PASS
- Summary: Total: 8 | Passed: 8 | Failed: 0 | Skipped: 0 | Duration: 0.14s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **test_login_creates_session_with_sid**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบการส่งคำขอ Login ของ Admin ส่งคืน access_token และกำหนดคุกกี้ `admin_refresh_token` สำเร็จ ค่า `sid` (Session ID) ที่ถูกถอดรหัสจาก JWT payload ตรงกับค่า `sid` ที่บันทึกในฐานข้อมูลเซสชัน
- **test_require_super_admin_rejects_normal_admin**:
  - พฤติกรรมที่ผ่าน: ระบบความปลอดภัย RBAC ตรวจสอบว่าบัญชี Admin ทั่วไปไม่สามารถเข้าถึงข้อมูลเฉพาะของ Super Admin ได้ โดยระบบส่งคืนสถานะ HTTP 403 Forbidden อย่างถูกต้อง
- **test_super_admin_allowed**:
  - พฤติกรรมที่ผ่าน: บัญชีผู้ดูแลระบบระดับ Super Admin สามารถเข้าถึงข้อมูล `/api/v1/admin/me` ได้รับสถานะ HTTP 200 และได้ payload ระบุ `is_superadmin: true`
- **test_refresh_rotates_and_old_token_fails**:
  - พฤติกรรมที่ผ่าน: การทำงานของ Refresh Token Rotation ทำงานถูกต้อง เมื่อนำ Token เดิมมารีเฟรชครั้งแรกผ่านได้ Token ชุดใหม่ และเซสชันเดิมถูกเพิกถอน (`revoked = true`) เมื่อพยายามใช้ Token เดิมซ้ำเป็นครั้งที่สอง ระบบปฏิเสธด้วยสถานะ HTTP 401 Unauthorized
- **test_logout_revokes_current_session**:
  - พฤติกรรมที่ผ่าน: คำขอ Logout ส่งผลให้ระบบสั่งเพิกถอนเซสชันของ Admin ตาม `sid` ปัจจุบันในฐานข้อมูลทันที และตอบกลับสถานะ HTTP 200 OK
- **test_change_password_without_current_password_rejected**:
  - พฤติกรรมที่ผ่าน: การเปลี่ยนรหัสผ่านโดยไม่ส่งรหัสผ่านเดิมเพื่อยืนยันตัวตน จะถูกปฏิเสธด้วยสถานะ HTTP 400/422 ป้องกันการแก้ไขรหัสผ่านโดยไม่ได้รับอนุญาต
- **test_get_report_detail**:
  - พฤติกรรมที่ผ่าน: การเรียกดูรายละเอียดรายงานสแกนเคสต้องสงสัยส่งคืนข้อมูลครบถ้วน ทั้งข้อมูลรายงาน สถานะการตรวจสอบ และผลการวิเคราะห์
- **test_get_report_detail_not_found**:
  - พฤติกรรมที่ผ่าน: การเรียกดูรายงานด้วยไอดีที่ไม่มีอยู่จริงในระบบ ระบบตอบกลับด้วย HTTP 404 Not Found พร้อมระบุข้อความแจ้งเตือนถูกต้อง

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)
