# แผนการทดสอบ: คุณลักษณะที่ไม่ใช่เชิงหน้าที่ (Non-Functional Requirements Test Plan)

> Version: 1.0.1 | Date: 2026-09-06 | Status: Baseline

- **System / Component**: ScamGuard Whole System (Infrastructure, Security, Performance, Compliance)
- **Standards & Guidelines**: ISO/IEC 25010 (Software Quality Models), OWASP Top 10:2021, PDPA (พ.ร.บ. คุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562), WCAG 2.1 Level AA
- **Document Version**: 1.0.1
- **Date**: 2026-09-06
- **Status**: Baseline

---

## 1. วัตถุประสงค์และขอบเขต (Objectives & Scope)

แผนการทดสอบนี้จัดทำขึ้นเพื่อกำหนดเกณฑ์และกระบวนการประเมินคุณภาพของระบบในมิติที่ไม่ใช่ฟังก์ชันการทำงานพื้นฐาน เพื่อสร้างความมั่นใจในความปลอดภัย ความเร็ว ความน่าเชื่อถือ และการปฏิบัติตามกฎหมายที่เกี่ยวข้อง

### 1.1 มิติคุณภาพที่ครอบคลุม (Quality Dimensions)
1. **ประสิทธิภาพและอัตราการรองรับ (Performance & Scalability)**:
   - ตรวจวัดเวลาตอบสนอง (Latency) ในสถานะ Cache Hit (P50 <= 1.5s, P95 <= 3.0s แบบ End-to-End ภาพ 1MB RTT ≤50ms)
   - ตรวจวัดเวลาประมวลผลการวิเคราะห์เต็มรูปแบบของ AI Pipeline (Cache Miss: P50 <= 15s, P95 <= 25s, P99 <= 35s ภาพ 1920x1080 JPG 3MB)
   - ความสามารถในการรองรับโหลดพร้อมกัน (Concurrency) ตั้งแต่ 50 ถึง 100 ผู้ใช้เสมือนรอบนี้ (200 VU เป็นตัวเลือก M4 ตาม §3 ข้อ 1 — ห้ามเคลม 200 VU หากยังไม่รัน scenario 4)
2. **ความมั่นคงปลอดภัย (Security & Hardening)**:
   - การตรวจสอบความถูกต้องของไฟล์อัปโหลด (Magic Bytes & Content-Type Validation Server ปฏิเสธเกิน 20MB ด้วย HTTP 413 และปฏิเสธภาพเกิน 100M px; rate limit แบบ tier ต่อนาที)
   - การป้องกันช่องโหว่ OWASP Top 10 (Injection, Broken Access Control, Security Misconfiguration)
   - การจัดการความลับ (Zero Hardcoded Secrets) และการบังคับใช้ HTTPS/TLS
3. **การคุ้มครองข้อมูลส่วนบุคคล (Data Privacy & PDPA)**:
   - กลไกการขอความยินยอมแบบชัดแจ้ง (Explicit Consent)
   - สิทธิ์ในการขอลบข้อมูลประวัติและรูปภาพ (Right to Erasure / Data Sanitization)
4. **ความพร้อมใช้งานและความเสถียร (Availability & Resilience)**:
   - เป้าหมายความพร้อมใช้งานไม่น้อยกว่า 99.5% Uptime
   - กลไกการตัดการทำงานอย่างนุ่มนวล (Graceful Degradation) เมื่อ AI Subprocess เกิดข้อผิดพลาด
5. **การเข้าถึงและการออกแบบเพื่อทุกคน (Accessibility & WCAG AA)**:
   - อัตราส่วนความเปรียบต่างสี (Color Contrast) ไม่น้อยกว่า 4.5:1 สำหรับเนื้อหาทั่วไป
   - ขนาดพื้นที่สัมผัส (Touch Target Size) บนอุปกรณ์สมาร์ตโฟนไม่ต่ำกว่า 48x48 dp

---

## 2. เครื่องมือและกลยุทธ์การทดสอบ (Tools & Methodologies)

| มิติการทดสอบ | เครื่องมือหลัก | วิธีการและตัวชี้วัด |
|---|---|---|
| **Performance** | Locust / K6 | ยิงโหลดแบบ Step-up จาก 10 ถึง 200 ผู้ใช้ วัดค่า p95, p99 Latency และ Error Rate |
| **Security SAST** | TruffleHog / GitLeaks / Bandit | สแกนหา Hardcoded Secrets และช่องโหว่ในระดับโค้ดเบส |
| **Security DAST** | OWASP ZAP / Curl Scripts | ทดสอบ Payload การแทรกโค้ด, MIME Spoofing, และการ Bypass สิทธิ์ RBAC |
| **Data Privacy** | Automated Test Suites / DB Audit | ตรวจสอบการลบไฟล์ภาพออกจากดิสก์เมื่อมีการส่งคำขอลบประวัติ |
| **Accessibility** | Google Lighthouse / Axe Core | ประเมินคะแนนการเข้าถึง (เป้าหมาย >= 95) และอัตราส่วน Contrast |

