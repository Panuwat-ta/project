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
  - เกณฑ์โหลด: Cache Hit avg ไม่เกิน 3 วินาที (ตรงตาม NFR-PERF-01), Error Rate ต่ำกว่า 1 เปอร์เซ็นต์
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
1. สถานะนี้เป็น GAP บางส่วนด้านจังหวะการตอบ: `POST /api/v1/scan/` ตอบ `200 OK` พร้อมสถานะ `uploading` ก่อน ไฟล์ที่ไม่มี Magic Bytes รูปภาพจะทำให้งานเบื้องหลังจบสถานะ `failed` (ตรวจซ้ำด้วย `GET /api/v1/scan/{scan_id}`) ไม่ได้ตอบ `400/422` ทันทีตอนอัปโหลด
2. ฝั่งบริการไม่มีบัญชีขาวนามสกุลไฟล์ (รับทุกไฟล์ที่ PIL ถอดรหัสได้ เช่น BMP และ HEIC ตาม `server/tests/api/test_scan.py`) การตรวจใช้ Magic Bytes ผ่านการถอดรหัสจริง ไม่เชื่อ `content_type` หรือนามสกุล
3. ไฟล์ที่ไม่ผ่านการตรวจไม่ถูกบันทึกลงดิสก์และไม่ถูกส่งต่อเข้า AI Pipeline ส่วนไฟล์ที่ผ่านการถอดรหัสจะถูกเข้ารหัสใหม่เป็น PNG ผ่าน `encode_lossless_png` ก่อนเก็บเป็นหลักฐาน
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

---

## 8. หมวดหมู่ความทนทานภายใต้โหลดต่อเนื่องและโหลดกระชาก (Soak and Spike)

### TC-NFR-PERF-04: การทดสอบความเสถียรเมื่อรับโหลดต่อเนื่องยาวนาน (Soak Test)
- **Module / Feature**: Performance / Sustained Load Stability
- **Requirement ID**: NFR-PERF-01, NFR-PERF-02, NFR-PERF-03
- **Test Type**: Performance
- **Priority**: P2 (Major)
- **Pre-conditions**:
  1. รันระบบเต็มรูปแบบผ่านคอนเทนเนอร์ Backend PostgreSQL และ Redis พร้อมใช้งาน
   2. เตรียมบัญชีผู้ใช้สำหรับยิงโหลดและภาพทดสอบทั้งแบบซ้ำแคชและแบบใหม่ไม่ซ้ำแคช
   3. ติดตั้งเครื่องมือ Locust (GAP เครื่องมือ: `locustfile.py` ปัจจุบันมีเพียงงานพื้นฐาน `GET /health` กับ `POST /api/v1/scan/` แบบไม่แนบ Token ซึ่งถูกปฏิเสธด้วย 401 ไม่มีการยิงต่อเนื่องหลายชั่วโมง ไม่แยกกลุ่ม Cache Hit กับ Cache Miss และไม่มีรูปคลื่นโหลด ต้องขยายสคริปต์ให้รองรับการแนบ Token การยิงต่อเนื่อง และการเก็บเปอร์เซ็นไทล์แยกกลุ่มก่อนจึงจะทดสอบข้อนี้ได้จริง)
- **Test Data**:
  - เส้นทาง `GET /health` และ `POST /api/v1/scan/` ผ่านฟิลด์ `file` พร้อมหัวข้อ
  - รูปแบบโหลดต่อเนื่องระดับปานกลางเป็นเวลาหลายชั่วโมง ไม่ใช่การยิงกระชากสั้น
  - เกณฑ์อ้างอิงเดิมคือ Cache Hit ไม่เกิน 3 วินาที งานวิเคราะห์ใหม่ค่ามัธยฐานไม่เกิน 15 วินาที อัตราผิดพลาดรวมต่ำกว่า 1 เปอร์เซ็นต์
