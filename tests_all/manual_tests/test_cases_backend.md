# ชุดกรณีทดสอบ: ระบบบริการหลังบ้านและฐานข้อมูล (Backend API & Database - FastAPI)

- **System**: ScamGuard Backend Service
- **Framework**: FastAPI (Asynchronous Python 3.10+), SQLAlchemy 2.0 ORM, Pydantic V2
- **Database & Cache**: PostgreSQL 15 (Alpine), Redis 7 (Alpine)
- **Version**: 1.0.0
- **Status**: Baseline

---

## 1. หมวดหมู่การยืนยันตัวตนและการจัดการสิทธิ์ (Authentication & RBAC)

### TC-BE-AUTH-01: การลงทะเบียนผู้ใช้งานใหม่ผ่าน API (User Registration API)
- **Module / Feature**: Auth / Register Endpoint
- **Requirement ID**: FR-AUTH-01
- **Test Type**: Functional / API
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. PostgreSQL Container และ FastAPI Service ทำงานปกติ
- **Test Data**:
  - Endpoint: `POST /api/v1/auth/register`
  - Payload:
    ```json
    {
      "email": "be_test_user@scamguard.local",
      "password": "StrongPassword123!",
      "full_name": "Backend Test User"
    }
    ```
- **Test Steps**:
  1. ยิง HTTP POST ไปยัง `/api/v1/auth/register` พร้อม JSON Payload
  2. ตรวจสอบข้อมูลในตาราง `users` ของฐานข้อมูล
- **Expected Results**:
  1. ได้รับ HTTP Status Code: `201 Created`
  2. Response Body มี `user_id`, `email`, `created_at` (ไม่มี Plaintext Password คืนกลับมา)
  3. ในตาราง `users` คอลัมน์ `hashed_password` ต้องถูกเข้ารหัสด้วย bcrypt โดยมีความยาวแฮชมาตรฐาน
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

### TC-BE-AUTH-02: การเข้าสู่ระบบเพื่อรับ JWT Tokens (Login & Token Generation)
- **Module / Feature**: Auth / Login Endpoint
- **Requirement ID**: FR-AUTH-02, NFR-SEC-02
- **Test Type**: Functional / API
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มีผู้ใช้ `be_test_user@scamguard.local` ในระบบ
- **Test Data**:
  - Endpoint: `POST /api/v1/auth/login`
  - Payload:
    ```json
    {
      "email": "be_test_user@scamguard.local",
      "password": "StrongPassword123!"
    }
    ```
- **Test Steps**:
  1. ส่งคำขอ Login ไปยัง Backend
- **Expected Results**:
  1. ได้รับ HTTP Status Code: `200 OK`
  2. Response Body ส่งคืนโครงสร้าง DTO:
     ```json
     {
       "access_token": "eyJhbGciOiJIUzI1...",
       "refresh_token": "eyJhbGciOiJIUzI1...",
       "token_type": "bearer",
       "expires_in": 3600
     }
     ```
  3. Access Token ถอดรหัสได้ `sub` ตรงกับ User ID และมีค่า `exp` กำหนดวันหมดอายุ
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

### TC-BE-AUTH-03: การต่ออายุโทเค็น (Refresh Token Flow)
- **Module / Feature**: Auth / Refresh Token Endpoint
- **Requirement ID**: FR-AUTH-04
- **Test Type**: Functional / Security
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. มี Valid Refresh Token จากการล็อกอิน
- **Test Data**:
  - Endpoint: `POST /api/v1/auth/refresh`
  - Headers: `Authorization: Bearer <valid_refresh_token>`
- **Test Steps**:
  1. ส่งคำขอเพื่อขอ Access Token ชุดใหม่
- **Expected Results**:
  1. ได้รับ HTTP Status Code: `200 OK`
  2. ได้รับ `access_token` ใหม่ที่มีอายุการใช้งานนับจากเวลาปัจจุบัน
  3. ไม่จำเป็นต้องให้ผู้ใช้กรอกรหัสผ่านใหม่
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

### TC-BE-AUTH-04: การปฏิเสธคำขอเมื่อ Token หมดอายุหรือไม่ถูกต้อง (Unauthorized Access)
- **Module / Feature**: Auth / Token Validation Middleware
- **Requirement ID**: NFR-SEC-02
- **Test Type**: Security / Negative
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. เตรียม Expired Token หรือ Invalid Token
- **Test Data**:
  - Endpoint: `GET /api/v1/auth/me`
  - Headers: `Authorization: Bearer invalid_or_expired_token`
