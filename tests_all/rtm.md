# ตารางสอบย้อนกลับความต้องการ (Requirements Traceability Matrix - RTM)

- **Project**: ScamGuard (Scam Image Detection System)
- **Standard**: ISO/IEC/IEEE 29119-3 Test Documentation
- **Version**: 1.0.0
- **Status**: Baseline

---

## 1. คำอธิบายตาราง (Overview)

ตารางสอบย้อนกลับความต้องการ (RTM) ฉบับนี้ จัดทำขึ้นเพื่อเชื่อมโยงความต้องการของระบบ (Requirements) ทั้งหมดจาก Software Requirements Specification (SRS) และ Wiki (`wiki/requirements/`) เข้ากับกรณีทดสอบเชิงปฏิบัติการ (Test Cases) ในโฟลเดอร์ `tests_all/manual_tests/` และชุดทดสอบอัตโนมัติใน `tests_all/automate_tests/` และ `server/tests/` เพื่อให้มั่นใจว่าทุกความต้องการของระบบได้รับการทดสอบอย่างครอบคลุม 100%

---

## 2. เมทริกซ์การสืบย้อนความต้องการเชิงฟังก์ชัน (Functional Requirements Traceability)

### 2.1 โมดูลการยืนยันตัวตน (Authentication)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-AUTH-01** | ผู้ใช้สมัครสมาชิกด้วย Email/Password ได้ | `TC-MOB-AUTH-01`<br>`TC-BE-AUTH-01` | Hybrid | `tests_all/automate_tests/tests/api/test_auth_flow.py` | Covered |
| **FR-AUTH-02** | ผู้ใช้เข้าสู่ระบบด้วย Email/Password ได้รับ JWT | `TC-MOB-AUTH-02`<br>`TC-BE-AUTH-02` | Hybrid | `tests_all/automate_tests/tests/api/test_auth_flow.py` | Covered |
| **FR-AUTH-03** | ผู้ใช้เข้าสู่ระบบด้วย Google OAuth ได้ | `TC-MOB-AUTH-03` | Manual | Manual Verification | Covered |
| **FR-AUTH-04** | เก็บ Token ใน Secure Storage อย่างปลอดภัย | `TC-MOB-AUTH-04`<br>`TC-BE-AUTH-03` | Hybrid | `scam_image_mobile/test/core/network/` | Covered |
| **FR-AUTH-05** | ผู้ใช้ออกจากระบบ (Logout) เพื่อล้างค่า Session | `TC-MOB-AUTH-05` | Manual | Manual Verification | Covered |

---

### 2.2 โมดูลการรับภาพและการตรวจสอบไฟล์ (Image Input & Validation)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-INPUT-01** | เลือกรูปภาพจากแกลเลอรีในเครื่องได้ | `TC-MOB-IMG-01` | Manual | Manual UI Test | Covered |
| **FR-INPUT-02** | ถ่ายภาพใหม่ผ่านกล้องของสมาร์ตโฟนได้ | `TC-MOB-IMG-02` | Manual | Manual Device Test | Covered |
| **FR-INPUT-03** | เครื่องมือครอบตัด (Crop) ภาพก่อนส่งสแกน | `TC-MOB-IMG-03` | Manual | Manual UI Test | Covered |
| **FR-INPUT-04** | อัปโหลดภาพผ่าน Multipart HTTP ไปยัง Backend | `TC-MOB-SCAN-01`<br>`TC-BE-SCAN-01` | Hybrid | `tests_all/automate_tests/tests/api/test_scan_workflow.py` | Covered |
| **FR-INPUT-05** | ปฏิเสธไฟล์เกิน 10MB และนามสกุลที่ไม่รองรับ | `TC-MOB-IMG-04`<br>`TC-BE-SCAN-02` | Hybrid | `tests_all/automate_tests/tests/api/test_scan_workflow.py` | Covered |
| **FR-INPUT-06** | ตรวจจับ Magic Bytes ป้องกันไฟล์อันตราย | `TC-BE-SCAN-03` | Automated | `tests_all/automate_tests/tests/api/test_scan_workflow.py` | Covered |

---

