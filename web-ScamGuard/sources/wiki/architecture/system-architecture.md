---
title: "สถาปัตยกรรมระบบ (System Architecture)"
category: architecture
tags: [architecture, cloud-native, decoupled, C1, C2, layers]
sources: [design/architecture.md, Document/C1-System-Context-Diagram.md, Document/C2-Container-Diagram.md]
updated: 2026-08-02
---

# สถาปัตยกรรมระบบ

สถาปัตยกรรมแบบ Cloud-Native และ Decoupled 3 ชั้น สำหรับระบบ Scam Image Detection

---

## หลักการออกแบบ

- **Cloud-Native Architecture** — บริการรันบน Cloud Container; Storage อยู่บน Cloud
- **Decoupled Architecture** — Mobile Frontend แยกจาก Business Logic; งาน AI หนักแยกเป็น ONNX Worker subprocess เพื่อไม่บล็อกการตอบสนองของ FastAPI

---

## 3 ชั้นของระบบ

```
+---------------------------+
|   ชั้นการแสดงผล          |   Flutter Mobile App (Android)
|   (Presentation Layer)    |   React.js Admin Portal (Tailwind CSS)
+---------------------------+
            |  HTTPS/REST
+---------------------------+
|   ชั้นธุรกิจและประมวลผล  |   FastAPI API Application (Orchestrator)
|   (Backend Layer)         |   ONNX Worker subprocess (SegFormer ONNX + Surya OCR + Qwen XAI)
+---------------------------+
            |
+---------------------------+
|   ชั้นข้อมูลและจัดเก็บ   |   PostgreSQL (ข้อมูลเชิงสัมพันธ์)
|   (Data & Storage Layer)  |   Redis (SHA-256 image-hash Cache, TTL 30 วัน)
|                           |   Local filesystem (รูปต้นฉบับ + Heatmap, เสิร์ฟผ่าน /uploads)
+---------------------------+
```

---

## C1: บริบทระบบ (System Context)

| ผู้ใช้/ระบบ | ประเภท | บทบาท |
| :--- | :--- | :--- |
| ผู้ใช้ทั่วไป (General User) | บุคคล | อัปโหลดรูป, ดูรายงานความเสี่ยง |
| Admin / นักวิจัย (Researcher) | บุคคล | ตรวจสอบเคสที่รายงาน, จัดการโมเดลและข้อมูล |
| Scam Image Detection App | Software System | ขอบเขตระบบหลัก |
| Google Vision API / Bing Visual Search | ระบบภายนอก | Reverse Image Search สำหรับ Source Verification |
| Firebase Cloud Messaging (FCM) | ระบบภายนอก | Push Notification เมื่อประมวลผลแบบ Async เสร็จ |

---

## C2: แผนที่ Container

| Container | เทคโนโลยี | ความรับผิดชอบ |
| :--- | :--- | :--- |
| Mobile App | Flutter | แอปผู้ใช้: อัปโหลดรูป, แสดงผลลัพธ์ |
| Admin Portal | React.js + Tailwind CSS | Dashboard, จัดการรายงาน, Deploy โมเดล |
| API Application | Python FastAPI | Orchestrator, Auth, OCR/NLP, ประสานงาน Job |
| ONNX Worker (subprocess) | ONNX Runtime + Surya OCR + Qwen XAI | SegFormer segmentation, AI-Gen prob, แผนที่ความร้อนแบบ mask-to-heatmap overlay |
| Main DB | PostgreSQL | ผู้ใช้, ประวัติสแกน, รายงาน, Log |
| Cache Store | Redis | SHA-256 image-hash Cache, TTL 30 วัน |
| Object Storage | Local filesystem | รูปภาพต้นฉบับและ Heatmap |

---

## โปรโตคอลการสื่อสาร

| การเชื่อมต่อ | โปรโตคอล |
| :--- | :--- |
| Mobile/Admin → API Gateway | HTTPS / REST JSON |
| API Gateway → ONNX Worker | Subprocess IPC ภายใน Backend เดียวกัน |
| API Gateway → PostgreSQL | SQLAlchemy ORM ผ่าน TCP |
| API Gateway → Redis | Redis Protocol (TTL 30 วัน) |
| API Gateway → Local Storage | Filesystem สำหรับรูปภาพและ Heatmap |
| API Gateway → Google Vision API | HTTPS / REST |
| API Gateway → FCM | HTTPS / REST |

---

## ความปลอดภัย

- การสื่อสาร Client-Server ทั้งหมดผ่าน HTTPS/TLS
- JWT Token สำหรับ Authentication เก็บใน Secure Storage บนอุปกรณ์
- RBAC แยกสิทธิ์ User และ Admin อย่างเด็ดขาด
- การจัดการยินยอม (Consent) ตาม PDPA

ดูที่ [[requirements/non-functional-requirements]] สำหรับข้อกำหนดความปลอดภัยและ Compliance ทั้งหมด

---

## หน้าที่เกี่ยวข้อง

- [[architecture/mobile-app]]
- [[architecture/backend-api]]
- [[architecture/ai-inference-service]]
- [[architecture/database-schema]]
- [[architecture/external-integrations]]
- [[entities/tech-stack]]
- [[decisions/technology-choices]]
