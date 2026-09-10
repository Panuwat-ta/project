# ตารางสอบย้อนกลับความต้องการ (Requirements Traceability Matrix - RTM)

- **Project**: ScamGuard (Scam Image Detection System)
- **Standard**: ISO/IEC/IEEE 29119-3 Test Documentation
- **Version**: 1.3.0
- **Date**: 2026-09-06
- **Status**: Baseline (106 TCs, Version 1.3.0)

---

## 1. คำอธิบายตาราง (Overview)

ตารางสอบย้อนกลับความต้องการ (RTM) ฉบับนี้ เชื่อมโยงความต้องการของระบบ (Requirements) จาก Software Requirements Specification (SRS) และ Wiki เข้ากับกรณีทดสอบในโฟลเดอร์ `tests_all/manual_tests/` (68 TCs) และชุดทดสอบอัตโนมัติใน `tests_all/automate_tests/`

### 1.1 ID Scheme ทางการสำหรับงานทดสอบ (Baseline Declaration)

- **Wiki scheme (`FR-AUTH` / `FR-INPUT` / `FR-SYS` / `FR-REPORT` / `FR-HIST` / `FR-RPT` / `FR-ADM` / `FR-PDPA`) คือ baseline สำหรับงานทดสอบ**
- **Document scheme (`FR-SCAN` / `FR-ANALYSIS` / `FR-XAI` / `FR-HISTORY` / `FR-ADMIN`) ให้ map มาหา wiki scheme ผ่าน mapping table ใน §2.8**
- **กฎการอ้างอิง**: ทุก `Test Case ID` ที่ RTM อ้างถึงต้องมีอยู่ใน `tests_all/manual_tests/*.md` — FR ใดที่ยังไม่มี TC ให้ระบุเป็น GAP / Deferred และไม่นับเป็น Covered

### 1.2 Baseline ทางเทคนิค

- Risk 3 ระดับ Low 0-39 / Medium 40-69 / High 70-100; สูตร max+bonus (S_base = max(...), +5 ต่อมิติรองที่ >= 40)
- Hash ภาพ = SHA-256; Cache TTL 30 วัน
- Surya OCR v0.5.0 PyTorch Native; SegFormer รันผ่าน ONNX Runtime; Heatmap มาจาก segmentation mask
- API prefix `/api/v1` (`/scan`, `/reports`, `/history`, `/admin/*`, WS `/api/v1/ws/admin/dashboard`)
- Roles: `user` / `researcher` / `admin` + ตาราง `admins` (`is_superadmin`); Flutter cross-platform

---

## 2. เมทริกซ์การสืบย้อนความต้องการเชิงฟังก์ชัน (Functional Requirements Traceability)

### 2.1 โมดูลการยืนยันตัวตน (Authentication)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-AUTH-01** | ผู้ใช้สมัครสมาชิกด้วย Email/Password ได้ | `TC-MOB-AUTH-01`<br>`TC-BE-AUTH-01` | Hybrid | `tests_all/automate_tests/tests/api/test_auth_flow.py` | Covered |
| **FR-AUTH-02** | ผู้ใช้เข้าสู่ระบบด้วย Email/Password ได้รับ JWT | `TC-MOB-AUTH-02`<br>`TC-MOB-AUTH-03`<br>`TC-BE-AUTH-02`<br>`TC-BE-AUTH-05` | Hybrid | `tests_all/automate_tests/tests/api/test_auth_flow.py` | Covered |
| **FR-AUTH-03** | ผู้ใช้เข้าสู่ระบบด้วย Google OAuth ได้ | — (ไม่มี TC) | — | — | Deferred |
| **FR-AUTH-04** | เก็บ Token ใน Secure Storage + ต่ออายุด้วย Refresh Token | `TC-MOB-AUTH-02`<br>`TC-BE-AUTH-03`<br>`TC-MOB-AUTH-05`<br>`TC-MOB-AUTH-06` | Hybrid | `tests_all/automate_tests/tests/api/test_auth_flow.py` | Covered |
| **FR-AUTH-05** | ผู้ใช้ออกจากระบบ (Logout) เพื่อล้างค่า Session | `TC-MOB-AUTH-04`<br>`TC-BE-AUTH-05` | Hybrid | `tests_all/automate_tests/tests/api/test_auth_flow.py` + Manual Verification | Covered |

