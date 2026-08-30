---
title: "Backend API — FastAPI Orchestrator"
category: architecture
tags: [FastAPI, backend, orchestrator, OCR, NLP, EXIF, auth, RBAC]
sources: [design/architecture.md, design/server.md]
updated: 2026-08-02
---

# Backend API — FastAPI Orchestrator

Python FastAPI ทำหน้าที่เป็น **Core Orchestrator** ของระบบ เป็นจุดเข้าเดียวสำหรับ Request ทั้งหมดและประสานงาน Multi-layer Analysis Pipeline

---

## บทบาทในระบบ

API Application อยู่ระหว่าง Client (Mobile App, Admin Portal) กับ Service ปลายทาง (AI Inference, Database, External API) โดยทำหน้าที่:

1. ตรวจสอบ Authentication และ Authorization
2. รัน Analysis ที่ทำได้รวดเร็วใน Process เดียว (EXIF, OCR/NLP)
3. ส่งงานหนักไปยัง AI Inference Service
4. จัดการ Cache Lookup และบันทึกผลลัพธ์
5. ส่ง Push Notification เมื่อ Async Job เสร็จ

---

## โครงสร้างโฟลเดอร์โปรเจค

```
server/
  app/
    core/
      config.py       # อ่านค่า Environment Variables (.env)
      security.py     # JWT Encoding/Decoding, Password Hashing
      database.py     # SQLAlchemy Engine และ Session Factory
    models/           # ORM Models (SQLAlchemy)
      user.py
      scan.py
      report.py
    repositories/     # Data Access Layer (Queries)
      user_repo.py
      scan_repo.py
    services/         # Business Logic
      auth_service.py
      ocr_service.py        # Surya-OCR Integration
      scan_service.py       # Multi-layer Orchestration, Risk Aggregation
      storage_service.py
    api/
      v1/
        auth.py       # /register, /login endpoints
        scan.py       # /scan endpoints
        report.py     # /report endpoints
        admin.py      # จัดการโมเดล (Admin เท่านั้น)
      router.py
    main.py           # FastAPI Initialization
  migrations/         # Alembic DB Migration Scripts
  requirements.txt
  Dockerfile
```

---

## ความรับผิดชอบหลัก

### 1. Authentication และ Authorization

- ลงทะเบียนและ Login ด้วย Email/Password
- Google OAuth (Social Login)
- ออก JWT Token เมื่อ Login สำเร็จ ตรวจสอบทุก Protected Endpoint
- **RBAC** — แยก Role ผู้ใช้ทั่วไปและ Admin Endpoint ที่เป็น Admin Only ล็อคด้วย Dependency Injection

### 2. การดึง EXIF Metadata

- ดึง Metadata ที่ซ่อนอยู่ในรูปภาพ (พิกัด GPS, รุ่นกล้อง, วันที่สร้าง, Software ที่ใช้)
- ความไม่สอดคล้องของ Metadata (เช่น มี "Photoshop" ใน Software Field, GPS ไม่ตรง) มีส่วนในการประเมินความเสี่ยง
- รันใน Process เดียวกับ API Application ไม่ต้องเรียก External Service

### 3. OCR และ NLP วิเคราะห์ข้อความ

- **OCR Engine:** Surya-OCR (รองรับภาษาไทยและอังกฤษ)
- ข้อความที่ดึงได้ → ส่งให้ NLP Module (RegEx Pattern + โมเดล NLP ขนาดเล็ก)
- ตรวจจับคำหลอกลวง: คำแสดงความเร่งด่วน, สัญญาผลตอบแทนสูง, ชื่อที่อยู่ใน Blacklist
- สร้างคะแนน `S_text` (0–100) ซึ่งมีน้ำหนัก 25% ของ Risk Score รวม

### 4. ประสานงาน Job

- ตรวจสอบ Redis Cache สำหรับ Image Hash ที่เคยวิเคราะห์แล้ว
- Cache Miss: ส่ง Task ตามลำดับ (Metadata → OCR → Visual → Source → AI-Gen)
- รวมผลลัพธ์บางส่วนจาก AI Inference Service เป็น Weighted Risk Score
- เก็บผลลัพธ์ใน PostgreSQL และ Cache Image Hash ใน Redis
- ส่ง FCM Push Notification เมื่อ Async Processing เสร็จ

---

## API Endpoints (v1)

| Method | Path | คำอธิบาย |
| :--- | :--- | :--- |
| POST | `/api/v1/auth/register` | สร้าง Account ใหม่ |
| POST | `/api/v1/auth/login` | ยืนยันตัวตน รับ JWT |
| POST | `/api/v1/scan` | อัปโหลดรูปเพื่อวิเคราะห์ |
| GET | `/api/v1/scan/{id}` | ดึงผลลัพธ์สแกนตาม ID |
| GET | `/api/v1/scan/history` | ดูประวัติสแกนของผู้ใช้ |
| POST | `/api/v1/report` | ส่งรายงาน Scam |
| GET | `/api/v1/admin/reports` | (Admin) ดูรายการรายงานที่รอตรวจสอบ |
| POST | `/api/v1/admin/model` | (Admin) อัปโหลด Model Weight ใหม่ |

> [!NOTE]
> API Specification ฉบับเต็มอยู่ใน `design/server.md` ซึ่งยังไม่ได้ ingest ครบ อาจมี Endpoint เพิ่มเติม

---

## ประสิทธิภาพ

- FastAPI รัน **Asynchronous** — เหมาะสำหรับ Request พร้อมกันจำนวนมากขณะรอ I/O
- Throughput เทียบเท่า Go/Node.js สำหรับงาน I/O-bound
- Pydantic Validation อัตโนมัติสำหรับ Request/Response
- OpenAPI Documentation สร้างอัตโนมัติที่ `/docs`

---

## หน้าที่เกี่ยวข้อง

- [[architecture/system-architecture]]
- [[architecture/ai-inference-service]]
- [[architecture/database-schema]]
- [[architecture/external-integrations]]
- [[concepts/multi-layer-analysis]]
- [[concepts/risk-scoring]]
- [[requirements/non-functional-requirements]]
