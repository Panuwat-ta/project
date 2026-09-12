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
| `TC-E2E-REPORT-03` | User Incident Reporting to Admin Review | Mobile (User) | FastAPI, PostgreSQL (`scam_reports` table) | Admin Forensic Console | P1 (Critical) |
| `TC-E2E-MODEL-04` | AI Model Deployment to Live Inference | Admin Portal | FastAPI, Model Versions, AI Worker | Mobile Scan Engine | P1 (Critical) |
| `TC-E2E-BAN-05` | Malicious Actor Ban and Session Revocation | Admin Portal | FastAPI, DB Users, Mobile Dio Interceptor | Mobile Client Screen | P1 (Critical) |
| `TC-E2E-OFFLINE-06` | Offline Storage and Reconnection Sync | Mobile Client | Local Cache (History/Result Local DataSource) | FastAPI Backend | P2 (Major) |
| `TC-E2E-FULL-07` | Full Lifecycle Register to Audit Verification | Mobile (Flutter) | FastAPI, PostgreSQL (`scans`, `scam_reports`, `audit_log`), Admin Portal | Audit Logs Screen | P1 (Critical) |
| `TC-E2E-AUTH-08` | Mid Journey Access Expiry With Refresh Resume | Mobile (Flutter) | FastAPI, Dio AuthInterceptor, Secure Storage | Mobile History and Scan Screen | P1 (Critical) |
| `TC-E2E-REG-09` | Post Deploy Scan Regression Stability | Admin Portal | FastAPI, Model Versions, AI Worker | Mobile Scan Engine | P1 (Critical) |
| `TC-E2E-HIST-10` | History Delete Then Detail Not Found | Mobile (Flutter) | FastAPI, PostgreSQL (`scans`), Local Uploads | Mobile History Screen | P2 (Major) |

---

## 2. รายละเอียดกรณีทดสอบ E2E (Detailed Test Cases)

### TC-E2E-SCAN-01: การตรวจสอบภาพต้องสงสัยแบบครบวงจร (Full Detection Workflow)
- **Module / Feature**: Cross-System / End-to-End Scan Journey
- **Requirement ID**: FR-INPUT-01, FR-INPUT-03, FR-INPUT-05, FR-SYS-01, FR-SYS-02, FR-SYS-03, FR-SYS-05, FR-SYS-07, FR-SYS-08, FR-SYS-09, FR-SYS-11, FR-REPORT-01, FR-REPORT-02, FR-REPORT-03, FR-REPORT-04, FR-REPORT-05, FR-HIST-01, NFR-PERF-02
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
  2. กดปุ่ม "เริ่มสแกน" (Start Scan)
  3. สังเกตหน้าจอ Mobile เปลี่ยน State จาก `ScanInitial` เป็น `ScanUploading` แล้วเป็น `ScanPolling`
  4. Backend รับไฟล์ผ่าน `POST /api/v1/scan/` ตรวจสอบ Magic Bytes และสร้าง SHA-256 Hash
  5. AI Inference Pipeline รับงานและประมวลผล:
     - Tiling 512x512 with 64px overlap ส่งเข้า SegFormer Model
     - Surya OCR สกัดข้อความภาษาไทยและภาษาอังกฤษ
     - Qwen2.5-1.5B วิเคราะห์บริบทความน่าสงสัยและสร้างคำอธิบาย XAI
     - คำนวณความเสี่ยงด้วย Hybrid Worst-Case Formula
  6. Backend บันทึกผลลัพธ์ลง PostgreSQL และบันทึกแคชลง Redis
  7. Mobile รับ Response และเปลี่ยนเส้นทางไปยังหน้า Result Screen