---

### 2.2 โมดูลการรับภาพและการตรวจสอบไฟล์ (Image Input & Validation)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-INPUT-01** | เลือกรูปภาพจากแกลเลอรีในเครื่องได้ | `TC-MOB-IMG-01`<br>`TC-MOB-IMG-02` | Manual | Manual UI Test | Covered |
| **FR-INPUT-02** | เครื่องมือครอบตัด (Crop) ภาพก่อนส่งสแกน | `TC-MOB-IMG-05` | Manual | Manual UI Test | Covered |
| **FR-INPUT-03** | อัปโหลดภาพผ่าน Multipart HTTP ไปยัง Backend — GAP: cancelScan เรียก DELETE /scan/{id} แต่ฝั่ง Server มีแค่ POST / กับ GET /{scan_id} ยังไม่มี endpoint ยกเลิก | `TC-MOB-SCAN-01`<br>`TC-MOB-SCAN-02`<br>`TC-MOB-SCAN-03`<br>`TC-MOB-SCAN-04`<br>`TC-BE-SCAN-01` | Hybrid | `tests_all/automate_tests/tests/api/test_scan_workflow.py` + `scam_image_mobile/test/features/scan/presentation/bloc/scan_bloc_test.dart` | Partial |
| **FR-INPUT-04** | ปฏิเสธไฟล์เกินลิมิต (Mobile ≤10MB / Server ≤20MB + decode ≤100M px), นามสกุลที่ไม่รองรับ และตรวจ Magic Bytes — GAP: ฝั่ง Mobile ไม่ปฏิเสธไฟล์เกิน 10MB ส่งต่อให้ data source เสมอ เหลือแค่เตือนใน debug | `TC-MOB-IMG-03`<br>`TC-MOB-IMG-04`<br>`TC-BE-SCAN-02`<br>`TC-BE-SCAN-03`<br>`TC-BE-SCAN-04` | Hybrid | `tests_all/automate_tests/tests/api/test_scan_workflow.py` + `server/tests/api/test_scan.py` | Partial |
| **FR-INPUT-05** | ตรวจ SHA-256 + Redis Cache ระดับ input (ซ้ำกับ FR-SYS-09) | `TC-BE-CACHE-01`<br>`TC-BE-CACHE-02` | Automated | `tests_all/automate_tests/tests/api/test_scan_workflow.py` | Covered |

---

