# ตารางสอบย้อนกลับความต้องการ (Requirements Traceability Matrix - RTM)

- **Project**: ScamGuard (Scam Image Detection System)
- **Standard**: ISO/IEC/IEEE 29119-3 Test Documentation
- **Version**: 1.3.1
- **Date**: 2026-09-12
- **Status**: Baseline (150 TCs, Version 1.3.1)

---

## 1. คำอธิบายตาราง (Overview)

ตารางสอบย้อนกลับความต้องการ (RTM) ฉบับนี้ เชื่อมโยงความต้องการของระบบ (Requirements) จาก Software Requirements Specification (SRS) และ Wiki เข้ากับกรณีทดสอบในโฟลเดอร์ `tests_all/manual_tests/` (150 TCs) และชุดทดสอบอัตโนมัติใน `tests_all/automate_tests/`

### 1.1 ID Scheme ทางการสำหรับงานทดสอบ (Baseline Declaration)

- **Wiki scheme (`FR-AUTH` / `FR-INPUT` / `FR-SYS` / `FR-REPORT` / `FR-HIST` / `FR-RPT` / `FR-ADM` / `FR-AUDIT` / `FR-SHARE` / `FR-PDPA`) คือ baseline สำหรับงานทดสอบ** (OAuth = `FR-AUTH-06`; `FR-INPUT-05` ยุบรวมเข้า `FR-SYS-09`, `FR-ADM-06` ยุบรวมเข้า `FR-AUDIT-01` แล้ว — ไม่นับซ้ำ; กลุ่ม AUTH ใช้เลขชุดเดียวกับ Document แล้ว: `FR-AUTH-01..04` = สมัคร/ล็อกอิน(+Secure Storage)/ต่ออายุ/ออกจากระบบ)
- **Document scheme (`FR-SCAN` / `FR-ANALYSIS` / `FR-XAI` / `FR-HISTORY` / `FR-ADMIN`, NFR-01..09) เป็น canonical** ให้ map มาหา wiki scheme ผ่าน mapping table ใน §2.9–§2.10
- **กฎการอ้างอิง**: ทุก `Test Case ID` ที่ RTM อ้างถึงต้องมีอยู่ใน `tests_all/manual_tests/*.md` — FR ใดที่ยังไม่มี TC ให้ระบุเป็น GAP / Deferred และไม่นับเป็น Covered
- **Freeze**: baseline ชุดเดียวคือ wiki scheme ตามประกาศข้างต้น (v1.3.1, 2026-09-12) ห้ามย้ายเลข/เปลี่ยนชื่อ Req โดยไม่ bump เวอร์ชัน RTM และอัปเดต mapping table §2.9–§2.10 พร้อมกัน

### 1.2 Baseline ทางเทคนิค

- Risk 3 ระดับ Low 0-39 / Medium 40-69 / High 70-100 (visual ≥80 → High); สูตร max+bonus (S_base = max(...), +5 ต่อมิติรองที่ >= 40) — นิยามหลักที่ Document FR-ANALYSIS-04 (RC-ANALYSIS-07/08)
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
| **FR-AUTH-02** | ผู้ใช้เข้าสู่ระบบด้วย Email/Password ได้รับ JWT + เก็บ Token ใน Secure Storage (Document FR-AUTH-02 AC-1/AC-4; ส่วน Secure Storage เดิมเรียก FR-AUTH-04) | `TC-MOB-AUTH-02`<br>`TC-MOB-AUTH-03`<br>`TC-BE-AUTH-02`<br>`TC-BE-AUTH-05` | Hybrid | `tests_all/automate_tests/tests/api/test_auth_flow.py` | Covered |
| **FR-AUTH-06** | (Phase 2 backlog, RC-AUTH-06) ผู้ใช้เข้าสู่ระบบด้วย Google OAuth ได้ — ย้ายเลขจาก FR-AUTH-03 เพื่อเลี่ยงชน Document FR-AUTH-03 (ต่ออายุ Token, 05:117) | — (ไม่มี TC) | — | — | Deferred |
| **FR-AUTH-03** | ต่ออายุ Access Token ด้วย Refresh Token (Document FR-AUTH-03; เดิมเรียก FR-AUTH-04) | `TC-BE-AUTH-03`<br>`TC-MOB-AUTH-05`<br>`TC-MOB-AUTH-06` | Hybrid | `tests_all/automate_tests/tests/api/test_auth_flow.py` | Covered |
| **FR-AUTH-04** | ผู้ใช้ออกจากระบบ (Logout) เพื่อล้างค่า Session (Document FR-AUTH-04; เดิมเรียก FR-AUTH-05) | `TC-MOB-AUTH-04`<br>`TC-BE-AUTH-05` | Hybrid | `tests_all/automate_tests/tests/api/test_auth_flow.py` + Manual Verification | Covered |