- **Expected Results**:
  1. Mobile แสดง Risk Score พร้อมระดับตัวพิมพ์เล็กถูกต้อง (low: 0-39, medium: 40-69, high: 70-100) ไม่พบคำว่าระดับ Safe
  2. Heatmap ซ้อนทับภาพต้นฉบับตรงตำแหน่งที่มีการตัดต่อ พร้อมสไลเดอร์ปรับ Opacity ได้
  3. แสดงผลคะแนนแยก 3 ปัจจัย: Text Analysis, Source Verification, Visual Anomaly
  4. แสดงบทวิเคราะห์สรุปจาก Qwen2.5 ภาษาไทยสอดคล้องกับข้อความ Surya OCR และพิกัด Heatmap
  5. ประวัติการสแกนปรากฏในหน้า History ทันที
  6. เวลาประมวลผลภาพใหม่เต็มรูปแบบ (Cache Miss, ภาพ 1920x1080) P50 ≤ 15 วินาที และ P95 ≤ 25 วินาที ตรงตาม NFR-PERF-02 (วัดแบบ End-to-End ตั้งแต่กดสแกนถึงหน้า Result)
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
  - Endpoint: `POST /api/v1/scan/` พร้อมภาพที่มี SHA-256 ซ้ำกับในแคช
- **Test Steps**:
  1. ผู้ใช้ทำการอัปโหลดไฟล์ `voucher_sample.png` ผ่าน `POST /api/v1/scan/` (หน้า Mobile หรือ API Client)
  2. Backend คำนวณ SHA-256 Checksum ของไฟล์ที่รับเข้ามา
  3. Backend ตรวจสอบคีย์ใน Redis Cache
  4. ตรวจสอบว่าระบบข้ามขั้นตอนการเรียก GPU Model Inference หรือไม่
  5. ส่งผลลัพธ์เดิมกลับมายัง Client ทันที
- **Expected Results**:
  1. ระบบคืนผลลัพธ์เดิมโดยไม่เรียก GPU Model Inference ซ้ำ
  2. เวลาในการประมวลผล (Response Time) P95 ต้องน้อยกว่าหรือเท่ากับ 3 วินาทีแบบ End-to-End (P95 ≤ 3.0s ตรงตาม NFR-PERF-01; ภาพ 1MB, RTT ≤50ms)
  3. ผลลัพธ์ Risk Score, Visual Anomaly, และ Heatmap URL ตรงกับผลการสแกนรอบแรก 100%
  4. ระบบไม่เกิดการคำนวณ GPU ซ้ำซ้อน ซึ่งช่วยลดภาระของ Inference Worker
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_scan_workflow.py`

---

### TC-E2E-REPORT-03: การส่งรายงานข้อร้องเรียนและการตรวจสอบของแอดมิน (Report & Audit Flow)
- **Module / Feature**: Cross-System / User Report to Admin Resolution
- **Requirement ID**: FR-RPT-01, FR-ADM-02, FR-ADM-06
- **Test Type**: End-to-End Integration
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. มีรายการประวัติการสแกน (Scan ID) ที่ผู้ใช้ต้องการรายงาน
  2. บัญชี Admin มีสิทธิ์จัดการรายงานบน Admin Portal
- **Test Data**:
  - scan_id ของผลสแกนที่ต้องการรายงาน
  - category: `fake_slip`
  - description: "ภาพใบเสร็จนี้ระบบตรวจว่ามีความเสี่ยงสูงผิดปกติ ขอให้ตรวจสอบซ้ำ" (ยาวไม่ต่ำกว่า 10 ตัวอักษร)
- **Test Steps**:
  1. ผู้ใช้เปิดหน้าผลการสแกนใน Mobile App และกดปุ่ม "รายงานผลผิดพลาด" (Report)
  2. กรอกเหตุผลและกดยืนยันส่งรายงานผ่าน `POST /api/v1/reports`
  3. เข้าสู่ Admin Portal ด้วยบัญชีแอดมิน ไปยังเมนู "Report Review"
  4. ตรวจสอบว่ารายการรายงานใหม่ปรากฏขึ้นในตาราง พร้อมสถานะ `pending`
  5. แอดมินกดเปิด Forensic Detail ด้วย `GET /api/v1/admin/reports/{report_id}` ตรวจดูภาพต้นฉบับ, Heatmap, และเหตุผลของผู้ร้องเรียน
  6. แอดมินเริ่มตรวจด้วย `POST /api/v1/admin/reports/{report_id}/review` พร้อม `version` แล้วตัดสินด้วย `PATCH /api/v1/admin/reports/{report_id}` พร้อม `status` และ `version` (แนบ `admin_note` ทุกครั้งเมื่อตัดสินเป็น `rejected` หรือส่งกลับเป็น `pending`)
  7. ระบบอัปเดตสถานะในตาราง `scam_reports` พร้อมปรับปรุงค่า `version` (Optimistic Locking)
  8. ตรวจสอบบันทึกในหน้า "Audit Logs" ผ่าน `GET /api/v1/admin/audit-logs`
- **Expected Results**:
  1. Mobile App แสดงข้อความยืนยันการส่งรายงานสำเร็จ
  2. ข้อมูลรายงานในตาราง `scam_reports` มี `status` เปลี่ยนเป็น `approved` หรือ `rejected` (จาก `pending` ผ่าน `reviewing` ตัวพิมพ์เล็กเท่านั้น)
  3. คอลัมน์ `version` ถูกเพิ่มค่าขึ้น (+1) อย่างถูกต้องเพื่อป้องกัน Race Condition
  4. หน้า Audit Logs มีบันทึก Action ระบุ Admin ID, Timestamp (UTC+7), และ JSON Diff ก่อนและหลังการเปลี่ยนสถานะ
  5. รายงานที่ผูกกับภาพคะแนนสูง (70-100 ระดับ high) แสดงคะแนนและระดับความเสี่ยงของภาพต้นฉบับในหน้ารายละเอียดเพื่อให้แอดมินจัดลำดับความสำคัญได้
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_history.py`

