---
title: "ความต้องการเชิงฟังก์ชัน (Functional Requirements)"
category: requirements
tags: [functional, FR, use-case, canonical]
sources: [Document/srs/05_Software_Requirement_Specification.md, Document/srs/06_Requirement_Traceability.md, Document/srs/07_Appendix_A_Full_Traceability_Matrix.md]
updated: 2026-09-16
---

# ความต้องการเชิงฟังก์ชัน (Functional Requirements)

สรุป Functional Requirements โดยใช้รหัสชุดเดียวกับ SRS ฉบับ canonical

> **Canonical ID policy:** `Document/srs/05_Software_Requirement_Specification.md` เป็นแหล่งอ้างอิงเลข FR/NFR เพียงชุดเดียว Wiki ไม่สร้าง alias หรือ catalog ระดับหยาบคู่ขนานอีก

---

## Authentication & Authorization

- **FR-AUTH-01 — การสมัครสมาชิก:** รับ Full Name, Email, Password, `system_consent` และ `research_consent` ใน body ของ `POST /api/v1/auth/register` แล้วบันทึก `users` กับ `consent_logs`
- **FR-AUTH-02 — การเข้าสู่ระบบ:** Email/Password และ JWT; Mobile เก็บ token ใน Secure Storage
- **FR-AUTH-03 — การต่ออายุ Token:** ออก Access Token ใหม่จาก Refresh Token
- **FR-AUTH-04 — การออกจากระบบ:** ล้าง token และข้อมูล session ฝั่ง client

Code v1 รองรับ Email/Password เท่านั้น; Google/Apple OAuth ไม่ใช่ FR ใน baseline นี้

## Image Upload & Scan

- **FR-SCAN-01 — เลือกและครอบตัดรูปภาพ:** เลือกจาก Gallery และครอบตัดได้
- **FR-SCAN-02 — ตรวจสอบและอัปโหลด:** ตรวจไฟล์ก่อนส่ง multipart ไปยัง `POST /api/v1/scan/`
- **FR-SCAN-03 — Cache และประมวลผล:** คำนวณ SHA-256, ค้น Redis และรัน pipeline เมื่อ cache miss; Mobile poll `GET /api/v1/scan/{scan_id}` ทุก 3 วินาที

## Multi-layer Analysis

- **FR-ANALYSIS-01 — Textual Analysis:** Surya OCR + keyword matching สร้าง `text_score`
- **FR-ANALYSIS-02 — Visual Analysis:** SegFormer/ONNX วิเคราะห์รอยตัดต่อและค่า AI-generated เพื่อสร้าง `visual_score`
- **FR-ANALYSIS-03 — Source Analysis:** Reverse Image Search สร้าง `source_score`; หากบริการไม่พร้อมต้องระบุสถานะและไม่สรุปว่าภาพปลอดภัย
- **FR-ANALYSIS-04 — Risk Score Calculation:** คำนวณจาก 3 มิติ Visual/Textual/Source ด้วย Hybrid max+bonus; EXIF เก็บเป็น display-only และไม่ร่วมคำนวณ

## Explainability, History & Reporting

- **FR-XAI-01 — Mask-to-Heatmap Overlay:** สร้าง Heatmap, แสดงภาพซ้อนทับ, toggle/opacity และคำอธิบาย XAI
- **FR-HISTORY-01 — จัดการประวัติการสแกน:** แสดงรายการ/รายละเอียดและลบประวัติของตนเอง
- **FR-HISTORY-02 — รายงานภาพหลอกลวง:** ส่ง Scam Report ไปยังคิวตรวจสอบของ Admin

## PDPA & Consent

- **FR-PDPA-01 — Consent Management:** `system_consent` และ `research_consent` ถูกส่งใน register body และบันทึกใน `consent_logs`; research consent ถอนได้

## Admin Portal

- **FR-ADMIN-01 — Dashboard & User Management:** ดู dashboard และจัดการบัญชีผู้ใช้
- **FR-ADMIN-02 — Report Queue Management:** ตรวจ อนุมัติ หรือปฏิเสธ Scam Report
- **FR-ADMIN-03 — Model Management:** ดูรุ่นโมเดลและสั่ง deploy/dry-run ตาม endpoint ที่ code มี
- **FR-ADMIN-04 — Audit Logs Viewer:** ดู audit log แบบ append-only

บัญชี Mobile อยู่ใน `users`; บัญชี Admin Portal อยู่ใน `admins` และใช้ `admin_sessions` แยกจากกัน

## ประเด็นสำคัญ

- Catalog canonical มี 19 FR: AUTH 4, SCAN 3, ANALYSIS 4, XAI 1, HISTORY 2, PDPA 1 และ ADMIN 4
- Acceptance Criteria และ traceability ฉบับเต็มอยู่ใน `Document/srs/05_*`, `06_*` และ `07_*`
- พฤติกรรมที่ Document กับ code ไม่ตรงกันให้ติดป้าย implementation gap โดยไม่ออก ID ใหม่ใน Wiki

## หน้าที่เกี่ยวข้อง

- [[requirements/srs]]
- [[requirements/non-functional-requirements]]
- [[requirements/traceability-matrix]]
- [[requirements/use-case-diagram]]
- [[architecture/mobile-app]]
- [[architecture/backend-api]]
- [[concepts/multi-layer-analysis]]