---

### 2.2 โมดูลการรับภาพและการตรวจสอบไฟล์ (Image Input & Validation)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-INPUT-01** | เลือกรูปภาพจากแกลเลอรีในเครื่องได้ | `TC-MOB-IMG-01`<br>`TC-MOB-IMG-02` | Manual | Manual UI Test | Covered |
| **FR-INPUT-02** | เครื่องมือครอบตัด (Crop) ภาพก่อนส่งสแกน | `TC-MOB-IMG-05` | Manual | Manual UI Test | Covered |
| **FR-INPUT-03** | อัปโหลดภาพผ่าน Multipart HTTP ไปยัง Backend — GAP: cancelScan เรียก DELETE /scan/{scan_id} แต่ฝั่ง Server มีแค่ POST / กับ GET /{scan_id} ยังไม่มี endpoint ยกเลิก (ทวนกับโค้ด `server/app/api/v1/scan.py` + prefix `/api/v1` ใน `server/app/main.py:57` แล้ว 2026-09-12) | `TC-MOB-SCAN-01`<br>`TC-MOB-SCAN-02`<br>`TC-MOB-SCAN-03`<br>`TC-MOB-SCAN-04`<br>`TC-BE-SCAN-01` | Hybrid | `tests_all/automate_tests/tests/api/test_scan_workflow.py` + `scam_image_mobile/test/features/scan/presentation/bloc/scan_bloc_test.dart` | Partial |
| **FR-INPUT-04** | ปฏิเสธไฟล์เกินลิมิต (Mobile ≤10MB / Server ≤20MB + decode ≤100M px), นามสกุลที่ไม่รองรับ และตรวจ Magic Bytes — GAP: ฝั่ง Mobile ไม่ปฏิเสธไฟล์เกิน 10MB ส่งต่อให้ data source เสมอ เหลือแค่เตือนใน debug | `TC-MOB-IMG-03`<br>`TC-MOB-IMG-04`<br>`TC-BE-SCAN-02`<br>`TC-BE-SCAN-03`<br>`TC-BE-SCAN-04` | Hybrid | `tests_all/automate_tests/tests/api/test_scan_workflow.py` + `server/tests/api/test_scan.py` | Partial |
| **FR-INPUT-05** | ยุบรวมเข้า **FR-SYS-09** แล้ว (pointer — ดูแถว FR-SYS-09 ใน §2.3; ไม่นับ coverage ซ้ำ — TC และการนับดูแถว FR-SYS-09) | `TC-BE-CACHE-01`<br>`TC-BE-CACHE-02` (นับที่ FR-SYS-09) | Automated | `tests_all/automate_tests/tests/api/test_scan_workflow.py` | Merged → FR-SYS-09 |

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
| **FR-SYS-07** | คำนวณ Overall Risk Score (Hybrid max+bonus) | `TC-AI-RISK-01`<br>`TC-AI-RISK-02` | Automated | `server/tests/utils/test_risk_calculator.py` | Covered |
| **FR-SYS-08** | สร้าง Full-Resolution Mask Heatmap Overlay — ครอบคลุมบางส่วนผ่าน TC ประกอบและแสดงผล heatmap | `TC-AI-TILE-02` (ประกอบ heatmap)<br>`TC-AI-HEAT-01` (ประกอบเต็ม)<br>`TC-MOB-RES-02` (แสดงผล) | Hybrid | `server/tests/inference/test_heatmap.py` | Partial |
| **FR-SYS-09** | แคชผลการสแกนลง Redis ด้วย SHA-256 Hash (TTL 30 วัน) | `TC-BE-CACHE-01`<br>`TC-BE-CACHE-02` | Automated | `tests_all/automate_tests/tests/api/test_scan_workflow.py` | Covered |
| **FR-SYS-10** | ยิง FCM Push Notification เมื่อประมวลผลแบบ Async เสร็จ — มี TC รองรับแต่รอทำ Phase 2 | `TC-MOB-NOTIF-01`<br>`TC-NFR-FCM-01` | Manual | Manual Device Test | Deferred |
| **FR-SYS-11** | สร้างคำอธิบายภาษาไทยประกอบ Heatmap ด้วย Qwen2.5-1.5B (XAI; wiki baseline — ย้ายจาก §2.8) | `TC-AI-XAI-01`<br>`TC-AI-XAI-02` | Hybrid | `server/tests/inference/test_qwen_xai.py` | Covered |

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
| **FR-SHARE-01** | ผู้ใช้แชร์ภาพผลลัพธ์/คำเตือนไปยังแอปภายนอก (trace → SRS BR-07/FR-08; หลักฐาน 02 SC01 §5) | — (ไม่มี TC) | — | — | GAP |