- **Test Steps**:
  1. ยิงคำขอไปยัง Protected Endpoint
- **Expected Results**:
  1. ระบบตอบกลับด้วย HTTP Status Code: `401 Unauthorized`
  2. Response Body: `{"detail": "Could not validate credentials"}` หรือ `{"detail": "Token expired"}`
  3. ไม่สามารถเข้าถึงข้อมูลเบื้องหลังได้
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

## 2. หมวดหมู่การอัปโหลดและตรวจสอบไฟล์รูปภาพ (Scan & File Validation API)

### TC-BE-SCAN-01: การอัปโหลดภาพและรับผลการวิเคราะห์ (Normal Scan Flow)
- **Module / Feature**: Scan / Image Scan Endpoint
- **Requirement ID**: FR-INPUT-04, FR-SYS-07
- **Test Type**: Integration / API
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มี Bearer Token ที่ถูกต้องของผู้ใช้
  2. รูปภาพตัวอย่างที่ถูกต้องตามมาตรฐาน (เช่น `sample.jpg`, ขนาด 500 KB)
- **Test Data**:
  - Endpoint: `POST /api/v1/scan/`
  - Content-Type: `multipart/form-data`
  - File: `sample.jpg`
- **Test Steps**:
  1. แนบไฟล์รูปภาพใน Form Field `file`
  2. ส่งคำขอพร้อม Authorization Header
- **Expected Results**:
  1. ได้รับ HTTP Status Code: `200 OK`
  2. Response Body ประกอบด้วย:
     - `analysis_id`: รหัสการสแกน (UUID v4)
     - `overall_risk_score`: ตัวเลขอัตราความเสี่ยง 0 – 100
     - `risk_level`: ระดับความเสี่ยง (`Low`, `Medium`, หรือ `High`)
     - `breakdown`: คะแนนจำแนก Textual, Source, Visual
     - `heatmap_url`: URL สำหรับดาวน์โหลดภาพ Heatmap
  3. ข้อมูลถูกบันทึกลงในตาราง `scans` ของ PostgreSQL พร้อมเวลาที่บันทึก
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

### TC-BE-SCAN-02: การปฏิเสธไฟล์ที่มีขนาดเกินขีดจำกัด 10MB (Server-side File Size Enforcement)
- **Module / Feature**: Scan / Size Enforcement
- **Requirement ID**: FR-INPUT-05
- **Test Type**: Boundary / Negative
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. เตรียมไฟล์ภาพจำลองขนาด 10.5 MB
- **Test Data**:
  - Endpoint: `POST /api/v1/scan/`
  - File: ขนาด 10.5 MB
- **Test Steps**:
  1. ยิงคำขออัปโหลดไฟล์ขนาดเกิน 10MB เข้าสู่ Endpoint
- **Expected Results**:
  1. Backend ปฏิเสธคำขอทันทีด้วย HTTP Status Code: `400 Bad Request` หรือ `413 Payload Too Large`
  2. Response Body: `{"detail": "File size exceeds maximum limit of 10MB"}`
  3. เซิร์ฟเวอร์ยกเลิกการอ่าน Stream เพื่อประหยัด RAM
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

### TC-BE-SCAN-03: การตรวจจับ Magic Bytes ป้องกันไฟล์ปลอมแปลงนามสกุล (MIME Spoofing / Magic Bytes)
- **Module / Feature**: Security / File Sanitization
- **Requirement ID**: FR-INPUT-06, NFR-SEC-04
- **Test Type**: Security / Negative
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. สร้างไฟล์สคริปต์อันตรายหรือไฟล์ข้อความ แต่เปลี่ยนนามสกุลเป็น `.png` (เช่น ไฟล์ Text ธรรมดาที่ข้างในเป็นสคริปต์ Bash แต่ตั้งชื่อ `malicious.png`)
- **Test Data**:
  - Filename: `fake_image.png` (เนื้อหาภายในไม่มี Magic Bytes ของ PNG: `89 50 4E 47`)
- **Test Steps**:
  1. พยายามอัปโหลดไฟล์ดังกล่าวเข้าสู่ API สแกนภาพ
