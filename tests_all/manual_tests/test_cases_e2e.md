# ชุดกรณีทดสอบ: กระบวนการทำงานข้ามระบบตั้งแต่ต้นจนจบ (End-to-End Test Cases)

- **System**: ScamGuard System (Mobile Client, FastAPI Backend, AI Inference Service, PostgreSQL, Redis, Admin Portal)
- **Scope**: การทดสอบแบบบูรณาการข้ามทุกคอมโพเนนต์ ตั้งแต่หน้าบ้านจนถึงหลังบ้านและคอนโซลผู้ดูแลระบบ
- **Version**: 1.0.0
- **Status**: Baseline

---

## 1. ผังการทำงานข้ามระบบ (Cross-System Workflow Matrix)

| Scenario ID | Journey Name | Source System | Intermediate Systems | Target System | Priority |
|---|---|---|---|---|---|
| `TC-E2E-SCAN-01` | Full User Scam Detection Journey | Mobile (Flutter) | FastAPI, Redis, SegFormer, Surya OCR, Qwen2.5 | Mobile Result Screen | P0 (Blocker) |
| `TC-E2E-CACHE-02` | High-Speed Cache Hit Workflow | Mobile / API Client | FastAPI, Redis (SHA-256 Hash Cache) | Client (Bypass AI) | P0 (Blocker) |
| `TC-E2E-REPORT-03` | User Incident Reporting to Admin Review | Mobile (User) | FastAPI, PostgreSQL (`reports` table) | Admin Forensic Console | P1 (Critical) |
| `TC-E2E-MODEL-04` | AI Model Deployment to Live Inference | Admin Portal | FastAPI, Model Registry, AI Worker | Mobile Scan Engine | P1 (Critical) |
| `TC-E2E-BAN-05` | Malicious Actor Ban and Session Revocation | Admin Portal | FastAPI, DB Users, Mobile Dio Interceptor | Mobile Client Screen | P1 (Critical) |
| `TC-E2E-OFFLINE-06` | Offline Storage and Reconnection Sync | Mobile Client | Local Cache (Flutter Secure Storage / Hive) | FastAPI Backend | P2 (Major) |

---

## 2. รายละเอียดกรณีทดสอบ E2E (Detailed Test Cases)

### TC-E2E-SCAN-01: การตรวจสอบภาพต้องสงสัยแบบครบวงจร (Full Detection Workflow)
- **Module / Feature**: Cross-System / End-to-End Scan Journey
- **Requirement ID**: FR-INPUT-04, FR-SYS-01, FR-SYS-02, FR-SYS-05, FR-SYS-07, FR-SYS-08, FR-SYS-10, FR-REPORT-01, FR-REPORT-02, FR-REPORT-05
- **Test Type**: End-to-End Integration
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. Backend FastAPI Service และ AI Inference Pipeline พร้อมใช้งานบน Environment
  2. Redis Cache และ PostgreSQL Database เชื่อมต่อปกติ
  3. ผู้ใช้เข้าสู่ระบบผ่าน Mobile App เรียบร้อยแล้ว
- **Test Data**:
  - Image: `slip_tampered_high_res.jpg` (ภาพสลิปหรือเอกสารที่มีการตัดต่อตัวเลขและข้อความ ขนาด 1920x1080)
  - Title: "ตรวจสอบสลิปโอนเงินต้องสงสัย"
- **Test Steps**:
  1. เปิดแอป ScamGuard บนสมาร์ตโฟน แล้วเลือกภาพ `slip_tampered_high_res.jpg` จากแกลเลอรี
  2. ครอบตัด (Crop) ภาพตามสัดส่วนที่ต้องการ และกดปุ่ม "เริ่มสแกน" (Start Scan)
  3. สังเกตหน้าจอ Mobile แสดงแอนิเมชัน Loading พร้อมข้อความอธิบายสถานะการวิเคราะห์แบบเรียลไทม์
  4. Backend รับไฟล์ผ่าน `POST /api/v1/scan/` ตรวจสอบ Magic Bytes และสร้าง SHA-256 Hash
  5. AI Inference Pipeline รับงานและประมวลผล:
     - Tiling 512x512 with 64px overlap ส่งเข้า SegFormer Model
     - Surya OCR สกัดข้อความภาษาไทยและภาษาอังกฤษ
     - Qwen2.5-1.5B วิเคราะห์บริบทความน่าสงสัยและสร้างคำอธิบาย XAI
     - คำนวณความเสี่ยงด้วย Hybrid Worst-Case Formula
  6. Backend บันทึกผลลัพธ์ลง PostgreSQL และบันทึกแคชลง Redis
  7. Mobile รับ Response และเปลี่ยนเส้นทางไปยังหน้า Result Screen