- **Test Steps**:
  1. ใช้ `tests_all/automate_tests/tests/performance/locustfile.py` ยิง `GET /health` สลับกับ `POST /api/v1/scan/` แบบต่อเนื่องยาวนาน
  2. บันทึกค่ามัธยฐาน เปอร์เซ็นไทล์ที่ 95 และ 99 ของเวลาตอบสนองแยกกลุ่ม Cache Hit และ Cache Miss
  3. เฝ้าระวังหน่วยความจำ Worker การเชื่อมต่อฐานข้อมูลและ Redis ตลอดช่วงทดสอบ
  4. ตรวจ `GET /health` เป็นระยะว่าสถานะฐานข้อมูลและแคชยังปกติ
- **Expected Results**:
  1. เวลาตอบสนองกลุ่ม Cache Hit ยังไม่เกิน 3 วินาทีแบบ End-to-End ตลอดช่วงทดสอบ
  2. งานวิเคราะห์ใหม่ค่ามัธยฐานไม่เกิน 15 วินาที ไม่เกิด Timeout หรือหน่วยความจำล้นในงานเบื้องหลัง
  3. อัตราความผิดพลาดรวมต่ำกว่า 1 เปอร์เซ็นต์และไม่มีหน่วยความจำรั่วจนต้องรีสตาร์ตกลางคัน
  4. หลังจบการทดสอบ ระบบยังสแกนภาพใหม่และดึงประวัติได้ตามปกติ
- **Automation Mapping**: `tests_all/automate_tests/tests/performance/locustfile.py`

---

### TC-NFR-PERF-05: การทดสอบเมื่อโหลดพุ่งกระชากฉับพลันแล้วคลายตัว (Spike Test)
- **Module / Feature**: Performance / Burst Load Recovery
- **Requirement ID**: NFR-PERF-01, NFR-PERF-02, NFR-PERF-03
- **Test Type**: Performance
- **Priority**: P2 (Major)
- **Pre-conditions**:
  1. ระบบอยู่ในสถานะว่างก่อนเริ่มทดสอบและวัดเวลาตอบสนองฐานไว้แล้ว
   2. เตรียมภาพทดสอบแบบซ้ำแคชและแบบใหม่แยกกันเพื่อดูผลกระทบรายกลุ่ม
   3. ติดตั้งเครื่องมือ Locust (GAP เครื่องมือ: `locustfile.py` ปัจจุบันมีเพียงงานพื้นฐาน `GET /health` กับ `POST /api/v1/scan/` แบบไม่แนบ Token ซึ่งถูกปฏิเสธด้วย 401 ไม่มีรูปคลื่นพุ่งกระชากฉับพลันแล้วคลายตัว ไม่มี `LoadTestShape` หรือขั้นตอนเพิ่มลดผู้ใช้ ต้องขยายสคริปต์ให้รองรับการแนบ Token รูปคลื่น spike และการเก็บกราฟเวลาตอบสนองก่อนจึงจะทดสอบข้อนี้ได้จริง)
- **Test Data**:
  - เส้นทาง `GET /health` และ `POST /api/v1/scan/` ผ่านฟิลด์ `file` พร้อมหัวข้อ
  - รูปแบบโหลดฐานต่ำ สลับช่วงพุ่งสูงฉับพลัน แล้วลดกลับสู่ระดับฐาน
  - เกณฑ์อ้างอิงเดิมคือ Cache Hit ไม่เกิน 3 วินาที อัตราผิดพลาดรวมต่ำกว่า 1 เปอร์เซ็นต์ ความพร้อมใช้งานรวมไม่น้อยกว่า 99.5 เปอร์เซ็นต์
- **Test Steps**:
  1. ยิงโหลดฐานต่ำด้วย `tests_all/automate_tests/tests/performance/locustfile.py` เพื่อเก็บค่าฐาน
  2. เพิ่มผู้ใช้พร้อมกันแบบฉับพลันในช่วงสั้นแล้วลดกลับสู่ระดับฐาน
  3. บันทึกเวลาตอบสนอง อัตราผิดพลาด และพฤติกรรมคิวงานเบื้องหลังช่วงพีคและช่วงฟื้นตัว
  4. ตรวจ `GET /health` ว่าสถานะฐานข้อมูลและแคชกลับมาปกติหลังพีค
