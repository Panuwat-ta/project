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
- **Test Type**: Performance & Benchmark
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. ไฟล์ทดสอบขนาด 1MB ถูกสแกนเข้าระบบแล้ว และมีข้อมูลแคชใน Redis
  2. สภาพแวดล้อมเน็ตเวิร์กจำลอง Latency ปกติ (RTT <= 50ms)
- **Test Data**:
  - Request: `POST /api/v1/scan/` พร้อมภาพที่มี SHA-256 ซ้ำกับในแคช
  - ปริมาณ Concurrent Users: 50 Virtual Users
- **Test Steps**:
  1. ใช้เครื่องมือ Locust หรือ K6 ยิงคำขออัปโหลดภาพซ้ำแบบต่อเนื่องเป็นเวลา 5 นาที
  2. บันทึกและวัดผลค่ามัธยฐาน (Median), 95th Percentile (p95), และ 99th Percentile (p99)
- **Expected Results**:
  1. ค่าเฉลี่ยและค่า p95 Response Time ต้องไม่เกิน 3.0 วินาที
  2. อัตราความสำเร็จของคำขอ (HTTP 200/201) ต้องเท่ากับ 100% (Error Rate 0.0%)
  3. ทรัพยากร CPU ของ Worker ไม่เกิด Spike เนื่องจากไม่ผ่านขั้นตอน GPU Model Inference
- **Automation Mapping**: `tests_all/automate_tests/tests/performance/locustfile.py`

---

### TC-NFR-PERF-02: การทดสอบเวลาประมวลผลการวิเคราะห์เต็มรูปแบบ (Full Inference Latency <= 15s)
- **Module / Feature**: Performance / End-to-End AI Inference Pipeline
- **Requirement ID**: NFR-PERF-02
- **Test Type**: Performance & Stress Test
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. เป็นภาพสแกนใหม่ที่ไม่เคยมีในระบบมาก่อน (Cache Miss)
  2. โมเดล SegFormer, Surya OCR, และ Qwen2.5-1.5B พร้อมทำงานบน GPU/CPU Worker
- **Test Data**:
  - Image: ภาพความละเอียดสูง 1920x1080 พิกเซล นามสกุล JPG ขนาด 3MB
  - โหลดการทดสอบ: 10 คำขอพร้อมกัน (10 Concurrent Pipeline Executions)
- **Test Steps**:
  1. ยิงคำขออัปโหลดภาพแบบ Cache Miss เข้าสู่ `POST /api/v1/scan/`
  2. จับเวลาตั้งแต่ช่วงส่งคำขอ (HTTP Request Sent) จนกระทั่งได้ Payload ผลลัพธ์สุดท้าย
  3. ตรวจสอบการทำงานของ Tiling Process และการรวมผลลัพธ์
- **Expected Results**:
  1. เวลาประมวลผลรวมทั้งหมดสำหรับภาพความละเอียดสูงต้องไม่เกิน 15.0 วินาที (p90 <= 15.0s)
  2. ไม่เกิด Timeout หรือ Out-Of-Memory (OOM) ใน Subprocess ของ AI Engine
  3. ผลลัพธ์ Heatmap Overlay และคะแนน 3 มิติครบถ้วนสมบูรณ์
- **Automation Mapping**: `tests_all/automate_tests/tests/performance/locustfile.py`

---

### TC-NFR-PERF-03: การทดสอบความต่อเนื่องและความพร้อมใช้งานของระบบ (High Availability >= 99.5%)
- **Module / Feature**: Reliability / System Uptime & Health Check
- **Requirement ID**: NFR-PERF-03
- **Test Type**: Availability & Soak Test
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. รันระบบ ScamGuard เต็มรูปแบบผ่าน Docker Compose
  2. สคริปต์ Health Monitor ทำงานตรวจสอบทุก 1 นาที
- **Test Data**:
  - Endpoint: `GET /health` และ `GET /api/v1/health`
  - ระยะเวลาทดสอบ: 24 ชั่วโมงต่อเนื่อง