---

### TC-E2E-MODEL-04: การสลับโมเดล AI ในระบบจัดการและส่งผลต่อการสแกนทันที (Model Rollout Flow)
- **Module / Feature**: Cross-System / AI Model Registry & Worker Hot-Swap
- **Requirement ID**: FR-ADM-04, NFR-PERF-03
- **Test Type**: End-to-End Integration
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. ตาราง `model_versions` มีโมเดล SegFormer อย่างน้อย 2 เวอร์ชัน (เช่น `v1.0.0` สถานะ `active` และ `v1.0.1` สถานะ `inactive`)
  2. แอดมินเข้าสู่ระบบ Admin Portal
- **Test Data**:
  - Target Version: `v1.0.1` (SegFormer B0 Fine-Tuned)
  - model_id (int) ของเวอร์ชันเป้าหมาย
- **Test Steps**:
  1. เข้าหน้า "AI Model Management" บน Admin Portal
  2. เลือกเวอร์ชัน `v1.0.1` และกดปุ่ม Dry-run ผ่าน `POST /api/v1/admin/models/{model_id}/dry-run` เพื่อตรวจสอบความพร้อมของไฟล์ Weights และ Checksum
  3. เมื่อระบบรายงานสุขภาพผ่าน ให้กดปุ่ม "Deploy Model" ผ่าน `POST /api/v1/admin/models/{model_id}/deploy` พร้อม `reason`
  4. Backend ทำงานภายใต้ Database Transaction แบบ Atomic
  5. ปรับสถานะ `v1.0.0` เป็น `inactive` และ `v1.0.1` เป็น `active`
  6. AI Inference Service โหลด Model Weights ของเวอร์ชันใหม่เข้าหน่วยความจำ
  7. ใช้ Mobile App ส่งสแกนภาพใหม่ 1 รายการ