- **Expected Results**:
  1. ช่วงพีคระบบไม่ล่ม ไม่ตอบ `500 Internal Server Error` เป็นวงกว้าง งานที่รับไว้ยังจบสถานะ `completed` หรือ `failed` อย่างชัดเจน
  2. หลังลดโหลด เวลาตอบสนองกลุ่ม Cache Hit กลับมาต่ำกว่าหรือเท่ากับ 3 วินาทีโดยไม่ต้องรีสตาร์ตระบบ
  3. ไม่เกิดงานค้างถาวรในคิวเบื้องหลังและไม่มีข้อมูลประวัติสูญหาย
  4. สรุปกราฟเวลาตอบสนองช่วงก่อนพีค ขณะพีค และหลังพีคครบถ้วน
- **Automation Mapping**: `tests_all/automate_tests/tests/performance/locustfile.py`

---

## 9. หมวดหมู่ความมั่นคงเพิ่มเติม (Session Fixation and Rate Limit Resilience)

### TC-NFR-SEC-05: การตรึงเซสชันและการใช้ Token ต่อหลังออกจากระบบ (Session Fixation and Post Logout Refresh)
- **Module / Feature**: Security / Session Fixation and Logout Revocation
- **Requirement ID**: NFR-SEC-02, NFR-SEC-03, FR-AUTH-04, FR-AUTH-05
- **Test Type**: Security
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. มีบัญชีผู้ใช้ทั่วไปและบัญชีแอดมินที่เปิดใช้งานอยู่
  2. ทราบพฤติกรรมจริงว่าฝั่งผู้ใช้ใช้ JWT แบบไร้สถานะ ส่วนฝั่งแอดมินผูก Access Token กับเซสชันและเพิกถอนได้
  3. เตรียมเครื่องมือดักจับคำขอเพื่อเก็บค่า Token ก่อนและหลังล็อกอิน
- **Test Data**:
  - ฝั่งผู้ใช้คือ `POST /api/v1/auth/login` ผ่านฟอร์ม `username` และ `password` `POST /api/v1/auth/refresh` พร้อมฟิลด์ `refresh_token` `GET /api/v1/auth/me` และ `POST /api/v1/auth/logout`
  - ฝั่งแอดมินคือ `POST /api/v1/admin/login` `POST /api/v1/admin/refresh` ผ่านคุกกี้ `admin_refresh_token` `GET /api/v1/admin/me` `GET /api/v1/admin/sessions` และ `POST /api/v1/admin/logout`
- **Test Steps**:
  1. ล็อกอินผู้ใช้ เก็บ Access Token และ Refresh Token ชุดแรกไว้ แล้วเรียก `GET /api/v1/auth/me` เพื่อยืนยัน
  2. เรียก `POST /api/v1/auth/logout` แล้วนำ Refresh Token ชุดเดิมไปเรียก `POST /api/v1/auth/refresh` ซ้ำ
  3. ล็อกอินแอดมิน เก็บ Access Token และคุกกี้ Refresh ไว้ แล้วเรียก `GET /api/v1/admin/me` และ `GET /api/v1/admin/sessions`
  4. เรียก `POST /api/v1/admin/logout` แล้วนำ Access Token เดิมไปเรียก `GET /api/v1/admin/me` และนำคุกกี้เดิมไปเรียก `POST /api/v1/admin/refresh` ซ้ำ
  5. ทดสอบการตรึงเซสชันโดยนำ Token เก่าก่อนล็อกอินใหม่กลับมาใช้ซ้ำหลังล็อกอินรอบใหม่
