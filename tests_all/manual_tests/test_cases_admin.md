# ชุดกรณีทดสอบ: เว็บคอนโซลผู้ดูแลระบบ (Admin Portal - React / Vite)

- **System**: ScamGuard Admin Web Portal
- **Framework**: React 18, Vite, Tailwind CSS (Dual Dark/Light Theme)
- **State & Network**: Axios with JWT Interceptors, Native WebSocket Telemetry
- **Database Entity**: Dedicated `admins` Table (RBAC Isolated from `users`)
- **Version**: 1.0.0
- **Status**: Baseline

---

## 1. หมวดหมู่การยืนยันตัวตนของผู้ดูแลระบบ (Admin Authentication)

### TC-ADM-AUTH-01: การเข้าสู่ระบบด้วยบัญชีผู้ดูแลระบบ (Admin Login Flow)
- **Module / Feature**: Admin Auth / Login
- **Requirement ID**: FR-ADM-01, NFR-SEC-03
- **Test Type**: Functional / Security
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มีข้อมูลบัญชีในตาราง `admins` (เช่น `admin@scamguard.local`)
  2. เปิดหน้าเว็บ Admin Portal ที่ `/login`
- **Test Data**:
  - Email: `admin@scamguard.local`
  - Password: รหัสผ่านของผู้ดูแลระบบ
- **Test Steps**:
  1. กรอกอีเมลและรหัสผ่านของผู้ดูแลระบบ
  2. กดปุ่ม "Sign In"
- **Expected Results**:
  1. ระบบส่งคำขอไปยัง `POST /api/v1/admin/login`
  2. ได้รับ JWT Token สำหรับ Admin
  3. จัดเก็บ Token ลงใน Secure Storage / LocalStorage (`scamguard_admin_token`)
  4. นำทางเข้าสู่หน้าแดชบอร์ดหลัก (`/admin/dashboard`) อัตโนมัติ
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

### TC-ADM-AUTH-02: การปฏิเสธบัญชีผู้ใช้ธรรมดาเมื่อพยายามล็อกอินหน้า Admin (Role Rejection)
- **Module / Feature**: Admin Auth / RBAC Separation
- **Requirement ID**: NFR-SEC-03
- **Test Type**: Security / Negative
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มีบัญชีผู้ใช้ทั่วไปจากตาราง `users` (ไม่ได้อยู่ในตาราง `admins`)
- **Test Data**:
  - Email: `normal_user@example.com`
  - Password: `Password123!`
- **Test Steps**:
  1. พยายามใช้ข้อมูลผู้ใช้ทั่วไปล็อกอินเข้าหน้า Admin Portal
- **Expected Results**:
  1. ระบบตอบกลับด้วย HTTP 401 หรือ 403
  2. หน้าจอแสดงข้อความแจ้งเตือน "บัญชีนี้ไม่มีสิทธิ์เข้าถึงระบบผู้ดูแลระบบ"
  3. ไม่สามารถเข้าถึงหน้าแดชบอร์ดหรือข้อมูลภายในได้
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

## 2. หมวดหมู่แดชบอร์ดและการตรวจสอบสถานะสด (Dashboard & Real-time Telemetry)

### TC-ADM-DASH-01: การแสดงตัวเลขตัวชี้วัดหลักบนแดชบอร์ด (KPI Cards & Charts)
- **Module / Feature**: Dashboard / KPI Cards
- **Requirement ID**: FR-ADM-01
- **Test Type**: Functional / UI
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. เข้าสู่ระบบด้วยสิทธิ์ Admin อยู่ที่หน้า Dashboard
- **Test Data**: ข้อมูลการสแกนและรายงานในฐานข้อมูลจริง
- **Test Steps**:
  1. ตรวจสอบการ์ดสรุปตัวเลข KPI ทั้ง 4 การ์ด (Total Scans, High Risk Detections, Active Users Today, Pending Reports)
  2. ตรวจสอบกราฟแนวโน้ม (Trend Charts)
- **Expected Results**:
  1. ตัวเลขแสดงผลตรงตามข้อมูลจริงในฐานข้อมูล ไม่ใช้ข้อมูล Mock
  2. ค่า `Active Users Today` คำนวณจากการสแกนและส่งรายงานจริงในวันนี้
  3. มีปุ่ม Refresh และแสดงเวลาการอัปเดตล่าสุด (Last Refresh Time)
- **Automation Mapping**: Manual Console Test

---