### 2.3 โมดูลการประมวลผลและการตรวจจับ AI (AI Analysis & Scoring)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-SYS-01** | ดึงข้อมูล EXIF และ Metadata จากรูปภาพ | — (ไม่มี TC) | — | — | GAP |
| **FR-SYS-02** | สกัดข้อความ (OCR) ด้วย Surya OCR v0.5.0 PyTorch Native (TH/EN) | `TC-AI-OCR-01` | Hybrid | `server/tests/inference/test_surya.py` | Covered |
| **FR-SYS-03** | ตรวจจับคำหลอกลวงหรือข้อความผิดปกติด้วย NLP | `TC-AI-OCR-02` | Automated | `tests_all/automate_tests/tests/api/test_scan_workflow.py` | Covered |
| **FR-SYS-04** | สืบค้นประวัติภาพย้อนกลับด้วย Reverse Image Search | — (ไม่มี TC) | — | — | GAP |
| **FR-SYS-05** | ตรวจจับร่องรอยการตัดต่อด้วย SegFormer Tiling | `TC-AI-TILE-01`<br>`TC-AI-TILE-02`<br>`TC-AI-EDGE-01`<br>`TC-AI-EDGE-02`<br>`TC-AI-EDGE-03`<br>`TC-AI-EDGE-04` | Hybrid | `server/tests/inference/test_gpu.py` (partial: โหลด ONNX SegFormer) + Manual Tiling | Covered |
| **FR-SYS-06** | คัดกรองภาพสังเคราะห์ Generative AI | — (ไม่มี TC) | — | — | GAP |
| **FR-SYS-07** | คำนวณ Overall Risk Score (Hybrid Worst-Case max+bonus) | `TC-AI-RISK-01`<br>`TC-AI-RISK-02` | Automated | `server/tests/utils/test_risk_calculator.py` | Covered |
| **FR-SYS-08** | สร้าง Full-Resolution Mask Heatmap Overlay — ครอบคลุมบางส่วนผ่าน TC ประกอบและแสดงผล heatmap | `TC-AI-TILE-02` (ประกอบ heatmap)<br>`TC-AI-HEAT-01` (ประกอบเต็ม)<br>`TC-MOB-RES-02` (แสดงผล) | Hybrid | `server/tests/inference/test_heatmap.py` | Partial |
| **FR-SYS-09** | แคชผลการสแกนลง Redis ด้วย SHA-256 Hash (TTL 30 วัน) | `TC-BE-CACHE-01`<br>`TC-BE-CACHE-02` | Automated | `tests_all/automate_tests/tests/api/test_scan_workflow.py` | Covered |
| **FR-SYS-10** | ยิง FCM Push Notification เมื่อประมวลผลแบบ Async เสร็จ — มี TC รองรับแต่รอทำ Phase 2 | `TC-MOB-NOTIF-01`<br>`TC-NFR-FCM-01` | Manual | Manual Device Test | Deferred |

---

### 2.4 โมดูลการแสดงผลรายงานและประวัติ (Report & History)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-REPORT-01** | แสดง Risk Score (0-100) พร้อมสี 3 ระดับ (Low / Medium / High) — GAP: app_translations ยังมี key safe และ result_safe ตกค้าง ขัดกับกฎ 3 ระดับ | `TC-MOB-RES-01` | Manual | `scam_image_mobile/test/core/utils/risk_level_helper_test.dart` | Partial |
| **FR-REPORT-02** | แสดง Heatmap Overlay ซ้อนทับภาพต้นฉบับ | `TC-MOB-RES-02` | Manual | Manual UI Test | Covered |
| **FR-REPORT-03** | ปุ่มเปิด/ปิด และปรับความโปร่งใส Heatmap | `TC-MOB-RES-02` | Manual | Manual UI Test | Covered |
| **FR-REPORT-04** | แสดงคะแนนจำแนกรายชั้น (Text, Source, Visual) | `TC-MOB-RES-03` | Manual | Manual UI Test | Covered |
| **FR-REPORT-05** | แสดงคำที่เข้าข่ายน่าสงสัย (OCR/NLP keywords) | `TC-MOB-RES-03` | Manual | Manual UI Test | Covered |
| **FR-REPORT-06** | แสดงผล Source Verification (จำนวนเว็บไซต์ที่พบภาพเดียวกัน) — ฝั่ง backend (FR-SYS-04) ยังเป็น GAP | `TC-MOB-RES-03` (บางส่วน: การ์ด Source ใน breakdown) | Manual | Manual UI Test | Partial |
| **FR-HIST-01** | แสดงรายการประวัติการสแกนย้อนหลังเรียงตามเวลา | `TC-MOB-HIST-01`<br>`TC-BE-HIST-01` | Hybrid | `tests_all/automate_tests/tests/api/test_history.py` | Covered |
| **FR-HIST-02** | แตะรายการประวัติเพื่อเปิดดูผลลัพธ์เดิมได้ | `TC-MOB-HIST-02`<br>`TC-BE-HIST-02` | Hybrid | `tests_all/automate_tests/tests/api/test_history.py` + Manual UI Test | Covered |
| **FR-HIST-03** | ลบประวัติการสแกน (DELETE /api/v1/history/{id} ลบไฟล์ original/heatmap) — Offline ย้ายเป็น NFR/out-of-scope | `TC-NFR-PRIV-02`<br>`TC-MOB-HIST-04`<br>`TC-BE-HIST-02` | Hybrid | `tests_all/automate_tests/tests/api/test_history.py` + Manual Device Test | Covered |
| **FR-RPT-01** | ผู้ใช้ส่งรายงานข้อร้องเรียน (Scam Report) ได้ — GAP: category keys ไม่ตรงกัน ฝั่ง Server ใช้ romance_scam online_shopping ส่วนฝั่ง Mobile ใช้ cat_romance cat_ecommerce | `TC-MOB-RPT-01`<br>`TC-MOB-RPT-02`<br>`TC-BE-RPT-01` | Hybrid | `tests_all/automate_tests/tests/api/test_history.py` (`test_report_create`, `test_report_categories`) | Partial |