---

## 3. เกณฑ์การตรวจรับด้าน NFR (Exit Criteria)

1. **Performance**:
   - Cache Hit Latency: ค่ามัธยฐาน <= 1.5s, ค่า p95 <= 3.0s ที่โหลดงานผสม 30 RPS (unify ตรงกับ test_plan_performance; เลิกอ้าง 50 RPS)
   - Full Inference Latency (Cache Miss ภาพ 1920x1080 JPG 3MB): P50 <= 15.0s, P95 <= 25.0s, P99 <= 35.0s (unify ตรงกับ NFR-PERF-02 และ test_cases_nfr.md; P99 เป็น exit เต็มเฉพาะรอบ N ≥ 100 samples/endpoint)
   - Error Rate ในช่วงทดสอบโหลดปกติต้องเท่ากับ 0.0%
   - ขอบเขต 200 VU (ตัวเลือกพร้อมข้อเสนอ ไม่ตัดสินใจแทน): A (เสนอ) คง 50–100 VU รอบนี้แล้วประกาศชัดว่ารอบนี้ไม่เคลม 200 VU ผูกแผนขยาย M4; B เพิ่ม scenario 200 VU/10 นาที (spawn 5/s) เป็น exit รอบนี้ — ต้องมีเครื่อง+คิวงานรองรับก่อน
2. **Availability วิธีวัด (ตัวเลือกพร้อมข้อเสนอ)**: A (เสนอ) วัดจาก probe `GET /health` ทุก 60s คิด uptime = สำเร็จ/ทั้งหมด เป้า ≥99.5% ต่อรอบ soak; B ใช้ log gateway จริงเมื่อขึ้น staging/prod — รอบนี้ยังไม่เลือก B ถือว่าใช้ A
3. **Security**:
   - ไม่พบช่องโหว่ระดับ High หรือ Critical ตามเกณฑ์ OWASP
   - ตรวจสอบไฟล์อัปโหลดด้วย Magic Bytes 100% ปฏิเสธไฟล์ Polyglot และ Executable
   - ความลับ (API Keys, JWT Secrets, DB Credentials) ทั้งหมดถูกเก็บใน Environment Variables
4. **Privacy (PDPA — ครอบ cache/ไฟล์ทุกชั้น)**:
   - ระบบกำหนดให้มีการยืนยัน Consent จากผู้ใช้ในขั้นตอนลงทะเบียนก่อนการใช้งานการสแกน
   - คำขอลบต้องลบครบทุกชั้น: แถว DB + ไฟล์ดิสก์/อ็อบเจ็กต์สโตร์ + คีย์ Redis (SHA-256) + thumbnail/offline cache ฝั่ง mobile + สำเนาใน log/audit ที่ถอดรหัสย้อนกลับได้ วิธีตรวจ: เรียก GET เดิมต้อง 404 + ค้น hash ใน Redis ต้อง miss + ตรวจดิสก์ต้องไม่มีไฟล์
5. **Accessibility (+ theme latency ย้ายจาก test_plan_admin)**:
   - ทุกหน้าจอหลักของ Mobile App และ Admin Portal ผ่านเกณฑ์ WCAG 2.1 Level AA (Contrast Ratio >= 4.5:1)
   - Theme latency (เจ้าของ: NFR plan นี้): สลับ Dark/Light จบภายใน 500ms ไม่ FOUC วัดด้วย Lighthouse/DevTools timeline (ย้ายออกจาก exit ของ admin เหลือ cross-ref)

---

## 4. ความเชื่อมโยงไปยังชุดกรณีทดสอบจริง
- **เอกสารกรณีทดสอบละเอียด**: `tests_all/manual_tests/test_cases_nfr.md`
- **ชุดทดสอบประสิทธิภาพอัตโนมัติ**: `tests_all/automate_tests/tests/performance/locustfile.py`
- **ตารางความสอดคล้องความต้องการ**: `tests_all/rtm.md` (หมวดหมู่ NFR ทั้งหมด)

## 5. ขอบเขตนอกการทดสอบและ GAP
- FCM Push Notification และ OAuth Social Login เป็น Deferred Phase 2 ไม่อยู่ในขอบเขตการทดสอบรอบนี้
- เส้นทาง POST /api/v1/scan/upload ไม่มีอยู่จริง ต้องใช้ POST /api/v1/scan/ เท่านั้น
