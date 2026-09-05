# แผนการทดสอบ: ระบบหลังบ้านและฐานข้อมูล (Backend API & Database Test Plan)

- **System / Component**: ScamGuard Backend Core Service
- **Architecture**: Asynchronous RESTful API, Service Layer Pattern, Repository Pattern
- **Tech Stack**: FastAPI (Python 3.10), SQLAlchemy 2.0, Alembic, PostgreSQL 15, Redis 7, Slowapi, Pydantic v2
- **Document Version**: 1.0.0
- **Status**: Approved

---

## 1. ขอบเขตการทดสอบ (Scope of Testing)

### 1.1 สิ่งที่อยู่ในขอบเขต (In-Scope)
1. **Authentication & Authorization**:
   - `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `GET /api/v1/auth/me`
   - การออก JWT Token (Access Token และ Refresh Token)
   - การตรวจสอบสิทธิ์แบบ RBAC แยกบทบาท `user` และ `admin` (ตาราง `users` และ `admins`)
2. **Scan & Upload Pipeline**:
   - `POST /api/v1/scan/` รองรับ Multipart/form-data
   - การตรวจสอบขนาดไฟล์ (Limit 10MB) และ Magic Bytes (JPEG/PNG)
   - การคำนวณ SHA-256 Hash เพื่อทำ Redis Caching
   - การสร้างงานส่งต่อไปยัง AI Subprocess Pipeline
3. **Scan History & Detail Query**:
   - `GET /api/v1/history/` และ `GET /api/v1/history/{scan_id}`
   - การดึงข้อมูลผลลัพธ์ย้อนหลัง พร้อมคะแนนแยก 3 ปัจจัย และ URL ภาพ Heatmap
4. **Scam Incident Reporting**:
   - `POST /api/v1/reports/` สำหรับผู้ใช้ทั่วไป
   - การบันทึกข้อร้องเรียนลงตาราง `reports` พร้อมการควบคุม Concurrency (คอลัมน์ `version`)
5. **Database Integrity & Migrations**:
   - การทำงานของ Alembic Migrations
   - ความถูกต้องของ Foreign Key Constraints, Indexes (Hash Index, B-Tree Index บน `user_id`, `image_hash`)
   - การจัดการ Timezone ต้องเป็น UTC+7 (Asia/Bangkok)
6. **Security & Rate Limiting**:
   - การป้องกัน Brute Force ด้วย Slowapi Rate Limiting (เช่น 5 requests/min สำหรับ Login, 30 requests/min สำหรับ Scan)
   - การตั้งค่า CORS Header และ Security Headers

### 1.2 สิ่งที่อยู่นอกขอบเขต (Out-of-Scope)
1. การเทรนโมเดล AI (การทดสอบนี้มุ่งเน้นการให้บริการ API Backend)
2. การจัดการ DNS หรือ Cloud CDN ระดับองค์กร

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
- รันคำสั่งตรวจสอบการเชื่อมต่อผ่าน `/health` ให้ผลลัพธ์สถานะ OK

### 3.2 เกณฑ์การสิ้นสุดการทดสอบ (Exit Criteria)
- ชุดทดสอบ Automated API Suite ใน `tests_all/automate_tests/tests/api/` ผ่าน 100% (15/15 tests PASS)
- กรณีทดสอบระดับ P0 และ P1 ใน `tests_all/manual_tests/test_cases_backend.md` ผ่าน 100%
- ความครอบคลุมของโค้ด (Code Coverage) บนโมดูล Router และ Core Services ไม่น้อยกว่า 80%
- ไม่มีข้อผิดพลาดประเภท Unhandled Exception (HTTP 500) เกิดขึ้นระหว่างการทดสอบ

---

## 4. ความเชื่อมโยงไปยังชุดกรณีทดสอบจริง
- **เอกสารกรณีทดสอบละเอียด**: `tests_all/manual_tests/test_cases_backend.md`
- **ชุดทดสอบอัตโนมัติ**: `tests_all/automate_tests/tests/api/`
- **ตารางความสอดคล้องความต้องการ**: `tests_all/rtm.md` (หมวดหมู่ FR-AUTH, FR-INPUT, FR-SYS, FR-HIST, FR-RPT)