---

### 2.5 โมดูลระบบจัดการผู้ดูแลระบบ (Admin Portal)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-ADM-01** | แดชบอร์ดสถิติภาพรวม + WebSocket realtime (`/api/v1/ws/admin/dashboard`) | `TC-ADM-AUTH-01`<br>`TC-ADM-DASH-01`<br>`TC-ADM-WS-01`<br>`TC-ADM-AUTH-03`<br>`TC-ADM-DASH-02`<br>`TC-BE-ADMIN-02`<br>`TC-BE-ADMIN-03` | Hybrid | `tests_all/automate_tests/tests/api/test_admin.py` + `server/tests/api/test_admin_auth.py` + Manual Console Test | Covered |
| **FR-ADM-02** | ตรวจสอบข้อร้องเรียน อนุมัติ/ปัดตก รายงาน (Concurrency เป็น impl detail ด้วย version column) | `TC-ADM-REP-01`<br>`TC-ADM-REP-02` | Hybrid | `tests_all/automate_tests/tests/api/test_history.py` (`test_report_create`) + `server/tests/api/test_admin_reports.py` | Covered |
| **FR-ADM-03** | แอดมิน Export ภาพ Scam ที่ยืนยันแล้วไปทำ Dataset | `TC-ADM-EXP-01` | Manual | Manual Console Test | Covered |
| **FR-ADM-04** | การบริหารจัดการโมเดล AI (Deploy / Rollback) | `TC-ADM-MOD-01`<br>`TC-ADM-MOD-02`<br>`TC-BE-MODEL-01` | Hybrid | Manual Console + `tests_all/automate_tests/tests/api/test_admin.py` (partial: auth/RBAC) | Covered |
| **FR-ADM-05** | จัดการรายชื่อผู้ใช้และสั่งระงับการใช้งาน (Ban) | `TC-ADM-USR-01` | Hybrid | Manual Console + `tests_all/automate_tests/tests/api/test_admin.py` (partial) | Covered |
| **FR-ADM-06** | ยุบรวมเข้า **FR-AUDIT-01** แล้ว (pointer — ดูแถว FR-AUDIT-01 ใน §2.5; ไม่นับ coverage ซ้ำ — TC และการนับดูแถว FR-AUDIT-01) | `TC-E2E-REPORT-03` (ตรวจ Audit Logs)<br>`TC-BE-AUDIT-01`<br>`TC-ADM-AUD-01` (นับที่ FR-AUDIT-01) | Hybrid | `tests_all/automate_tests/tests/api/test_admin.py` + Manual Console | Merged → FR-AUDIT-01 |
| **FR-AUDIT-01** | ตรวจสอบบันทึกความปลอดภัย (Audit Logs + JSON Diff) — มี TC แล้วแต่ยังขาดการตรวจ JSON Diff ครบทุก entity | `TC-E2E-REPORT-03` (ตรวจ Audit Logs)<br>`TC-BE-AUDIT-01`<br>`TC-ADM-AUD-01` | Hybrid | `tests_all/automate_tests/tests/api/test_admin.py` + Manual Console | Partial |

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
| **E2E-07** | วงจรสมัคร→สแกน→รายงาน→แอดมิน→Audit ครบวงจร | `TC-E2E-FULL-07` | Manual | Manual Device + Console Test | Covered |
| **E2E-08** | Token หมดอายุกลางทาง ต่ออายุแล้วทำต่อได้โดยไม่เสียงาน | `TC-E2E-AUTH-08` | Manual | Manual Device Test | Covered |
| **E2E-09** | สแกนซ้ำหลัง Deploy โมเดลใหม่ผลคงเดิม (Regression) | `TC-E2E-REG-09` | Manual | Manual Console + Device Test | Covered |
| **E2E-10** | ลบประวัติแล้วเปิดรายละเอียดต้องไม่พบ (Not Found) | `TC-E2E-HIST-10` | Manual | Manual Device Test | Covered |

---

### 2.7 การจัดการข้อมูลส่วนบุคคลตามกฎหมาย PDPA (PDPA Controls)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-PDPA-01** | แสดงหน้า Consent ยินยอมการประมวลผลข้อมูลในครั้งแรกที่เปิดแอป | `TC-MOB-PDPA-01` | Manual | Manual UI Test | Covered |
| **FR-PDPA-02** | ผู้ใช้ถอนความยินยอมในการเข้าร่วมวิจัยได้จากหน้าการตั้งค่า | `TC-MOB-PDPA-01`<br>`TC-NFR-PRIV-01` | Hybrid | `tests_all/automate_tests/tests/api/test_history.py` | Covered |
| **FR-PDPA-03** | หากถอนความยินยอม ระบบต้องลบภาพของผู้ใช้ออกจาก Dataset วิจัย | `TC-NFR-PRIV-02` | Automated | `tests_all/automate_tests/tests/api/test_history.py` | Covered |