- **Expected Results**:
  1. Mobile แสดง Risk Score อยู่ในช่วงความเสี่ยงถูกต้อง (Low: 0-39, Medium: 40-69, High: 70-100) ไม่พบคำว่า "Safe"
  2. Heatmap ซ้อนทับภาพต้นฉบับตรงตำแหน่งที่มีการตัดต่อ พร้อมสไลเดอร์ปรับ Opacity ได้
  3. แสดงผลคะแนนแยก 3 ปัจจัย: Text Analysis, Source Verification, Visual Anomaly
  4. แสดงบทวิเคราะห์สรุปจาก AI Explainable Text ภาษาไทยอย่างถูกต้อง
  5. ประวัติการสแกนปรากฏในหน้า History ทันที
- **Automation Mapping**: `tests_all/automate_tests/tests/e2e/test_e2e_scam_flow.py`

---

### TC-E2E-CACHE-02: กระบวนการดึงผลลัพธ์จาก Redis Cache เมื่อส่งภาพซ้ำ (Cache Hit Flow)
- **Module / Feature**: Cross-System / Redis Hash Caching
- **Requirement ID**: FR-SYS-09, NFR-PERF-01
- **Test Type**: End-to-End Performance & Integration
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มีการสแกนภาพ `voucher_sample.png` สำเร็จแล้ว 1 ครั้ง และผลลัพธ์ถูกจัดเก็บลง Redis Key ด้วย SHA-256
  2. ผู้ใช้อีกรายหนึ่ง (User B) หรือผู้ใช้เดิมเปิดแอปเพื่อทดสอบ
- **Test Data**:
  - Image: `voucher_sample.png` (ไฟล์เดิม ข้อมูลไบต์เหมือนเดิม 100%)
- **Test Steps**:
  1. ผู้ใช้ทำการอัปโหลดไฟล์ `voucher_sample.png` เข้าสู่ระบบผ่านหน้า Mobile หรือ API
  2. Backend คำนวณ SHA-256 Checksum ของไฟล์ที่รับเข้ามา
  3. Backend ตรวจสอบคีย์ใน Redis Cache
  4. ตรวจสอบว่าระบบข้ามขั้นตอนการเรียก GPU Model Inference หรือไม่
  5. ส่งผลลัพธ์เดิมกลับมายัง Client ทันที