### TC-ADM-WS-01: การเชื่อมต่อ WebSocket เพื่อรับข้อมูล Telemetry แบบเรียลไทม์
- **Module / Feature**: Telemetry / WebSocket Connection
- **Requirement ID**: FR-ADM-01
- **Test Type**: Integration / Real-time
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. เปิดหน้าแดชบอร์ด
  2. WebSocket Endpoint `/api/v1/admin/ws/telemetry` พร้อมทำงาน
- **Test Data**: สตรีมข้อมูลสถานะระบบ
- **Test Steps**:
  1. ตรวจสอบสถานะการเชื่อมต่อ WebSocket บนหน้าจอ
  2. ตรวจสอบข้อมูลโมเดล Active Model และการใช้งานระบบ
- **Expected Results**:
  1. แดชบอร์ดแสดง Badge สถานะ "Live Connected" สีเขียว
  2. เมื่อมีการสแกนภาพเกิดขึ้น ตัวเลขเคาน์เตอร์สแกนอัปเดตทันทีโดยไม่ต้องกดรีเฟรชหน้าเว็บ
  3. หากเครือข่ายหลุด ระบบมีกลไกพยายามเชื่อมต่อใหม่ (Auto-Reconnect)
- **Automation Mapping**: Manual Verification

---

## 3. หมวดหมู่การจัดการเวอร์ชันโมเดล AI (Model Version Registry)

### TC-ADM-MOD-01: ตารางแสดงเวอร์ชันโมเดล (Active Model Must Be First)
- **Module / Feature**: Model Registry / Active Ordering
- **Requirement ID**: FR-ADM-04
- **Test Type**: Functional / UI
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. อยู่ในหน้าจัดการโมเดล (`/admin/models`)
  2. มีโมเดลในระบบหลายเวอร์ชัน (`v1.0.0` ถึง `v1.0.4`)
- **Test Data**: ตาราง `model_versions`
- **Test Steps**:
  1. ตรวจสอบลำดับการแสดงผลในตารางโมเดล
- **Expected Results**:
  1. โมเดลที่มีสถานะ `is_active = true` จะต้องถูกจัดให้อยู่ในแถวบนสุดของตารางเสมอ
  2. มี Badge สีเขียวระบุชัดเจนว่า "ACTIVE"
  3. แสดงค่า Benchmark Metrics ครบถ้วน: mIoU, aAcc, mAcc, mDice
- **Automation Mapping**: `tests_all/tests_report/automate_tests/server/admin_api.md`

---

### TC-ADM-MOD-02: การสลับใช้งานโมเดลพร้อมกล่องยืนยัน (Model Deployment Modal)
- **Module / Feature**: Model Registry / Deploy Action
- **Requirement ID**: FR-ADM-04
- **Test Type**: Integration / State Flow
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. อยู่ในหน้า `/admin/models`
- **Test Data**: เลือกโมเดลเวอร์ชันที่เป็น Inactive เพื่อ Deploy
- **Test Steps**:
  1. กดปุ่ม "Deploy" ที่แถวโมเดลเป้าหมาย
  2. ตรวจสอบ Modal ยืนยัน
  3. กดยืนยันการ Deploy
- **Expected Results**:
  1. แสดง Modal คำเตือนผลกระทบต่อระบบสแกน
  2. เมื่อกดยืนยัน Backend ทำการสลับสถานะในฐานข้อมูลแบบ Row-Level Lock
  3. ตารางรีเฟรช และโมเดลที่เลือกจะย้ายขึ้นมาอยู่อันดับแรกพร้อมป้าย ACTIVE ทันที
  4. มีการบันทึกการกระทำลงใน Audit Log
- **Automation Mapping**: `server/tests/api/test_admin_models.py`

---

## 4. หมวดหมู่การตรวจสอบข้อร้องเรียน (Report Moderation Flow)

### TC-ADM-REP-01: การอนุมัติหรือปัดตกรายงานข้อร้องเรียน (Approve / Reject Report)
- **Module / Feature**: Report Moderation / Decision Making
- **Requirement ID**: FR-ADM-02
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. มีรายการรายงานข้อร้องเรียนที่มีสถานะ `pending` ในระบบ
- **Test Data**: รายงาน ID `REP-101`
- **Test Steps**:
  1. ไปที่หน้า `/admin/reports`
  2. แตะเปิดดูรายงาน `REP-101`
  3. ตรวจสอบภาพและผลสแกนเดิม
  4. กดปุ่ม "อนุมัติว่าเป็น Scam จริง" (Approve)
- **Expected Results**:
  1. สถานะของรายงานเปลี่ยนจาก `pending` -> `approved`
  2. บันทึกข้อมูล Admin ผู้ทำการตัดสินลงในระบบ
  3. ภาพจะถูกเพิ่มเข้าไปในคิว Dataset เตรียมส่งออกสำหรับเทรนโมเดลรอบถัดไป
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

