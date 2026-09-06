# ชุดกรณีทดสอบ: คุณลักษณะที่ไม่ใช่เชิงหน้าที่ (Non-Functional Requirements Test Cases)

- **System**: ScamGuard System (Mobile Client, Backend API, AI Inference Engine, Admin Portal, Infrastructure)
- **Scope**: การทดสอบด้านประสิทธิภาพ (Performance), ความมั่นคงปลอดภัย (Security), การคุ้มครองข้อมูลส่วนบุคคล (PDPA), ความพร้อมใช้งาน (Reliability) และการเข้าถึง (Accessibility)
- **Version**: 1.0.0
- **Status**: Baseline

---

## 1. หมวดหมู่ประสิทธิภาพและความพร้อมใช้งาน (Performance & Reliability)

### TC-NFR-PERF-01: การทดสอบเวลาตอบสนองเมื่อพบข้อมูลในแคช (Cache Hit Latency <= 3s)
- **Module / Feature**: Performance / Redis Response Time
- **Requirement ID**: NFR-PERF-01
- **Test Type**: Performance
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. ไฟล์ทดสอบขนาด 1MB ถูกสแกนเข้าระบบแล้ว และมีข้อมูลแคชใน Redis
  2. สภาพแวดล้อมเน็ตเวิร์กจำลอง Latency ปกติ (RTT <= 50ms)
- **Test Data**:
  - Request: `POST /api/v1/scan/` พร้อมภาพที่มี SHA-256 ซ้ำกับในแคช
  - ปริมาณ Concurrent Users: 100 Virtual Users
  - เกณฑ์โหลด: Cache Hit avg ไม่เกิน 5 วินาที, Error Rate ต่ำกว่า 1 เปอร์เซ็นต์
- **Test Steps**:
  1. ใช้เครื่องมือ Locust (`tests_all/automate_tests/tests/performance/locustfile.py` ต้องยิง `POST /api/v1/scan/` และ `GET /health`) ยิงคำขออัปโหลดภาพซ้ำแบบต่อเนื่องเป็นเวลา 5 นาที
  2. บันทึกและวัดผลค่ามัธยฐาน (Median), 95th Percentile (p95), และ 99th Percentile (p99)
- **Expected Results**:
  1. Response Time กรณี Cache Hit ไม่เกิน 3.0 วินาทีแบบ End-to-End
  2. อัตราความผิดพลาดรวมต่ำกว่า 1 เปอร์เซ็นต์
  3. ทรัพยากร CPU ของ Worker ไม่เกิด Spike เนื่องจากไม่ผ่านขั้นตอน GPU Model Inference
- **Automation Mapping**: `tests_all/automate_tests/tests/performance/locustfile.py`

---

### TC-NFR-PERF-02: การทดสอบเวลาประมวลผลการวิเคราะห์เต็มรูปแบบ (Full Inference Latency <= 15s)
- **Module / Feature**: Performance / End-to-End AI Inference Pipeline
- **Requirement ID**: NFR-PERF-02
- **Test Type**: Performance
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. เป็นภาพสแกนใหม่ที่ไม่เคยมีในระบบมาก่อน (Cache Miss)
  2. โมเดล SegFormer, Surya OCR, และ Qwen2.5-1.5B พร้อมทำงานบน GPU/CPU Worker
- **Test Data**:
  - Image: ภาพความละเอียดสูง 1920x1080 พิกเซล นามสกุล JPG ขนาด 3MB
  - โหลดการทดสอบ: 10 คำขอพร้อมกัน (10 Concurrent Pipeline Executions)
  - เกณฑ์โหลด: Cache Miss avg ไม่เกิน 20 วินาทีที่ 100 Concurrent Users, Error Rate ต่ำกว่า 1 เปอร์เซ็นต์
- **Test Steps**:
  1. ยิงคำขออัปโหลดภาพแบบ Cache Miss เข้าสู่ `POST /api/v1/scan/`
  2. จับเวลาตั้งแต่ช่วงส่งคำขอ (HTTP Request Sent) จนกระทั่งได้ Payload ผลลัพธ์สุดท้าย
  3. ตรวจสอบการทำงานของ Tiling Process และการรวมผลลัพธ์
