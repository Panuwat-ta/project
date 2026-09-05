# แผนการทดสอบอัตโนมัติ: การทดสอบส่วนต่อประสานโปรแกรมประยุกต์ (Backend API Automation Test Plan)

- **System / Component**: ScamGuard Backend REST API
- **Framework**: Pytest, Pytest-Asyncio, HTTPX AsyncClient, Pydantic
- **Execution Script**: `tests_all/automate_tests/run.sh api`
- **Document Version**: 1.0.0
- **Status**: Approved

---

## 1. วัตถุประสงค์และสถาปัตยกรรมชุดทดสอบ (Architecture & Objectives)

ชุดทดสอบอัตโนมัติระดับ API ออกแบบมาเพื่อทำ Regression Testing อย่างรวดเร็ว ตรวจสอบความถูกต้องของสัญญาสื่อสาร (API Contracts), รหัสสถานะ HTTP (Status Codes), โครงสร้างข้อมูล JSON Payload, และตรรกะความปลอดภัย โดยไม่ต้องพึ่งพาหน้าจอผู้ใช้งาน

```text
tests_all/automate_tests/
├── config/
│   ├── environments.yaml         # การกำหนดค่า URL สำหรับ Local, Staging, Production
│   └── settings.py               # ตัวโหลด Environment Variables (.env)
├── helpers/
│   ├── api_client.py             # HTTPX Asynchronous Client Wrapper
│   ├── auth_helper.py            # ฟังก์ชันสร้างผู้ใช้ทดสอบและขอ JWT Token
│   ├── assertions.py             # Custom Assertions สำหรับตรวจ Schema และ Status
│   └── image_factory.py          # เครื่องมือสร้างไฟล์ภาพทดสอบเสมือนใน Memory (BytesIO)
├── tests/
│   └── api/
│       ├── test_health.py        # ตรวจสอบความพร้อมของระบบและฐานข้อมูล
│       ├── test_auth_flow.py     # ตรวจสอบ Register, Login, Duplicate User, Token Expiry
│       ├── test_scan_workflow.py # ตรวจสอบ Upload, Magic Bytes, Redis Cache Hit
│       ├── test_history.py       # ตรวจสอบ History Retrieval, Pagination, Deletion
│       └── test_admin.py         # ตรวจสอบ Admin Auth, Reports Review, User Ban
└── run.sh                        # เชลล์สคริปต์สำหรับการสั่งรันตามพารามิเตอร์
```

---

## 2. รายละเอียดโมดูลการทดสอบ (Test Modules Breakdown)

### 2.1 Health & Service Readiness (`test_health.py`)
- ตรวจสอบ `GET /health` และ `GET /api/v1/health`
- ยืนยันการเชื่อมต่อของ Database Driver และ Redis Client
- เกณฑ์ผ่าน: HTTP 200 OK พร้อมฟิลด์สถานะ `healthy`

### 2.2 Authentication Flow (`test_auth_flow.py`)
- ทดสอบการลงทะเบียนผู้ใช้ใหม่ด้วยอีเมลสุ่ม (Randomized Email) เพื่อป้องกันชนกับข้อมูลเก่า
- ทดสอบการเข้าสู่ระบบและตรวจสอบโครงสร้าง JWT Token
- ทดสอบกรณี Negative: ปฏิเสธการลงทะเบียนอีเมลซ้ำ (HTTP 400), ปฏิเสธรหัสผ่านผิด (HTTP 401)
- ตรวจสอบ `GET /api/v1/auth/me` ภายใต้ Bearer Authorization Header

### 2.3 Scan Workflow & Caching (`test_scan_workflow.py`)
- สร้างไฟล์ภาพจำลองในหน่วยความจำผ่าน `image_factory.py` (RGB 512x512)
- ส่งคำขอ `POST /api/v1/scan/` แบบ Multipart
- ตรวจสอบการส่งคืน `scan_id`, `risk_score`, และ `risk_level` (ตรงตาม 3 ระดับ)
- ทดสอบ Cache Hit โดยการส่งภาพเดิมซ้ำ ตรวจสอบว่า `cached: true` และตอบกลับทันที
- ทดสอบส่งไฟล์ที่ไม่ใช่รูปภาพ (Text file หรือ Corrupted file) เพื่อยืนยันการปฏิเสธของระบบ

### 2.4 History Management (`test_history.py`)
- ตรวจสอบ `GET /api/v1/history/` ยืนยันว่าพบรายการที่เพิ่งสแกน
- ตรวจสอบโครงสร้างข้อมูลรายการประวัติว่ามีฟิลด์ `id`, `timestamp`, `risk_score` ครบถ้วน
- ทดสอบการส่งคำขอลบประวัติ `DELETE /api/v1/history/{scan_id}`

### 2.5 Admin Operations (`test_admin.py`)
- ทดสอบการล็อกอินของแอดมินและการเข้าถึง Protected Admin Endpoints
- ทดสอบการปฏิเสธ User ทั่วไปเมื่อพยายามเรียก `/api/v1/admin/*` (HTTP 403 Forbidden)
- ทดสอบการอนุมัติ/ปฏิเสธรายงานข้อร้องเรียนและการทำงานของคอลัมน์ `version`

---

## 3. ขั้นตอนการสั่งรันและรายงานผล (Execution & Reporting)

### 3.1 คำสั่งการรัน
```bash
# รันชุดทดสอบ API ทั้งหมดผ่านเชลล์สคริปต์
cd /home/panuwat/project/tests_all/automate_tests
./run.sh api

# หรือสั่งรันผ่าน Pytest โดยตรง
source ../../server/venv/bin/activate
pytest tests/api -v --tb=short
```

### 3.2 การบันทึกผลการทดสอบ
- บันทึกรายงานผลการทดสอบลงใน `tests_all/tests_report/automate_tests/server/`
- ต้องระบุรายละเอียด 4 มิติ: รายการที่ผ่าน, พฤติกรรมที่ผ่าน, รายการที่ไม่ผ่าน (ถ้ามี), และสาเหตุที่ไม่ผ่าน

---

## 4. เกณฑ์การยอมรับ (Acceptance Criteria)
- ชุดทดสอบ API ทั้งหมดต้องผ่าน 100% (Zero Failure)
- เวลาในการรันชุดทดสอบทั้งหมดต้องไม่เกิน 30 วินาที เพื่อรองรับการทำงานใน CI/CD Pipeline