---

### 2.5 โมดูลระบบจัดการผู้ดูแลระบบ (Admin Portal)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-ADM-01** | แดชบอร์ดสถิติภาพรวม + WebSocket realtime (`/api/v1/ws/admin/dashboard`) | `TC-ADM-AUTH-01`<br>`TC-ADM-DASH-01`<br>`TC-ADM-WS-01`<br>`TC-ADM-AUTH-03`<br>`TC-ADM-DASH-02`<br>`TC-BE-ADMIN-02`<br>`TC-BE-ADMIN-03` | Hybrid | `tests_all/automate_tests/tests/api/test_admin.py` + `server/tests/api/test_admin_auth.py` + Manual Console Test | Covered |
| **FR-ADM-02** | ตรวจสอบข้อร้องเรียน อนุมัติ/ปัดตก รายงาน (Concurrency เป็น impl detail ด้วย version column) | `TC-ADM-REP-01`<br>`TC-ADM-REP-02` | Hybrid | `tests_all/automate_tests/tests/api/test_history.py` (`test_report_create`) + `server/tests/api/test_admin_reports.py` | Covered |
| **FR-ADM-03** | แอดมิน Export ภาพ Scam ที่ยืนยันแล้วไปทำ Dataset | — (ไม่มี TC เฉพาะ) | — | — | GAP |
| **FR-ADM-04** | การบริหารจัดการโมเดล AI (Deploy / Rollback) | `TC-ADM-MOD-01`<br>`TC-ADM-MOD-02`<br>`TC-BE-MODEL-01` | Hybrid | Manual Console + `tests_all/automate_tests/tests/api/test_admin.py` (partial: auth/RBAC) | Covered |
| **FR-ADM-05** | จัดการรายชื่อผู้ใช้และสั่งระงับการใช้งาน (Ban) | `TC-ADM-USR-01` | Hybrid | Manual Console + `tests_all/automate_tests/tests/api/test_admin.py` (partial) | Covered |
| **FR-ADM-06** | ดู Audit Logs (append-only) | `TC-E2E-REPORT-03` (ตรวจ Audit Logs)<br>`TC-BE-AUDIT-01`<br>`TC-ADM-AUD-01` | Hybrid | `tests_all/automate_tests/tests/api/test_admin.py` + Manual Console | Covered |
| **FR-AUDIT-01** | ตรวจสอบบันทึกความปลอดภัย (Audit Logs + JSON Diff) — มี TC แล้วแต่ยังขาดการตรวจ JSON Diff ครบทุก entity | `TC-BE-AUDIT-01`<br>`TC-ADM-AUD-01` | Hybrid | `tests_all/automate_tests/tests/api/test_admin.py` + Manual Console | Partial |

---

### 2.6 กระบวนการทำงานข้ามระบบครบวงจร (Cross-System End-to-End Journeys)

