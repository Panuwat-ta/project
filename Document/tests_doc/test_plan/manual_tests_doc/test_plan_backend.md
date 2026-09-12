# แผนการทดสอบ: ระบบหลังบ้านและฐานข้อมูล (Backend API & Database Test Plan)

> Version: 1.0.1 | Date: 2026-09-06 | Status: Baseline

- **System / Component**: ScamGuard Backend Core Service
- **Architecture**: Asynchronous RESTful API, Service Layer Pattern, Repository Pattern
- **Tech Stack**: FastAPI (Python 3.10), SQLAlchemy 2.0, Alembic, PostgreSQL 15, Redis 7, Slowapi, Pydantic v2
- **Document Version**: 1.0.1
- **Date**: 2026-09-06
- **Status**: Baseline

---

## 1. ขอบเขตการทดสอบ (Scope of Testing)

### 1.1 สิ่งที่อยู่ในขอบเขต (In-Scope)
1. **Authentication & Authorization**:
   - `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `POST /api/v1/auth/refresh`, `POST /api/v1/auth/logout`, `GET /api/v1/auth/me`
   - การออก JWT Token (Access Token และ Refresh Token)
   - การตรวจสอบสิทธิ์แยกบทบาท Admin จากตาราง admins แบบบังคับ is_superadmin กับ User จากตาราง users
2. **Scan & Upload Pipeline**:
   - `POST /api/v1/scan/` รองรับ Multipart/form-data พารามิเตอร์ file+title และ `GET /api/v1/scan/{id}` สำหรับดึงผลหรือ Poll สถานะ
    - การตรวจสอบขนาดไฟล์ (Server ปฏิเสธเกิน 20MB ด้วย HTTP 413 และปฏิเสธภาพเกิน 100M px ฝั่ง Mobile มีตัวชี้วัด isValidSize 10MB แต่ usecase ไม่ปฏิเสธให้ compress ต่อ) และ Magic Bytes (JPEG/PNG/WebP)
   - การคำนวณ SHA-256 Hash เพื่อทำ Redis Caching TTL 30 วัน
   - การสร้างงานส่งต่อไปยัง AI Subprocess Pipeline
3. **Scan History & Detail Query**:
    - `GET /api/v1/history` และ `GET /api/v1/history/{scan_id}` และ `DELETE /api/v1/history/{scan_id}`
   - การดึงข้อมูลผลลัพธ์ย้อนหลัง พร้อมคะแนนแยก 3 ปัจจัย และ URL ภาพ Heatmap
4. **Scam Incident Reporting**:
    - `POST /api/v1/reports` สำหรับผู้ใช้ทั่วไป `GET /api/v1/reports/categories` สำหรับดึงประเภท และ `GET /api/v1/reports/my` สำหรับดูรายงานตนเอง
    - การบันทึกข้อร้องเรียนลงตาราง `scam_reports` สถานะ pending/reviewing/approved/rejected พร้อมการควบคุม Concurrency (คอลัมน์ `version`)
5. **Database Integrity & Migrations**:
   - การทำงานของ Alembic Migrations
   - ความถูกต้องของ Foreign Key Constraints, Indexes (Hash Index, B-Tree Index บน `user_id`, `image_hash`)
   - การจัดการ Timezone ต้องเป็น UTC+7 (Asia/Bangkok)
   - การบันทึกทุกการกระทำสำคัญของ Admin ลงตารางเอกพจน์ audit_log พร้อม Structured JSON before_state และ after_state
6. **Security & Rate Limiting**:
    - การป้องกัน Brute Force ด้วย Slowapi Rate Limiting แบบ tier ต่อนาที (guest 10 / user 60 / admin 300 / POST scan 5; Admin Login/Refresh 5/minute ส่ง HTTP 429)
   - การบังคับ is_superadmin ทุกเส้น /api/v1/admin/* ผู้ใช้ทั่วไปเรียกต้องได้ HTTP 403
   - การตั้งค่า CORS Header และ Security Headers

### 1.2 สิ่งที่อยู่นอกขอบเขต (Out-of-Scope)
1. การเทรนโมเดล AI (การทดสอบนี้มุ่งเน้นการให้บริการ API Backend)
2. การจัดการ DNS หรือ Cloud CDN ระดับองค์กร

### 1.3 หมายเหตุ GAP ที่ห้ามเขียนแผนเทสของสิ่งที่ไม่มี
- เส้นทาง POST /api/v1/scan/upload ไม่มีอยู่จริง ต้องใช้ POST /api/v1/scan/ เท่านั้น
- เส้นทาง DELETE /api/v1/scan/{id} ไม่มีอยู่จริง มีเฉพาะ DELETE /api/v1/history/{id}
- ชุดค่า category keys ฝั่ง Mobile กับ Backend ไม่ตรงกัน ให้ mark เป็น GAP

---

## 2. กลยุทธ์และวิธีการทดสอบ (Testing Strategy)

### 2.1 สภาพแวดล้อมการทดสอบ (Test Environment)
- **Container Environment**: Docker Compose จำลอง PostgreSQL 15, Redis 7, และ Backend FastAPI Container
- **Test Database**: ฐานข้อมูลทดสอบแยกต่างหาก (`scamguard_test`) ซึ่งทำการ Reset State ระหว่างรอบการทดสอบ
- **Automation Runner**: Pytest พร้อมปลั๊กอิน `pytest-asyncio`, `httpx`, `coverage`

### 2.2 ระดับและประเภทการทดสอบ (Test Levels & Types)
1. **API Contract & Schema Testing**: ตรวจสอบว่า Response Body ตรงตาม Pydantic Schemas ที่กำหนดไว้
2. **Negative & Edge Case Testing**: ส่งข้อมูลที่ผิดปกติ เช่น ไฟล์ Corrupted, Header ปลอมแปลง, Payload ว่างเปล่า, และการส่ง Token ที่หมดอายุ
3. **Concurrency & Locking Testing**: ทดสอบการอัปเดตสถานะของ Report พร้อมกันหลายแอดมิน เพื่อยืนยันว่า Optimistic Locking ทำงานถูกต้อง
4. **Cache Invalidation & Hit Ratio**: ยืนยันการทำงานของ Redis ว่าสามารถคืนผลลัพธ์ได้ถูกต้องโดยไม่เกิด Data Stale

---

## 3. เกณฑ์การตรวจรับ (Entry & Exit Criteria)

### 3.1 เกณฑ์การเริ่มต้นทดสอบ (Entry Criteria)
- ฐานข้อมูล PostgreSQL และ Redis พร้อมเชื่อมต่อ และ Migration อยู่ในสถานะ Head ล่าสุด
- Environment Variables ถูกกำหนดผ่านไฟล์ `.env` ครบถ้วนโดยไม่มี Missing Config
- รันคำสั่งตรวจสอบการเชื่อมต่อผ่าน GET /health ที่รากเซิร์ฟเวอร์ ให้ผลลัพธ์ `200 OK` พร้อมฟิลด์สถานะ `healthy` ภายใน 2 วินาที

### 3.2 เกณฑ์การสิ้นสุดการทดสอบ (Exit Criteria)
- ชุดทดสอบ Automated API Suite ใน `tests_all/automate_tests/tests/api/` ผ่าน 100% (อ้างอิงจำนวนปัจจุบัน)
- กรณีทดสอบระดับ P0 และ P1 ใน `tests_all/manual_tests/test_cases_backend.md` ผ่าน 100%
- ความครอบคลุมของโค้ด (Code Coverage) บนโมดูล Router และ Core Services ไม่น้อยกว่า 80%
- ไม่มีข้อผิดพลาดประเภท Unhandled Exception (HTTP 500) เกิดขึ้นระหว่างการทดสอบ

---

## 4. ความเชื่อมโยงไปยังชุดกรณีทดสอบจริง
- **เอกสารกรณีทดสอบละเอียด**: `tests_all/manual_tests/test_cases_backend.md`
- **ชุดทดสอบอัตโนมัติ**: `tests_all/automate_tests/tests/api/`
- **ตารางความสอดคล้องความต้องการ**: `tests_all/rtm.md` (หมวดหมู่ FR-AUTH, FR-INPUT, FR-SYS, FR-HIST, FR-RPT)
