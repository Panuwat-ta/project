---
title: "Software Requirements Specification (SRS)"
category: requirements
tags: [requirements, SRS, canonical, baseline]
sources: [Document/srs/05_Software_Requirement_Specification.md, Document/srs/06_Requirement_Traceability.md, Document/srs/07_Appendix_A_Full_Traceability_Matrix.md]
updated: 2026-09-16
---

# Software Requirements Specification (SRS)

Wiki หน้านี้เป็นสรุปสำหรับอ่านเร็ว โดยยึด SRS ใน `Document/srs/` เป็น canonical catalog

> **Authority:** รหัสข้อกำหนดและ Acceptance Criteria ต้องอ้างจาก `Document/srs/05_Software_Requirement_Specification.md`; traceability อ้างจาก `06_Requirement_Traceability.md` และ `07_Appendix_A_Full_Traceability_Matrix.md` เท่านั้น Wiki ไม่มี catalog คู่ขนาน

---

## 1. ขอบเขต v1

- Mobile App: Flutter บน Android เท่านั้น
- Admin Portal: React 19 + Vite 8 + Tailwind CSS v4
- Backend: FastAPI application เดียว โดยแยก ONNX inference เป็น worker subprocess
- Data: PostgreSQL, Redis และ local filesystem (`LOCAL_UPLOAD_DIR`, เสิร์ฟผ่าน `/uploads`)
- Authentication: Mobile ใช้ `users`; Admin Portal ใช้ `admins` และ `admin_sessions` แยกกัน
- Async scan: Mobile อัปโหลดด้วย `POST /api/v1/scan/` และ poll `GET /api/v1/scan/{scan_id}`; ไม่มี Mobile WebSocket client

## 2. Functional Requirements

| หมวด | Canonical IDs | ขอบเขต |
| :--- | :--- | :--- |
| Authentication | FR-AUTH-01..04 | สมัคร, login, refresh, logout |
| Scan | FR-SCAN-01..03 | เลือก/ครอปตัด, validate/upload, cache/process |
| Analysis | FR-ANALYSIS-01..04 | Textual, Visual, Source และ Risk Score |
| XAI | FR-XAI-01 | Mask-to-Heatmap overlay และคำอธิบาย |
| History/Report | FR-HISTORY-01..02 | ประวัติการสแกนและรายงานภาพหลอกลวง |
| PDPA | FR-PDPA-01 | บันทึก consent จาก register body และจัดการการถอนยินยอม |
| Admin | FR-ADMIN-01..04 | Dashboard/User, Report Queue, Model, Audit Logs |

รายละเอียดอยู่ที่ [[requirements/functional-requirements]]

## 3. Non-Functional Requirements

| Canonical ID | หัวข้อหลัก |
| :--- | :--- |
| NFR-01 | Response Time |
| NFR-02 | Scalability |
| NFR-03 | Availability & Monitoring |
| NFR-04 | Security |
| NFR-05 | Model Accuracy |
| NFR-06 | Usability & Explainability |
| NFR-07 | Cache Efficiency |
| NFR-08 | Android Compatibility & API Interoperability |
| NFR-09 | Maintainability & Modularity |

ไม่ออกหมายเลข NFR เพิ่มจากชุด NFR-01..09 ใน Wiki; เนื้อหา PDPA อยู่ใต้ FR-PDPA-01/NFR-04 และ fallback อยู่ใต้ FR-ANALYSIS-03 AC-4

## 4. กฎทางโดเมนที่ใช้จริง

- Overall Risk Score คำนวณจาก Visual, Textual และ Source เท่านั้น; EXIF เป็น display-only
- Risk Grade: Low 0–39, Medium 40–69, High 70–100; `visual_score >= 80` บังคับ High
- Badge ฝั่ง Mobile: Low สีเขียว, Medium สี amber, High สีแดง
- mIoU คือค่าเฉลี่ย IoU ข้ามคลาส ไม่ใช่ pixel accuracy
- Config v10 ใช้ Cross-Entropy `loss_weight=1.0`, `class_weight=[1.0, 2.5]` ร่วมกับ Dice `loss_weight=1.5`

## 5. ประเด็นสำคัญ

- Document เป็น canonical สำหรับ requirement IDs
- Code เป็น canonical สำหรับพฤติกรรมที่ implement แล้ว
- หาก Document กับ code ไม่ตรงกัน ให้แก้ Document ตาม code หรือติดป้ายว่าเป็น backlog/GAP อย่างชัดเจน

## หน้าที่เกี่ยวข้อง

- [[requirements/functional-requirements]]
- [[requirements/non-functional-requirements]]
- [[requirements/traceability-matrix]]
- [[requirements/use-case-diagram]]
- [[architecture/system-architecture]]
- [[testing/test-cases]]