| Journey ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **E2E-01** | ตรวจสอบภาพสแกนครบวงจร (Mobile -> API -> AI -> Result) | `TC-E2E-SCAN-01` | Hybrid | `tests_all/automate_tests/tests/e2e/test_e2e_scam_flow.py` (`test_e2e_full_user_journey`) | Covered |
| **E2E-02** | ตรวจสอบความเร็วแคช Redis ข้ามผู้ใช้ (Cache Hit Latency ≤ 3s) | `TC-E2E-CACHE-02` | Automated | `tests_all/automate_tests/tests/api/test_scan_workflow.py` | Covered |
| **E2E-03** | ผู้ใช้ส่งรายงานข้อร้องเรียนสู่การพิจารณาของแอดมิน | `TC-E2E-REPORT-03` | Hybrid | `tests_all/automate_tests/tests/api/test_history.py` (`test_report_create`) + Manual Admin Console | Covered |
| **E2E-04** | แอดมินสลับโมเดล AI และมีผลต่อการสแกนทันที (Hot-Swap) | `TC-E2E-MODEL-04` | Manual | Manual Console + Device Test | Covered |
| **E2E-05** | แอดมินระงับผู้ใช้และการตัดสิทธิ์ Session บนมือถือทันที | `TC-E2E-BAN-05` | Manual | Manual Console + Device Test | Covered |
| **E2E-06** | การทำงานในโหมดออฟไลน์และการซิงก์ข้อมูลเมื่อต่อเน็ต | `TC-E2E-OFFLINE-06` | Manual | Manual Device Test | Covered |

---

### 2.7 การจัดการข้อมูลส่วนบุคคลตามกฎหมาย PDPA (PDPA Controls)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-PDPA-01** | แสดงหน้า Consent ยินยอมการประมวลผลข้อมูลในครั้งแรกที่เปิดแอป | `TC-MOB-PDPA-01` | Manual | Manual UI Test | Covered |
| **FR-PDPA-02** | ผู้ใช้ถอนความยินยอมในการเข้าร่วมวิจัยได้จากหน้าการตั้งค่า | `TC-MOB-PDPA-01`<br>`TC-NFR-PRIV-01` | Hybrid | `tests_all/automate_tests/tests/api/test_history.py` | Covered |
| **FR-PDPA-03** | หากถอนความยินยอม ระบบต้องลบภาพของผู้ใช้ออกจาก Dataset วิจัย | `TC-NFR-PRIV-02` | Automated | `tests_all/automate_tests/tests/api/test_history.py` | Covered |

---

### 2.8 FR เพิ่มเติมที่ manual TCs อ้างถึง (นอก wiki baseline)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-SET-01** | สลับภาษาไทย/อังกฤษ (i18n) | `TC-MOB-UI-01` | Manual | Manual UI Test | Covered |
| **FR-SET-02** | สลับโหมดมืด/โหมดสว่าง (Dark/Light) | `TC-MOB-UI-02` | Manual | Manual UI Test | Covered |
| **FR-SYS-11** | สร้างคำอธิบายเชิงเหตุผลด้วย Qwen2.5-1.5B (XAI) — extra นอก wiki baseline | `TC-AI-XAI-01` | Hybrid | `server/tests/inference/test_qwen_xai.py` | Covered |

**Offline ย้ายออกจาก FR-HIST-03:** `TC-MOB-HIST-03`, `TC-E2E-OFFLINE-06` เป็นการทดสอบโหมด Offline/Local Cache ย้ายไป map กับ `NFR-PERF-03` (Availability) ไม่นับ coverage FR-HIST-03

---

### 2.9 Mapping Table: Document scheme → Wiki scheme (baseline สำหรับ tests)

Document scheme ให้ map มาหา wiki scheme ดังนี้:

| Document scheme (05_SRS) | Wiki scheme (baseline สำหรับ tests) | หมายเหตุ |
| :--- | :--- | :--- |
| FR-AUTH-01/02/04 (สมัคร/ล็อกอิน/ออกจากระบบ) | FR-AUTH-01 / FR-AUTH-02 / FR-AUTH-05 | Document ไม่มี FR-AUTH-03 ต่ออายุ Token แยก / ไม่มี OAuth |
| FR-SCAN-01 (เลือก+ครอบตัด) | FR-INPUT-01 / FR-INPUT-02 (GAP) | Crop ยังไม่มี TC |
| FR-SCAN-02 (ตรวจ+อัปโหลด) | FR-INPUT-03 / FR-INPUT-04 (dual-limit Mobile 10MB / Server 20MB + decode 100M px + Magic Bytes) / FR-INPUT-05 (SHA-256 + Redis Cache) | Magic Bytes ย้ายเข้า FR-INPUT-04; FR-INPUT-05 เหลือ SHA-256 + Cache |
| FR-SCAN-03 (Cache) | FR-SYS-09 | hash SHA-256 |
| FR-ANALYSIS-01 (OCR+NLP) | FR-SYS-02 / FR-SYS-03 | ตรงกัน |
| FR-ANALYSIS-02 (Visual + AI-Gen) | FR-SYS-05 / FR-SYS-06 (GAP) | AI-Gen classifier ยังไม่มี TC |
| FR-ANALYSIS-03 (Source) | FR-SYS-04 (GAP) | ยังไม่มี integration/TC |
| FR-ANALYSIS-04 (Weighted Risk Score) | FR-SYS-07 (Hybrid max+bonus) | สูตร Hybrid max+bonus |
| FR-XAI-01 (Mask Heatmap) | FR-SYS-08 (Mask Heatmap) + FR-REPORT-02/03 | Heatmap มาจาก segmentation mask; Qwen XAI = FR-SYS-11 extra นอก wiki baseline |
| FR-HISTORY-01 (ประวัติ) | FR-HIST-01/02 + FR-HIST-03 (ลบประวัติ DELETE /api/v1/history/{id}) | Offline ย้ายเป็น NFR/out-of-scope |
| FR-HISTORY-02 (รายงาน) | FR-RPT-01 | ตรงกัน |
| FR-PDPA-01 (Consent) | FR-PDPA-01/02/03 | ตรงกัน |
| FR-ADMIN-01 (Dashboard+User) | FR-ADM-01 / FR-ADM-05 | แยก Dashboard กับ User Management |
| FR-ADMIN-02 (Report Queue) | FR-ADM-02 (รวม Concurrency impl detail + version column) + FR-ADM-06 (Audit Logs append-only) | Concurrency เป็น impl detail ของ FR-ADM-02; FR-ADM-06 ใหม่คือดู Audit Logs |
| FR-ADMIN-03 (Model Mgmt) | FR-ADM-04 | ตรงกัน |
| FR-ADMIN-04 (Audit Logs) | FR-AUDIT-01 (GAP) | เดิม FR-ADM-07 เปลี่ยนเป็น FR-AUDIT-01 ตาม wiki (FR-ADM-01..06 + FR-AUDIT-01) |

### 2.10 Mapping Table: SRS NFR-01..10 → Wiki NFR scheme (baseline สำหรับ tests)

| SRS NFR-01..10 | Wiki NFR scheme | หมายเหตุ |
| :--- | :--- | :--- |
| NFR-01 (Performance response) | NFR-PERF-01 / NFR-PERF-02 | Cache Hit ≤3s / Full Inference ≤15s |
| NFR-02 (Availability) | NFR-PERF-03 (+ `TC-AI-ISO-01` fault tolerance) | Uptime ≥99.5% + subprocess isolation |
| NFR-03 (Security transport) | NFR-SEC-01 (+ `TC-BE-CORS-01`) | HTTPS/TLS + CORS |
| NFR-04 (Security auth) | NFR-SEC-02 / NFR-SEC-03 (+ `TC-ADM-AUTH-02`) | JWT + RBAC 403 |
| NFR-05 (Security input/OWASP) | NFR-SEC-04 (+ `TC-BE-RATE-01`) | OWASP + rate limit 429 |
| NFR-06 (Security secrets) | NFR-SEC-05 | Zero hardcoded secrets |
| NFR-07 (Privacy/PDPA) | NFR-PDPA-01 / NFR-PDPA-02 | Consent + Right to erasure (DELETE history) |
| NFR-08 (AI accuracy) | NFR-AI-01 / NFR-AI-02 (GAP) | mDice ≥85% / AI-gen ≥85% ยังไม่มี TC |
| NFR-09 (Usability/Accessibility) | NFR-A11Y-01 (+ `TC-ADM-UI-01`) / NFR-A11Y-02 | Contrast ≥4.5:1 / Touch ≥48dp |
| NFR-10 (Data integrity) | NFR-SYS-01 | Timezone UTC+7 Asia/Bangkok |