- **Expected Results**:
  1. เวลาประมวลผลรวมทั้งหมดสำหรับภาพความละเอียดสูงต้องไม่เกิน 15.0 วินาทีที่ค่ามัธยฐาน (P50 <= 15.0s) โดย P95 ไม่เกิน 25 วินาที และ P99 ไม่เกิน 35 วินาที
  2. ไม่เกิด Timeout หรือ Out-Of-Memory (OOM) ใน Subprocess ของ AI Engine
  3. ผลลัพธ์ Heatmap Overlay และคะแนน 3 มิติครบถ้วนสมบูรณ์
- **Automation Mapping**: `tests_all/automate_tests/tests/performance/locustfile.py`

---

### TC-NFR-PERF-03: การทดสอบความต่อเนื่องและความพร้อมใช้งานของระบบ (High Availability >= 99.5%)
- **Module / Feature**: Reliability / System Uptime & Health Check
- **Requirement ID**: NFR-PERF-03
- **Test Type**: Reliability
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. รันระบบ ScamGuard เต็มรูปแบบผ่าน Docker Compose
  2. สคริปต์ Health Monitor ทำงานตรวจสอบทุก 1 นาที
- **Test Data**:
  - Endpoint: `GET /health` (สาธารณะ) และ `GET /api/v1/admin/health` (ต้องใช้ Token แอดมิน)
  - ระยะเวลาทดสอบ: 24 ชั่วโมงต่อเนื่อง
- **Test Steps**:
  1. ตั้งค่า Cron Job ยิงคำขอตรวจสอบ Health Check ทุก 60 วินาที
  2. คำนวณอัตราคำขอที่ได้รับ HTTP 200 OK ต่อจำนวนคำขอทั้งหมด
  3. จำลองสถานการณ์ Service AI Worker ตาย (Crash Injection) และตรวจสอบการ Auto-restart
- **Expected Results**:
  1. อัตราความพร้อมใช้งาน (Availability) รวมตลอด 24 ชั่วโมงต้องไม่น้อยกว่า 99.5% ไม่นับช่วงบำรุงรักษาตามแผน
  2. เมื่อ AI Subprocess ล้มเหลว กลไก Graceful Degradation ต้องคืนค่าข้อผิดพลาดชัดเจน โดยไม่ทำให้ Backend Web Server หยุดทำงาน
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_health.py`

---

## 2. หมวดหมู่ความมั่นคงปลอดภัย (Security - OWASP Top 10)

### TC-NFR-SEC-01: การบังคับใช้ HTTPS/TLS 1.2+ และการเข้ารหัสการสื่อสาร
- **Module / Feature**: Security / Transport Layer Security
- **Requirement ID**: NFR-SEC-01
- **Test Type**: Security Audit
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. ระบบ Reverse Proxy (Nginx/Traefik) ติดตั้ง SSL/TLS Certificate
- **Test Data**:
  - URL: `http://api.scamguard.local/` และ `https://api.scamguard.local/`
- **Test Steps**:
  1. ส่ง HTTP Request แบบ Unencrypted ไปยังพอร์ต 80
  2. ตรวจสอบการ Redirect และ Header
  3. ตรวจสอบเวอร์ชัน TLS และ Cipher Suites ด้วยคำสั่ง `testssl.sh` หรือ `nmap`
- **Expected Results**:
  1. คำขอ HTTP ธรรมดาถูก Redirect เป็น HTTPS อัตโนมัติด้วยสถานะ 301 หรือ 308
  2. รองรับเฉพาะ TLS 1.2 และ TLS 1.3 ปฏิเสธ SSLv3, TLS 1.0, และ TLS 1.1
  3. มีการแนบ Header `Strict-Transport-Security (HSTS)`
- **Automation Mapping**: Automated Security Linting & Infrastructure Scan

---

### TC-NFR-SEC-02: การป้องกันการโจมตีผ่านไฟล์อัปโหลดอันตราย (MIME Spoofing & Polyglot)
- **Module / Feature**: Security / File Upload Hardening
- **Requirement ID**: FR-INPUT-04, NFR-SEC-04
- **Test Type**: Security
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. ผู้ใช้เข้าสู่ระบบและได้รับ Token ที่ถูกต้อง
- **Test Data**:
  - File 1: สคริปต์ PHP ที่เปลี่ยนนามสกุลเป็น `.jpg` (`malicious.php.jpg`)
  - File 2: ไฟล์ Executable ที่มี Magic Bytes ของ PNG นำหน้า (Polyglot File)
  - File 3: ไฟล์ข้อความที่เปลี่ยนนามสกุลเป็น `.png` โดยไม่มี Magic Bytes รูปภาพ