- **Test Steps**:
  1. ตั้งค่า Cron Job ยิงคำขอตรวจสอบ Health Check ทุก 60 วินาที
  2. คำนวณอัตราคำขอที่ได้รับ HTTP 200 OK ต่อจำนวนคำขอทั้งหมด
  3. จำลองสถานการณ์ Service AI Worker ตาย (Crash Injection) และตรวจสอบการ Auto-restart
- **Expected Results**:
  1. อัตราความพร้อมใช้งาน (Availability) รวมตลอด 24 ชั่วโมงต้องไม่น้อยกว่า 99.5%
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
- **Requirement ID**: FR-INPUT-06, NFR-SEC-04
- **Test Type**: Security & Penetration Testing
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. ผู้ใช้เข้าสู่ระบบและได้รับ Token ที่ถูกต้อง
- **Test Data**:
  - File 1: สคริปต์ PHP ที่เปลี่ยนนามสกุลเป็น `.jpg` (`malicious.php.jpg`)
  - File 2: ไฟล์ Executable ที่มี Magic Bytes ของ PNG นำหน้า (Polyglot File)
  - File 3: ไฟล์ SVG ที่ฝังโค้ด XSS (`<script>alert(1)</script>`)
- **Test Steps**:
  1. อัปโหลด File 1, 2 และ 3 ผ่าน Endpoint `POST /api/v1/scan/`
  2. สังเกตพฤติกรรมการตรวจสอบส่วนหัวของไฟล์ (Magic Bytes Inspection) ของ Backend
- **Expected Results**:
  1. Backend ต้องปฏิเสธไฟล์ทั้งหมดด้วย HTTP 400 Bad Request หรือ 422 Unprocessable Entity
  2. ข้อความ Error ระบุชัดเจนว่าไฟล์ไม่ถูกต้องตามมาตรฐานรูปภาพที่อนุญาต (JPEG/PNG เท่านั้น)
  3. ไฟล์อันตรายจะไม่ถูกบันทึกลงในดิสก์หรือส่งต่อไปยัง AI Pipeline
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

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
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_health.py`

---

## 3. หมวดหมู่การคุ้มครองข้อมูลส่วนบุคคล (Data Privacy & PDPA)

### TC-NFR-PRIV-01: การขอความยินยอมและการบันทึก Consent ของผู้ใช้ (Explicit Consent)
- **Module / Feature**: Privacy / PDPA Consent Mechanism
- **Requirement ID**: NFR-PDPA-01
- **Test Type**: Functional & Compliance
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. ผู้ใช้ติดตั้งแอปใหม่ หรือเข้าใช้งานเป็นครั้งแรก
- **Test Data**:
  - นโยบายความเป็นส่วนตัวเวอร์ชัน 1.0 (Privacy Policy v1.0)
- **Test Steps**:
  1. เปิดแอป ScamGuard ครั้งแรก สังเกตหน้าต่าง PDPA Consent Modal
  2. ตรวจสอบปุ่ม "ยินยอม" (Accept) และปุ่ม "ปฏิเสธ" (Decline)
  3. กด "ยินยอม" แล้วส่งภาพสแกน
- **Expected Results**:
  1. ก่อนให้ความยินยอม ผู้ใช้ไม่สามารถเข้าสู่หน้าการสแกนภาพได้
  2. สถานะความยินยอมถูกบันทึกลงในฐานข้อมูลพร้อม Timestamp (UTC+7)
  3. Payload การสแกนมีฟิลด์ `consent: true` กำกับอย่างชัดเจน
- **Automation Mapping**: `tests_all/manual_tests/test_cases_mobile.md::TC-MOB-PDPA-01`

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
  1. Record ข้อมูลในตาราง `scans` ถูกลบ (หรือทำ Soft Delete นิรนามข้อมูลตามนโยบาย PDPA)
  2. ไฟล์รูปภาพต้นฉบับและ Heatmap Overlay ใน Local Storage / S3 ถูกลบทิ้งอย่างถาวร
  3. เมื่อเรียกดู `GET /api/v1/history/{scan_id}` ระบบตอบกลับด้วย 404 Not Found
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
- **Automation Mapping**: Flutter Widget Golden Test / Inspector Review