- **Expected Results**:
  1. Admin Portal อัปเดตการแสดงผลเวอร์ชัน `v1.0.1` ปักหมุดเป็นโมเดล Active อันดับแรกทันที
  2. สแกนใหม่สำเร็จโดยไม่มี Downtime หรือข้อผิดพลาด 500 Internal Server Error
  3. ตรวจสอบ Active Model ผ่าน Admin API ว่าเป็น `v1.0.1` อย่างถูกต้อง
  4. หากเกิดความผิดพลาดระหว่างสลับโมเดล (เช่น ไฟล์ Weights ไม่อยู่) การ Deploy ต้องไม่สำเร็จ และตรวจสอบว่าเวอร์ชันเดิมยังคงสถานะ Active อยู่
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py` (partial: ตรวจสิทธิ์เข้าถึง) + Manual Console Test

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
  - User ID (int) ของ `abusive_user`
  - Ban Reason: "ตรวจพบพฤติกรรมพยายามยิงคำขอโจมตีระบบเกินอัตราปกติ"
- **Test Steps**:
  1. แอดมินเปิดหน้า "User Management" บน Admin Portal และค้นหา `abusive_user@scamguard.local` ด้วย `GET /api/v1/admin/users?search=`
  2. กดปุ่ม "Ban User" ระบบแสดง Modal บังคับกรอกเหตุผล
  3. กรอกเหตุผลและกดยืนยันด้วย `PATCH /api/v1/admin/users/{user_id}` พร้อม `is_active` เป็น `false` และ `reason` Backend บันทึกประวัติลง `audit_log`
  4. บน Mobile App ผู้ใช้ที่ถูกระงับพยายามกดปุ่ม "เริ่มสแกน" หรือดึงข้อมูลหน้า "ประวัติ"
  5. ตรวจสอบว่า Dio Interceptor ส่งต่อ 403 ให้ชั้น BLoC แสดงข้อความผิดพลาด (ปัจจุบันไม่มีการล้าง Token อัตโนมัติสำหรับ 403 ซึ่งเป็น GAP ตามผลข้อ 2)
- **Expected Results**:
  1. Backend ปฏิเสธคำขอทันทีด้วย HTTP 403 Forbidden พร้อม Message แจ้งว่าบัญชีถูกระงับ
2. สถานะนี้เป็น GAP ฝั่ง Client: `AuthInterceptor` ใน `dio_client.dart` จัดการเฉพาะ `401` (ต่ออายุ Token อัตโนมัติหรือล้าง Token เมื่อต่ออายุไม่สำเร็จ) ไม่มีการล้าง Token หรือนำทางกลับหน้า Login อัตโนมัติเมื่อได้ `403` บัญชีถูกระงับ ผู้ใช้จะเห็นเพียงข้อความผิดพลาด (เช่น `ReportBloc` แสดง `เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่`) จนกว่าจะออกจากระบบเองหรือ Token หมดอายุ
3. การออกจากระบบเองเรียก `POST /api/v1/auth/logout` แล้วล้าง Token ผ่าน `clearTokens()` (`deleteAll()`) และ `AuthBloc` เปลี่ยนเป็น `AuthUnauthenticated` จึงกลับหน้า Login (โค้ดจริงไม่มี Dialog แจ้งสาเหตุการระงับบัญชีโดยเฉพาะ)
  4. ผู้ใช้ไม่สามารถเข้าสู่ระบบซ้ำได้จนกว่าแอดมินจะเปิดใช้งานใหม่
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py` (partial: ตรวจสิทธิ์เข้าถึง) + Manual Console Test + Manual Device Test

---

### TC-E2E-OFFLINE-06: การจัดเก็บข้อมูลออฟไลน์และการกู้คืนข้อมูลเมื่อเชื่อมต่อใหม่ (Offline Resilience)
- **Module / Feature**: Mobile / Local Persistence & Network Interruption
- **Requirement ID**: NFR-PERF-03 (Offline, เดิม FR-HIST-03)
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
  2. สถานะนี้เป็น GAP ส่วนย่อยฝั่งหน้าจอ: ไม่พบแถบแจ้งเตือนโหมดออฟไลน์ในโค้ดปัจจุบัน (มีแคชประวัติใน `history_repository_impl` และแคชผลวิเคราะห์ใน `result_repository_impl` สำหรับดูออฟไลน์ แต่ไม่มีวิดเจ็ตแบนเนอร์แจ้งสถานะ) การยืนยันทำได้เพียงว่าไม่มี Crash และข้อมูลแคชยังเปิดดูได้
  3. เมื่อเชื่อมต่ออินเทอร์เน็ตสำเร็จ แถบแจ้งเตือนหายไป และข้อมูลถูกซิงก์อัปเดตล่าสุดจาก Backend
- **Automation Mapping**: `scam_image_mobile/test/features/history/presentation/bloc/history_bloc_test.dart`

---

### TC-E2E-FULL-07: การเดินทางครบวงจรตั้งแต่สมัครจนถึงตรวจสอบบันทึกย้อนหลัง (Full Lifecycle Register to Audit)
- **Module / Feature**: Cross-System / Register Scan History Report Admin Audit Journey
- **Requirement ID**: FR-AUTH-01, FR-INPUT-03, FR-HIST-01, FR-RPT-01, FR-ADM-02, FR-ADM-06
- **Test Type**: End-to-End Integration
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. Backend FastAPI PostgreSQL และ Redis พร้อมใช้งาน
  2. มีบัญชีแอดมินที่มีสิทธิ์ Super Admin สำหรับตัดสินรายงาน
  3. เตรียมภาพทดสอบที่ไม่เคยสแกนมาก่อน 1 ไฟล์