- **Test Steps**:
  1. อัปโหลด File 1, 2 และ 3 ผ่าน Endpoint `POST /api/v1/scan/`
  2. สังเกตพฤติกรรมการตรวจสอบส่วนหัวของไฟล์ (Magic Bytes Inspection) ของ Backend
- **Expected Results**:
  1. Backend ต้องปฏิเสธไฟล์ทั้งหมดด้วย HTTP 400 Bad Request หรือ 422 Unprocessable Entity
  2. ข้อความ Error ระบุชัดเจนว่าไฟล์ไม่ถูกต้องตามมาตรฐานรูปภาพที่อนุญาต (jpg, jpeg, png, webp)
  3. ไฟล์อันตรายจะไม่ถูกบันทึกลงในดิสก์หรือส่งต่อไปยัง AI Pipeline
- **Automation Mapping**: `server/tests/api/test_scan.py`

---

### TC-NFR-SEC-03: การตรวจสอบความลับในซอร์สโค้ด (Zero Hardcoded Secrets)
- **Module / Feature**: Security / Static Application Security Testing (SAST)
- **Requirement ID**: NFR-SEC-05
- **Test Type**: Security Code Audit
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. ทำการสแกน Repository ทั้งหมดของโปรเจกต์
- **Test Data**:
  - Pattern ตรวจจับ: รหัสผ่าน, JWT Secret Keys, API Keys, Database Connection String
- **Test Steps**:
  1. รันเครื่องมือ `trufflehog` หรือ `gitleaks` หรือ Regular Expression ตรวจจับ Sensitive Data ทั่วทั้งโค้ดเบส
  2. ตรวจสอบการโหลดการตั้งค่าผ่าน `server/app/core/config.py` และ `.env`
- **Expected Results**:
  1. ไม่พบ Hardcoded Credentials ในโค้ดของ Backend, Mobile, Admin หรือ Automation Script
  2. การตั้งค่าความลับทั้งหมดต้องโหลดผ่าน Environment Variables ผ่าน pydantic-settings
- **Automation Mapping**: SAST (`gitleaks`/`trufflehog`) + ตรวจ `server/app/core/config.py` และ `.env`

---

### TC-NFR-SEC-04: การบังคับยืนยันตัวตน JWT และการแยกสิทธิ์แอดมิน (RBAC 403)
- **Module / Feature**: Security / Authentication & Authorization
- **Requirement ID**: NFR-SEC-02, NFR-SEC-03
- **Test Type**: Security
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มีบัญชีผู้ใช้ทั่วไปและบัญชีแอดมินในระบบ
  2. มี Token ที่ถูกต้อง หมดอายุ และไม่มี Token สำหรับเปรียบเทียบ
- **Test Data**:
  - Endpoint สาธารณะ: `GET /health`
  - Endpoint ผู้ใช้: `POST /api/v1/scan/`, `GET /api/v1/history`
  - Endpoint แอดมิน: `GET /api/v1/admin/users`, `GET /api/v1/admin/reports`
- **Test Steps**:
  1. เรียก Endpoint ผู้ใช้โดยไม่แนบ Token ตรวจสอบว่าถูกปฏิเสธด้วย 401
  2. เรียก Endpoint ผู้ใช้ด้วย Token ของผู้ใช้ที่ถูกระงับ (`is_active` เป็น `false`) ตรวจสอบว่าถูกปฏิเสธด้วย 403
  3. เรียก Endpoint แอดมินด้วย Token ผู้ใช้ทั่วไป ตรวจสอบว่าถูกปฏิเสธด้วย 403
  4. เรียก Endpoint แอดมินด้วย Token แอดมินที่ถูกต้อง ตรวจสอบว่าเข้าถึงได้
