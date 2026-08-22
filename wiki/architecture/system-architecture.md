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
- **Decoupled Architecture** — Mobile Frontend แยกจาก Business Logic; AI Inference Node แยกจาก API Gateway ช่วยให้ Scale GPU Inference อย่างอิสระโดยไม่ต้อง Scale ทั้ง Backend
- **Microservices** — API Application และ AI Inference Service เป็นหน่วยที่ Deploy แยกกันได้

---

## 3 ชั้นของระบบ

```
+---------------------------+
|   ชั้นการแสดงผล          |   Flutter Mobile App (Android)
|   (Presentation Layer)    |   React.js Admin Portal
+---------------------------+
            |  HTTPS/REST
+---------------------------+
|   ชั้นธุรกิจและประมวลผล  |   FastAPI API Application (Orchestrator)
|   (Backend Layer)         |   AI Inference Service (PyTorch/ONNX)
+---------------------------+
            |
+---------------------------+
|   ชั้นข้อมูลและจัดเก็บ   |   PostgreSQL (ข้อมูลเชิงสัมพันธ์)
|   (Data & Storage Layer)  |   Redis (Image Hash Cache)
|                           |   Cloud Storage (ไฟล์รูปและ Heatmap)
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
| Admin Portal | React.js + Tailwind | Dashboard, จัดการรายงาน, Deploy โมเดล |
| API Application | Python FastAPI | Orchestrator, Auth, OCR/NLP, ประสานงาน Job |
| AI Inference Service | PyTorch / ONNX Runtime | Semantic Segmentation, ตรวจจับ AI-Gen, สร้าง Heatmap |
| Main DB | PostgreSQL | ผู้ใช้, ประวัติสแกน, รายงาน, Log |
| Cache Store | Redis | ค้นหา Image Hash, Cache ผลลัพธ์ |
| Object Storage | Cloud Storage | รูปภาพดิบ, Heatmap Overlay |

---

## โปรโตคอลการสื่อสาร

| การเชื่อมต่อ | โปรโตคอล |
| :--- | :--- |
| Mobile/Admin → API Gateway | HTTPS / REST JSON |
| API Gateway → AI Inference Service | HTTP (ภายใน) |
| API Gateway → PostgreSQL | SQLAlchemy ORM ผ่าน TCP |
| API Gateway → Redis | Redis Protocol |
| API Gateway → Cloud Storage | Cloud SDK (Presigned URLs สำหรับ Client) |
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