- **Expected Results**:
  1. ฝั่งผู้ใช้ `POST /api/v1/auth/logout` ตอบ `200 OK` พร้อม `{"message": "Successfully logged out"}` โดยการล้าง Token หลักทำที่ฝั่ง Client และ Refresh Token เดิมยังต่ออายุได้จนกว่าจะหมดอายุหรือบัญชีถูกระงับ จึงต้องล้าง Secure Storage ทุกครั้งหลังออกจากระบบ
  2. ฝั่งแอดมินหลัง `POST /api/v1/admin/logout` เซสชันปัจจุบันถูกเพิกถอน Access Token เดิมเรียก `GET /api/v1/admin/me` ไม่สำเร็จ และคุกกี้เดิมเรียก `POST /api/v1/admin/refresh` ตอบ `401 Unauthorized`
  3. Token ก่อนล็อกอินใหม่ไม่สามารถสวมสิทธิ์เซสชันใหม่ได้ ระบบยึดตัวตนจาก Token ชุดปัจจุบันเท่านั้น
  4. บัญชีที่ถูกระงับเรียกเส้นทางที่ต้องยืนยันตัวตนถูกปฏิเสธด้วย `403 Forbidden`
  5. ไม่มีการเปิดเผยข้อมูลภายในในข้อความผิดพลาด `401 Unauthorized` และ `403 Forbidden`
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py` + `server/tests/api/test_admin_auth.py` + Manual Verification

---

### TC-NFR-SEC-06: การรับมือเมื่อถูกจำกัดอัตราและการถอยจังหวะตามเวลาที่แจ้ง (Rate Limit Backoff)
- **Module / Feature**: Security and Performance / Rate Limit Client Resilience
- **Requirement ID**: NFR-SEC-04, NFR-PERF-01
- **Test Type**: Security and Performance
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. ทราบโควตาจริงคือภาพรวม 60 ครั้งต่อชั่วโมงต่อ IP และเส้นทาง `POST /api/v1/admin/login` กับ `POST /api/v1/admin/refresh` จำกัด 5 ครั้งต่อนาที
  2. เตรียม Client ทดสอบจาก IP เดียวกันเพื่อยิงเกินโควตาโดยตั้งใจ
  3. เตรียมภาพทดสอบสำหรับ `POST /api/v1/scan/` และบัญชีแอดมินสำหรับเส้นทางล็อกอิน
- **Test Data**:
  - เส้นทาง `POST /api/v1/admin/login` ผ่านฟอร์ม `username` และ `password`
  - เส้นทาง `GET /health` และ `POST /api/v1/scan/` ผ่านฟิลด์ `file` พร้อมหัวข้อ
  - ตัวนับคำขอแยกโควตาภาพรวมและโควตาแอดมินออกจากกัน
- **Test Steps**:
  1. ยิง `POST /api/v1/admin/login` เกิน 5 ครั้งภายใน 1 นาทีจาก IP เดียวกันแล้วบันทึกสถานะและส่วนหัวเวลารอ
  2. ยิงคำขอภาพรวมเกิน 60 ครั้งต่อชั่วโมงแล้วสังเกตสถานะ `429 Too Many Requests`
  3. ให้ Client หยุดยิงตามเวลารอที่แจ้งแล้วลองใหม่หลังพ้นช่วงเวลาจำกัด
  4. ยืนยันว่าคำขอในโควตายังทำงานปกติระหว่างการทดสอบ
- **Expected Results**:
  1. คำขอในโควตาตอบตามปกติ คำขอเกินโควตาตอบ `429 Too Many Requests` พร้อมส่วนหัวแจ้งเวลารอ
  2. Client ที่เคารพเวลารอสามารถกลับมาทำงานได้โดยไม่ต้องรีสตาร์ตระบบ
  3. โควตาภาพรวม 60 ครั้งต่อชั่วโมงมีผลทุกคำขอ ส่วนโควตา 5 ครั้งต่อนาทีมีผลเฉพาะเส้นทางล็อกอินและต่ออายุฝั่งแอดมิน
  4. ไม่พบการหลุดโควตา ไม่พบข้อมูลรั่วในช่วงถูกจำกัดอัตรา
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py` + `tests_all/automate_tests/tests/performance/locustfile.py`

---

## 10. หมวดหมู่ความเข้ากันได้ (Compatibility)