### 2.3 โมดูลการประมวลผลและการตรวจจับ AI (AI Analysis & Scoring)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-SYS-01** | ดึงข้อมูล EXIF และ Metadata จากรูปภาพ | `TC-BE-SCAN-04` | Automated | `server/tests/api/test_scan_workflow.py` | Covered |
| **FR-SYS-02** | สกัดข้อความ (OCR) ด้วย Surya OCR (TH/EN) | `TC-AI-OCR-01` | Hybrid | `server/tests/inference/test_surya.py` | Covered |
| **FR-SYS-03** | ตรวจจับคำหลอกลวงหรือข้อความผิดปกติด้วย NLP | `TC-AI-OCR-02` | Automated | `tests_all/automate_tests/tests/api/test_scan_workflow.py` | Covered |
| **FR-SYS-04** | ค้นหาประวัติภาพย้อนกลับด้วย Google Vision API | `TC-AI-SRC-01` | Hybrid | `server/tests/services/test_source_verify.py` | Covered |
| **FR-SYS-05** | ตรวจจับร่องรอยการตัดต่อด้วย SegFormer Tiling | `TC-AI-TILE-01`<br>`TC-AI-TILE-02` | Hybrid | `server/tests/inference/test_segformer.py` | Covered |
| **FR-SYS-06** | คัดกรองภาพสังเคราะห์ Generative AI | `TC-AI-GEN-01` | Hybrid | `server/tests/inference/test_ai_classifier.py` | Covered |
| **FR-SYS-07** | คำนวณ Overall Risk Score (Hybrid Worst-Case) | `TC-AI-RISK-01`<br>`TC-AI-RISK-02` | Automated | `server/tests/utils/test_risk_calculator.py` | Covered |
| **FR-SYS-08** | สร้าง Full-Resolution Heatmap Overlay | `TC-AI-HEAT-01` | Hybrid | `server/tests/inference/test_heatmap.py` | Covered |
| **FR-SYS-09** | แคชผลการสแกนลง Redis ด้วย SHA-256 Hash | `TC-BE-CACHE-01`<br>`TC-BE-CACHE-02` | Automated | `tests_all/automate_tests/tests/api/test_scan_workflow.py` | Covered |
| **FR-SYS-10** | สร้างคำอธิบายเชิงเหตุผลด้วย Qwen2.5-1.5B (XAI) | `TC-AI-XAI-01` | Hybrid | `server/tests/inference/test_qwen_xai.py` | Covered |

---

### 2.4 โมดูลการแสดงผลรายงานและประวัติ (Report & History)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-REPORT-01** | แสดง Risk Score (0-100) พร้อมสี 3 ระดับ | `TC-MOB-RES-01` | Manual | `scam_image_mobile/test/core/utils/` | Covered |
| **FR-REPORT-02** | แสดง Heatmap Overlay ซ้อนทับภาพต้นฉบับ | `TC-MOB-RES-02` | Manual | Manual UI Test | Covered |
| **FR-REPORT-03** | ปุ่มเปิด/ปิด และปรับความโปร่งใส Heatmap | `TC-MOB-RES-03` | Manual | Manual UI Test | Covered |
| **FR-REPORT-04** | แสดงคะแนนจำแนกรายชั้น (Text, Source, Visual) | `TC-MOB-RES-04` | Manual | `tests_all/tests_report/automate_tests/mobile/result_factors_test.md` | Covered |
| **FR-REPORT-05** | แสดงข้อความเหตุผลและสรุปจาก AI (Qwen) | `TC-MOB-RES-05` | Manual | Manual UI Test | Covered |
| **FR-REPORT-06** | แสดงผล Source Verification (จำนวนเว็บไซต์ที่พบภาพเดียวกัน) | `TC-MOB-RES-04`<br>`TC-AI-SRC-01` | Hybrid | `tests_all/tests_report/automate_tests/mobile/result_factors_test.md` | Covered |
| **FR-HIST-01** | แสดงรายการประวัติการสแกนย้อนหลังเรียงตามเวลา | `TC-MOB-HIST-01`<br>`TC-BE-HIST-01` | Hybrid | `tests_all/automate_tests/tests/api/test_history.py` | Covered |
| **FR-HIST-02** | แตะรายการประวัติเพื่อเปิดดูผลลัพธ์เดิมได้ | `TC-MOB-HIST-02` | Manual | Manual UI Test | Covered |
| **FR-HIST-03** | การทำงานในโหมด Offline และแคช Local Storage | `TC-MOB-HIST-03` | Manual | Manual Device Test | Covered |
| **FR-RPT-01** | ผู้ใช้ส่งรายงานข้อร้องเรียน (Scam Report) ได้ | `TC-MOB-RPT-01`<br>`TC-BE-HIST-02` | Hybrid | `tests_all/automate_tests/tests/api/test_history.py` | Covered |