- **Expected Results**:
  1. คำขอไม่มี Token ถูกปฏิเสธด้วย 401 โดยไม่เปิดเผยข้อมูลภายใน
  2. บัญชีถูกระงับถูกปฏิเสธด้วย 403 พร้อมข้อความแจ้งว่าบัญชีถูกระงับ
  3. ผู้ใช้ทั่วไปเรียก Endpoint แอดมินถูกปฏิเสธด้วย 403 ทุกกรณี
  4. Token เก็บใน Secure Storage ของเครื่องและแนบผ่าน Authorization Header ทุกคำขอ
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py` (`test_scan_without_auth_should_fail`) + `tests_all/automate_tests/tests/api/test_admin.py`

---

## 3. หมวดหมู่การคุ้มครองข้อมูลส่วนบุคคล (Data Privacy & PDPA)

### TC-NFR-PRIV-01: การขอความยินยอมและการบันทึก Consent ของผู้ใช้ (Explicit Consent)
- **Module / Feature**: Privacy / PDPA Consent Mechanism
- **Requirement ID**: NFR-PDPA-01
- **Test Type**: Functional
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. ผู้ใช้ติดตั้งแอปใหม่ หรือเข้าใช้งานเป็นครั้งแรก
- **Test Data**:
  - นโยบายความเป็นส่วนตัวเวอร์ชัน 1.0 (Privacy Policy v1.0)
  - `system_consent` และ `research_consent` ในคำขอสมัครสมาชิก
- **Test Steps**:
  1. เปิดแอป ScamGuard ครั้งแรก สังเกตหน้าต่าง PDPA Consent Modal
  2. ตรวจสอบปุ่ม "ยินยอม" (Accept) และปุ่ม "ปฏิเสธ" (Decline)
  3. กด "ยินยอม" แล้วสมัครสมาชิกพร้อมส่งค่าความยินยอม
- **Expected Results**:
  1. ก่อนให้ความยินยอมขั้นพื้นฐาน ผู้ใช้ไม่สามารถเข้าสู่หน้าการสแกนภาพได้
  2. สถานะความยินยอมถูกบันทึกลงในตาราง `consent_logs` พร้อม Timestamp (UTC+7)
  3. คำขอสมัครสมาชิกมีฟิลด์ `system_consent` และ `research_consent` กำกับชัดเจน
- **Automation Mapping**: `scam_image_mobile/test/core/widgets/consent_checkbox_tile_test.dart`

---

### TC-NFR-PRIV-02: สิทธิ์ในการขอลบข้อมูลประวัติและภาพสแกน (Right to Erasure)
- **Module / Feature**: Privacy / Data Deletion Workflow
- **Requirement ID**: NFR-PDPA-02
- **Test Type**: Integration & Compliance
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. ผู้ใช้มีประวัติการสแกนอย่างน้อย 1 รายการในตาราง `scans`
- **Test Data**:
  - Scan ID: UUID ของรายการสแกนเป้าหมาย
- **Test Steps**:
  1. ผู้ใช้ส่งคำขอ `DELETE /api/v1/history/{scan_id}` หรือส่งคำขอลบบัญชี
  2. ตรวจสอบการลบข้อมูลใน PostgreSQL และไฟล์ภาพใน Storage
- **Expected Results**:
  1. Record ข้อมูลในตาราง `scans` ถูกลบออกจากฐานข้อมูลจริง (Hard Delete)
  2. ไฟล์รูปภาพต้นฉบับและ Heatmap Overlay ใน Local Storage / S3 ถูกลบทิ้งอย่างถาวร
  3. เมื่อเรียกดู `GET /api/v1/history/{scan_id}` ระบบตอบกลับด้วย 404 Not Found
  4. บันทึกในตาราง `audit_log` ยังคงอยู่เพื่อการตรวจสอบย้อนหลัง (ไม่ถูกลบตามข้อมูลสแกน)
  5. สถานะนี้เป็น GAP บางส่วนสำหรับการลบอัตโนมัติเมื่อครบ 1 ปี เนื่องจากยังไม่มีงาน Cron รายวันในระบบปัจจุบัน (ผู้ใช้ลบด้วยตนเองได้ทันที)
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_history.py`

---

## 4. หมวดหมู่การเข้าถึงและการออกแบบเพื่อทุกคน (Accessibility - WCAG AA)