---

## 3. เมทริกซ์การสืบย้อนความต้องการที่ไม่ใช่ฟังก์ชัน (Non-Functional Requirements Traceability)

| Requirement ID | ประเภทข้อกำหนด | เป้าหมายและเกณฑ์การยอมรับ | Test Case ID | วิธีการทดสอบ | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **NFR-PERF-01** | Performance | เวลาตอบสนอง Cache Hit ≤ 3 วินาที (E2E) | `TC-NFR-PERF-01` | Automated (Locust `tests_all/automate_tests/tests/performance/locustfile.py`) | Covered |
| **NFR-PERF-02** | Performance | เวลาตอบสนอง Full Inference ≤ 15 วินาที | `TC-NFR-PERF-02` | Automated (Locust `tests_all/automate_tests/tests/performance/locustfile.py`) | Covered |
| **NFR-PERF-03** | Availability | System Availability / Uptime ≥ 99.5% | `TC-NFR-PERF-03`<br>`TC-AI-ISO-01`<br>`TC-MOB-HIST-03`<br>`TC-E2E-OFFLINE-06` | Monitoring / Health | Covered |
| **NFR-AI-01** | AI Accuracy | SegFormer mDice การตรวจจับภาพตัดต่อ ≥ 85% — มี TC แล้วแต่ยังไม่มีชุดทดสอบมาตรฐาน | `TC-AI-ACC-01`<br>`TC-NFR-AI-01` | Manual | Manual Verification | Partial |
| **NFR-AI-02** | AI Accuracy | ความแม่นยำจำแนกภาพ AI-Generated ≥ 85% — มี TC แล้วแต่ยังไม่มีโมเดลจำแนกเฉพาะ | `TC-AI-ACC-02`<br>`TC-NFR-AI-02` | Manual | Manual Verification | Partial |
| **NFR-SEC-01** | Security | เข้ารหัสการรับส่งข้อมูลด้วย HTTPS/TLS 100% | `TC-NFR-SEC-01`<br>`TC-BE-CORS-01` | Security Audit | Covered |
| **NFR-SEC-02** | Security | บังคับตรวจสอบสิทธิ์ JWT ทุก Protected Endpoint | `TC-BE-AUTH-04` | Automated (Pytest) | Covered |
| **NFR-SEC-03** | Security | แยกสิทธิ์ Admin RBAC ปฏิเสธ User ทั่วไป (403) | `TC-BE-ADMIN-01`<br>`TC-ADM-AUTH-02` | Automated (Pytest) | Covered |
| **NFR-SEC-04** | Security | ป้องกันการโจมตี OWASP Top 10 (SQLi, XSS) | `TC-NFR-SEC-02`<br>`TC-BE-RATE-01` | Automated Scanner | Covered |
| **NFR-SEC-05** | Security | Zero Hardcoded Secrets (โหลดจาก .env ล้วน) | `TC-NFR-SEC-03` | Code Audit / Pytest | Covered |
| **NFR-PDPA-01** | Privacy & PDPA | หน้า Consent ยินยอมการประมวลผลข้อมูล | `TC-MOB-PDPA-01` | Manual UI Test | Covered |
| **NFR-PDPA-02** | Privacy & PDPA | สิทธิ์การขอลบข้อมูลและภาพสแกนของผู้ใช้ | `TC-NFR-PRIV-02` | Integration Test | Covered |
| **NFR-A11Y-01** | Accessibility | Contrast Ratio ≥ 4.5:1 ตามเกณฑ์ WCAG AA | `TC-NFR-A11Y-01`<br>`TC-ADM-UI-01`<br>`TC-ADM-UI-02` | Hybrid | Automated Lighthouse + Manual Verification | Covered |
| **NFR-A11Y-02** | Usability | ขนาด Touch Target บน Mobile ≥ 48x48dp | `TC-NFR-A11Y-02` | Manual UI Test | Covered |
| **NFR-SYS-01** | Data Integrity | Timezone UTC+7 (Asia/Bangkok) ทุก Record | `TC-BE-DB-01` | Script (`server/tests/check_time_tz.py`) | Covered |