---

### 2.5 โมดูลระบบจัดการผู้ดูแลระบบ (Admin Portal)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-ADM-01** | แดชบอร์ดสถิติภาพรวม และ WebSocket Telemetry | `TC-ADM-DASH-01`<br>`TC-ADM-WS-01` | Manual | Playwright / Manual Console | Covered |
| **FR-ADM-02** | ตรวจสอบข้อร้องเรียน อนุมัติ/ปัดตก รายงาน | `TC-ADM-REP-01`<br>`TC-ADM-REP-02` | Hybrid | `tests_all/automate_tests/tests/api/test_admin.py` | Covered |
| **FR-ADM-03** | การควบคุม Concurrency ด้วย Version Column | `TC-ADM-REP-03` | Automated | `server/tests/api/test_admin_reports.py` | Covered |
| **FR-ADM-04** | การบริหารจัดการโมเดล AI (Deploy / Rollback) | `TC-ADM-MOD-01`<br>`TC-ADM-MOD-02` | Hybrid | `server/tests/api/test_admin_models.py` | Covered |
| **FR-ADM-05** | จัดการรายชื่อผู้ใช้และสั่งระงับการใช้งาน (Ban) | `TC-ADM-USR-01`<br>`TC-ADM-USR-02` | Hybrid | `server/tests/api/test_admin_users.py` | Covered |
| **FR-ADM-06** | ตรวจสอบบันทึกความปลอดภัย (Audit Logs Diff) | `TC-ADM-LOG-01` | Manual | Manual Console Test | Covered |

---

### 2.6 กระบวนการทำงานข้ามระบบครบวงจร (Cross-System End-to-End Journeys)

| Journey ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **E2E-01** | ตรวจสอบภาพสแกนครบวงจร (Mobile -> API -> AI -> Result) | `TC-E2E-SCAN-01` | Hybrid | `tests_all/automate_tests/tests/e2e/test_e2e_scam_flow.py` | Covered |
| **E2E-02** | ตรวจสอบความเร็วแคช Redis ข้ามผู้ใช้ (Cache Hit Latency) | `TC-E2E-CACHE-02` | Automated | `tests_all/automate_tests/tests/api/test_scan_workflow.py` | Covered |
| **E2E-03** | ผู้ใช้ส่งรายงานข้อร้องเรียนสู่การพิจารณาของแอดมิน | `TC-E2E-REPORT-03` | Hybrid | `tests_all/automate_tests/tests/api/test_admin.py` | Covered |
| **E2E-04** | แอดมินสลับโมเดล AI และมีผลต่อการสแกนทันที (Hot-Swap) | `TC-E2E-MODEL-04` | Hybrid | `server/tests/api/test_admin_models.py` | Covered |
| **E2E-05** | แอดมินระงับผู้ใช้และการตัดสิทธิ์ Session บนมือถือทันที | `TC-E2E-BAN-05` | Hybrid | `tests_all/automate_tests/tests/api/test_admin.py` | Covered |
| **E2E-06** | การทำงานในโหมดออฟไลน์และการซิงก์ข้อมูลเมื่อต่อเน็ต | `TC-E2E-OFFLINE-06` | Manual | Manual Device Test | Covered |

---

### 2.7 การจัดการข้อมูลส่วนบุคคลตามกฎหมาย PDPA (PDPA Controls)

| Requirement ID | รายละเอียดความต้องการ | Test Case ID | รูปแบบการทดสอบ | สคริปต์อัตโนมัติอ้างอิง | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-PDPA-01** | แสดงหน้า Consent ยินยอมการประมวลผลข้อมูลในครั้งแรกที่เปิดแอป | `TC-MOB-PDPA-01` | Manual | Manual UI Test | Covered |
| **FR-PDPA-02** | ผู้ใช้ถอนความยินยอมในการเข้าร่วมวิจัยได้จากหน้าการตั้งค่า | `TC-MOB-PDPA-01`<br>`TC-NFR-PRIV-01` | Hybrid | `server/tests/api/test_user_privacy.py` | Covered |
| **FR-PDPA-03** | หากถอนความยินยอม ระบบต้องลบภาพของผู้ใช้ออกจาก Dataset วิจัย | `TC-NFR-PRIV-01` | Automated | `tests_all/automate_tests/tests/api/test_history.py` | Covered |