- **Expected Results**:
  1. ค่า `cached: true` ถูกส่งกลับมาใน Response Payload
  2. เวลาในการประมวลผล (Response Time) ต้องน้อยกว่าหรือเท่ากับ 3 วินาที (E2E Latency <= 3.0s)
  3. ผลลัพธ์ Risk Score, Visual Anomaly, และ Heatmap URL ตรงกับผลการสแกนรอบแรก 100%
  4. ระบบไม่เกิดการคำนวณ GPU ซ้ำซ้อน ซึ่งช่วยลดภาระของ Inference Worker
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py::test_scan_image_cache_hit`

---

### TC-E2E-REPORT-03: การส่งรายงานข้อร้องเรียนและการตรวจสอบของแอดมิน (Report & Audit Flow)
- **Module / Feature**: Cross-System / User Report to Admin Resolution
- **Requirement ID**: FR-RPT-01, FR-ADM-02, FR-ADM-03, FR-ADM-06
- **Test Type**: End-to-End Integration
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. มีรายการประวัติการสแกน (Scan ID) ที่ผู้ใช้ต้องการรายงาน
  2. บัญชี Admin มีสิทธิ์จัดการรายงานบน Admin Portal
- **Test Data**:
  - Reason: "ภาพใบเสร็จนี้ไม่ใช่สลิปปลอม แต่ระบบตรวจว่ามีความเสี่ยงสูงผิดปกติ"
  - Report Type: `FALSE_POSITIVE`
- **Test Steps**:
  1. ผู้ใช้เปิดหน้าผลการสแกนใน Mobile App และกดปุ่ม "รายงานผลผิดพลาด" (Report)
  2. กรอกเหตุผลและกดยืนยันส่งรายงานผ่าน `POST /api/v1/reports/`
  3. เข้าสู่ Admin Portal ด้วยบัญชีแอดมิน ไปยังเมนู "Report Review"
  4. ตรวจสอบว่ารายการรายงานใหม่ปรากฏขึ้นในตาราง พร้อมสถานะ `PENDING`
  5. แอดมินกดเปิด Forensic Detail ตรวจดูภาพต้นฉบับ, Heatmap, และเหตุผลของผู้ร้องเรียน
  6. แอดมินกดปุ่ม "อนุมัติการแก้ไข" (Approve) หรือ "ปฏิเสธรายงาน" (Reject) พร้อมระบุบันทึก
  7. ระบบอัปเดตสถานะในตาราง `reports` พร้อมปรับปรุงค่า `version` (Optimistic Locking)
  8. ตรวจสอบบันทึกในหน้า "Audit Logs" ของระบบแอดมิน
- **Expected Results**:
  1. Mobile App แสดงข้อความยืนยันการส่งรายงานสำเร็จ
  2. ข้อมูลรายงานในตาราง `reports` มี `status` เปลี่ยนเป็น `RESOLVED` หรือ `REJECTED`
  3. คอลัมน์ `version` ถูกเพิ่มค่าขึ้น (+1) อย่างถูกต้องเพื่อป้องกัน Race Condition
  4. หน้า Audit Logs มีบันทึก Action `UPDATE_REPORT_STATUS` ระบุ Admin ID, Timestamp (UTC+7), และ JSON Diff ก่อนและหลังการเปลี่ยนสถานะ
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py::test_admin_report_review_flow`

---

### TC-E2E-MODEL-04: การสลับโมเดล AI ในระบบจัดการและส่งผลต่อการสแกนทันที (Model Rollout Flow)
- **Module / Feature**: Cross-System / AI Model Registry & Worker Hot-Swap
- **Requirement ID**: FR-ADM-04, NFR-PERF-03
- **Test Type**: End-to-End Integration
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. ตาราง `model_registry` มีโมเดล SegFormer อย่างน้อย 2 เวอร์ชัน (เช่น `v1.0.0` สถานะ ACTIVE และ `v1.0.1` สถานะ STAGING)
  2. แอดมินเข้าสู่ระบบ Admin Portal
- **Test Data**:
  - Target Version: `v1.0.1` (SegFormer B0 Fine-Tuned)
- **Test Steps**:
  1. เข้าหน้า "AI Model Management" บน Admin Portal
  2. เลือกเวอร์ชัน `v1.0.1` และกดปุ่ม "Dry-run Verification" เพื่อตรวจสอบความพร้อมของไฟล์ Weights และ Checksum
  3. เมื่อระบบรายงานสุขภาพผ่าน ให้กดปุ่ม "Deploy Model"
  4. Backend เรียก API `POST /api/v1/admin/models/deploy` ทำงานภายใต้ Database Row Lock (`SELECT FOR UPDATE`)
  5. ปรับสถานะ `v1.0.0` เป็น `INACTIVE` และ `v1.0.1` เป็น `ACTIVE`
  6. AI Inference Service โหลด Model Weights ของเวอร์ชันใหม่เข้าหน่วยความจำ
  7. ใช้ Mobile App ส่งสแกนภาพใหม่ 1 รายการ
- **Expected Results**:
  1. Admin Portal อัปเดตการแสดงผลเวอร์ชัน `v1.0.1` ปักหมุดเป็นโมเดล Active อันดับแรกทันที
  2. สแกนใหม่สำเร็จโดยไม่มี Downtime หรือข้อผิดพลาด 500 Internal Server Error
  3. ข้อมูลในตาราง `scans` ฟิลด์ `model_version` ต้องบันทึกเป็น `v1.0.1` อย่างถูกต้อง
  4. หากเกิดความผิดพลาดระหว่างสลับโมเดล ระบบต้อง Rollback คืนเวอร์ชันเดิมอัตโนมัติ
- **Automation Mapping**: `server/tests/api/test_admin_models.py`

---