### TC-NFR-COMP-01: การใช้งาน Mobile บน Android หลายรุ่นและ iOS (Android 10 to 14 and iOS)
- **Module / Feature**: Compatibility / Mobile OS Coverage
- **Requirement ID**: NFR-COMP-01
- **Test Type**: Compatibility
- **Priority**: P2 (Major)
- **Pre-conditions**:
  1. เตรียมอุปกรณ์หรือโปรแกรมจำลอง Android 10 11 12 13 14 และอุปกรณ์ iOS ที่มีโครงสร้าง Runner พร้อมติดตั้ง
  2. ติดตั้งแอปจากชุดซอร์ส Flutter ชุดเดียวกัน ไม่แยกโค้ดรายรุ่น
  3. Backend พร้อมใช้งานและมีบัญชีทดสอบที่ล็อกอินได้
- **Test Data**:
  - อุปกรณ์ Android 10 11 12 13 14 และ iOS อย่างน้อย 1 รุ่น
  - เส้นทางใช้งานคือสมัครด้วย `POST /api/v1/auth/register` ล็อกอิน สแกนด้วย `POST /api/v1/scan/` ดูประวัติด้วย `GET /api/v1/history` และส่งรายงานด้วย `POST /api/v1/reports`
  - การตั้งค่ากำหนดรุ่นขั้นต่ำและรุ่นเป้าหมายอ้างอิงไฟล์ `android/app/build.gradle.kts` ผ่านค่า `flutter.minSdkVersion` และ `flutter.targetSdkVersion`
- **Test Steps**:
  1. ติดตั้งและเปิดแอปบน Android ครบทุกรุ่นและบน iOS
  2. สมัครหรือล็อกอิน เลือกรูป สแกน รอผล เปิดประวัติ และส่งรายงาน 1 รอบบนแต่ละอุปกรณ์
  3. ตรวจการแสดงผลปุ่ม ตัวอักษร ภาพตัวอย่าง และ Heatmap บนขนาดจอต่างกัน
  4. ตรวจการขอสิทธิ์แกลเลอรีและการจัดการเมื่อผู้ใช้ปฏิเสธสิทธิ์บนแต่ละรุ่น
- **Expected Results**:
  1. ติดตั้งและเปิดแอปได้ทุกอุปกรณ์ทดสอบโดยไม่ Crash ตั้งแต่หน้าแรก
  2. วงจรสมัคร สแกน ประวัติ และรายงานสำเร็จครบทุกรุ่น ระดับความเสี่ยงแสดงตัวพิมพ์เล็ก `low` `medium` `high` ตรงกัน
  3. การปฏิเสธสิทธิ์แกลเลอรีแสดงคำอธิบายและทางไปต่อ ไม่ค้างหน้าว่าง
  4. บันทึกผลรายรุ่นพร้อมชื่อรุ่นและเลขระบบปฏิบัติการ หากรุ่นใดไม่ผ่านให้แยกบันทึกเป็นข้อบกพร่องรายรุ่น
- **Automation Mapping**: Manual Device Test

---

### TC-NFR-COMP-02: การใช้งาน Admin Portal บนเบราว์เซอร์หลัก (Chrome Firefox Safari)
- **Module / Feature**: Compatibility / Admin Portal Browsers
- **Requirement ID**: NFR-COMP-02
- **Test Type**: Compatibility
- **Priority**: P2 (Major)
- **Pre-conditions**:
  1. เตรียม Chrome Firefox และ Safari รุ่นล่าสุดบนคอมพิวเตอร์
  2. Backend พร้อมใช้งานและมีบัญชีแอดมินที่มีสิทธิ์ Super Admin
  3. Admin Portal สร้างจากชุดซอร์ส React และ Vite ชุดเดียวกัน
- **Test Data**:
  - เบราว์เซอร์ Chrome Firefox และ Safari รุ่นล่าสุด
  - เส้นทางแอดมินคือ `GET /api/v1/admin/dashboard` `GET /api/v1/admin/health` `GET /api/v1/admin/reports` `GET /api/v1/admin/models` และ `GET /api/v1/admin/audit-logs`
  - หน้าจอที่ตรวจคือ Dashboard รายงาน โมเดล ผู้ใช้ และ Audit Logs