### TC-NFR-A11Y-01: การตรวจสอบอัตราส่วนความเปรียบต่างของสี (Color Contrast Ratio >= 4.5:1)
- **Module / Feature**: Accessibility / WCAG 2.1 Level AA Contrast
- **Requirement ID**: NFR-A11Y-01
- **Test Type**: Accessibility & UI Design Test
- **Priority**: P2 (Major)
- **Pre-conditions**:
  1. รัน Admin Portal และ Mobile App ทั้งสองชุดธีม (Light Mode และ Dark Mode)
- **Test Data**:
  - สีพื้นหลังและสีตัวอักษรของปุ่ม, ตารางข้อมูล, ข้อความ Risk Badge
- **Test Steps**:
  1. ใช้เครื่องมือ Google Lighthouse หรือ Axe DevTools ตรวจสอบหน้า Admin Portal
  2. ใช้เครื่องมือ Color Contrast Analyzer ตรวจสอบสีบนแอป Mobile:
     - High Risk Badge (#EF4444 เทียบกับพื้นหลัง)
     - Medium Risk Badge (#F59E0B เทียบกับพื้นหลัง)
     - Low Risk Badge (#10B981 เทียบกับพื้นหลัง)
- **Expected Results**:
  1. อัตราส่วนความเปรียบต่าง (Contrast Ratio) สำหรับข้อความปกติ (Body Text) ต้องไม่ต่ำกว่า 4.5:1
  2. ข้อความขนาดใหญ่ (Large Text / Headings) ต้องไม่ต่ำกว่า 3.0:1
  3. ไม่พบข้อผิดพลาดด้าน Accessibility Contrast ในผลการตรวจสอบของ Lighthouse (Score >= 95)
- **Automation Mapping**: Lighthouse Automated Audit

---

### TC-NFR-A11Y-02: ขนาดพื้นที่สัมผัสบนสมาร์ตโฟน (Touch Target Size >= 48x48dp)
- **Module / Feature**: Usability & Accessibility / Mobile Touch Targets
- **Requirement ID**: NFR-A11Y-02
- **Test Type**: UI & Usability Test
- **Priority**: P2 (Major)
- **Pre-conditions**:
  1. เปิดแอป Mobile บนอุปกรณ์ Android (Physical Device หรือ Android Emulator)
- **Test Data**:
  - ปุ่ม Action: "เลือกรูป", "เริ่มสแกน", "รายงาน", ไอคอน Back, ไอคอน Close
- **Test Steps**:
  1. เปิดใช้งาน Accessibility Scanner บนอุปกรณ์ Android หรือใช้ Flutter Widget Inspector
  2. ตรวจสอบขนาดของ Widget ทุกจุดที่มีการโต้ตอบด้วยการสัมผัส (Tappable Area)
- **Expected Results**:
  1. ทุกปุ่มและจุดสัมผัสมีขนาดไม่น้อยกว่า 48x48 dp ตามมาตรฐาน Material Design
  2. ระยะห่างระหว่างปุ่มที่อยู่ติดกันมีช่องว่างเพียงพอ ป้องกันการกดผิดพลาดโดยไม่ตั้งใจ
- **Automation Mapping**: Manual UI Test

---

## 5. หมวดหมู่ความแม่นยำ AI (AI Accuracy)

### TC-NFR-AI-01: ความแม่นยำการตรวจจับภาพตัดต่อไม่ต่ำกว่า 85 เปอร์เซ็นต์ (GAP ยังไม่มีชุดทดสอบมาตรฐาน)
- **Module / Feature**: AI Accuracy / Tamper Detection Benchmark
- **Requirement ID**: NFR-AI-01
- **Test Type**: Performance
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. เตรียมชุดทดสอบมาตรฐานพร้อมเฉลย
- **Test Data**:
  - ชุดภาพตัดต่อและภาพปกติพร้อมป้ายกำกับ
- **Test Steps**:
  1. รันโมเดลกับชุดทดสอบทั้งหมด
  2. คำนวณค่า mDice
- **Expected Results**:
  1. สถานะนี้เป็น GAP เนื่องจากยังไม่มีชุดทดสอบมาตรฐานและสคริปต์วัด mDice ในระบบปัจจุบัน
  2. เกณฑ์ยอมรับเมื่อมีชุดทดสอบคือ mDice ไม่ต่ำกว่า 85 เปอร์เซ็นต์
- **Automation Mapping**: Manual Verification

---

### TC-NFR-AI-02: ความแม่นยำการจำแนกภาพ AI-Generated ไม่ต่ำกว่า 85 เปอร์เซ็นต์ (GAP ยังไม่มีโมเดลเฉพาะ)
- **Module / Feature**: AI Accuracy / AI-Generated Classification
- **Requirement ID**: NFR-AI-02
- **Test Type**: Performance
- **Priority**: P2 (Major)
- **Pre-conditions**:
  1. เตรียมชุดภาพ AI-Generated และภาพถ่ายจริงพร้อมเฉลย
- **Test Data**:
  - ชุดภาพทดสอบสองกลุ่มพร้อมป้ายกำกับ
- **Test Steps**:
  1. รันการจำแนกกับชุดทดสอบทั้งหมด
  2. คำนวณความแม่นยำ
- **Expected Results**:
  1. สถานะนี้เป็น GAP เนื่องจากยังไม่มีโมเดลจำแนก AI-Generated เฉพาะทางในระบบปัจจุบัน
  2. เกณฑ์ยอมรับเมื่อมีโมเดลคือความแม่นยำไม่ต่ำกว่า 85 เปอร์เซ็นต์
- **Automation Mapping**: Manual Verification

---

## 6. หมวดหมู่การแจ้งเตือน (Notification - Deferred Phase 2)

### TC-NFR-FCM-01: การแจ้งเตือนเมื่องานวิเคราะห์พื้นหลังเสร็จ (GAP รอ FCM Phase 2)
- **Module / Feature**: Push Notification / Background Task Completion
- **Requirement ID**: FR-SYS-10
- **Test Type**: Functional
- **Priority**: P3 (Low)
- **Pre-conditions**:
  1. ผู้ใช้เริ่มงานวิเคราะห์แบบ Async แล้วสลับแอปไปพื้นหลัง
- **Test Data**:
  - งานวิเคราะห์ที่ใช้เวลานาน
- **Test Steps**:
  1. เริ่มงานวิเคราะห์แล้วย่อแอปลงพื้นหลัง
  2. รอจนงานเสร็จแล้วตรวจสอบการแจ้งเตือน
- **Expected Results**:
  1. สถานะนี้เป็น GAP เนื่องจากยังไม่มีการเชื่อมต่อ Firebase Cloud Messaging ในระบบปัจจุบัน
  2. เมื่อมี FCM ใน Phase 2 ต้องได้รับแจ้งเตือนและแตะเพื่อเปิดหน้ารายงานผลได้
- **Automation Mapping**: Manual Verification

---

## 7. หมวดหมู่ความถูกต้องของข้อมูล (Data Integrity)

### TC-NFR-SYS-01: การบันทึกและแสดงเวลาในเขตประเทศไทย (Timezone UTC+7)
- **Module / Feature**: Data Integrity / Timezone Handling
- **Requirement ID**: NFR-SYS-01
- **Test Type**: Functional
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. ระบบ Backend และฐานข้อมูลรันด้วยเขตเวลา Asia/Bangkok
- **Test Data**:
  - Record ตัวอย่างในตาราง `scans`, `scam_reports`, `consent_logs`, `audit_log`
- **Test Steps**:
  1. สร้างข้อมูลสแกน รายงาน และความยินยอมใหม่ แล้วอ่านค่า `created_at` จากฐานข้อมูล
  2. รันสคริปต์ `server/tests/check_time_tz.py` ตรวจสอบเขตเวลาของ Record
  3. ตรวจสอบการแสดงเวลาใน Mobile App, Admin Portal และ Audit Logs
- **Expected Results**:
  1. ค่า `created_at` ทุกตารางตรงกับเวลาประเทศไทย (UTC+7 Asia/Bangkok)
  2. สคริปต์ตรวจสอบเขตเวลาผ่านโดยไม่มี Record ที่คลาดเคลื่อน
  3. หน้า Audit Logs แสดง Timestamp (UTC+7) พร้อม JSON Diff ก่อนและหลังการเปลี่ยนสถานะ
- **Automation Mapping**: Script (`server/tests/check_time_tz.py`)
