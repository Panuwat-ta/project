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
    models/           # ORM Models (SQLAlchemy) — 9 ตาราง
      user.py           # users (role: user/researcher/admin)
      admin.py          # admins (is_superadmin)
      scan.py           # scans (UUID, SHA-256 image_hash, scores, exif/ocr/xai)
      consent.py        # consent_logs (system_consent/research_consent)
      report.py         # scam_reports
      model_version.py  # model_versions (metrics a_acc/m_iou/m_acc/m_dice)
      admin_session.py  # admin_sessions (refresh rotation)
      audit_log.py      # audit_log (เอกพจน์)
      export_job.py     # export_jobs (พหูพจน์)
    services/         # Business Logic
      scan_service          # Multi-layer Orchestration, Risk Aggregation
      inference_service     # Surya OCR + Qwen XAI + เรียก Worker subprocess
      worker                # SegFormer ONNX (tiling 512/overlap 64, mask-heatmap)
      report_service.py / admin_service.py / export_service.py
    api/
      v1/
        auth.py       # /auth: register/login/refresh/logout/me
        scan.py       # /scan (เอกพจน์): POST /, GET /{scan_id}
        report.py     # /reports (พหูพจน์): POST "", GET /categories, GET /my
        history.py    # /history: GET "", GET/DELETE /{scan_id}
        admin.py      # /admin/* (super_admin): login/refresh/logout/me/sessions/dashboard/health/search/reports/users/models/audit-logs/export-jobs
        ws.py         # /ws/admin/dashboard (WS เดียว)
      router.py       # รวม routers (prefix /api/v1)
    main.py           # FastAPI Initialization
  migrations/         # Alembic DB Migration Scripts
  requirements.txt
  Dockerfile
```

---

## ความรับผิดชอบหลัก

### 1. Authentication และ Authorization

- ลงทะเบียนและ Login ด้วย Email/Password — consent ส่งมาใน body ของ register แล้วบันทึกเป็น consent logs
- JWT + refresh/logout/me; Google/Apple OAuth เป็น Phase 2
- แยกบทบาท user/researcher/admin ออกจากบัญชี admins; ทุก /admin/* ต้องเป็น super_admin
- ตรวจสอบทุก Protected Endpoint ด้วยการยืนยันตัวตนและสิทธิ์

### 2. การดึง EXIF Metadata

- ดึง Metadata ที่ซ่อนอยู่ในรูปภาพ (พิกัด GPS, รุ่นกล้อง, วันที่สร้าง, Software ที่ใช้)
- ความไม่สอดคล้องของ Metadata (เช่น มี "Photoshop" ใน Software Field, GPS ไม่ตรง) มีส่วนในการประเมินความเสี่ยง
- รันใน Process เดียวกับ API Application ไม่ต้องเรียก External Service

### 3. OCR และ NLP วิเคราะห์ข้อความ

- **OCR Engine:** Surya-OCR (รองรับภาษาไทยและอังกฤษ)
- ข้อความที่ดึงได้ → ส่งให้ NLP Module (RegEx Pattern + โมเดล NLP ขนาดเล็ก)
- ตรวจจับคำหลอกลวง: คำแสดงความเร่งด่วน, สัญญาผลตอบแทนสูง, ชื่อที่อยู่ใน Blacklist
- สร้างคะแนน `S_text` (0–100%) เป็นมิติอิสระสำหรับการประเมินความเสี่ยง

### 4. ประสานงาน Job

- ตรวจสอบ Redis Cache (TTL 30 วัน) สำหรับ Image Hash ที่เคยวิเคราะห์แล้ว
- Cache Miss: ประมวลผลผ่าน ONNX Worker subprocess แล้วรวมผลเป็น Hybrid max+bonus Risk Score
- เก็บผลลัพธ์ใน PostgreSQL + เขียนไฟล์รูปต้นฉบับและ Heatmap ลง Storage
- ส่ง FCM Push Notification เมื่อ Async Processing เสร็จ

---

## API Endpoints (v1 — prefix /api/v1)

### Auth (/api/v1/auth)
| Method | Path | คำอธิบาย |
| :--- | :--- | :--- |
| POST | `/api/v1/auth/register` | สร้าง Account ใหม่ (consent ผ่าน body) |
| POST | `/api/v1/auth/login` | ยืนยันตัวตน รับ JWT |
| POST | `/api/v1/auth/refresh` | ต่ออายุ token ด้วย refresh token |
| POST | `/api/v1/auth/logout` | ออกจากระบบ |
| GET | `/api/v1/auth/me` | โปรไฟล์ผู้ใช้ปัจจุบัน |

### Scan (/api/v1/scan เอกพจน์)
| Method | Path | คำอธิบาย |
| :--- | :--- | :--- |
| POST | `/api/v1/scan/` | อัปโหลดรูป (multipart file + title) เพื่อวิเคราะห์แบบ async |
| GET | `/api/v1/scan/{scan_id}` | ดึงผลลัพธ์สแกนตาม ID / poll สถานะ |

### Reports (/api/v1/reports พหูพจน์)
| Method | Path | คำอธิบาย |
| :--- | :--- | :--- |
| POST | `/api/v1/reports` | ส่งรายงาน Scam |
| GET | `/api/v1/reports/categories` | รายการประเภทรายงาน |
| GET | `/api/v1/reports/my` | รายงานที่ตนเองเคยส่ง |

### History (/api/v1/history)
| Method | Path | คำอธิบาย |
| :--- | :--- | :--- |
| GET | `/api/v1/history` | ประวัติสแกนของผู้ใช้ |
| GET | `/api/v1/history/{scan_id}` | รายละเอียดประวัติ |
| DELETE | `/api/v1/history/{scan_id}` | ลบประวัติ (ลบไฟล์จริงถ้าไม่มี scan อื่นใช้ hash เดียวกัน) |

### Admin (/api/v1/admin/* — ต้อง super_admin ทั้งหมด)
| Method | Path | คำอธิบาย |
| :--- | :--- | :--- |
| POST | `/api/v1/admin/login` | Login admin |
| POST | `/api/v1/admin/refresh` | Rotate admin session |
| POST | `/api/v1/admin/logout` | เพิกถอน session ปัจจุบัน |
| GET/PATCH | `/api/v1/admin/me` | โปรไฟล์ admin |
| GET/POST | `/api/v1/admin/sessions`, `/api/v1/admin/sessions/{id}/revoke` | จัดการ sessions |
| GET | `/api/v1/admin/dashboard` | สถิติภาพรวม |
| GET | `/api/v1/admin/health` | สุขภาพระบบ |
| GET | `/api/v1/admin/search?q=` | ค้นหาทั่ว |
| GET/PATCH/POST | `/api/v1/admin/reports`, `/{id}`, `/{id}/review` | คิว moderation |
| GET/PATCH | `/api/v1/admin/users`, `/api/v1/admin/users/{id}` | จัดการผู้ใช้ |
| GET | `/api/v1/admin/models` | รายการ model_versions |
| POST | `/api/v1/admin/models/{id}/deploy`, `/api/v1/admin/models/{id}/dry-run` | deploy/dry-run โมเดล |
| GET | `/api/v1/admin/audit-logs` | ตาราง audit_log |
| POST/GET | `/api/v1/admin/dataset/export-jobs`, `/{job_id}`, `/{job_id}/cancel`, `/{job_id}/download` | export jobs |

### WebSocket (/api/v1/ws)
| Method | Path | คำอธิบาย |
| :--- | :--- | :--- |
| WS | `/api/v1/ws/admin/dashboard` | Dashboard realtime (role admin) |

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