- **Expected Results**:
  1. Backend ตรวจสอบ Header Magic Bytes ของไฟล์ในฟังก์ชันตรวจสอบ
  2. ตรวจพบว่าเนื้อหาไม่ใช่รูปภาพจริง ปฏิเสธด้วย HTTP `400 Bad Request`
  3. ไฟล์ไม่ถูกส่งต่อไปยัง Subprocess หรือโมเดล AI ป้องกันช่องโหว่ RCE และ Memory Corrupt
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

## 3. หมวดหมู่การแคชผลลัพธ์ด้วย Redis (Redis Caching Mechanism)

### TC-BE-CACHE-01: การตรวจสอบแคชพลาดและบันทึกผลลงแคช (Cache Miss Flow)
- **Module / Feature**: Cache / SHA-256 Image Hash
- **Requirement ID**: FR-SYS-09
- **Test Type**: Integration
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. ล้างคีย์ใน Redis หรือใช้ภาพใหม่ที่ไม่เคยอัปโหลดมาก่อน
- **Test Data**: ภาพที่ไม่เคยผ่านระบบมาก่อน
- **Test Steps**:
  1. อัปโหลดภาพเข้าสู่ API
  2. ตรวจสอบ Key ใน Redis Container
- **Expected Results**:
  1. ตรวจไม่พบคีย์ใน Redis (Cache Miss)
  2. ระบบประมวลผลผ่าน AI Inference Pipeline ปกติ
  3. เมื่อได้ผลลัพธ์ ระบบคำนวณ SHA-256 Hash ของไฟล์ภาพ และบันทึกผลลัพธ์ลง Redis พร้อมตั้ง TTL
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

### TC-BE-CACHE-02: การตอบกลับทันทีเมื่อตรวจพบภาพซ้ำเดิม (Cache Hit Acceleration)
- **Module / Feature**: Cache / Performance Optimization
- **Requirement ID**: FR-SYS-09, NFR-PERF-01
- **Test Type**: Performance / Integration
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. เพิ่งสแกนภาพ A สำเร็จใน TC-BE-CACHE-01 ข้อมูลถูกแคชอยู่ใน Redis เรียบร้อยแล้ว
- **Test Data**: ภาพ A ไฟล์เดิมเป๊ะ
- **Test Steps**:
  1. ส่งคำขอสแกนภาพ A ซ้ำอีกครั้ง
  2. วัดเวลาตอบสนอง (Response Latency)
- **Expected Results**:
  1. ตรวจพบคีย์แฮชใน Redis ทันที (Cache Hit)
  2. ได้รับ HTTP 200 พร้อมผลลัพธ์การสแกนเดิม
  3. เวลาในการตอบกลับรวดเร็วมาก (< 100ms) โดยไม่มีการเรียกใช้งานโมเดล AI ใน Subprocess ซ้ำ
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

## 4. หมวดหมู่ความปลอดภัยและการจำกัดอัตราคำขอ (Security & Rate Limiting)

### TC-BE-RATE-01: การจำกัดอัตราการยิงสแกนภาพด้วย Slowapi (Rate Limiting)
- **Module / Feature**: Security / Rate Limiting Middleware
- **Requirement ID**: NFR-SEC-04
- **Test Type**: Boundary / Stress
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. Slowapi กำหนด Limit การสแกนภาพไว้ที่ 10 คำขอต่อนาทีต่อผู้ใช้/IP
- **Test Data**: ยิงคำขออัปโหลดภาพต่อเนื่อง 12 ครั้งติดต่อกันในเวลา 5 วินาที
- **Test Steps**:
  1. ใช้ลูปยิงคำขอ `POST /api/v1/scan/` รัวเกินโควตา
- **Expected Results**:
  1. คำขอที่ 1 ถึง 10 ตอบกลับสำเร็จ HTTP 200
  2. คำขอที่ 11 เป็นต้นไป ถูกปฏิเสธด้วย HTTP Status Code: `429 Too Many Requests`
  3. มี Header `Retry-After` แจ้งเวลาที่ต้องรอก่อนยิงใหม่อีกครั้ง
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

### TC-BE-CORS-01: การตรวจสอบและยอมรับเฉพาะ Origins ที่กำหนด (CORS Policy)
- **Module / Feature**: Security / CORS Middleware
- **Requirement ID**: NFR-SEC-01
- **Test Type**: Security
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. ตัวแปร `ALLOWED_ORIGINS` ใน `.env` ระบุเฉพาะโดเมนของ Admin Portal และ Localhost
- **Test Data**:
  - Origin ที่อนุญาต: `http://localhost:5173`
  - Origin แปลกปลอม: `http://malicious-site.com`
