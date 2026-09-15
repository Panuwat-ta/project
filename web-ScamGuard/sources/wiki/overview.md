---
title: "ภาพรวมโปรเจค — Scam Image Detection"
category: overview
tags: [ภาพรวม, synthesis, scam-detection, mobile-app, AI]
sources: [README.md, Document/objective.md, design/architecture.md]
updated: 2026-08-02
---

# ภาพรวมโปรเจค: Scam Image Detection

แอปพลิเคชันมือถือที่ใช้การวิเคราะห์หลายชั้นด้วย AI เพื่อช่วยให้ผู้ใช้ทั่วไปตรวจสอบว่ารูปภาพถูกตัดต่อหรือถูกนำมาใช้ในการหลอกลวงหรือไม่ ก่อนที่จะเชื่อหรือโอนเงิน

---

## ปัญหาที่โปรเจคนี้แก้ไข

การหลอกลวงโดยใช้รูปภาพพบได้บ่อยในประเทศไทยและทั่วโลก รูปแบบการโจมตีที่พบบ่อย ได้แก่:

- **Romance Scam** — รูปโปรไฟล์ที่สร้างด้วย AI หรือขโมยจากคนอื่น
- **การตัดต่อภาพ (Image Forgery)** — สกรีนช็อตที่ดัดแปลง, สลิปโอนเงินปลอม, ใบเสร็จที่แก้ไขตัวเลข
- **ภาพสังเคราะห์จาก AI** — ใบหน้าหรือฉากที่สร้างขึ้นทั้งหมดเพื่อหลอกลวง
- **การแอบอ้างตัวตน** — นำรูปจากบริบทหนึ่งไปใช้อ้างตัวตนในอีกบริบท

ผู้ใช้ทั่วไปไม่สามารถตรวจจับสิ่งเหล่านี้ได้ด้วยตาเปล่า แอปนี้คือเครื่องมือนิติวิทยาศาสตร์ดิจิทัลในกระเป๋า

> [!IMPORTANT]
> โปรเจคนี้ตรวจจับ **ภาพหลอกลวงในวงกว้าง** ไม่ใช่เฉพาะ "สลิปปลอม" การแยกแยะประเภทการปลอมแปลง (splicing, copy-move, AI-generation, reverse image identity theft) คือฟีเจอร์หลักของระบบ

---

## แนวทางหลัก: การวิเคราะห์หลายชั้น (Multi-layer Analysis)

ระบบไม่พึ่งพาวิธีตรวจจับเดียว แต่รันการวิเคราะห์ 3 มิติอย่างอิสระและรวมผลเป็น **Overall Risk Score** ตามแนวทาง **Recommended Hybrid Approach (Worst-Case Trigger with Multi-Factor Breakdown)** ดูรายละเอียดที่ [[concepts/multi-layer-analysis]]

| มิติการวิเคราะห์ (Independent Factors) | วิธีการ | ช่วงคะแนนเดี่ยว |
| :--- | :--- | :--- |
| วิเคราะห์ข้อความ (Textual Analysis) | OCR + Keyword/Pattern Matching ตรวจจับคำหลอกลวง | 0–100% |
| ตรวจสอบแหล่งที่มา (Source Verification) | Reverse Image Search ผ่าน Google Vision API (external แบบ optional — เมื่อใช้ไม่ได้ต้องคืนผลบางส่วนพร้อมสถานะตาม FR-ANALYSIS-03 fallback และห้ามสรุปว่าภาพปลอดภัย) | 0–100% |
| ตรวจจับความผิดปกติทางภาพ (Visual Anomaly) | Deep Learning (SegFormer) + Heatmap Output | 0–100% |

- **สูตรคำนวณคะแนนรวม**: ยึดมิติที่มีความเสี่ยงสูงสุดเป็นฐานหลัก $S_{base} = \max(S_{visual}, S_{textual}, S_{source})$ ร่วมกับ Multi-factor Compounding (+5 คะแนนต่อมิติรองที่มีความเสี่ยง $\ge 40$)
- คะแนนรวมอยู่ระหว่าง 0–100 แบ่งเป็น 3 ระดับ: Low (0–39), Medium (40–69), High (70–100 หรือ Visual $\ge 80$) ดูเกณฑ์ที่ [[concepts/risk-scoring]]

---

## สรุปสถาปัตยกรรมระบบ

