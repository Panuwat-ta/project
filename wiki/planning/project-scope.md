---
title: "ขอบเขตโครงการ (Project Scope)"
category: planning
tags: [scope, work-packages, tasks, roadmap, containers]
sources: [doc/scop.md, README.md]
updated: 2026-08-02
---

# ขอบเขตโครงการ (Project Scope)

กำหนดสิ่งที่จะพัฒนา กรอบการทำงานของ 4 Containers หลัก และการแบ่งกลุ่มงานสำหรับสมาชิกทีม

---

## ภาพรวมระบบ (System Overview)

โครงการนี้ถูกแบ่งการพัฒนาออกเป็น **4 Development Containers** บวกกับ **1 Integration Layer**:

| Container | เทคโนโลยีหลัก | ความรับผิดชอบหลัก (Lead) |
| :--- | :--- | :--- |
| Mobile App | Flutter | ภานุวัฒน์ + เอกพันธ์ |
| API Backend | Python FastAPI | ภานุวัฒน์ |
| AI Inference Engine | PyTorch / ONNX | ภานุวัฒน์ |
| Admin Portal | React.js | ภานุวัฒน์ |
| External Integrations | Google Vision, FCM | ภานุวัฒน์ (ออกแบบ) |

---

## กลุ่มงาน Mobile App

| กลุ่มงาน (Task Group) | รายละเอียด (Tasks) |
| :--- | :--- |
| Authentication | สมัครและล็อกอินด้วยอีเมล/รหัสผ่าน, Google OAuth, และระบบ Secure Storage |
| Image Input | ส่วนการเลือกรูปภาพ, การถ่ายภาพ, และโหมด Crop ตัดรูปภาพก่อนส่งให้ระบบ |
| Risk Visualization | ส่วนแสดงผล Risk Score (เกจสี เขียว/เหลือง/แดง), ภาพ Heatmap ทับซ้อน, พร้อมรายละเอียดผลสแกน |
| History & PDPA | แสดงหน้าต่างประวัติการตรวจสอบย้อนหลัง, หน้าต่างยอมรับข้อตกลง PDPA และการยกเลิกอนุญาตข้อมูล |
| Scam Report | แบบฟอร์มกดแจ้งเตือนภาพ Scam ให้ตรวจสอบเพิ่มเติม พร้อมคุณสมบัติ Share ข้อมูล |

---

## กลุ่มงาน API Backend

| กลุ่มงาน (Task Group) | รายละเอียด (Tasks) |
| :--- | :--- |
| API Gateway | โครงสร้าง FastAPI พื้นฐาน, Routing, กฎ CORS, และตรวจสอบ JWT Middleware |
| Metadata / EXIF | โค้ดดึงรายละเอียดจากไฟล์ EXIF Metadata ของภาพที่อัปโหลด |
| OCR + NLP | บริหารและเชื่อมต่อ Surya-OCR สำหรับข้อความ (ไทย/อังกฤษ) และ NLP วิเคราะห์คีย์เวิร์ด |
| Redis Cache Logic | ค้นหารหัสรูป (Image Hash) และตัดสินใจดึงจาก Cache (Hit/Miss Routing) |
| PostgreSQL Schema | ดูแลโครงสร้างระบบตาราง: ผู้ใช้, รายงานสแกน, ระบบส่งรีพอร์ต และ Audit Log พร้อมทำระบบ Alembic Migrations |

---

## กลุ่มงาน AI Engine

| กลุ่มงาน (Task Group) | รายละเอียด (Tasks) |
| :--- | :--- |
| Semantic Segmentation | พัฒนาระบบ Preprocessing ตัดภาพ Semantic Segmentation ออกมา |
| GenAI Detection | พัฒนาและเชื่อมต่อระบบจำแนกและคัดกรองรูปภาพที่มาจากคำสั่ง AI อัตโนมัติ |
| PyTorch to ONNX | ขั้นตอนส่งออกตัว Model ให้อยู่ในมาตรฐานเปิด ONNX สำหรับการโหลดเข้าระบบในตอนรันจริง (Inference) |
| Heatmap | แปลงผลลัพธ์จาก Segmentation Mask เพื่อผลิตภาพ Heatmap คาดทับในขั้นสุดท้าย |

---

## กลุ่มงาน Admin Portal

| กลุ่มงาน (Task Group) | รายละเอียด (Tasks) |
| :--- | :--- |
| RBAC + Dashboard | ตรวจสอบ Role ของ Admin แดชบอร์ดสรุปผลภาพรวม |
| User Management | โค้ดที่ต้องบริหารข้อมูล (CRUD) ผู้ใช้งานในระบบต่างๆ |
| Scam Report Queue | ลำดับการอนุมัติ (Approve) หรือปฏิเสธ (Dismiss) เมื่อได้รับ Scam Report |
| Model Update Console | หน้าต่างสำหรับกดปุ่มรันเพื่อเปลี่ยนน้ำหนัก Model ไฟล์ตัวใหม่เข้าสู่ระบบ |

---

## สิ่งที่อยู่นอกเหนือโครงการในเวลานี้ (Out of Scope v1)

| คุณสมบัติ (Feature) | สถานะ |
| :--- | :--- |
| ระบบ iOS (iOS Support) | เก็บไว้ทำในอนาคต (ณ ตอนนี้รองรับเฉพาะ Android) |
| วิเคราะห์วิดีโอ (Video Analysis) | เก็บไว้ทำในอนาคต โดยการใช้ Keyframe Extraction |
| บนมือถือล้วนๆ (On-device Inference) | เก็บไว้ทำในอนาคต — ต้องผ่านกระบวนการทำ Model Quantization (INT8/FP16) เป็นหลักเสียก่อน |
| การแชร์และตัดสินใจรีวิวแบบ Real-time | ไม่ได้ระบุไว้ในแผน (Not Planned) |
| ระบบของ Google SynthID | ระบุไว้ว่าน่าสนใจแต่ยังไม่มีกระบวนการดีไซน์ในเวลาปัจจุบัน |
| บริการ Google Gemini LLM | ระบุไว้ว่าน่าสนใจแต่ยังไม่มีกระบวนการดีไซน์ในเวลาปัจจุบัน |

---

## ประเด็นสำคัญ (Key Points)

- ภาระงานมีขนาดกว้างมากสำหรับนักศึกษาทำร่วมกัน 2 คน โดย ภานุวัฒน์ แบกรับหน้าที่รับผิดชอบเกือบ 70% ในหลาย Containers พร้อมกัน
- Critical Path ของโครงการประกอบด้วย: การเทรนโมเดล AI (ต้องได้ Accuracy ขั้นต่ำ), API Backend (คือฐานหลักที่เชื่อมโยงทุกส่วน) และตัวแอป Mobile (ที่เป็นสิ่งที่ผู้ใช้สัมผัส)
- PDPA Compliance เป็นโจทย์สำคัญที่คลุมทับการพัฒนาทุกกระบวนการ ทั้ง Frontend, Backend และ AI

---

## หน้าที่เกี่ยวข้อง

- [[planning/team]]
- [[requirements/objectives-kpis]]
- [[requirements/functional-requirements]]
- [[architecture/system-architecture]]
- [[entities/actors]]