- **Test Data**:
  - อีเมลสมัครใหม่ 1 บัญชี พร้อมรหัสผ่าน ชื่อผู้ใช้ ค่า `system_consent` และ `research_consent`
  - ภาพ `slip_e2e_full.jpg` ขนาดไม่เกิน 20 MB พร้อมหัวข้อภาษาไทย
  - หมวดรายงาน `fake_slip` พร้อมคำอธิบายยาวไม่ต่ำกว่า 10 ตัวอักษร
  - เหตุผลการ Deploy โมเดลไม่ใช้ในเคสนี้ ใช้เพียงการตัดสินรายงานด้วยสถานะ `approved` หรือ `rejected` และเลข `version`
- **Test Steps**:
  1. สมัครสมาชิกด้วย `POST /api/v1/auth/register` แล้วเข้าสู่ระบบด้วย `POST /api/v1/auth/login` ผ่านฟอร์ม `username` และ `password`
  2. อัปโหลดภาพด้วย `POST /api/v1/scan/` ผ่านฟิลด์ `file` พร้อมหัวข้อ แล้วรอจนสถานะเป็น `completed` ผ่าน `GET /api/v1/scan/{scan_id}`
  3. เปิดรายการประวัติด้วย `GET /api/v1/history?page=1&limit=20` แล้วยืนยันว่ารายการใหม่ปรากฏพร้อม `scan_id` `risk_score` `risk_level` ตัวพิมพ์เล็ก `status` `created_at` `title`
  4. ส่งรายงานด้วย `POST /api/v1/reports` ระบุ `scan_id` `category` และ `description`
  5. เข้าสู่ Admin Portal ด้วยบัญชีแอดมิน เปิดรายละเอียดด้วย `GET /api/v1/admin/reports/{report_id}` แล้วรับเรื่องด้วย `POST /api/v1/admin/reports/{report_id}/review` พร้อม `version`
  6. ตัดสินด้วย `PATCH /api/v1/admin/reports/{report_id}` พร้อม `status` และ `version` โดยแนบ `admin_note` ทุกครั้งเมื่อตัดสินเป็น `rejected` หรือส่งกลับเป็น `pending`
  7. ตรวจสอบบันทึกด้วย `GET /api/v1/admin/audit-logs` พร้อมตัวกรอง `action` และ `entity_type`
- **Expected Results**:
  1. สมัครสำเร็จได้ `201 Created` ล็อกอินสำเร็จได้ Token ครบทั้ง `access_token` `refresh_token` `token_type` และ `user`
  2. สแกนสำเร็จ สถานะเป็น `completed` ระดับความเสี่ยงเป็นตัวพิมพ์เล็ก `low` หรือ `medium` หรือ `high` ตรงกับช่วงคะแนน 0-39 40-69 70-100
  3. ประวัติแสดงรายการใหม่และมีบันทึกความยินยอมในตาราง `consent_logs`
  4. รายงานใหม่มีสถานะเริ่มต้น `pending` ตัวพิมพ์เล็ก ตัดสินแล้วสถานะเปลี่ยนเป็น `reviewing` แล้วเป็น `approved` หรือ `rejected` พร้อมเลข `version` เพิ่มขึ้น
  5. ตาราง `audit_log` เอกพจน์มีรายการเปลี่ยนสถานะพร้อมผลต่าง `status` และ `version` ก่อนหลังครบถ้วน
- **Automation Mapping**: `tests_all/automate_tests/tests/e2e/test_e2e_scam_flow.py` + `tests_all/automate_tests/tests/api/test_history.py`

---

### TC-E2E-AUTH-08: การหมดอายุกลางการเดินทางแล้วต่ออายุเพื่อทำต่อโดยไม่ล็อกอินใหม่ (Mid Journey Refresh Resume)
- **Module / Feature**: Cross-System / Token Expiry During Journey With Auto Refresh
- **Requirement ID**: FR-AUTH-04, FR-HIST-01, FR-INPUT-03, NFR-SEC-02
- **Test Type**: End-to-End Integration and Security
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. ผู้ใช้ล็อกอินค้างไว้ มี Access Token และ Refresh Token ที่ถูกต้อง
  2. แอป Mobile เก็บ Token ใน Secure Storage และเปิดใช้งานตัวดักจับการยืนยันตัวตนที่ลองใหม่หลังต่ออายุ
  3. มีภาพทดสอบ 1 ไฟล์สำหรับสแกนต่อเนื่อง
