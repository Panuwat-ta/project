---
title: "ความต้องการเชิงฟังก์ชัน (Functional Requirements)"
category: requirements
tags: [functional, FR, use-case, features]
sources: [Document/srs.md, Document/Use-Case-Diagram.md, Document/scop.md]
updated: 2026-08-02
---

# ความต้องการเชิงฟังก์ชัน (Functional Requirements)

ความสามารถหลักที่ระบบต้องทำได้ จัดกลุ่มตามผู้ใช้และระบบย่อย

> **ชื่อผลิตภัณฑ์:** ScamGuard (ชื่อเต็ม: Scam Image Detection — แอปตรวจสอบรูปภาพตัดต่อเพื่อป้องกันการหลอกลวง)

> **Canonical catalog:** `Document/docs/05_Software_Requirement_Specification.md` (FR/NFR/AC), `06_Requirement_Traceability.md`, `07_Appendix_A_Full_Traceability_Matrix.md`, `04_Requirement_Candidates.md` (RC) — ไฟล์นี้ใช้เลขชุดเดียวกับ Document; ID กลุ่ม `FR-INPUT/FR-SYS/FR-REPORT/FR-HIST/FR-RPT/FR-ADM/FR-AUDIT/FR-SHARE/FR-SET` เป็น test-scheme ฝั่ง wiki (baseline งานทดสอบใน `tests_all/rtm.md`) โดยแต่ละข้อมี canonical mapping กำกับไว้

---

## ฟังก์ชันฝั่งผู้ใช้ (Mobile App)

### การยืนยันตัวตน (Authentication) — canonical: FR-AUTH-01..04 (Document 05 §2.1)

- **FR-AUTH-01:** ผู้ใช้สมัครสมาชิกด้วย Email/Password ได้ (→ Document FR-AUTH-01)
- **FR-AUTH-02:** ผู้ใช้เข้าสู่ระบบด้วย Email/Password + JWT ได้; โทเค็นเก็บใน Secure Storage ของเครื่อง (Secure Storage = Document FR-AUTH-02 AC-4)
- **FR-AUTH-03:** ผู้ใช้ต่ออายุ Access Token ด้วย Refresh Token ได้ (→ Document FR-AUTH-03)
- **FR-AUTH-04:** ผู้ใช้ออกจากระบบ (Logout) เพื่อล้างค่าเซสชั่นได้ (→ Document FR-AUTH-04; รวมเพิกถอน Refresh Token ฝั่ง server ภายใน 60 วินาที)
- **FR-AUTH-06:** (Phase 2 backlog, RC-AUTH-06 deferred — ไม่ใช่ baseline v1) ผู้ใช้เข้าสู่ระบบด้วย Google OAuth (canonical FR-AUTH-03 = ต่ออายุ Token ตาม Document/docs/05)

> Alias ประวัติ: test-scheme เดิมเรียก Secure Storage+Refresh ว่า FR-AUTH-04 และ Logout ว่า FR-AUTH-05 — ยุบ/ย้ายเป็น FR-AUTH-02/03/04 ตาม Document แล้ว (TC ที่เคยอ้างเลขเก่าอัปเดตตามใน `tests_all/rtm.md` และ `tests_all/manual_tests/`)

### การรับภาพ (Image Input) — test-scheme (canonical: Document FR-SCAN-01/02/03)

- **FR-INPUT-01:** ผู้ใช้เลือกรูปจากคลังภาพ (Gallery) ในเครื่องได้ (→ FR-SCAN-01)
- **FR-INPUT-02:** ผู้ใช้ปรับขนาดและครอบตัด (Crop) ภาพก่อนส่งได้ เพื่อเน้นจุดสนใจ (→ FR-SCAN-01)
- **FR-INPUT-03:** แอปอัปโหลดภาพผ่าน Multipart HTTP เพื่อส่งไปวิเคราะห์ (→ FR-SCAN-02)
- **FR-INPUT-04:** แอปตรวจสอบประเภท/ขนาดไฟล์ก่อนอัปโหลด (jpg/jpeg/png/webp; Mobile ≤ 10MB / API Server ≤ 20MB; decode แล้ว ≤ 100M พิกเซล; trace → SRS FR-02) (→ FR-SCAN-02)

### การแสดงรายงานความเสี่ยง (Risk Report Display) — test-scheme (canonical: Document FR-XAI-01 + FR-ANALYSIS-04)