**นิยาม 5 NFR กำกวม (strict count แยกหมวด):** `NFR-PERF-03` Monitoring / Health = ยิง health endpoint ทุก 60s ครบ 24h + crash injection; `NFR-SEC-01` Security Audit = ตรวจ redirect 301/308 + TLS 1.2/1.3 + HSTS ด้วย testssl/nmap; `NFR-SEC-05` Code Audit / Pytest = สแกน gitleaks/trufflehog + ตรวจ config ผ่าน env; `NFR-PDPA-02` Integration Test = ยิง DELETE history + ตรวจ DB/storage + GET ซ้ำ 404; `NFR-SYS-01` Script = รัน `server/tests/check_time_tz.py` ตรวจ `created_at` UTC+7

---

## 4. สรุปภาพรวมความครอบคลุม (Coverage Summary)

- **ขอบเขตการครอบคลุม: FR 27/40 Covered (34/40 รวม Partial), NFR 13/15 Covered (15/15 รวม Partial)**
- **Functional Requirements (wiki scheme) 40 รายการ** (ตัด FR-SYS-11 เป็น extra): Covered เต็ม **27** รายการ (**67.5%**), Partial **7** รายการ (`FR-INPUT-03` cancelScan ไม่มี endpoint, `FR-INPUT-04` Mobile ไม่ปฏิเสธเกิน 10MB, `FR-SYS-08`, `FR-REPORT-01` key safe ตกค้าง, `FR-REPORT-06`, `FR-RPT-01` category keys ไม่ตรง, `FR-AUDIT-01` ขาด JSON Diff ครบ), GAP **4** รายการ (`FR-SYS-01`, `FR-SYS-04`, `FR-SYS-06`, `FR-ADM-03`) + Deferred **2** รายการ (`FR-AUTH-03` OAuth, `FR-SYS-10` FCM) — รวม mapped 34/40 (**85.0%** นับ Partial)
- **FR เพิ่มเติมนอก wiki baseline 3 รายการ** (`FR-SET-01`, `FR-SET-02`, `FR-SYS-11` Qwen XAI): Covered 3/3 (100%)
- **Non-Functional Requirements 15 รายการ**: Covered **13** รายการ (**86.7%**), Partial **2** รายการ (`NFR-AI-01`, `NFR-AI-02` มี TC แล้วแต่ขาดชุดทดสอบมาตรฐาน), GAP **0** รายการ — รวม mapped 15/15 (**100%** นับ Partial)
- **Cross-System Journeys (E2E) 6 กระบวนการ**: Covered 6/6 (**100%**)
- **Manual TCs ทั้งหมด 106 TCs**: ทุก ID มีที่อ้างใน RTM แล้ว ไม่มี orphan (mobile 28, backend 24, ai 16, admin 17, e2e 6, nfr 15 + Offline `TC-MOB-HIST-03`/`TC-E2E-OFFLINE-06` ย้ายไป `NFR-PERF-03`)
- **รูปแบบการทดสอบ** (58 rows ที่มี TC, strict): Hybrid 24 รายการ / Automated 11 รายการ / Manual 18 รายการ + 5 NFR กำกวมแยกหมวด (`NFR-PERF-03`, `NFR-SEC-01`, `NFR-SEC-05`, `NFR-PDPA-02`, `NFR-SYS-01` นิยามชัดด้านบน); เพิ่มจาก 54 rows หลัง map TC ใหม่ โดย `FR-AUTH-05` Manual→Hybrid, `FR-HIST-02` Manual→Hybrid, `FR-HIST-03` Automated→Hybrid, `FR-ADM-01` Manual→Hybrid, `NFR-A11Y-01` เพิ่ม TC แบบ Manual, `FR-SYS-10` กับ `NFR-AI-01` `NFR-AI-02` `FR-AUDIT-01` เพิ่ม TC แบบ Manual Partial/Deferred