### TC-E2E-BAN-05: การระงับผู้ใช้ที่ไม่หวังดีและการตัดสิทธิ์การใช้งานทันที (User Ban Flow)
- **Module / Feature**: Cross-System / Security & User Session Revocation
- **Requirement ID**: FR-ADM-05, NFR-SEC-03
- **Test Type**: End-to-End Security & Functional
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. มีบัญชีผู้ใช้ `abusive_user@scamguard.local` กำลังใช้งานอยู่ในระบบ Mobile
  2. ผู้ใช้มี Access Token ที่ยังไม่หมดอายุ
- **Test Data**:
  - User ID: UUID ของ `abusive_user`
  - Ban Reason: "ตรวจพบพฤติกรรมพยายามยิงคำขอโจมตีระบบเกินอัตราปกติ"
- **Test Steps**:
  1. แอดมินเปิดหน้า "User Management" บน Admin Portal และค้นหา `abusive_user@scamguard.local`
  2. กดปุ่ม "Ban User" ระบบแสดง Modal บังคับกรอกเหตุผล
  3. กรอกเหตุผลและกดยืนยัน Backend ทำการอัปเดตฟิลด์ `is_banned = true` และบันทึก `ban_reason`
  4. บน Mobile App ผู้ใช้ที่ถูกระงับพยายามกดปุ่ม "เริ่มสแกน" หรือดึงข้อมูลหน้า "ประวัติ"
  5. Dio Interceptor ของ Mobile ตรวจสอบการตอบสนอง 403 Forbidden
- **Expected Results**:
  1. Backend ปฏิเสธคำขอทันทีด้วย HTTP 403 Forbidden พร้อม Message แจ้งว่าบัญชีถูกระงับ
  2. Mobile Client ล้างค่า Token ออกจาก Secure Storage ทันที
  3. แอปนำทางผู้ใช้กลับไปยังหน้า Login พร้อม Dialog แจ้งเตือนสาเหตุการระงับบัญชี
  4. ผู้ใช้ไม่สามารถเข้าสู่ระบบซ้ำได้จนกว่าแอดมินจะทำการ Unban
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py::test_ban_user_and_token_revocation`

---

### TC-E2E-OFFLINE-06: การจัดเก็บข้อมูลออฟไลน์และการกู้คืนข้อมูลเมื่อเชื่อมต่อใหม่ (Offline Resilience)
- **Module / Feature**: Mobile / Local Persistence & Network Interruption
- **Requirement ID**: FR-HIST-03, NFR-PERF-03
- **Test Type**: End-to-End Resilience
- **Priority**: P2 (Major)
- **Pre-conditions**:
  1. ผู้ใช้ล็อกอินและเคยสแกนภาพสำเร็จมาแล้วอย่างน้อย 5 รายการ
  2. ข้อมูลประวัติถูกบันทึกลงแคชในเครื่อง (Local Storage)
- **Test Data**:
  - โหมดการเชื่อมต่อ: Airplane Mode (No Wi-Fi / No Cellular)
- **Test Steps**:
  1. เปิดใช้งานโหมดเครื่องบิน (Airplane Mode) บนอุปกรณ์สมาร์ตโฟน
  2. เปิดแอป ScamGuard และสลับไปยังแท็บ "ประวัติการสแกน" (History)
  3. ตรวจสอบการแสดงผลรายการประวัติ
  4. แตะเปิดดูรายละเอียดของรายการที่เคยสแกนไว้
  5. ปิดโหมดเครื่องบินเพื่อกู้คืนการเชื่อมต่ออินเทอร์เน็ต แล้วกด Pull-to-Refresh
- **Expected Results**:
  1. ในขณะออฟไลน์ แอปสามารถแสดงผลรายการประวัติและภาพ Thumbnail ที่แคชไว้ได้โดยไม่เกิด Crash
  2. หน้าจอแสดงแถบแจ้งเตือน "กำลังทำงานในโหมดออฟไลน์ (Offline Mode)"
  3. เมื่อเชื่อมต่ออินเทอร์เน็ตสำเร็จ แถบแจ้งเตือนหายไป และข้อมูลถูกซิงก์อัปเดตล่าสุดจาก Backend
- **Automation Mapping**: `scam_image_mobile/test/features/history/data/datasources/history_local_data_source_test.dart`