- **Test Steps**:
  1. เปิด Admin Portal บนทั้งสามเบราว์เซอร์แล้วล็อกอินด้วยบัญชีเดียวกัน
  2. เปิด Dashboard ตรวจการ์ดตัวเลขและกราฟ แล้วเปิดหน้า Report Review ค้นหาและเปิดรายละเอียด
  3. เปิดหน้าโมเดล ตรวจ Dry-run และเปิดหน้า Audit Logs ตรวจตัวกรอง `action` และ `entity_type`
  4. ย่อขยายหน้าจอและรีเฟรชเพื่อดูความเสถียรของการแสดงผล
- **Expected Results**:
  1. ล็อกอินและใช้งานทุกหน้าได้ทั้งสามเบราว์เซอร์โดยไม่พบ Error จนใช้งานต่อไม่ได้
  2. ตัวเลข Dashboard ตารางรายงานและบันทึก Audit แสดงตรงกันทั้งสามเบราว์เซอร์
  3. การแสดงผลไม่แตก ไม่ซ้อนทับจนอ่านไม่ได้ที่ความกว้างจอปกติของคอมพิวเตอร์
  4. บันทึกผลรายเบราว์เซอร์พร้อมเลขรุ่น หากเบราว์เซอร์ใดไม่ผ่านให้แยกบันทึกเป็นข้อบกพร่องรายเบราว์เซอร์
- **Automation Mapping**: Manual Browser Test

---

## 11. หมวดหมู่ความสะดวกใช้ภายใต้สภาพจริง (Usability Under Real Conditions)

### TC-NFR-USE-01: การอ่านจอกลางแจ้ง ฟอนต์ระบบขนาดใหญ่ และโหมดประหยัดแบต (Light Font Battery Saver)
- **Module / Feature**: Usability and Accessibility / Real World Readability
- **Requirement ID**: NFR-A11Y-01, NFR-A11Y-02, FR-SET-02
- **Test Type**: Usability
- **Priority**: P2 (Major)
- **Pre-conditions**:
  1. เตรียมอุปกรณ์ Android หรือ iOS ที่ปรับขนาดฟอนต์ระบบ เปิดโหมดประหยัดแบต และทดสอบกลางแจ้งได้
  2. แอปรองรับโหมดสว่างและโหมดมืดผ่านการตั้งค่าธีมและใช้ Material Design
  3. มีบัญชีทดสอบ ภาพทดสอบ และประวัติเดิมสำหรับเปิดดู
- **Test Data**:
  - ขนาดฟอนต์ระบบระดับปกติและระดับใหญ่สุดของเครื่อง
  - สภาพแสงในร่มและกลางแจ้ง
  - สถานะโหมดประหยัดแบตเปิดและปิด
  - หน้าที่ตรวจคือหน้าสแกน หน้าผล หน้าประวัติ และหน้ารายงาน
- **Test Steps**:
  1. ตั้งฟอนต์ระบบเป็นขนาดใหญ่สุดแล้วเปิดหน้าสแกน หน้าผล หน้าประวัติ และหน้ารายงาน
  2. นำอุปกรณ์ออกกลางแจ้งแล้วอ่านคะแนน ระดับความเสี่ยง และปุ่มหลักทั้งโหมดสว่างและโหมดมืด
  3. เปิดโหมดประหยัดแบตแล้วสแกน 1 รอบ เปิดประวัติ เปิด Heatmap และสลับธีม
  4. ตรวจปุ่มหลักว่ายังแตะง่าย ไม่ซ้อนทับ และข้อความไม่ล้นจนใช้งานไม่ได้