---

### 2.8 FR เพิ่มเติมที่ manual TCs อ้างถึง (นอก wiki baseline: เหลือ FR-SET-01/02 — FR-SYS-11 ย้ายเข้า baseline §2.3 แล้ว)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-SET-01** | สลับภาษาไทย/อังกฤษ (i18n) | `TC-MOB-UI-01` | Manual | Manual UI Test | Covered |
| **FR-SET-02** | สลับโหมดมืด/โหมดสว่าง (Dark/Light) | `TC-MOB-UI-02` | Manual | Manual UI Test | Covered |

**Offline ย้ายออกจาก FR-HIST-03:** `TC-MOB-HIST-03`, `TC-E2E-OFFLINE-06` เป็นการทดสอบโหมด Offline/Local Cache ย้ายไป map กับ `NFR-PERF-03` (Availability) ไม่นับ coverage FR-HIST-03

---

### 2.9 Mapping Table: Document scheme → Wiki scheme (baseline สำหรับ tests)

Document scheme ให้ map มาหา wiki scheme ดังนี้:

| Document scheme (05_SRS) | Wiki scheme (baseline สำหรับ tests) | หมายเหตุ |
| :--- | :--- | :--- |
| FR-AUTH-01/02/03/04 (สมัคร/ล็อกอิน+Secure Storage/ต่ออายุ/ออกจากระบบ) | FR-AUTH-01 / FR-AUTH-02 / FR-AUTH-03 / FR-AUTH-04 | ตรง 1:1 กับ Document (OAuth = wiki FR-AUTH-06, Phase 2, RC-AUTH-06) |
| FR-SCAN-01 (เลือก+ครอบตัด) | FR-INPUT-01 / FR-INPUT-02 | ตรงกัน (`TC-MOB-IMG-05` ครอบตัด) |
| FR-SCAN-02 (ตรวจ+อัปโหลด) | FR-INPUT-03 / FR-INPUT-04 (dual-limit Mobile 10MB / Server 20MB + decode 100M px + Magic Bytes) / FR-SYS-09 (SHA-256 + Redis Cache) | Magic Bytes เข้า FR-INPUT-04; cache รวมที่ FR-SYS-09 (FR-INPUT-05 ยุบรวมแล้ว) |
| FR-SCAN-03 (Cache) | FR-SYS-09 | hash SHA-256 |
| FR-ANALYSIS-01 (OCR+NLP) | FR-SYS-02 / FR-SYS-03 | ตรงกัน |
| FR-ANALYSIS-02 (Visual + AI-Gen) | FR-SYS-05 / FR-SYS-06 (GAP) | AI-Gen classifier ยังไม่มี TC |
| FR-ANALYSIS-03 (Source) | FR-SYS-04 (GAP) | ยังไม่มี integration/TC |
| FR-ANALYSIS-04 (Risk Score, Hybrid max+bonus) | FR-SYS-07 (Hybrid max+bonus) | สูตร Hybrid max+bonus |
| FR-XAI-01 (Mask Heatmap) | FR-SYS-08 (Mask Heatmap) + FR-REPORT-02/03 | Heatmap มาจาก segmentation mask; Qwen XAI = FR-SYS-11 (wiki baseline §2.3) |
| FR-HISTORY-01 (ประวัติ) | FR-HIST-01/02 + FR-HIST-03 (ลบประวัติ DELETE /api/v1/history/{id}) | Offline ย้ายเป็น NFR/out-of-scope |
| FR-HISTORY-02 (รายงาน) | FR-RPT-01 | ตรงกัน |
| FR-PDPA-01 (Consent) | FR-PDPA-01/02/03 | ตรงกัน |
| FR-ADMIN-01 (Dashboard+User) | FR-ADM-01 / FR-ADM-05 | แยก Dashboard กับ User Management |
| FR-ADMIN-02 (Report Queue) | FR-ADM-02 (รวม Concurrency impl detail + version column) | FR-ADM-06 ยุบรวมเข้า FR-AUDIT-01 แล้ว |
| FR-ADMIN-03 (Model Mgmt) | FR-ADM-04 | ตรงกัน |
| FR-ADMIN-04 (Audit Logs) | FR-AUDIT-01 (Partial: ขาด JSON Diff ครบทุก entity) | FR-ADM-07 ไม่เคยมีใน wiki baseline; canonical คือ FR-AUDIT-01 (wiki FR-ADM-01..05 + FR-AUDIT-01) |