- **FR-REPORT-01:** แอปแสดงคะแนนความเสี่ยงรวม Overall Risk Score (0-100) พร้อม Color Badge 3 ระดับ (Low/Medium/High; เกณฑ์ตาม Document FR-ANALYSIS-04 — ดูนิยามที่ Document ที่เดียว)
- **FR-REPORT-02:** แอปแสดงภาพ Heatmap ซ้อนทับรูปจริง (→ FR-XAI-01)
- **FR-REPORT-03:** ผู้ใช้กดเปิด/ปิด (Toggle) ภาพ Heatmap ซ้อนทับได้ (→ FR-XAI-01)
- **FR-REPORT-04:** แอปแสดงคะแนนความเสี่ยงแยกย่อยแต่ละชั้น (Textual, Source, Visual) (→ FR-XAI-01 AC-5)
- **FR-REPORT-05:** แอปแสดงคำที่เข้าข่ายน่าสงสัย/หลอกลวง (ถ้าพบโดยโมดูล OCR/NLP) (→ FR-ANALYSIS-01)
- **FR-REPORT-06:** แอปแสดงผล Source Verification (จำนวนเว็บไซต์ที่พบภาพเดียวกัน) (→ FR-ANALYSIS-03)

### ประวัติการสแกน (Scan History) — test-scheme (canonical: Document FR-HISTORY-01)

- **FR-HIST-01:** ผู้ใช้ดูประวัติผลการสแกนย้อนหลังตามลำดับเวลาได้ (→ FR-HISTORY-01)
- **FR-HIST-02:** ผู้ใช้กดเปิดดูรายงานแบบละเอียดของการสแกนเก่าได้ (→ FR-HISTORY-01)
- **FR-HIST-03:** ผู้ใช้ลบประวัติการสแกนได้ (ทีละรายการ + ลบทั้งหมด; ลบไฟล์ original/heatmap ใน Object Storage ด้วย — ตาม PDPA Right to Delete) (→ FR-HISTORY-01)

### แจ้งรายงานหลอกลวง (Scam Reporting) — test-scheme (canonical: Document FR-HISTORY-02)

- **FR-RPT-01:** ผู้ใช้แจ้งยืนยันว่าผลสแกนคือการหลอกลวงจริง เพื่อส่งให้แอดมินตรวจสอบได้ (→ FR-HISTORY-02)

### การแชร์ผลลัพธ์ (Result Sharing) — test-scheme ฝั่ง wiki (ไม่มี FR แยกใน Document; อยู่ใต้ FR-HISTORY-02/FR-08 มุมมอง coarse)

- **FR-SHARE-01:** ผู้ใช้แชร์ภาพผลลัพธ์/คำเตือนความเสี่ยงไปยังแอปพลิเคชันภายนอกได้ (trace → SRS BR-07/FR-08; หลักฐาน 02 SC01 §5; GAP: ยังไม่มี TC)

### การจัดการข้อมูลส่วนบุคคล (PDPA Controls) — test-scheme (canonical: Document FR-PDPA-01)

- **FR-PDPA-01:** แสดงหน้าความยินยอม (Consent Screen) การประมวลผลข้อมูลในครั้งแรกที่เปิดแอป (→ Document FR-PDPA-01)
- **FR-PDPA-02:** ผู้ใช้สามารถถอนความยินยอมในการเข้าร่วมวิจัยได้จากหน้าการตั้งค่าตลอดเวลา (→ Document FR-PDPA-01 AC-3)
- **FR-PDPA-03:** หากถอนความยินยอม ระบบต้องลบภาพ/ข้อมูลของผู้ใช้ออกจาก Research Dataset ภายใน 72 ชม. (→ Document FR-PDPA-01; retention 1 ปี = RC-PDPA-04 deferred Phase 2)

---

## ฟังก์ชันฝั่งแอดมิน (Admin Portal) — test-scheme (canonical: Document FR-ADMIN-01..04)