- **Expected Results**:
  1. ข้อความสำคัญ คะแนน และปุ่มหลักยังอ่านออกและแตะได้ทั้งฟอนต์ปกติและฟอนต์ใหญ่สุด ไม่พบข้อความล้นจนใช้งานไม่ได้
  2. กลางแจ้งยังแยกป้ายระดับ `low` `medium` `high` และอ่านคะแนนออกทั้งสองธีม
  3. โหมดประหยัดแบตยังสแกน เปิดประวัติ และแสดง Heatmap ได้ครบ ไม่ค้างหรือ Crash
  4. บันทึกจุดที่อ่านยากหรือแตะพลาดพร้อมชื่อหน้าและสภาพที่พบแยกเป็นข้อเสนอปรับปรุง
- **Automation Mapping**: Manual UI Test

---

## 12. หมวดหมู่การสำรองและกู้คืนข้อมูล (Backup and Restore)

### TC-NFR-DB-01: การสำรองและกู้คืนฐานข้อมูลพร้อมการเข้ารหัส (Encrypted Backup Restore)
- **Module / Feature**: Database / Backup Encryption and Restore Verification
- **Requirement ID**: NFR-PERF-03
- **Test Type**: Reliability and Database
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. กำหนดรหัสผ่านสำรอง `BACKUP_PASSWORD` ในไฟล์ `.env` เรียบร้อยแล้ว
  2. ฐานข้อมูล PostgreSQL มีข้อมูลจริงทั้งบัญชีผู้ใช้ ประวัติสแกน รายงาน และบันทึกตรวจสอบ
  3. มีสิทธิ์รันสคริปต์สำรองและกู้คืนบนเครื่องทดสอบ
- **Test Data**:
  - สคริปต์ `server/scripts/backup.sh` ซึ่งสำรองด้วย `pg_dump` แล้วเข้ารหัสด้วย `openssl enc -aes-256-cbc` เป็นไฟล์ `.enc`
  - สคริปต์ `server/scripts/restore.sh` ซึ่งถอดรหัสแล้วนำเข้าด้วย `psql`
  - ข้อมูลอ้างอิงคือแถวในตาราง `users` `scans` `scam_reports` `consent_logs` `model_versions` และ `audit_log` เอกพจน์
  - คู่มืออ้างอิง `Document/admin/runbook.md`
- **Test Steps**:
  1. รัน `bash server/scripts/backup.sh` แล้วตรวจสอบว่ามีไฟล์สำรอง `.enc` ใหม่เกิดขึ้น
  2. บันทึกจำนวนแถวอ้างอิงและตัวอย่าง `scan_id` ก่อนกู้คืน
  3. จำลองความเสียหายบนฐานข้อมูลทดสอบแล้วรัน `./restore.sh <backup_file.enc>` ด้วยไฟล์จากข้อ 1
  4. ตรวจจำนวนแถว ตัวอย่าง `scan_id` และการล็อกอินด้วยบัญชีเดิม
  5. ตรวจว่าไฟล์สำรองที่ไม่อยู่ในรูปแบบ `.enc` หรือรหัสผ่านผิดไม่สามารถกู้คืนได้
- **Expected Results**:
  1. สำรองสำเร็จได้ไฟล์ `.enc` ไฟล์ดิบ `.sql` ถูกลบทิ้งหลังเข้ารหัส หากไม่มี `BACKUP_PASSWORD` สคริปต์หยุดพร้อมแจ้งให้กำหนดค่า
  2. กู้คืนสำเร็จ ข้อมูลบัญชี ประวัติ รายงาน และบันทึกตรวจสอบกลับมาตรงกับก่อนทดสอบ
  3. บัญชีเดิมล็อกอินได้ ประวัติดเดิมเรียกด้วย `GET /api/v1/history` ได้ครบ
  4. ไฟล์สำรองเสียหายหรือรหัสผ่านผิดกู้คืนไม่สำเร็จและมีข้อความผิดพลาดชัดเจน ไม่เขียนข้อมูลครึ่งเดียวโดยไม่มีการแจ้ง
- **Automation Mapping**: `server/scripts/backup.sh` + `server/scripts/restore.sh` + `Document/admin/runbook.md`
