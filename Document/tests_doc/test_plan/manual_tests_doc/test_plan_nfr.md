# แผนการทดสอบ: คุณลักษณะที่ไม่ใช่เชิงหน้าที่ (Non-Functional Requirements Test Plan)

- **System / Component**: ScamGuard Whole System (Infrastructure, Security, Performance, Compliance)
- **Standards & Guidelines**: ISO/IEC 25010 (Software Quality Models), OWASP Top 10:2021, PDPA (พ.ร.บ. คุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562), WCAG 2.1 Level AA
- **Document Version**: 1.0.0
- **Status**: Approved

---

## 1. วัตถุประสงค์และขอบเขต (Objectives & Scope)

แผนการทดสอบนี้จัดทำขึ้นเพื่อกำหนดเกณฑ์และกระบวนการประเมินคุณภาพของระบบในมิติที่ไม่ใช่ฟังก์ชันการทำงานพื้นฐาน เพื่อสร้างความมั่นใจในความปลอดภัย ความเร็ว ความน่าเชื่อถือ และการปฏิบัติตามกฎหมายที่เกี่ยวข้อง

### 1.1 มิติคุณภาพที่ครอบคลุม (Quality Dimensions)
1. **ประสิทธิภาพและอัตราการรองรับ (Performance & Scalability)**:
   - ตรวจวัดเวลาตอบสนอง (Latency) ในสถานะ Cache Hit (<= 3 วินาที)
   - ตรวจวัดเวลาประมวลผลการวิเคราะห์เต็มรูปแบบของ AI Pipeline (<= 15 วินาที)
   - ความสามารถในการรองรับโหลดพร้อมกัน (Concurrency) ตั้งแต่ 50 ถึง 200 ผู้ใช้เสมือน (Virtual Users)
2. **ความมั่นคงปลอดภัย (Security & Hardening)**:
   - การตรวจสอบความถูกต้องของไฟล์อัปโหลด (Magic Bytes & Content-Type Validation)
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
   - Cache Hit Latency: ค่ามัธยฐาน <= 1.5s, ค่า p95 <= 3.0s ที่โหลด 50 RPS
   - Full Inference Latency: ค่า p90 <= 15.0s สำหรับภาพความละเอียดสูง
   - Error Rate ในช่วงทดสอบโหลดปกติต้องเท่ากับ 0.0%
2. **Security**:
   - ไม่พบช่องโหว่ระดับ High หรือ Critical ตามเกณฑ์ OWASP
   - ตรวจสอบไฟล์อัปโหลดด้วย Magic Bytes 100% ปฏิเสธไฟล์ Polyglot และ Executable
   - ความลับ (API Keys, JWT Secrets, DB Credentials) ทั้งหมดถูกเก็บใน Environment Variables
3. **Privacy (PDPA)**:
   - ระบบไม่ประมวลผลการสแกนหากไม่มีการยืนยัน Consent จากผู้ใช้
   - ข้อมูลประวัติและไฟล์ภาพถูกลบอย่างสมบูรณ์ตามคำขอขอลบข้อมูล
4. **Accessibility**:
   - ทุกหน้าจอหลักของ Mobile App และ Admin Portal ผ่านเกณฑ์ WCAG 2.1 Level AA (Contrast Ratio >= 4.5:1)

---

## 4. ความเชื่อมโยงไปยังชุดกรณีทดสอบจริง
- **เอกสารกรณีทดสอบละเอียด**: `tests_all/manual_tests/test_cases_nfr.md`
- **ชุดทดสอบประสิทธิภาพอัตโนมัติ**: `tests_all/automate_tests/tests/performance/locustfile.py`
- **ตารางความสอดคล้องความต้องการ**: `tests_all/rtm.md` (หมวดหมู่ NFR ทั้งหมด)
