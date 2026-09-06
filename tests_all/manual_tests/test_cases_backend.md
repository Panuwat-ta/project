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
      "full_name": "Backend Test User",
      "system_consent": true,
      "research_consent": false
    }
    ```
- **Test Steps**:
  1. ยิง HTTP POST ไปยัง `/api/v1/auth/register` พร้อม JSON Payload
  2. ตรวจสอบข้อมูลในตาราง `users` และ `consent_logs` ของฐานข้อมูล
- **Expected Results**:
  1. ได้รับ HTTP Status Code: `201 Created`
  2. Response Body มี `id`, `email`, `full_name`, `role` (ไม่มี Plaintext Password คืนกลับมา)
  3. ในตาราง `users` คอลัมน์ `hashed_password` ต้องถูกเข้ารหัส โดยมีความยาวแฮชมาตรฐาน
  4. มีบันทึกความยินยอมในตาราง `consent_logs` ตรงกับค่าที่ส่งมา
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
  - Content-Type: `application/x-www-form-urlencoded`
  - Form fields:
    - `username`: `be_test_user@scamguard.local` (ใช้อีเมลเป็นชื่อผู้ใช้)
    - `password`: `StrongPassword123!`
- **Test Steps**:
  1. ส่งคำขอ Login แบบฟอร์มพร้อมฟิลด์ `username` และ `password` ไปยัง Backend
- **Expected Results**:
  1. ได้รับ HTTP Status Code: `200 OK`
  2. Response Body ส่งคืนโครงสร้าง DTO:
  ```json
      {
        "access_token": "eyJhbGciOiJIUzI1...",
        "refresh_token": "eyJhbGciOiJIUzI1...",
        "token_type": "bearer",
        "user": {
          "id": 1,
          "email": "be_test_user@scamguard.local",
          "full_name": "Backend Test User",
          "role": "user"
        }
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
  - Content-Type: `application/json`
  - Payload:
    ```json
    {
      "refresh_token": "<valid_refresh_token>"
    }
    ```
- **Test Steps**:
  1. ส่งคำขอพร้อม JSON ที่มีฟิลด์ `refresh_token` เพื่อขอ Access Token ชุดใหม่
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
2. Response Body: `{"detail": "Could not validate credentials"}` สำหรับ Token ไม่ถูกต้องหรือหมดอายุ หรือ `{"detail": "Invalid or expired refresh token"}` สำหรับการต่ออายุด้วย Refresh Token ที่ใช้ไม่ได้
3. ไม่สามารถเข้าถึงข้อมูลเบื้องหลังได้
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

### TC-BE-AUTH-05: การดึงโปรไฟล์และการออกจากระบบ (Me Plus Logout)
- **Module / Feature**: Auth / Profile and Logout
- **Requirement ID**: FR-AUTH-02, FR-AUTH-05
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มี Access Token ที่ยังไม่หมดอายุ
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `GET /api/v1/auth/me`
  - Endpoint: `POST /api/v1/auth/logout`
  - Headers: `Authorization: Bearer <valid_access_token>`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เรียก `GET /api/v1/auth/me` พร้อม Token ที่ถูกต้อง
  2. เรียก `POST /api/v1/auth/logout` พร้อม Token เดียวกัน
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
1. `GET /me` ตอบ `200 OK` พร้อม `id`, `email`, `full_name`, `role`
2. `POST /logout` ตอบ `200 OK` พร้อม `{"message": "Successfully logged out"}`
3. ฝั่ง Server ใช้ JWT แบบ Stateless การล้าง Token หลักทำที่ Client
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

### TC-BE-AUTH-06: การปฏิเสธการเข้าสู่ระบบเมื่อรหัสผ่านผิด (Login Wrong Password)
- **Module / Feature**: Auth / Login Error Handling
- **Requirement ID**: FR-AUTH-02
- **Test Type**: Negative
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มีผู้ใช้ `be_test_user@scamguard.local` ในระบบ
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `POST /api/v1/auth/login`
  - Content-Type: `application/x-www-form-urlencoded`
  - Form fields:
    - `username`: `be_test_user@scamguard.local`
    - `password`: `WrongPassword999`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ส่งคำขอ Login แบบฟอร์มโดยกรอกอีเมลถูกแต่รหัสผ่านผิด
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ได้รับ HTTP Status Code: `401 Unauthorized`
  2. Response Body: `{"detail": "Incorrect email or password"}`
  3. ไม่มีการออก Token ใดๆ
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

## 2. หมวดหมู่การอัปโหลดและตรวจสอบไฟล์รูปภาพ (Scan & File Validation API)

### TC-BE-SCAN-01: การอัปโหลดภาพและรับผลการวิเคราะห์ (Normal Scan Flow)
- **Module / Feature**: Scan / Image Scan Endpoint
- **Requirement ID**: FR-INPUT-03, FR-SYS-07
- **Test Type**: Integration / API
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มี Bearer Token ที่ถูกต้องของผู้ใช้
  2. รูปภาพตัวอย่างที่ถูกต้องตามมาตรฐาน (เช่น `sample.jpg`, ขนาด 500 KB)
- **Test Data**:
  - Endpoint: `POST /api/v1/scan/`
  - Content-Type: `multipart/form-data`
  - File: `sample.jpg`
  - Field: `file` พร้อม `title` (ถ้ามี)
- **Test Steps**:
  1. แนบไฟล์รูปภาพใน Form Field `file`
  2. ส่งคำขอพร้อม Authorization Header
- **Expected Results**:
  1. ได้รับ HTTP Status Code: `200 OK`
  2. Response Body ประกอบด้วย:
     - `id`: รหัสการสแกน (UUID v4)
     - `total_risk_score`: ตัวเลขอัตราความเสี่ยง 0 – 100
     - `risk_grade`: ระดับความเสี่ยงตัวพิมพ์เล็ก (`low`, `medium`, `high`)
     - `text_score`, `visual_score`, `source_score`: คะแนนจำแนกรายด้าน
     - `heatmap_image_url`: URL สำหรับดาวน์โหลดภาพ Heatmap
     - `status` และ `progress`: สถานะงานปัจจุบัน
  3. ข้อมูลถูกบันทึกลงในตาราง `scans` ของ PostgreSQL พร้อมเวลาที่บันทึก
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

### TC-BE-SCAN-02: การปฏิเสธไฟล์ที่มีขนาดเกินขีดจำกัด Server 20MB (Server-side File Size Enforcement)
- **Module / Feature**: Scan / Size Enforcement
- **Requirement ID**: FR-INPUT-04
- **Test Type**: Boundary / Negative
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. เตรียมไฟล์ภาพจำลองขนาด 21 MB (เกินลิมิตฝั่ง Server 20MB; ฝั่ง Mobile ไม่ปฏิเสธไฟล์เกิน 10MB แต่แสดงคำเตือนและบีบอัดก่อนส่ง)
- **Test Data**:
  - Endpoint: `POST /api/v1/scan/`
  - File: ขนาด 21 MB
- **Test Steps**:
  1. ยิงคำขออัปโหลดไฟล์ขนาดเกิน 20MB เข้าสู่ Endpoint
- **Expected Results**:
  1. Backend ปฏิเสธคำขอทันทีด้วย HTTP Status Code: `413 Payload Too Large`
  2. Response Body: `{"detail": "File too large. Maximum allowed size is 20 MB."}`
  3. หมายเหตุการอ่านไฟล์: เซิร์ฟเวอร์อ่านไฟล์ทั้งหมดเข้าหน่วยความจำก่อน (`await file.read()` ใน `create_scan_task`) แล้วจึงตรวจขนาด ไม่ได้ยกเลิกการอ่าน Stream กลางคัน
- **Automation Mapping**: `server/tests/api/test_scan.py`

---

### TC-BE-SCAN-03: การตรวจจับ Magic Bytes ป้องกันไฟล์ปลอมแปลงนามสกุล (MIME Spoofing / Magic Bytes)
- **Module / Feature**: Security / File Sanitization
- **Requirement ID**: FR-INPUT-04, NFR-SEC-04
- **Test Type**: Security / Negative
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. สร้างไฟล์สคริปต์อันตรายหรือไฟล์ข้อความ แต่เปลี่ยนนามสกุลเป็น `.png` (เช่น ไฟล์ Text ธรรมดาที่ข้างในเป็นสคริปต์ Bash แต่ตั้งชื่อ `malicious.png`)
- **Test Data**:
  - Filename: `fake_image.png` (เนื้อหาภายในไม่มี Magic Bytes ของ PNG: `89 50 4E 47`)
- **Test Steps**:
  1. พยายามอัปโหลดไฟล์ดังกล่าวเข้าสู่ API สแกนภาพ
- **Expected Results**:
1. `POST /api/v1/scan/` ตอบ `200 OK` พร้อมสถานะ `uploading` ก่อน ไม่ตรวจ Magic Bytes ทันทีตอนอัปโหลด (การตรวจอยู่ในงานเบื้องหลังผ่าน `load_image_verified` ซึ่งตรวจ Magic Bytes โดยไม่เชื่อ `content_type`)
2. งานเบื้องหลังตรวจพบว่าเนื้อหาไม่ใช่รูปภาพจริง สถานะงานเป็น `failed` เมื่อเรียกดูด้วย `GET /api/v1/scan/{scan_id}` ฝั่งแอปรับเป็น `ScanError` พร้อมข้อความทั่วไป (ข้อความรายละเอียด `File is not a valid image.` มีอยู่ใน `image_utils.py` แต่ไม่ถูกส่งกลับถึง Client ในโฟลว์ปัจจุบัน)
3. ไฟล์ไม่ถูกบันทึกเป็นหลักฐานและไม่ถูกส่งต่อไปยัง Subprocess หรือโมเดล AI (การบันทึกไฟล์เกิดหลังตรวจผ่านเท่านั้น) ป้องกันช่องโหว่ RCE และ Memory Corrupt
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

### TC-BE-SCAN-04: การปฏิเสธไฟล์รูปภาพที่เสียหายเปิดไม่ได้ (Corrupt Image)
- **Module / Feature**: Scan / Corrupt File Handling
- **Requirement ID**: FR-INPUT-04
- **Test Type**: Negative
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มี Bearer Token ที่ถูกต้อง
  2. เตรียมไฟล์นามสกุล jpg แต่ข้อมูลภายในเสียหายเปิดไม่ได้
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `POST /api/v1/scan/`
  - File: `corrupt.jpg` (ข้อมูลไบต์ไม่สมบูรณ์)
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. อัปโหลดไฟล์เสียหายเข้าสู่ Endpoint สแกน
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. `POST /api/v1/scan/` ตอบ `200 OK` พร้อมสถานะ `uploading` ก่อนเช่นเดียวกับ TC-BE-SCAN-03 งานเบื้องหลังตรวจพบว่าไฟล์เสียหาย สถานะงานเป็น `failed` เมื่อเรียกดูด้วย `GET /api/v1/scan/{scan_id}` (ไม่มีการตอบ `400/422` ทันทีตอนอัปโหลดในโฟลว์ปัจจุบัน ข้อความ `Image is corrupted or unsupported.` มีอยู่ใน `image_utils.py` ฝั่งงานเบื้องหลัง)
  2. ไฟล์ไม่ถูกส่งต่อเข้า AI Pipeline
  3. ไม่เกิดการแครชของ Worker
- **Automation Mapping**: `server/tests/api/test_scan.py`

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
  3. เวลาในการตอบกลับไม่เกิน 3 วินาทีแบบ End-to-End (≤ 3s ตรงตาม NFR-PERF-01) โดยไม่มีการเรียกใช้งานโมเดล AI ใน Subprocess ซ้ำ
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

## 4. หมวดหมู่ความปลอดภัยและการจำกัดอัตราคำขอ (Security & Rate Limiting)

### TC-BE-RATE-01: การจำกัดอัตราคำขอทั่วไปและฝั่ง Admin (Rate Limiting)
- **Module / Feature**: Security / Rate Limiting Middleware
- **Requirement ID**: NFR-SEC-04
- **Test Type**: Boundary
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. Server กำหนดโควตาทั่วไว้ที่ 60 ครั้งต่อชั่วโมงต่อ IP และกำหนด Limit ของ `POST /api/v1/admin/login` กับ `POST /api/v1/admin/refresh` ไว้ที่ 5 ครั้งต่อนาที
- **Test Data**: ยิงคำขอ `POST /api/v1/admin/login` เกิน 5 ครั้งภายใน 1 นาทีจาก IP เดียวกัน
- **Test Steps**:
  1. ใช้ลูปยิงคำขอล็อกอิน Admin รัวเกินโควตา
- **Expected Results**:
  1. คำขอภายในโควตาตอบกลับตามปกติ
  2. คำขอเกินโควตาถูกปฏิเสธด้วย HTTP Status Code: `429 Too Many Requests`
  3. มี Header `Retry-After` แจ้งเวลาที่ต้องรอก่อนยิงใหม่อีกครั้ง
  4. โควตาทั่ว 60 ครั้งต่อชั่วโมงมีผลกับทุกคำขอ ส่วนโควตา Admin 5 ครั้งต่อนาทีมีผลเฉพาะเส้นล็อกอินและต่ออายุ Token ฝั่ง Admin
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
  - Endpoint: `GET /api/v1/admin/users` หรือ `GET /api/v1/admin/models`
  - Headers: `Authorization: Bearer <normal_user_token>`
- **Test Steps**:
  1. ใช้ Token ของผู้ใช้ธรรมดาเรียก Endpoint ของ Admin
- **Expected Results**:
  1. ระบบปฏิเสธคำขอทันทีด้วย HTTP Status Code: `403 Forbidden`
  2. Response Body: `{"detail": "Super Admin access required"}`
  3. ข้อมูลรายชื่อผู้ใช้และระบบจัดการโมเดลไม่ถูกเปิดเผย
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

### TC-BE-MODEL-01: การสลับสถานะโมเดล Active ภายใต้งานฐานข้อมูลเดียว (Atomic Model Deployment)
- **Module / Feature**: Admin / Model Registry
- **Requirement ID**: FR-ADM-04
- **Test Type**: Concurrency / Integration
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. มีโมเดล SegFormer เวอร์ชัน `v1.0.0` (Active) และ `v1.0.1` (Inactive) ในตาราง `model_versions`
  2. ล็อกอินด้วยบัญชีแอดมิน
- **Test Data**:
  - Endpoint: `POST /api/v1/admin/models/{model_id}/deploy`
  - Body: `{"reason": "เลื่อนเวอร์ชันที่ผ่านการทดสอบขึ้นใช้งานจริง"}`
- **Test Steps**:
  1. ส่งคำขอ Deploy โมเดล `v1.0.1` โดยระบุ `model_id` (int) ของเวอร์ชันเป้าหมายพร้อมเหตุผล
  2. ตรวจสอบตาราง `model_versions` และ `audit_log`
- **Expected Results**:
1. ได้รับ HTTP Status Code: `200 OK`
2. กระบวนการรันภายใต้ Transaction แบบ Atomic โดยไม่มีการล็อกแถวแยกต่างหาก
3. โมเดลเดิมถูกปลดสถานะเป็น `is_active = false` และโมเดลใหม่กลายเป็น `is_active = true`
  4. มีการบันทึกประวัติการกระทำลงในตาราง `audit_log` เอกพจน์ทันที
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

### TC-BE-ADMIN-04: การรับเรื่องและตัดสินรายงานข้อร้องเรียน (Report Moderation)
- **Module / Feature**: Admin / Report Review and Decision
- **Requirement ID**: FR-ADM-02
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ล็อกอินด้วยบัญชี Admin ที่มี `is_superadmin` เป็นจริง
  2. มีรายงานของผู้ใช้สถานะ `pending` พร้อมเลข `version` ปัจจุบัน
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `POST /api/v1/admin/reports/{report_id}/review` พร้อม `{"version": 1}`
  - Endpoint: `PATCH /api/v1/admin/reports/{report_id}`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เรียกดูรายละเอียดด้วย `GET /api/v1/admin/reports/{report_id}`
  2. กดรับเรื่องด้วย `POST /review` โดยส่งเลข `version` ปัจจุบัน สถานะต้องเปลี่ยนเป็น `reviewing`
  3. ตัดสินรายงานด้วย `PATCH` แล้วตรวจตาราง `audit_log`
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. กดรับเรื่องสำเร็จ สถานะเป็น `reviewing` ตัวพิมพ์เล็ก เลข `version` เพิ่มขึ้น
  2. ส่งเลข `version` เก่าซ้ำได้ `409 Conflict` พร้อม `{"detail": "Conflict: Report has been updated by another user"}`
  3. การตัดสินบันทึกผลต่าง `status` และ `version` ก่อนหลังลงตาราง `audit_log` เอกพจน์
  4. Token ผู้ใช้ทั่วไปเรียกแล้วได้ `403 Forbidden` พร้อม `{"detail": "Super Admin access required"}`
- **Automation Mapping**: `server/tests/api/test_admin_reports.py`

---

## 6. หมวดหมู่ประวัติและรายงานของผู้ใช้ (History Plus User Reports)

### TC-BE-HIST-01: การดึงรายการประวัติการสแกน (History List)
- **Module / Feature**: History / List Scans
- **Requirement ID**: FR-HIST-01
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ผู้ใช้มีประวัติการสแกนอย่างน้อย 2 รายการ
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `GET /api/v1/history?page=1&limit=20`
  - Headers: `Authorization: Bearer <valid_access_token>`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เรียกดูรายการประวัติพร้อม Token ที่ถูกต้อง
  2. ตรวจสอบการเรียงลำดับและฟิลด์ที่ได้
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ตอบ `200 OK` พร้อม `items`, `total`, `page`, `limit`
  2. รายการเรียงจากใหม่ไปเก่า มี `scan_id`, `risk_score`, `risk_level` ตัวพิมพ์เล็ก, `status`, `created_at`, `title`
  3. เวลาเป็นเขตเวลาไทย UTC+7
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_history.py`

---

### TC-BE-HIST-02: การดูรายละเอียดประวัติรายฉบับและการลบประวัติ (History Detail Plus Delete)
- **Module / Feature**: History / Detail and Delete
- **Requirement ID**: FR-HIST-02, FR-HIST-03
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มี scan_id ที่เป็นของผู้ใช้เอง
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `GET /api/v1/history/{scan_id}`
  - Endpoint: `DELETE /api/v1/history/{scan_id}`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เรียกดูรายละเอียดด้วย `GET /api/v1/history/{scan_id}`
  2. ลบด้วย `DELETE /api/v1/history/{scan_id}`
  3. เรียกดูซ้ำด้วย `GET` เดิม
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
1. `GET` ครั้งแรกตอบ `200 OK` พร้อมข้อมูลตรงกับเจ้าของงาน
2. `DELETE` ตอบสำเร็จและลบไฟล์ภาพเมื่อไม่มีงานอื่นใช้ `image_hash` เดียวกัน
3. `GET` ซ้ำตอบ `404 Not Found` พร้อม `{"detail": "Scan not found"}`
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_history.py`

---

### TC-BE-RPT-01: การส่งรายงานและการดึงหมวดหมู่กับรายงานของตนเอง (User Reports)
- **Module / Feature**: User Reports / Submit and Query
- **Requirement ID**: FR-RPT-01
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มี scan_id ที่เป็นของผู้ใช้เองและยังไม่เคยถูกรายงาน
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `POST /api/v1/reports` พร้อม `scan_id`, `category` เป็น `fake_slip`, `description` ยาวไม่ต่ำกว่า 10 ตัวอักษร
  - Endpoint: `GET /api/v1/reports/categories`
  - Endpoint: `GET /api/v1/reports/my`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ดึงหมวดหมู่จาก `GET /api/v1/reports/categories`
  2. ส่งรายงานด้วย `POST /api/v1/reports`
  3. ดึงรายงานของตนเองด้วย `GET /api/v1/reports/my`
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
1. หมวดหมู่มี 7 ค่า ได้แก่ `romance_scam`, `online_shopping`, `fake_slip`, `investment`, `identity_theft`, `ai_deepfake`, `other`
2. ส่งรายงานสำเร็จได้ `201 Created` พร้อมสถานะ `pending` ตัวพิมพ์เล็ก
3. ส่งงานเดิมซ้ำได้ `409 Conflict` พร้อม `{"detail": "This scan has already been reported"}` ส่วนการรายงานงานที่ไม่ใช่ของตนเองได้ `403 Forbidden`
4. `GET /my` แสดงรายงานของตนเองพร้อมสถานะและเลข `version`
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_history.py`

---

## 7. หมวดหมู่การบริหาร Admin ขั้นสูง (Admin Health Search Sessions Audit)

### TC-BE-ADMIN-02: การตรวจสุขภาพระบบและการค้นหาข้ามระบบ (Admin Health Plus Search)
- **Module / Feature**: Admin / Health and Global Search
- **Requirement ID**: FR-ADM-01
- **Test Type**: Functional
- **Priority**: P2 (Medium)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ล็อกอินด้วยบัญชี Admin ที่มี `is_superadmin` เป็นจริง
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `GET /api/v1/admin/health`
  - Endpoint: `GET /api/v1/admin/search?q=slip`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เรียกดูสถานะสุขภาพระบบ
  2. ค้นหาด้วยคำค้นแล้วตรวจผลลัพธ์
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. `GET /api/v1/admin/health` ตอบ `200 OK` พร้อมฟิลด์ `database`, `storage`, `models`, `queue` (ไม่มีฟิลด์ชื่อแคชหรือ Worker โดยตรง คิวงานดูจาก `queue` และโมเดลดูจาก `models`)
  2. `GET /search` ตอบ `200 OK` พร้อมผลลัพธ์ที่ตรงกับคำค้น
  3. Token ผู้ใช้ทั่วไปเรียกแล้วได้ `403 Forbidden`
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

### TC-BE-ADMIN-03: การดูและเพิกถอน Session ของ Admin (Admin Sessions)
- **Module / Feature**: Admin / Session Management
- **Requirement ID**: FR-ADM-01
- **Test Type**: Security
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ล็อกอิน Admin สำเร็จมี Session ปัจจุบัน
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `GET /api/v1/admin/sessions`
  - Endpoint: `POST /api/v1/admin/sessions/{session_id}/revoke`
  - Endpoint: `GET /api/v1/admin/me`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ดึงรายการ Session ทั้งหมดของตนเอง
  2. เพิกถอน Session ที่สร้างเพื่อทดสอบ
  3. นำ Refresh Token เดิมไปเรียก `POST /api/v1/admin/refresh`
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. รายการ Session แสดงรหัส วันหมดอายุ และการใช้งานล่าสุด
  2. เพิกถอนสำเร็จและ Session ที่ถูกเพิกถอนใช้งานต่อไม่ได้
  3. Refresh Token ที่ถูกเพิกถอนตอบ `401 Unauthorized`
- **Automation Mapping**: `server/tests/api/test_admin_auth.py`

---

### TC-BE-AUDIT-01: การกรองบันทึก Audit Log และการแสดงผลต่าง JSON (Audit Filter)
- **Module / Feature**: Admin / Audit Log Viewer
- **Requirement ID**: FR-ADM-06, FR-AUDIT-01
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มีประวัติการ Deploy โมเดลหรือตัดสินรายงานในตาราง `audit_log`
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `GET /api/v1/admin/audit-logs?page=1&limit=50&search=&action=&entity_type=`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ดึงบันทึกแบบไม่กรอง
  2. กรองด้วย `action` และ `entity_type`
  3. ตรวจสอบฟิลด์ผลต่างของรายการที่เปลี่ยนสถานะ
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ตอบ `200 OK` พร้อม `items`, `total`, `page`, `limit`
  2. แต่ละรายการมี `action`, `entity_type`, `entity_id`, `before_state`, `after_state`
  3. การเปลี่ยนสถานะรายงานแสดงผลต่าง `status` และ `version` ก่อนหลังถูกต้อง
  4. ตารางที่ใช้คือ `audit_log` เอกพจน์
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

## 8. หมวดหมู่ความสอดคล้องของฐานข้อมูลและเวลา (Database Integrity & Timezone)

### TC-BE-DB-01: การบันทึกเวลาเป็นเขตเวลาประเทศไทย UTC+7 (Timezone Verification)
- **Module / Feature**: Database / Timezone Consistency
- **Requirement ID**: NFR-SYS-01
- **Test Type**: Functional / Data Integrity
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. PostgreSQL Container และระบบ FastAPI ตั้งค่า Timezone ตรงกัน
- **Test Data**: การสร้าง Record ใหม่ในตาราง `users`, `scans`, หรือ `audit_log`
- **Test Steps**:
  1. ส่งคำขอสร้างข้อมูลใหม่
  2. ตรวจสอบค่าในคอลัมน์ `created_at` ใน PostgreSQL
- **Expected Results**:
  1. ค่าเวลา `created_at` ตรงกับเวลาจริงของประเทศไทย (`Asia/Bangkok` หรือ `UTC+7`)
  2. ไม่เกิดปัญหาเวลาเลื่อนถอยหลังไป 7 ชั่วโมง (UTC Offset 0)
- **Automation Mapping**: `server/tests/check_time_tz.py`

---

## 9. หมวดหมู่การตรวจสอบข้อมูลนำเข้าและสิทธิ์ผิดพลาด (Negative Auth & API Errors)

### TC-BE-AUTH-07: การปฏิเสธข้อมูลสมัครสมาชิกไม่ครบ รูปแบบผิด อีเมลซ้ำ และฟิลด์บทบาทแปลกปลอม (Register Negative Plus Duplicate)
- **Module / Feature**: Auth / Register Validation and Duplicate Handling
- **Requirement ID**: FR-AUTH-01
- **Test Type**: Functional / API
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. PostgreSQL และ FastAPI ทำงานปกติ
  2. มีผู้ใช้ `be_test_user@scamguard.local` อยู่แล้ว
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `POST /api/v1/auth/register`
  - เคส body ว่าง: `{}`
  - เคสอีเมลผิดรูปแบบ: `{"email": "not-an-email", "password": "StrongPassword123!", "full_name": "Test"}`
  - เคสไม่ส่ง `full_name`
  - เคสอีเมลซ้ำ: อีเมล `be_test_user@scamguard.local` พร้อมรหัสผ่านและชื่อครบ
  - เคสฟิลด์แปลกปลอม: body ครบถ้วนบวก `"role": "admin"`
  - เคสรหัสผ่านสั้น: `"password": "abc"`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ยิงทีละเคสไปยัง `POST /api/v1/auth/register`
  2. ตรวจรหัสสถานะ ข้อความตอบกลับ และแถวในตาราง `users` กับ `consent_logs`
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. body ว่าง อีเมลผิดรูปแบบ และไม่ส่ง `full_name` ได้ `422 Unprocessable Entity` และไม่มีแถวใหม่ในตาราง `users`
  2. อีเมลซ้ำได้ `400 Bad Request` พร้อม `{"detail": "Email already registered"}` (หมายเหตุ: ปลายทางนี้ใช้ 400 ไม่ใช่ 409)
  3. ฟิลด์ `role` ที่ส่งมาเพิ่มถูกเพิกเฉย บัญชีใหม่มี `role` เป็น `user` เสมอ และไม่มี Plaintext Password ใน Response
  4. รหัสผ่านสั้นยังสร้างบัญชีสำเร็จ (`201 Created`) เนื่องจากฝั่งบริการไม่มีเกณฑ์ความยาวขั้นต่ำ การตรวจความยาวทำที่ฝั่งแอปเท่านั้น
  5. ไม่ส่ง `system_consent` และ `research_consent` ระบบบันทึกค่าเริ่มต้น (`system_consent` เป็นจริง `research_consent` เป็นเท็จ) ลงตาราง `consent_logs`
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

### TC-BE-API-01: การปฏิเสธ Token หมดอายุ รูปแบบผิด และบทบาทไม่ตรงงาน (Expired Token Plus Wrong Role)
- **Module / Feature**: Auth / Cross-endpoint Authorization
- **Requirement ID**: NFR-SEC-02, NFR-SEC-03
- **Test Type**: API
- **Priority**: P0 (Blocker)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มี Token ผู้ใช้ทั่วไปที่ถูกต้อง 1 ชุด และ Token หมดอายุ 1 ชุด
  2. มี `scan_id` ของผู้ใช้อีกคนหนึ่งราย
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `GET /api/v1/history`, `GET /api/v1/scan/{scan_id}`, `POST /api/v1/reports`, `GET /api/v1/admin/users`
  - Header: `Authorization: Bearer <expired_or_malformed_token>` และ `Bearer <normal_user_token>`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เรียก `GET /api/v1/history` ด้วย Token หมดอายุและด้วย Token รูปแบบผิด
  2. เรียก `GET /api/v1/scan/{scan_id}` ของผู้ใช้คนอื่นด้วย Token ผู้ใช้ทั่วไป
  3. ส่ง `POST /api/v1/reports` อ้าง `scan_id` ของผู้ใช้คนอื่น
  4. เรียก `GET /api/v1/admin/users` ด้วย Token ผู้ใช้ทั่วไป
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. Token หมดอายุหรือรูปแบบผิดเรียก `GET /api/v1/history` ได้ `401 Unauthorized` พร้อม `{"detail": "Could not validate credentials"}`
  2. เปิดงานสแกนของผู้อื่นได้ `403 Forbidden` พร้อม `{"detail": "Not authorized to view this scan"}`
  3. รายงานงานของผู้อื่นได้ `403 Forbidden` พร้อม `{"detail": "Scan not found or you don't have permission"}`
  4. ผู้ใช้ทั่วไปเรียกปลายทางแอดมินได้ `403 Forbidden` พร้อม `{"detail": "Super Admin access required"}`
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

## 10. หมวดหมู่การป้องกันข้อมูลอันตราย (Injection Safety)

### TC-BE-SEC-01: การรับข้อความ SQLi และ XSS ในชื่อเรื่อง คำค้น และรายละเอียดรายงาน (SQLi Plus XSS Payloads)
- **Module / Feature**: Security / Untrusted Text in Title Keyword and Description
- **Requirement ID**: NFR-SEC-04
- **Test Type**: Security
- **Priority**: P0 (Blocker)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มี Bearer Token ที่ถูกต้อง
  2. มีภาพตัวอย่างขนาดไม่เกิน 20MB
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `POST /api/v1/scan/` ฟิลด์ฟอร์ม `title` เป็น `' OR '1'='1` และ `<script>alert(1)</script>`
  - Endpoint: `GET /api/v1/history?keyword=<script>alert(1)</script>`
  - Endpoint: `POST /api/v1/reports` ฟิลด์ `description` (ยาวเกิน 10 ตัวอักษร) เป็น `<img src=x onerror=alert(1)> สลิปปลอมยอดเงิน`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. อัปโหลดภาพพร้อม `title` ที่เป็นข้อความโจมตี แล้วเปิดดูประวัติ
  2. ค้นหาประวัติด้วย `keyword` ที่เป็นข้อความโจมตี
  3. ส่งรายงานด้วย `description` ที่ฝังแท็ก แล้วดึงรายงานของตนเองด้วย `GET /api/v1/reports/my`
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ทุกคำขอผ่านตามปกติ (`200 OK` หรือ `201 Created`) โดยข้อความโจมตีถูกเก็บและแสดงเป็นตัวอักษรธรรมดา ไม่รันสคริปต์
  2. การค้นหาไม่เกิดข้อผิดพลาดฐานข้อมูล ไม่คืนข้อมูลของผู้อื่น ไม่หลุดโครงสร้างตาราง
  3. ไม่มีไฟล์อันตรายถูกเขียนลงดิสก์เพิ่มนอกเหนือภาพหลักฐานปกติ และไม่มีบันทึกผิดปกติในตาราง `audit_log`
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

## 11. หมวดหมู่ความสัมพันธ์ข้อมูล (Database Relations)

### TC-BE-DB-02: การคงความสัมพันธ์เมื่อลบผู้ใช้ (งานสแกน รายงาน บันทึกยินยอม) (FK Delete Behavior)
- **Module / Feature**: Database / Foreign Key Delete Rules
- **Requirement ID**: FR-HIST-03, NFR-PDPA-02
- **Test Type**: Database
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. สร้างผู้ใช้ทดสอบที่มีงานสแกน 1 งาน รายงาน 1 ฉบับ และบันทึกยินยอม 1 แถว
  2. จด `user_id`, `scan_id`, ค่า `image_hash` ไว้
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ตาราง `users`, `scans`, `scam_reports`, `consent_logs`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ลบแถวผู้ใช้ทดสอบออกจากตาราง `users`
  2. ค้นตาราง `scans` ด้วย `image_hash` เดิม
  3. ค้นตาราง `scam_reports` และ `consent_logs` ของผู้ใช้นั้น
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. แถวงานสแกนยังคงอยู่ โดย `user_id` กลายเป็นค่าว่าง (ไม่ถูกลบตามผู้ใช้)
  2. แถวรายงานยังคงอยู่ โดย `user_id` กลายเป็นค่าว่าง (ไม่ถูกลบตามผู้ใช้)
  3. บันทึกยินยอมของผู้ใช้ถูกลบตามผู้ใช้จนหมด (ลบแบบพ่วง)
- **Automation Mapping**: Manual DB Verification

---

### TC-BE-DB-03: การสแกนภาพซ้ำรหัสแฮชเดิมและการลบไฟล์เมื่อไม่มีงานใดใช้แล้ว (Duplicate Hash Plus Shared File Delete)
- **Module / Feature**: Database / Duplicate Image Hash Handling
- **Requirement ID**: FR-INPUT-03, FR-HIST-03
- **Test Type**: Database
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มี Bearer Token ที่ถูกต้อง
  2. มีภาพตัวอย่าง 1 ไฟล์
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `POST /api/v1/scan/`, `DELETE /api/v1/history/{scan_id}`, `GET /api/v1/history/{scan_id}`
  - อัปโหลดไฟล์เดิมซ้ำ 2 ครั้ง
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. อัปโหลดไฟล์เดิม 2 ครั้ง จด `scan_id` ทั้งสองและค่า `image_hash`
  2. ลบงานแรกด้วย `DELETE /api/v1/history/{scan_id}` แล้วตรวจไฟล์ภาพต้นฉบับและ Heatmap
  3. ลบงานที่สอง แล้วเรียกดูงานที่ลบด้วย `GET` ซ้ำ
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ทั้งสองครั้งสำเร็จ (`200 OK`) ได้งานคนละรหัสแต่ `image_hash` เดียวกัน (คอลัมน์นี้เป็นดัชนีค้นหา ไม่ใช่ค่าห้ามซ้ำ)
  2. ลบงานแรกแล้วไฟล์ภาพยังอยู่ เพราะยังมีอีกงานใช้รหัสแฮชเดียวกัน
  3. ลบงานที่สองแล้วไฟล์ถูกลบออกจากดิสก์ และเรียกดูซ้ำได้ `404 Not Found` พร้อม `{"detail": "Scan not found"}`
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_history.py`

---

## 12. หมวดหมู่การเชื่อมงานข้ามบริการ (Cross-service Integration)

### TC-BE-INT-01: โซ่สแกน ประวัติ รายงาน ตั้งแต่ต้นจนจบ (Scan to History to Report Chain)
- **Module / Feature**: Integration / Scan History Report Flow
- **Requirement ID**: FR-INPUT-03, FR-HIST-01, FR-RPT-01
- **Test Type**: Integration
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มี Bearer Token ที่ถูกต้อง
  2. มีภาพตัวอย่างที่ไม่เคยรายงานมาก่อน
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `POST /api/v1/scan/` พร้อม `file` และ `title` ว่า `สลิปทดสอบโซ่`
  - Endpoint: `GET /api/v1/history?page=1&limit=20`
  - Endpoint: `GET /api/v1/scan/{scan_id}`
  - Endpoint: `POST /api/v1/reports` พร้อม `scan_id`, `category` เป็น `fake_slip`, `description` ยาวเกิน 10 ตัวอักษร
  - Endpoint: `GET /api/v1/reports/my`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. อัปโหลดภาพแล้วรอจน `GET /api/v1/scan/{scan_id}` มีสถานะ `completed`
  2. เปิด `GET /api/v1/history` ตรวจว่างานใหม่ปรากฏรายการแรก
  3. ส่งรายงานของงานนั้น แล้วดึง `GET /api/v1/reports/my`
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. งานสแกนจบด้วยสถานะตัวพิมพ์เล็ก `completed` มีคะแนน 3 ด้าน `text_score`, `visual_score`, `source_score` และ `risk_grade` เป็น `low`, `medium` หรือ `high`
  2. ประวัติแสดงงานใหม่เป็นรายการแรก มี `scan_id`, `risk_score`, `risk_level` ตัวพิมพ์เล็ก, `status`, `created_at`, `title` ตรงกัน
  3. ส่งรายงานสำเร็จได้ `201 Created` สถานะ `pending` ตัวพิมพ์เล็ก และพบรายงานใน `GET /my` ของผู้ใช้คนเดียวกัน
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_history.py`

---

## 13. หมวดหมู่การถดถอยหลังเปลี่ยนโมเดล (Post-deploy Regression)

### TC-BE-REG-01: ข้อมูลเดิมยังอ่านได้และเกณฑ์เสี่ยงไม่เปลี่ยนหลัง Deploy โมเดล (History Readable After Deploy)
- **Module / Feature**: Regression / Model Deploy Backward Compatibility
- **Requirement ID**: FR-ADM-04, FR-HIST-01
- **Test Type**: Regression
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ล็อกอินแอดมินที่มี `is_superadmin` เป็นจริง
  2. มีประวัติสแกนเดิมของผู้ใช้ทั่วไปอย่างน้อย 2 งาน พร้อมจด `scan_id`, `total_risk_score`, `risk_grade`
  3. มีโมเดลเป้าหมายในตาราง `model_versions` พร้อม `model_id` (int)
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `POST /api/v1/admin/models/{model_id}/deploy` พร้อมเหตุผล
  - Endpoint: `GET /api/v1/history`, `GET /api/v1/history/{scan_id}`, `POST /api/v1/scan/`
  - เกณฑ์เดิม: 0-39 เป็น `low`, 40-69 เป็น `medium`, 70-100 เป็น `high`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. Deploy โมเดลเป้าหมาย แล้วตรวจตาราง `audit_log`
  2. เรียกประวัติและรายละเอียดงานเดิมซ้ำ เปรียบเทียบคะแนนและระดับกับค่าที่จดไว้
  3. สแกนภาพตัวอย่างใหม่อีก 1 ภาพ ตรวจโครงสร้าง Response เดิม
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. Deploy สำเร็จ (`200 OK`) โมเดลเก่าหมดสถานะ โมเดลใหม่ใช้งาน และมีบันทึกในตาราง `audit_log`
  2. งานเดิมทุกงานยังอ่านได้ คะแนนและระดับความเสี่ยงเท่าเดิมทุกประการ
  3. งานสแกนใหม่ยังได้ฟิลด์ครบ (`id`, `total_risk_score`, `risk_grade`, `text_score`, `visual_score`, `source_score`, `heatmap_image_url`, `status`, `progress`) และเกณฑ์ 3 ระดับยังแบ่งที่ 40 กับ 70 เหมือนเดิม
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`