ระบบเป็นแบบ Cloud-Native และแยกส่วนออกเป็น 3 ชั้น:

1. **Frontend** — Flutter Mobile App (v1: Android; iOS เป็น future) สำหรับผู้ใช้ทั่วไป; React.js Admin Portal สำหรับนักวิจัยและเจ้าหน้าที่
2. **Backend** — Python FastAPI ทำหน้าที่เป็น Orchestrator/API Gateway; ONNX Worker subprocess สำหรับประมวลผลโมเดล
3. **Storage** — PostgreSQL สำหรับข้อมูลเชิงสัมพันธ์; Redis สำหรับ cache; Cloud Storage สำหรับไฟล์รูปภาพและ Heatmap

ดูสถาปัตยกรรมเต็มที่ [[architecture/system-architecture]]

---

## เทคโนโลยีหลัก

| งาน | เทคโนโลยี |
| :--- | :--- |
| Mobile App | Flutter (Dart) — v1 Android, iOS ในอนาคต |
| Admin Portal | React.js + Tailwind CSS |
| API Backend | Python FastAPI |
| โมเดล AI | SegFormer (PyTorch → ONNX) |
| ฐานข้อมูล | PostgreSQL |
| Cache | Redis |
| เก็บไฟล์ | Cloud Object Storage |
| ค้นหาภาพย้อนกลับ | Google Vision API |
| Push Notification | Firebase Cloud Messaging (FCM) — **Phase 2** (v1 ใช้ polling + in-app notification) |

ดูรายละเอียดที่ [[entities/tech-stack]] และ [[decisions/technology-choices]]

---

## ผลลัพธ์ที่ผู้ใช้ได้รับ

1. **Overall Risk Score** (0–100) แสดงเป็น color badge 3 ระดับ (Low / Medium / High) พร้อมผลแจกแจงแยก 3 มิติ (Multi-Factor Breakdown)
2. **Heatmap** ซ้อนทับรูปภาพต้นฉบับแสดงจุดที่โมเดลตรวจพบความผิดปกติ
3. **ผลการวิเคราะห์ข้อความ** — คำหลอกลวงหรือรูปแบบน่าสงสัยที่พบในภาพ
4. **ผลการตรวจสอบแหล่งที่มา** — รูปนี้พบในเว็บไซต์ใดบ้างและกี่แหล่ง

Heatmap เป็นหัวใจของการออกแบบ **Explainable AI (XAI)** ดูที่ [[concepts/explainable-ai]]

---

## ข้อจำกัดของโปรเจค

- **PDPA** — ผู้ใช้ต้องยินยอมก่อนที่รูปภาพจะถูกเก็บหรือใช้เพื่อ training โมเดล ยินยอมแบบแยกส่วนและถอนได้ ดูที่ [[requirements/non-functional-requirements]]
- **เป้าหมายประสิทธิภาพ** — Cache Hit P95 ≤ 3 วินาที (ภาพ 1080p, เครือข่าย 4G/Wi-Fi, หน้าต่างวัด 7 วัน); Full AI inference P50 ≤ 15 วินาที / P95 ≤ 25 วินาทีต่อรูป (ภาพ 1080p, GPU T4)
- **เป้าหมายความแม่นยำ** — โมเดล AI ต้องได้ Accuracy ≥ 85% และ mDice ≥ 85% บน frozen test set 1,000 ภาพ (ดูวิธีวัดใน requirements)
- **เป้าหมาย Availability** — API และ AI Inference Service uptime ≥ 99.5% ต่อรอบ 30 วัน (ไม่รวม maintenance ที่ประกาศล่วงหน้า)

---

## สิ่งที่อยู่นอกขอบเขต (v1)

- วิเคราะห์วิดีโอ (วางแผนในอนาคตด้วย keyframe extraction)
- Inference บนอุปกรณ์ (วางแผนด้วย model quantization)
- แอปเป็น Flutter ทดสอบและรองรับบน Android ใน v1 — iOS เป็น future (build จาก codebase เดียวกันได้)

---

## หน้าที่เกี่ยวข้อง

- [[concepts/multi-layer-analysis]]
- [[concepts/risk-scoring]]
- [[concepts/explainable-ai]]
- [[architecture/system-architecture]]
- [[requirements/objectives-kpis]]
- [[planning/project-scope]]
- [[planning/team]]
- [[entities/tech-stack]]