- **Test Steps**:
  1. ส่งคำขอ Preflight `OPTIONS /api/v1/auth/login` โดยตั้ง Header `Origin: http://malicious-site.com`
- **Expected Results**:
  1. Response จะไม่มี Header `Access-Control-Allow-Origin` ส่งกลับไปให้กับ Origin แปลกปลอม
  2. เมื่อส่งด้วย Origin ที่อนุญาต จะได้รับ Header `Access-Control-Allow-Origin: http://localhost:5173` ครบถ้วน
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_health.py`

---

## 5. หมวดหมู่การจัดการสิทธิ์และการบริหารผู้ดูแลระบบ (Admin APIs & RBAC)

### TC-BE-ADMIN-01: การปฏิเสธผู้ใช้ทั่วไปเมื่อพยายามเรียกใช้ Admin Endpoints (RBAC Enforcement)
- **Module / Feature**: Admin / Authorization Check
- **Requirement ID**: NFR-SEC-03
- **Test Type**: Security / Negative
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มี Token ของผู้ใช้ทั่วไป (Normal User จากตาราง `users`)
- **Test Data**:
  - Endpoint: `GET /api/v1/admin/users/` หรือ `GET /api/v1/admin/models/`
  - Headers: `Authorization: Bearer <normal_user_token>`
- **Test Steps**:
  1. ใช้ Token ของผู้ใช้ธรรมดาเรียก Endpoint ของ Admin
- **Expected Results**:
  1. ระบบปฏิเสธคำขอทันทีด้วย HTTP Status Code: `403 Forbidden`
  2. Response Body: `{"detail": "Admin privileges required"}`
  3. ข้อมูลรายชื่อผู้ใช้และระบบจัดการโมเดลไม่ถูกเปิดเผย
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

### TC-BE-MODEL-01: การสลับสถานะโมเดล Active พร้อม Database Row Lock (Atomic Model Deployment)
- **Module / Feature**: Admin / Model Registry
- **Requirement ID**: FR-ADM-04
- **Test Type**: Concurrency / Integration
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. มีโมเดล SegFormer เวอร์ชัน `v1.0.0` (Active) และ `v1.0.1` (Inactive) ในตาราง `model_versions`
  2. ล็อกอินด้วยบัญชีแอดมิน
- **Test Data**:
  - Endpoint: `POST /api/v1/admin/models/v1.0.1/deploy`
- **Test Steps**:
  1. ส่งคำขอ Deploy โมเดล `v1.0.1`
  2. ตรวจสอบตาราง `model_versions` และ `audit_logs`
- **Expected Results**:
  1. ได้รับ HTTP Status Code: `200 OK`
  2. กระบวนการรันภายใต้ Transaction พร้อม Row-Level Lock (`with_for_update`)
  3. โมเดลเดิมถูกปลดสถานะเป็น `is_active = false` และโมเดลใหม่กลายเป็น `is_active = true`
  4. มีการบันทึกประวัติการกระทำลงในตาราง `audit_logs` ทันที
- **Automation Mapping**: `tests_all/tests_report/automate_tests/server/admin_api.md`

---

## 6. หมวดหมู่ความสอดคล้องของฐานข้อมูลและเวลา (Database Integrity & Timezone)

### TC-BE-DB-01: การบันทึกเวลาเป็นเขตเวลาประเทศไทย UTC+7 (Timezone Verification)
- **Module / Feature**: Database / Timezone Consistency
- **Requirement ID**: NFR-SYS-01
- **Test Type**: Functional / Data Integrity
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. PostgreSQL Container และระบบ FastAPI ตั้งค่า Timezone ตรงกัน
- **Test Data**: การสร้าง Record ใหม่ในตาราง `users`, `scans`, หรือ `audit_logs`
- **Test Steps**:
  1. ส่งคำขอสร้างข้อมูลใหม่
  2. ตรวจสอบค่าในคอลัมน์ `created_at` ใน PostgreSQL
- **Expected Results**:
  1. ค่าเวลา `created_at` ตรงกับเวลาจริงของประเทศไทย (`Asia/Bangkok` หรือ `UTC+7`)
  2. ไม่เกิดปัญหาเวลาเลื่อนถอยหลังไป 7 ชั่วโมง (UTC Offset 0)
- **Automation Mapping**: `server/tests/check_time_tz.py`