### 2.10 Mapping Table: Document NFR-01..09 → Wiki NFR scheme (baseline สำหรับ tests)

| Document NFR (05_SRS; wiki srs ใช้เลขชุดเดียวกัน) | Wiki NFR scheme | หมายเหตุ |
| :--- | :--- | :--- |
| NFR-01 (Performance response: cache/full/GPU/CPU) | NFR-PERF-01 / NFR-PERF-02 | Cache Hit ≤3s / Full P50 ≤15s (GPU ≤10s / CPU ≤60s รวมใน PERF-02) |
| NFR-02 (Scalability: 100 concurrent) | NFR-PERF-02 (+ `TC-NFR-PERF-04/05`, `TC-NFR-DB-01`) | โหลด 100 users ผ่าน Locust; scale-out 1→4 replicas ยังไม่มี TC เฉพาะ |
| NFR-03 (Availability: uptime/monitoring/alerting) | NFR-PERF-03 (+ `TC-AI-ISO-01` fault tolerance) | Uptime ≥99.5% + monitoring/alerting |
| NFR-04 (Security: TLS/JWT/hash/rate-limit/input) | NFR-SEC-01 (+ `TC-BE-CORS-01`) / NFR-SEC-02 / NFR-SEC-03 (+ `TC-ADM-AUTH-02`) / NFR-SEC-04 (+ `TC-BE-RATE-01`) / NFR-SEC-05 | ครบ 5 ด้าน: transport/auth/RBAC/OWASP/secrets |
| NFR-05 (Accuracy: Acc+mDice) | NFR-AI-01 / NFR-AI-02 (Partial) | ≥85% — มี TC แล้วแต่ขาด test set มาตรฐาน |
| NFR-06 (Usability: UAT/Likert/heatmap) | NFR-A11Y-01 (+ `TC-ADM-UI-01/02/03`) / NFR-A11Y-02 (+ `TC-NFR-USE-01`) | WCAG AA + UAT ≥80%/Likert ≥4.00 |
| NFR-07 (Cache efficiency) | NFR-PERF-01 (hit ≤3s) | hit-rate ≥40%/สัปดาห์ ยังไม่มี TC วัดเฉพาะ |
| NFR-08 (Compatibility: Document NFR-08) | NFR-COMP-01 / NFR-COMP-02 | key flows Android 10–14 (v1 Android เท่านั้น — ตรงกับ §3) + API schema validation (§3) |
| NFR-09 (Maintainability: Document NFR-09) | — (ไม่มี TC) | GAP: ยังไม่มี TC วัด branch coverage/static analysis |
| ex-NFR-10 wiki-local (ยกเลิกเลขนี้แล้ว → Document FR-PDPA-01 + NFR-04 + RC-PDPA-04) | NFR-PDPA-01 / NFR-PDPA-02 + FR-AUDIT-01 (`TC-BE-AUDIT-01`, `TC-ADM-AUD-01`) | Consent/retention tiers/audit append-only |
| ex-NFR-11 wiki-local (ยกเลิกเลขนี้แล้ว → Document FR-ANALYSIS-03 AC-4 fallback, มติ DOC-01) | FR-SYS-04 (GAP: ยังไม่มี integration/TC) | ไม่สรุปว่าปลอดภัยเมื่อวิเคราะห์ไม่ครบ — ตั้ง `source_status = "unavailable"` คำนวณเฉพาะมิติที่สำเร็จ |

### 2.11 TC เพิ่มเติมที่ยังไม่ map (Orphan disposition — recount และ orphan-scan 2026-09-12)

- **วิธี recount**: `grep -hoE 'TC-[A-Z0-9]+(-[A-Z0-9]+)+-[0-9]+' tests_all/manual_tests/*.md | sort -u` ได้ **150 TCs** = mobile 37 + backend 31 + ai 24 + admin 25 + e2e 10 + nfr 23
- **วิธี orphan-scan**: `comm -23 <(TC ทั้งหมดใน manual_tests) <(TC ที่ RTM อ้าง)` พบ **52 TCs** ที่ RTM v1.3.0 ยังไม่ map (Audit §D: ~44 ตัว) — ตารางนี้ map ทั้ง 52 ตัวเข้ากับแถว requirement เดิมที่ TC อ้างถึง (Requirement ID มีอยู่แล้วในไฟล์ TC ทุกตัว) จึง **orphan ค้าง = 0** โดยไม่เปลี่ยนความหมายธุรกิจ
- TC กลุ่มนี้ขยาย coverage ของแถวเดิมใน §2.1–§2.8 และ §3 ไม่ได้นิยาม requirement ใหม่ ยกเว้น `E2E-07..10` (§2.6), `NFR-COMP-01/02` (§3) และ `FR-ADM-03` (§2.5) ที่แยกแถวไว้แล้วข้างต้น

