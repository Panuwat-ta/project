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
| Core Model | SegFormer (ONNX เดียว) | Transformer-based Semantic Segmentation, tiling 512/overlap 64 |
| Training Framework | PyTorch | มาตรฐาน; Ecosystem ใหญ่ |
| Serving Format | ONNX | รันผ่าน ONNX Worker subprocess ภายใน Backend เดียวกัน |
| Inference Runtime | ONNX Runtime | Engine สำหรับ Serving ที่ Optimized แล้ว |
| AI-Gen classifier | ค่าความน่าจะเป็นภาพสังเคราะห์จาก AI (0–1) | คู่กับคะแนนความเสี่ยงด้านภาพ |
| XAI | แผนที่ความร้อนแบบ mask-to-heatmap overlay | แปลง Segmentation Mask เป็นภาพสีซ้อนทับบนภาพต้นฉบับ |
| XAI reasoning | Qwen2.5-1.5B | สำหรับสร้างคำอธิบายภาษาไทย |
| OCR | Surya OCR v0.5.0 (Native PyTorch) | ดึงข้อความภาษาไทย + อังกฤษ |
| Risk | Hybrid max+bonus 3 ระดับ: Low 0-39 / Medium 40-69 / High 70-100 | คะแนนฐานจากมิติสูงสุด บวกเพิ่มมิติรอง สูงสุดไม่เกิน 100 |

---

## ทำไมถึงเลือก Flutter สำหรับ Mobile?

> [!NOTE]
> โครงการนี้เลือกใช้ **Flutter** สำหรับการพัฒนาแอปพลิเคชันมือถือแบบ Cross-Platform (Android) เนื่องจากประสิทธิภาพสูง, มี Hot Reload, UI สวยงามด้วย Material Design และ Cupertino, และมี BLoC State Management ที่เขียน Test ได้ง่าย — ดูรายละเอียดการตัดสินใจเทคโนโลยีได้ที่ [[decisions/technology-choices]]

---

## หน้าที่เกี่ยวข้อง

- [[decisions/technology-choices]]
- [[architecture/system-architecture]]
- [[architecture/mobile-app]]
- [[architecture/backend-api]]
- [[architecture/ai-inference-service]]
- [[concepts/ai-model-segformer]]