### TC-ADM-REP-02: การป้องกัน Race Condition ด้วย Optimistic Locking (`version` column)
- **Module / Feature**: Report Moderation / Concurrency Control
- **Requirement ID**: FR-ADM-03
- **Test Type**: Concurrency / Negative
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. แอดมิน A และ แอดมิน B เปิดดูรายงานฉบับเดียวกันพร้อมกัน (เวอร์ชันเดิมคือ `version = 1`)
- **Test Data**: รายงานฉบับเดียวกัน
- **Test Steps**:
  1. แอดมิน A กดปุ่ม "Approve" (ระบบอัปเดตเป็น `version = 2` สำเร็จ)
  2. แอดมิน B กดปุ่ม "Reject" ในหน้าจอเดิมที่ยังค้างไว้
- **Expected Results**:
  1. คำขอของแอดมิน B จะถูกปฏิเสธด้วย HTTP `409 Conflict`
  2. หน้าจอของแอดมิน B แจ้งเตือน: "รายงานนี้ได้รับการอัปเดตโดยผู้ดูแลระบบท่านอื่นแล้ว กรุณารีเฟรชข้อมูล"
  3. ป้องกันการเขียนทับสถานะโดยไม่ตั้งใจ
- **Automation Mapping**: `server/tests/api/test_admin_reports.py`

---

## 5. หมวดหมู่การจัดการผู้ใช้งาน (User Management)

### TC-ADM-USR-01: การระงับการใช้งานบัญชีผู้ใช้พร้อมการบังคับระบุเหตุผล (Ban User with Mandatory Reason)
- **Module / Feature**: User Management / Ban Action
- **Requirement ID**: FR-ADM-05
- **Test Type**: Functional / Security
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. อยู่ในหน้า `/admin/users` มีรายชื่อผู้ใช้แสดงในตาราง
- **Test Data**: ผู้ใช้ `spammer@example.com`
- **Test Steps**:
  1. คลิกที่ผู้ใช้ `spammer@example.com` เพื่อเปิดดูหน้ารายละเอียด
  2. กดปุ่ม "ระงับการใช้งาน" (Ban User)
  3. พยายามกดยืนยันโดยไม่กรอกเหตุผล
  4. กรอกเหตุผล "ยิงสแกนภาพสแปมเพื่อรบกวนระบบ" และกดยืนยัน
- **Expected Results**:
  1. เมื่อไม่กรอกเหตุผล ระบบไม่อนุญาตให้กดส่ง (Validation Error)
  2. เมื่อกรอกเหตุผลและกดยืนยัน ผู้ใช้ถูกเปลี่ยนสถานะเป็น `is_banned = true`
  3. บัญชีผู้ใช้นี้จะไม่สามารถล็อกอินเข้าสู่ระบบได้อีก
  4. เหตุผลการแบนถูกบันทึกลงใน Audit Log พร้อม Admin ID ผู้สั่งแบน
- **Automation Mapping**: `server/tests/api/test_admin_users.py`

---

## 6. หมวดหมู่การเข้าถึงและธีม (Accessibility & Dark/Light Theme)

### TC-ADM-UI-01: ความคมชัดของคู่สีตามมาตรฐาน WCAG 2.1 AA (Contrast Ratio >= 4.5:1)
- **Module / Feature**: Accessibility / Theme Contrast
- **Requirement ID**: NFR-A11Y-01
- **Test Type**: Visual / a11y
- **Priority**: P2 (Medium)
- **Pre-conditions**:
  1. เปิดใช้งาน Admin Portal
- **Test Data**: ตรวจสอบทั้งโหมด Light Mode และ Dark Mode
- **Test Steps**:
  1. ใช้เครื่องมือตรวจสอบสี (Lighthouse / Axe DevTools) สแกนหน้า Dashboard, Data Tables และ Badges
- **Expected Results**:
  1. อัตราส่วนความเปรียบต่างของสี (Contrast Ratio) ของข้อความปกติกับพื้นหลังมีค่า >= 4.5:1 ทุกจุด
  2. สีของสถานะ (เขียว, เหลือง, แดง, น้ำเงิน) อ่านง่ายและมีความชัดเจนทั้งในโหมดสว่างและโหมดมืด
  3. ผ่านเกณฑ์การตรวจประเมิน Accessibility ตามมาตรฐาน WCAG 2.1 Level AA
- **Automation Mapping**: Lighthouse Automated Audit