| Test Case ID (orphan เดิม) | Maps to (แถว requirement เดิม) | Priority | สถานะ RTM ใหม่ |
| :--- | :--- | :--- | :--- |
| `TC-ADM-AUTH-04` | NFR-SEC-03 | P0 | Covered (ขยาย) |
| `TC-ADM-SEC-02` | FR-ADM-01 | P0 | Covered (ขยาย) |
| `TC-ADM-MOD-03` | FR-ADM-04 | P1 | Covered (ขยาย) |
| `TC-ADM-MOD-04` | FR-ADM-04 | P1 | Covered (ขยาย) |
| `TC-ADM-EXP-01` | FR-ADM-03 | P1 | Covered (แยกแถว §2.5) |
| `TC-ADM-SEC-01` | FR-ADM-02, FR-ADM-01 | P1 | Covered (ขยาย) |
| `TC-ADM-USR-02` | FR-ADM-05 | P2 | Covered (ขยาย) |
| `TC-ADM-SRCH-01` | FR-ADM-01, FR-ADM-02 | P2 | Covered (ขยาย) |
| `TC-ADM-PAGE-01` | FR-ADM-02, FR-ADM-05, FR-AUDIT-01 | P2 | Covered (ขยาย) |
| `TC-ADM-UI-03` | NFR-A11Y-01, FR-ADM-01 | P2 | Covered (ขยาย) |
| `TC-ADM-COMP-01` | FR-ADM-01, NFR-A11Y-01 | P2 | Covered (ขยาย) |
| `TC-AI-RISK-04` | FR-SYS-07 | P0 | Covered (ขยาย) |
| `TC-AI-RISK-03` | FR-SYS-07 | P1 | Covered (ขยาย) |
| `TC-AI-HEAT-02` | FR-SYS-08 | P1 | Covered (ขยาย) |
| `TC-AI-XAI-02` | FR-SYS-11 | P1 | Covered (ขยาย) |
| `TC-AI-REG-01` | FR-ADM-04 | P1 | Covered (ขยาย) |
| `TC-AI-SEC-01` | FR-SYS-03, FR-SYS-11 | P1 | Covered (ขยาย) |
| `TC-AI-EDGE-05` | FR-SYS-05 | P2 | Covered (ขยาย) |
| `TC-AI-OCR-03` | FR-SYS-02 | P2 | Covered (ขยาย) |
| `TC-AI-PERF-01` | NFR-PERF-03 | P2 | Covered (ขยาย, GAP ทางสำรองตาม TC) |
| `TC-BE-API-01` | NFR-SEC-02, NFR-SEC-03 | P0 | Covered (ขยาย) |
| `TC-BE-SEC-01` | NFR-SEC-04 | P0 | Covered (ขยาย) |
| `TC-BE-AUTH-06` | FR-AUTH-02 | P1 | Covered (ขยาย) |
| `TC-BE-AUTH-07` | FR-AUTH-01 | P1 | Covered (ขยาย) |
| `TC-BE-ADMIN-04` | FR-ADM-02 | P1 | Covered (ขยาย) |
| `TC-BE-DB-02` | FR-HIST-03, NFR-PDPA-02 | P1 | Covered (ขยาย) |
| `TC-BE-DB-03` | FR-INPUT-03, FR-HIST-03 | P1 | Covered (ขยาย) |
| `TC-BE-INT-01` | FR-INPUT-03, FR-HIST-01, FR-RPT-01 | P1 | Covered (ขยาย) |
| `TC-BE-REG-01` | FR-ADM-04, FR-HIST-01 | P1 | Covered (ขยาย) |
| `TC-E2E-FULL-07` | E2E-07 (§2.6) | P1 | Covered (แยกแถว §2.6) |
| `TC-E2E-AUTH-08` | E2E-08 (§2.6) | P1 | Covered (แยกแถว §2.6) |
| `TC-E2E-REG-09` | E2E-09 (§2.6) | P1 | Covered (แยกแถว §2.6) |
| `TC-E2E-HIST-10` | E2E-10 (§2.6) | P2 | Covered (แยกแถว §2.6) |
| `TC-MOB-SEC-01` | FR-HIST-01 | P1 | Covered (ขยาย) |
| `TC-MOB-AUTH-07` | FR-AUTH-01 | P1 | Covered (ขยาย) |
| `TC-MOB-AUTH-08` | FR-AUTH-02 | P2 | Covered (ขยาย) |
| `TC-MOB-IMG-06` | FR-INPUT-04 | P2 | Covered (ขยาย) |
| `TC-MOB-UI-03` | FR-SET-02 | P2 | Covered (ขยาย) |
| `TC-MOB-RPT-03` | FR-RPT-01 | P2 | Covered (ขยาย) |
| `TC-MOB-COMP-01` | FR-INPUT-01 | P2 | Covered (ขยาย) |
| `TC-MOB-A11Y-01` | NFR-A11Y-01, NFR-A11Y-02 | P2 | Covered (ขยาย) |
| `TC-MOB-REG-01` | FR-HIST-01, FR-HIST-02 | P2 | Covered (ขยาย) |
| `TC-NFR-SEC-04` | NFR-SEC-02, NFR-SEC-03 | P0 | Covered (ขยาย) |
| `TC-NFR-SYS-01` | NFR-SYS-01 | P1 | Covered (ขยาย) |
| `TC-NFR-SEC-05` | NFR-SEC-02, NFR-SEC-03 | P1 | Covered (ขยาย) |
| `TC-NFR-SEC-06` | NFR-SEC-04, NFR-PERF-01 | P1 | Covered (ขยาย) |
| `TC-NFR-DB-01` | NFR-PERF-03 | P1 | Covered (ขยาย) |
| `TC-NFR-COMP-01` | NFR-COMP-01 (§3) | P2 | Covered (แยกแถว §3) |
| `TC-NFR-COMP-02` | NFR-COMP-02 (§3) | P2 | Covered (แยกแถว §3) |
| `TC-NFR-PERF-04` | NFR-PERF-01/02/03 | P2 | Covered (ขยาย) |
| `TC-NFR-PERF-05` | NFR-PERF-01/02/03 | P2 | Covered (ขยาย) |
| `TC-NFR-USE-01` | NFR-A11Y-01/02, FR-SET-02 | P2 | Covered (ขยาย) |

