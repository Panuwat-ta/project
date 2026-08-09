---
title: "เทคโนโลยีที่ใช้ (Technology Stack)"
category: entities
tags: [tech-stack, Flutter, FastAPI, PyTorch, ONNX, PostgreSQL, Redis]
sources: [design/architecture.md]
updated: 2026-08-02
---

# เทคโนโลยีที่ใช้ (Technology Stack)

รายการเทคโนโลยีที่เลือกใช้สำหรับโปรเจค พร้อมเหตุผลทางวิศวกรรม

---

## สรุป Full Stack

| ส่วนประกอบ | เทคโนโลยี | เหตุผล |
| :--- | :--- | :--- |
| **Mobile App** | Flutter (Dart) | รองรับ Android (และ iOS ในอนาคต) ด้วย Codebase เดียว; รองรับ Dark Mode ดีเยี่ยม; ใช้ BLoC State Management |
| **Admin Portal** | React.js + Tailwind CSS | โหลดข้อมูล Dynamic รวดเร็ว; จัดการ State สำหรับ Dashboard ได้ดี; เขียนแบบ Component-based |
| **API Backend** | Python FastAPI | Async I/O ประสิทธิภาพเทียบเท่า Go/Node.js; ตรวจสอบ Pydantic อัตโนมัติ; Auto-generated OpenAPI Docs |
| **AI Training** | PyTorch | Framework มาตรฐานอุตสาหกรรมสำหรับ Deep Learning; มี Ecosystem ของ SegFormer รองรับดี |
| **AI Inference** | ONNX Runtime | เร็วกว่า Native PyTorch 2–5 เท่าตอน Serving; ไม่ยึดติดกับ Framework |
| **Primary Database** | PostgreSQL | ACID Transactions; ความถูกต้องของ Relational Data; รองรับ PostGIS สำหรับฟีเจอร์พิกัดในอนาคต |
| **Cache** | Redis | ค้นหา Image Hash ไวระดับ Sub-millisecond; ลดโหลด AI Inference สำหรับรูปซ้ำได้มหาศาล |
| **File Storage** | Cloud Object Storage | ขยายได้ไม่จำกัด; ใช้ Presigned URL เพื่อความปลอดภัยของ Client |
| **Reverse Image Search** | Google Vision API | ค้นหาภาพย้อนกลับครอบคลุมและแม่นยำที่สุด |
| **Push Notifications** | Firebase Cloud Messaging (FCM) | ฟรี, เสถียรบน Android, ไม่ต้องบริหาร Infrastructure เอง |

---

## รายละเอียดฝั่ง Mobile App

- **State Management:** BLoC (Business Logic Component)
- **HTTP Client:** Dio + Secure Storage สำหรับเก็บ JWT
- **จัดการรูปภาพ:** `image_picker` + `image_cropper`
- **Platform:** Android (หลัก), iOS (อนาคต)
- **Architecture:** Clean Architecture (Presentation / Domain / Data)

ดูเพิ่มเติมที่ [[architecture/mobile-app]]

---

## รายละเอียดฝั่ง AI

| ส่วน | เทคโนโลยี | หมายเหตุ |
| :--- | :--- | :--- |
| Core Model | SegFormer | Transformer-based Semantic Segmentation |
| Training Framework | PyTorch | มาตรฐาน; Ecosystem ใหญ่ |
| Serving Format | ONNX | แปลงจาก PyTorch หลัง Train เสร็จ |
| Inference Runtime | ONNX Runtime | Engine สำหรับ Serving ที่ Optimized แล้ว |
| XAI | Heatmap | คำนวณจาก Segmentation Mask หลัง Inference |
| OCR | Surya-OCR | ดึงข้อความภาษาไทย + อังกฤษ |
| ฟีเจอร์ AI อนาคต | SynthID, Gemini | ตรวจจับ Watermark, วิเคราะห์ด้วย LLM (ยังไม่ได้ออกแบบ) |

---

## ทำไมไม่ใช้ React Native สำหรับ Mobile?

> [!NOTE]
> ใน SRS (`doc/objective.md`) ขัอ OBJ-01 ระบุว่า "Cross-Platform (React Native)" แต่ในเอกสารการออกแบบ (`design/architecture.md`, `design/mobile.md`) ระบุ **Flutter** อย่างสม่ำเสมอ เอกสารการออกแบบเป็นเวอร์ชันที่ใหม่กว่าและใช้อ้างอิงเป็นหลัก — Flutter คือเทคโนโลยีที่ถูกนำมาใช้จริง ดูบันทึกฉบับเต็มได้ที่ [[decisions/technology-choices]]

---

## หน้าที่เกี่ยวข้อง

- [[decisions/technology-choices]]
- [[architecture/system-architecture]]
- [[architecture/mobile-app]]
- [[architecture/backend-api]]
- [[architecture/ai-inference-service]]
- [[concepts/ai-model-segformer]]