- **FR-ADM-01:** แอดมินดูสถิติภาพรวมระบบ (จำนวนการสแกน, สถิติความแม่นยำ, ยอดใช้งาน) ได้ (→ FR-ADMIN-01)
- **FR-ADM-02:** แอดมินตรวจสอบรายการ Scam Report จากผู้ใช้ และอนุมัติ/ปัดตก ได้ (→ FR-ADMIN-02)
- **FR-ADM-03:** แอดมิน Export ภาพ Scam ที่ถูกยืนยันแล้ว ไปทำ Dataset ได้ (→ FR-ADMIN-02 AC-3)
- **FR-ADM-04:** แอดมินอัปโหลดไฟล์น้ำหนัก AI Model ล่าสุด และสั่ง Deploy ได้ (→ FR-ADMIN-03; อัปโหลดไฟล์ = Phase 2, v1 วางไฟล์บน server แล้ว deploy ผ่าน API)
- **FR-ADM-05:** แอดมินจัดการบัญชีผู้ใช้งาน (ดูข้อมูล, แบนผู้ใช้) ได้ (→ FR-ADMIN-01; เปลี่ยนสถานะเท่านั้น ห้าม hard-delete)
- **FR-ADM-06:** → ดู **FR-AUDIT-01** (ID เดียวสำหรับ Audit Log; ยุบรวมกันแล้ว ไม่นิยามซ้ำ) (→ FR-ADMIN-04)

### การตรวจสอบย้อนหลัง (Audit) — test-scheme (canonical: Document FR-ADMIN-04)

- **FR-AUDIT-01:** ระบบบันทึกกิจกรรมของผู้ดูแลระบบลง Audit Log แบบ Append-only (แยกจาก FR-SYS-10 ซึ่งคือการแจ้งเตือน; FCM push = Phase 2) (→ FR-ADMIN-04)

---

## ฟังก์ชันระบบอัตโนมัติ (Backend / AI) — test-scheme (canonical: Document FR-SCAN/FR-ANALYSIS/FR-XAI)

- **FR-SYS-01:** ระบบดึงข้อมูล EXIF Metadata ออกจากรูปที่อัปโหลด (→ RC-ANALYSIS-06 แสดงผลเท่านั้น ไม่ใช้คำนวณ Risk; ไม่มี FR แยกใน Document)
- **FR-SYS-02:** ระบบสกัดข้อความ (OCR) รองรับภาษาไทยและอังกฤษ (→ FR-ANALYSIS-01)
- **FR-SYS-03:** ระบบตรวจจับคำหลอกลวงหรือคีย์เวิร์ดเฝ้าระวังด้วย NLP (→ FR-ANALYSIS-01)
- **FR-SYS-04:** ระบบสแกนหาที่มาภาพย้อนกลับด้วย Google Vision API (→ FR-ANALYSIS-03)
- **FR-SYS-05:** ระบบตรวจสอบร่องรอยการดัดแปลงภาพระดับพิกเซลด้วย Deep Learning (SegFormer) (→ FR-ANALYSIS-02)
- **FR-SYS-06:** ระบบคัดกรองรูปภาพที่สร้างจาก AI ด้วย Classifier (→ FR-ANALYSIS-02)
- **FR-SYS-07:** ระบบประมวลผลคะแนนความเสี่ยงรวม Overall Risk Score พร้อม Multi-Factor Breakdown (สูตร/เกณฑ์ตาม Document FR-ANALYSIS-04 — ดูนิยามที่ Document ที่เดียว)
- **FR-SYS-08:** ระบบสร้างภาพ Heatmap แบบ mask-to-heatmap overlay (→ FR-XAI-01)
- **FR-SYS-09:** ระบบคำนวณ SHA-256 Hash ของภาพและเก็บผลสแกนลง Cache (Redis, TTL 30 วัน) เพื่อตอบกลับคำขอที่ซ้ำกันให้เร็วขึ้น (เป้าหมายเวลา: NFR-01; ยุบรวม FR-INPUT-05 แล้ว — ไม่นิยามซ้ำ) (→ FR-SCAN-03)
- **FR-SYS-10:** ระบบแจ้งเตือนแบบ in-app/polling ภายใน 60 วินาทีเมื่อประมวลผลเบื้องหลัง (Async) เสร็จ (FCM push = Phase 2, RC-NOTIFY deferred; ไม่มี FR แยกใน Document)
- **FR-SYS-11:** ระบบสร้างคำอธิบายภาษาไทยประกอบ Heatmap ด้วย Qwen2.5-1.5B (XAI; trace → Document FR-XAI-01 AC-1)

---

## หน้าที่เกี่ยวข้อง

- [[requirements/objectives-kpis]]
- [[requirements/non-functional-requirements]]
- [[entities/actors]]
- [[architecture/mobile-app]]
- [[architecture/backend-api]]
- [[concepts/multi-layer-analysis]]