- **Test Data**:
  - Access Token ที่ปล่อยให้หมดอายุระหว่างรอผล
  - Refresh Token ที่ยังไม่หมดอายุสำหรับเรียก `POST /api/v1/auth/refresh` พร้อมฟิลด์ `refresh_token`
  - เส้นทางที่เรียกต่อเนื่องคือ `GET /api/v1/scan/{scan_id}` และ `GET /api/v1/history`
- **Test Steps**:
  1. เริ่มสแกนด้วย `POST /api/v1/scan/` ขณะ Access Token ยังใช้งานได้ แล้วจดค่า `scan_id`
  2. รอให้ Access Token หมดอายุระหว่างการรอผล แล้วเรียก `GET /api/v1/scan/{scan_id}` หรือ `GET /api/v1/history` ซ้ำ
  3. สังเกตว่าแอปรับ `401 Unauthorized` แล้วเรียก `POST /api/v1/auth/refresh` อัตโนมัติโดยไม่ขอรหัสผ่านใหม่
  4. สังเกตการลองคำขอเดิมซ้ำหลังได้ Token ชุดใหม่
  5. ทำงานต่อจนดูผลสแกนและเปิดประวัติได้ครบ
- **Expected Results**:
  1. คำขอแรกหลังหมดอายุตอบ `401 Unauthorized` พร้อม `{"detail": "Could not validate credentials"}`
  2. การต่ออายุด้วย Refresh Token ที่ถูกต้องตอบ `200 OK` พร้อม `access_token` ใหม่โดยไม่ต้องกรอกรหัสผ่านซ้ำ
  3. คำขอเดิมถูกลองใหม่สำเร็จโดยผู้ใช้ไม่ต้องล็อกอินใหม่และไม่เสีย `scan_id` ระหว่างทาง
  4. หาก Refresh Token หมดอายุด้วย แอปล้าง Token ใน Secure Storage แล้วนำทางกลับหน้า Login พร้อมแจ้งให้ล็อกอินใหม่
  5. ไม่มีการใช้ Token ที่หมดอายุเข้าถึงข้อมูลสำเร็จแม้แต่ครั้งเดียว
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py` + Manual Device Test

---

### TC-E2E-REG-09: การสแกนซ้ำหลังขึ้นโมเดลใหม่แล้วผลยังคงรูปเดิม (Post Deploy Regression Stability)
- **Module / Feature**: Cross-System / Model Deploy Regression Guard
- **Requirement ID**: FR-ADM-04, FR-INPUT-03, NFR-PERF-03
- **Test Type**: End-to-End Regression
- **Priority**: P1 (Critical)
- **Pre-conditions**:
  1. ตาราง `model_versions` มีเวอร์ชัน `v1.0.0` สถานะ `active` และ `v1.0.1` สถานะ `inactive`
  2. แอดมินเข้าสู่ระบบด้วยสิทธิ์ Super Admin
  3. เตรียมภาพอ้างอิง 1 ไฟล์ที่ไม่เปลี่ยนไบต์ตลอดการทดสอบ
- **Test Data**:
  - รหัสโมเดลเป้าหมายชนิดตัวเลข พร้อมเหตุผลการ Deploy
  - ภาพอ้างอิง `slip_regression_ref.jpg` 1 ไฟล์
  - เกณฑ์เปรียบเทียบคือโครงสร้างผลลัพธ์ ไม่ใช่คะแนนต้องตรงทศนิยมทุกจุด
- **Test Steps**:
  1. สแกนภาพอ้างอิงก่อน Deploy ด้วย `POST /api/v1/scan/` แล้วรอจน `completed` บันทึก `risk_grade` `status` และชุดฟิลด์หลักไว้
  2. ตรวจสอบความพร้อมด้วย `POST /api/v1/admin/models/{model_id}/dry-run`
  3. ขึ้นโมเดลด้วย `POST /api/v1/admin/models/{model_id}/deploy` พร้อม `reason`
  4. ยืนยันโมเดลปัจจุบันด้วย `GET /api/v1/admin/models` ว่าเวอร์ชันเป้าหมายเป็น `is_active` จริง
  5. สแกนภาพอ้างอิงไฟล์เดิมซ้ำด้วย `POST /api/v1/scan/` แล้วรอจน `completed`
  6. เปรียบเทียบโครงสร้างผลรอบก่อนและหลัง Deploy
- **Expected Results**:
  1. Deploy สำเร็จโดยไม่มีข้อผิดพลาด `500 Internal Server Error` และไม่มีช่วงหยุดให้บริการ
  2. สแกนหลัง Deploy สำเร็จ สถานะเป็น `completed` มีฟิลด์ `id` `image_hash` `text_score` `visual_score` `source_score` `total_risk_score` `risk_grade` `status` `progress` ครบเหมือนเดิม
  3. ระดับความเสี่ยงยังเป็นตัวพิมพ์เล็ก `low` `medium` หรือ `high` และอยู่ในช่วงคะแนนเดิม ไม่พบค่าหลุดช่วง 0-100
  4. มีบันทึกการ Deploy ในตาราง `audit_log` เอกพจน์พร้อมเหตุผล
  5. หากไฟล์ Weights ไม่พร้อม การ Deploy ต้องไม่สำเร็จและเวอร์ชันเดิมยังเป็น Active อยู่
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py` + Manual Console Test + Manual Device Test

