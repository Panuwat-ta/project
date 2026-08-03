---
title: "สารบัญ Wiki — โปรเจค Scam Image Detection"
updated: 2026-08-02
---

# สารบัญ Wiki

รายการหน้าทั้งหมดใน wiki จัดหมวดหมู่ตามประเภท อัปเดตทุกครั้งที่มีการเพิ่มหน้าใหม่ ให้อ่านไฟล์นี้ก่อนเสมอเมื่อต้องการค้นหาข้อมูล

---

## ภาพรวม

| หน้า | สรุป |
| :--- | :--- |
| [[overview]] | ภาพรวมโปรเจคทั้งหมด — คืออะไร ทำไมต้องมี และทำงานอย่างไรตั้งแต่ต้นจนจบ |

---

## ความต้องการของระบบ

| หน้า | สรุป |
| :--- | :--- |
| [[requirements/objectives-kpis]] | วัตถุประสงค์โปรเจค (OBJ-01 ถึง OBJ-04) และ KPI เชิงปริมาณ/เชิงคุณภาพ |
| [[requirements/functional-requirements]] | ความต้องการเชิงฟังก์ชันจาก SRS และ Use Case |
| [[requirements/non-functional-requirements]] | ประสิทธิภาพ, ความปลอดภัย, ความพร้อมใช้งาน และการปฏิบัติตาม PDPA |

---

## สถาปัตยกรรม

| หน้า | สรุป |
| :--- | :--- |
| [[architecture/system-architecture]] | ภาพรวมสถาปัตยกรรม Cloud-Native แบบ 3 ชั้น และ data flow |
| [[architecture/mobile-app]] | Flutter Mobile App: Clean Architecture, BLoC, หน้าจอต่างๆ และขั้นตอนการอัปโหลดรูป |
| [[architecture/backend-api]] | FastAPI Orchestrator: auth, OCR/NLP, ดึง metadata และประสานงาน job |
| [[architecture/ai-inference-service]] | PyTorch/ONNX AI Node: ELA, ตรวจจับภาพ AI-Gen, สร้าง Grad-CAM |
| [[architecture/database-schema]] | PostgreSQL schema, Redis cache strategy, Cloud Object Storage layout |
| [[architecture/external-integrations]] | Google Vision API (reverse search), Firebase FCM และ integration อื่นๆ ในอนาคต |

---

## แนวคิดและเทคนิค

| หน้า | สรุป |
| :--- | :--- |
| [[concepts/multi-layer-analysis]] | การวิเคราะห์ 3 ชั้น: Textual, Source Verification, Visual Anomaly |
| [[concepts/risk-scoring]] | สูตรคำนวณ Weighted Risk Score, เกณฑ์ระดับความเสี่ยง และการรวมคะแนน |
| [[concepts/explainable-ai]] | แนวทาง XAI: การสร้าง Grad-CAM Heatmap, overlay ลงรูปภาพ และการแสดงผล UI |
| [[concepts/ai-model-segformer]] | สถาปัตยกรรม SegFormer, MiT encoder, All-MLP decoder และ output ระดับพิกเซล |
| [[concepts/ela-technique]] | Error Level Analysis — หลักการทำงานและการตรวจจับบริเวณที่ถูกดัดแปลง |

---

## เอนทิตี

| หน้า | สรุป |
| :--- | :--- |
| [[entities/actors]] | ผู้ใช้ทั่วไปและ Admin/Researcher — บทบาทและรูปแบบการใช้งาน |
| [[entities/tech-stack]] | สรุป Technology Stack ทั้งหมดพร้อมเหตุผลเชิงวิศวกรรม |

---

## การตัดสินใจ

| หน้า | สรุป |
| :--- | :--- |
| [[decisions/technology-choices]] | การตัดสินใจเลือกเทคโนโลยีหลัก: Flutter, SegFormer, FastAPI, ONNX |

---

## การวางแผน

| หน้า | สรุป |
| :--- | :--- |
| [[planning/project-scope]] | 4 Development Container, Work Package และงานที่ยังไม่ได้พัฒนา |
| [[planning/team]] | สมาชิกทีม, ความรับผิดชอบ และข้อมูลอาจารย์ที่ปรึกษา |