---

## 3. เมทริกซ์การสืบย้อนความต้องการที่ไม่ใช่ฟังก์ชัน (Non-Functional Requirements Traceability)

| Requirement ID | ประเภทข้อกำหนด | เป้าหมายและเกณฑ์การยอมรับ | Test Case ID | วิธีการทดสอบ | สถานะความครอบคลุม |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **NFR-PERF-01** | Performance | เวลาตอบสนอง Cache Hit <= 3 วินาที (E2E) | `TC-NFR-PERF-01` | Automated (Locust) | Covered |
| **NFR-PERF-02** | Performance | เวลาตอบสนอง Full Inference <= 15 วินาที | `TC-NFR-PERF-02` | Automated (Locust) | Covered |
| **NFR-PERF-03** | Availability | System Availability / Uptime >= 99.5% | `TC-NFR-PERF-03` | Monitoring / Health | Covered |
| **NFR-AI-01** | AI Accuracy | SegFormer mDice การตรวจจับภาพตัดต่อ >= 85% | `TC-AI-METRIC-01` | Benchmark Test | Covered |
| **NFR-AI-02** | AI Accuracy | ความแม่นยำจำแนกภาพ AI-Generated >= 85% | `TC-AI-METRIC-02` | Benchmark Test | Covered |
| **NFR-SEC-01** | Security | เข้ารหัสการรับส่งข้อมูลด้วย HTTPS/TLS 100% | `TC-NFR-SEC-01` | Security Audit | Covered |
| **NFR-SEC-02** | Security | บังคับตรวจสอบสิทธิ์ JWT ทุก Protected Endpoint | `TC-BE-AUTH-04` | Automated (Pytest) | Covered |
| **NFR-SEC-03** | Security | แยกสิทธิ์ Admin RBAC ปฏิเสธ User ทั่วไป (403) | `TC-BE-ADMIN-01` | Automated (Pytest) | Covered |
| **NFR-SEC-04** | Security | ป้องกันการโจมตี OWASP Top 10 (SQLi, XSS) | `TC-NFR-SEC-02` | Automated Scanner | Covered |
| **NFR-SEC-05** | Security | Zero Hardcoded Secrets (โหลดจาก .env ล้วน) | `TC-NFR-SEC-03` | Code Audit / Pytest | Covered |
| **NFR-PDPA-01** | Privacy & PDPA | หน้า Consent ยินยอมการประมวลผลข้อมูล | `TC-MOB-PDPA-01` | Manual UI Test | Covered |
| **NFR-PDPA-02** | Privacy & PDPA | สิทธิ์การขอลบข้อมูลและภาพสแกนของผู้ใช้ | `TC-NFR-PRIV-01` | Integration Test | Covered |
| **NFR-A11Y-01** | Accessibility | Contrast Ratio >= 4.5:1 ตามเกณฑ์ WCAG AA | `TC-NFR-A11Y-01` | Automated Lighthouse | Covered |
| **NFR-A11Y-02** | Usability | ขนาด Touch Target บน Mobile >= 48x48dp | `TC-NFR-A11Y-02` | Manual UI Test | Covered |

---

## 4. สรุปภาพรวมความครอบคลุม (Coverage Summary)

- **Total Functional Requirements (FR)**: 40 รายการ -> ครอบคลุมแล้ว 40 รายการ (**100%**)
- **Total Non-Functional Requirements (NFR)**: 14 รายการ -> ครอบคลุมแล้ว 14 รายการ (**100%**)
- **Total Cross-System Journeys (E2E)**: 6 กระบวนการ -> ครอบคลุมแล้ว 6 กระบวนการ (**100%**)
- **รูปแบบการทดสอบ**:
  - Automated Tests: 21 รายการ
  - Hybrid Tests (Manual + Automated): 22 รายการ
  - Manual Tests: 17 รายการ
