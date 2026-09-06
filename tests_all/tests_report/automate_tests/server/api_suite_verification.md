## 2026-09-06 05:07 +07 - Backend API Automated Test Suite (tests_all/automate_tests)

- Target: tests_all/automate_tests/tests/api/
- Command: `./run.sh api`
- Result: PASS
- Summary: Total: 15 | Passed: 15 | Failed: 0 | Skipped: 0 | Duration: 16.96s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **test_admin_requires_auth (`tests/api/test_admin.py`)**:
  - พฤติกรรมที่ผ่าน: ยิงคำขอไปยัง Endpoint ของ Admin โดยไม่แนบ Bearer Token แล้วได้รับ HTTP 401 Unauthorized ตามข้อกำหนดความปลอดภัย
- **test_rate_limit_headers_present (`tests/api/test_admin.py`)**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบ Response Headers พบ Rate Limit Headers จาก Slowapi ครบถ้วน (`X-RateLimit-Limit`, `X-RateLimit-Remaining`)
- **test_register_login_me_flow (`tests/api/test_auth_flow.py`)**:
  - พฤติกรรมที่ผ่าน: สมัครสมาชิกใหม่ ล็อกอินรับ Access Token และเรียกดูข้อมูลโปรไฟล์ `/me` ได้รับข้อมูลตรงตามผู้ใช้ที่สร้าง
- **test_login_wrong_password (`tests/api/test_auth_flow.py`)**:
  - พฤติกรรมที่ผ่าน: ส่งรหัสผ่านผิดไปยัง `/login` ได้รับ HTTP 401 พร้อมข้อความแจ้งข้อผิดพลาดถูกต้อง ไม่เปิดเผยข้อมูลภายใน
- **test_register_duplicate (`tests/api/test_auth_flow.py`)**:
  - พฤติกรรมที่ผ่าน: สมัครสมาชิกด้วยอีเมลเดิมซ้ำ ระบบปฏิเสธด้วย HTTP 400 Bad Request ป้องกันข้อมูลผู้ใช้ซ้ำซ้อน
- **test_unauthorized_access (`tests/api/test_auth_flow.py`)**:
  - พฤติกรรมที่ผ่าน: เข้าถึง Protected Endpoint โดยไม่มี Token หรือ Token ไม่ถูกต้อง ระบบตอบกลับ HTTP 401
- **test_health_status (`tests/api/test_health.py`)**:
  - พฤติกรรมที่ผ่าน: เรียก `GET /health` ได้รับ HTTP 200 พร้อมสถานะ `{"status": "healthy"}` หรือ `{"status": "ok"}`
- **test_health_security_headers (`tests/api/test_health.py`)**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบ Security Headers ในการตอบกลับ เช่น `X-Content-Type-Options`, `X-Frame-Options` ครบถ้วน
- **test_api_v1_not_found (`tests/api/test_health.py`)**:
  - พฤติกรรมที่ผ่าน: ยิงคำขอไปยัง Endpoint ที่ไม่มีอยู่จริง ได้รับ HTTP 404 Not Found ตามมาตรฐาน REST API
- **test_history_list (`tests/api/test_history.py`)**:
  - พฤติกรรมที่ผ่าน: เรียกดูประวัติการสแกนของผู้ใช้ ได้รับรายการประวัติในรูปแบบ JSON Array ถูกต้องตาม DTO
- **test_report_create (`tests/api/test_history.py`)**:
  - พฤติกรรมที่ผ่าน: สร้างรายงานข้อร้องเรียน (Report) ลงฐานข้อมูลสำเร็จ บันทึกความสัมพันธ์กับ Scan ID ได้รับ HTTP 200/201
- **test_report_categories (`tests/api/test_history.py`)**:
  - พฤติกรรมที่ผ่าน: ตรวจสอบหมวดหมู่รายงานที่ส่งเข้ามา ตรงกับ Enumeration ในระบบ
- **test_scan_upload_and_get_result (`tests/api/test_scan_workflow.py`)**:
  - พฤติกรรมที่ผ่าน: อัปโหลดรูปภาพทดสอบผ่าน `POST /api/v1/scan/` ระบบประมวลผลและส่งผลลัพธ์คะแนนความเสี่ยง (Risk Score) และ Heatmap กลับมาครบถ้วน
- **test_scan_without_auth_should_fail (`tests/api/test_scan_workflow.py`)**:
  - พฤติกรรมที่ผ่าน: อัปโหลดภาพสแกนโดยไม่แนบ Token ระบบปฏิเสธทันทีด้วย HTTP 401
- **test_scan_invalid_file (`tests/api/test_scan_workflow.py`)**:
  - พฤติกรรมที่ผ่าน: ส่งไฟล์ที่ไม่ใช่รูปภาพหรือไฟล์ที่เสียหาย ระบบตรวจจับและปฏิเสธด้วย HTTP 400 / 422

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)