### 2.12 ตารางย้อนกลับ TC-to-Req ถาวร + orphan-scan อัตโนมัติ

- ตาราง §2.11 คือ TC-to-Req แบบถาวร: ทุก TC ใน `manual_tests/` ต้องมีแถว map กลับไป Req เดิม ห้ามมี orphan ค้าง
- คำสั่งตรวจ orphan ทุกรอบปล่อย (ต้องได้ 0 ก่อน sign-off): `comm -23 <(grep -hoE 'TC-[A-Z0-9]+(-[A-Z0-9]+)+-[0-9]+' tests_all/manual_tests/*.md | sort -u) <(grep -hoE 'TC-[A-Z0-9]+(-[A-Z0-9]+)+-[0-9]+' tests_all/rtm.md | sort -u)`
- ถ้าพบ TC ใหม่: เพิ่มแถวใน §2.11 (map เข้าแถว Req เดิมที่ TC อ้างถึง) แล้ว recount จำนวน TC รวมใน §4 พร้อมกัน

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
| **NFR-COMP-01** | Compatibility | ติดตั้งและเปิดแอปได้บน Android 10–14 (v1 Android เท่านั้น); วงจรสมัคร/สแกน/ประวัติ/รายงานสำเร็จครบทุกรุ่น | `TC-NFR-COMP-01` | Manual Device Test | Covered |
| **NFR-COMP-02** | Compatibility | Admin Portal ใช้งานได้บน Chrome/Firefox/Safari รุ่นล่าสุด ตัวเลข Dashboard ตรงกันทุกเบราว์เซอร์ | `TC-NFR-COMP-02` | Manual Browser Test | Covered |

**นิยาม 5 NFR กำกวม (strict count แยกหมวด):** `NFR-PERF-03` Monitoring / Health = ยิง health endpoint ทุก 60s ครบ 24h + crash injection; `NFR-SEC-01` Security Audit = ตรวจ redirect 301/308 + TLS 1.2/1.3 + HSTS ด้วย testssl/nmap; `NFR-SEC-05` Code Audit / Pytest = สแกน gitleaks/trufflehog + ตรวจ config ผ่าน env; `NFR-PDPA-02` Integration Test = ยิง DELETE history + ตรวจ DB/storage + GET ซ้ำ 404; `NFR-SYS-01` Script = รัน `server/tests/check_time_tz.py` ตรวจ `created_at` UTC+7

---

## 4. สรุปภาพรวมความครอบคลุม (Coverage Summary)