---

### TC-E2E-HIST-10: การลบประวัติแล้วเรียกดูซ้ำต้องไม่พบข้อมูล (History Delete Then Not Found)
- **Module / Feature**: Cross-System / History Delete Consistency Across Mobile Backend Storage
- **Requirement ID**: FR-HIST-02, FR-HIST-03, NFR-PDPA-02
- **Test Type**: End-to-End Integration and Database
- **Priority**: P2 (Major)
- **Pre-conditions**:
  1. ผู้ใช้ล็อกอินและมีประวัติการสแกนที่เป็นของตนเองอย่างน้อย 1 รายการ
  2. ทราบค่า `scan_id` รูปแบบ UUID ของรายการที่จะลบ
  3. เปิดหน้าประวัติบน Mobile เพื่อยืนยันภาพรวมก่อนลบ
- **Test Data**:
  - `scan_id` เป้าหมายที่เป็นของผู้ใช้เอง
  - เส้นทาง `GET /api/v1/history/{scan_id}` และ `DELETE /api/v1/history/{scan_id}` และ `GET /api/v1/history?page=1&limit=20`
- **Test Steps**:
  1. เปิดรายละเอียดด้วย `GET /api/v1/history/{scan_id}` เพื่อยืนยันว่าเป็นของตนเอง
  2. ลบด้วย `DELETE /api/v1/history/{scan_id}` จาก Mobile หรือ API Client
  3. รีเฟรชรายการด้วย `GET /api/v1/history?page=1&limit=20` แล้วค้นหา `scan_id` เดิม
  4. เรียกดูรายการเดิมซ้ำด้วย `GET /api/v1/history/{scan_id}`
  5. ตรวจสอบไฟล์ภาพต้นฉบับและ Heatmap ในที่เก็บไฟล์ตามเงื่อนไขการใช้ `image_hash` ร่วมกัน
- **Expected Results**:
  1. การดูครั้งแรกตอบ `200 OK` พร้อมข้อมูลตรงกับเจ้าของงาน
  2. การลบสำเร็จและรายการหายจากหน้าประวัติบน Mobile หลังรีเฟรช
  3. การดูซ้ำตอบ `404 Not Found` พร้อม `{"detail": "Scan not found"}`
  4. แถวในตาราง `scans` ถูกลบจริง และไฟล์ภาพถูกลบเมื่อไม่มีงานอื่นใช้ `image_hash` เดียวกัน หากมีงานอื่นใช้ร่วม ไฟล์ต้องคงอยู่เพื่อไม่กระทบงานอื่น
  5. บันทึกในตาราง `audit_log` ยังคงอยู่เพื่อการตรวจสอบย้อนหลัง
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_history.py` + Manual Device Test