- **ขอบเขตการครอบคลุม: FR 26/39 Covered (33/39 รวม Partial), NFR 15/17 Covered (17/17 รวม Partial)** — สูตรเดียวทั้งเล่ม: ฐานนับ = wiki scheme 39 รายการ (ตัด pointer ยุบรวม `FR-INPUT-05`/`FR-ADM-06` ไม่นับซ้ำ; `FR-SET-01/02` นอก baseline นับแยก) — ห้ามใช้ฐาน 28/41
- **Functional Requirements (wiki scheme) 39 รายการ** (`FR-SYS-11` เข้า baseline §2.3 แล้ว; `FR-INPUT-05`/`FR-ADM-06` เป็น pointer ยุบรวม ไม่นับซ้ำ): Covered เต็ม **26** รายการ (**66.7%**) — ตัด `FR-INPUT-05` + `FR-ADM-06` ที่ยุบรวม (recount §F 2026-09-12), Partial **7** รายการ (`FR-INPUT-03` cancelScan ไม่มี endpoint, `FR-INPUT-04` Mobile ไม่ปฏิเสธเกิน 10MB, `FR-SYS-08`, `FR-REPORT-01` key safe ตกค้าง, `FR-REPORT-06`, `FR-RPT-01` category keys ไม่ตรง, `FR-AUDIT-01` ขาด JSON Diff ครบ), GAP **4** รายการ (`FR-SYS-01`, `FR-SYS-04`, `FR-SYS-06`, `FR-SHARE-01` ใหม่) + Deferred **2** รายการ (`FR-AUTH-06` OAuth, `FR-SYS-10` FCM) — รวม mapped 33/39 (**84.6%** นับ Partial)
- **FR เพิ่มเติมนอก wiki baseline 2 รายการ** (`FR-SET-01`, `FR-SET-02`): Covered 2/2 (100%)
- **Non-Functional Requirements 17 รายการ** (15 เดิม + `NFR-COMP-01/02` จาก TC จริง): Covered **15** รายการ (**88.2%**), Partial **2** รายการ (`NFR-AI-01`, `NFR-AI-02` มี TC แล้วแต่ขาดชุดทดสอบมาตรฐาน), GAP **0** รายการ — รวม mapped 17/17 (**100%** นับ Partial)
- **Cross-System Journeys (E2E) 10 กระบวนการ** (6 เดิม + `E2E-07..10` จาก TC จริง `TC-E2E-FULL-07/AUTH-08/REG-09/HIST-10`): Covered 10/10 (**100%**)
- **Manual TCs ทั้งหมด 150 TCs** (recount 2026-09-12: mobile 37, backend 31, ai 24, admin 25, e2e 10, nfr 23): orphan-scan พบ 52 TCs ที่ v1.3.0 ยังไม่ map — map ครบแล้วใน §2.11 (รวม `E2E-07..10`, `NFR-COMP-01/02`, `FR-ADM-03`) **orphan ค้าง = 0** (Offline `TC-MOB-HIST-03`/`TC-E2E-OFFLINE-06` map กับ `NFR-PERF-03` ตามเดิม)
### 4.1 ดัชนีหลักฐาน (Evidence link — กรอกไฟล์รายงาน+วันที่+pass/fail เมื่อมีผลรันจริง ห้ามแต่งตัวเลข)

| Requirement ID | ไฟล์รายงาน | วันที่รัน | Pass/Fail |
| :--- | :--- | :--- | :--- |
| (ตัวอย่าง) FR-AUTH-01 | `tests_report/automate_tests/server/auth_api.md` | ปปปป-ดด-วว | — |
| ...ทุกรายการ Covered/Partial... | | | |

กฎ: ทุกรายการ Covered/Partial ต้องมีแถวหลักฐานก่อน sign-off; GAP/Deferred ใส่ `—` พร้อมอ้างหัวข้อที่ 5 ของ release_signoff.md

- **รูปแบบการทดสอบ** (63 rows ที่มี TC, strict): Hybrid 23 รายการ / Automated 10 รายการ / Manual 25 รายการ (+7: `FR-ADM-03`, `E2E-07..10`, `NFR-COMP-01/02`) + 5 NFR กำกวมแยกหมวด (`NFR-PERF-03`, `NFR-SEC-01`, `NFR-SEC-05`, `NFR-PDPA-02`, `NFR-SYS-01` นิยามชัดด้านบน); เพิ่มจาก 58 rows ใน v1.3.0 หลัง map orphan 52 TCs โดย `FR-AUTH-04` (Logout; เดิมเรียก FR-AUTH-05) Manual→Hybrid, `FR-HIST-02` Manual→Hybrid, `FR-HIST-03` Automated→Hybrid, `FR-ADM-01` Manual→Hybrid, `NFR-A11Y-01` เพิ่ม TC แบบ Manual, `FR-SYS-10` กับ `NFR-AI-01` `NFR-AI-02` `FR-AUDIT-01` เพิ่ม TC แบบ Manual Partial/Deferred
