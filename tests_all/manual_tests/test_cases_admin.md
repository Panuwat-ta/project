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
  2. กดปุ่ม "เข้าสู่ระบบตรวจสอบ"
- **Expected Results**:
  1. ระบบส่งคำขอไปยัง `POST /api/v1/admin/login`
  2. ได้รับ JWT Token สำหรับ Admin
  3. จัดเก็บ Access Token ไว้ในหน่วยความจำของเบราว์เซอร์ และจัดเก็บข้อมูลผู้ใช้ลงใน LocalStorage พร้อมคุกกี้รีเฟรชแบบ HttpOnly
  4. นำทางเข้าสู่หน้าแดชบอร์ดหลัก (`/admin/dashboard`) อัตโนมัติ
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

### TC-ADM-AUTH-02: การปฏิเสธบัญชีผู้ใช้ธรรมดาเมื่อพยายามล็อกอินหน้า Admin (Role Rejection)
- **Module / Feature**: Admin Auth / RBAC Separation
- **Requirement ID**: NFR-SEC-03
- **Test Type**: Security
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
- **Automation Mapping**: `server/tests/api/test_admin_auth.py`

---

### TC-ADM-AUTH-03: การต่ออายุและเพิกถอน Session ของ Admin พร้อมการจำกัดอัตรา (Refresh Logout Sessions Rate Limit)
- **Module / Feature**: Admin Auth / Session Lifecycle
- **Requirement ID**: FR-ADM-01
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ล็อกอิน Admin สำเร็จมี Session ปัจจุบัน
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `POST /api/v1/admin/refresh` (จำกัด 5 ครั้งต่อนาที)
  - Endpoint: `POST /api/v1/admin/logout`
  - Endpoint: `GET /api/v1/admin/me` และ `GET /api/v1/admin/sessions`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เรียก `GET /api/v1/admin/me` เพื่อยืนยันโปรไฟล์
  2. เรียก `GET /api/v1/admin/sessions` เพื่อดูรายการ Session
  3. เรียก `POST /api/v1/admin/refresh` เพื่อต่ออายุ Token
  4. ยิง `POST /api/v1/admin/login` เกิน 5 ครั้งใน 1 นาทีเพื่อทดสอบ Rate Limit
  5. เรียก `POST /api/v1/admin/logout` เพื่อออกจากระบบ
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. `GET /me` และ `GET /sessions` ตอบ `200 OK` พร้อมข้อมูลถูกต้อง
  2. `POST /refresh` สำเร็จได้ Token ชุดใหม่แบบหมุนเวียน Session
  3. คำขอเกิน 5 ครั้งต่อนาทีตอบ `429 Too Many Requests`
  4. `POST /logout` เพิกถอน Session ปัจจุบันและ Refresh ต่อไม่ได้
- **Automation Mapping**: `server/tests/api/test_admin_auth.py`

---

### TC-ADM-AUTH-04: การบังคับสิทธิ์ Super Admin ทุก Endpoint ภายใต้ /admin (Super Admin Enforcement)
- **Module / Feature**: Admin Auth / Authorization Guard
- **Requirement ID**: NFR-SEC-03
- **Test Type**: Security
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มีโทเคนของบัญชีที่ไม่ได้เป็น Super Admin
- **Test Data**:
  - Endpoint: `GET /api/v1/admin/dashboard`
  - Endpoint: `GET /api/v1/admin/users`
- **Test Steps**:
  1. เรียก Endpoint ภายใต้ `/admin/*` ด้วยโทเคนที่ไม่มีสิทธิ์ Super Admin
  2. เรียกซ้ำโดยไม่แนบโทเคนเลย
- **Expected Results**:
  1. โทเคนที่ไม่ได้เป็น Super Admin ถูกปฏิเสธด้วย HTTP `403 Forbidden`
  2. คำขอที่ไม่มีโทเคนถูกปฏิเสธด้วย HTTP `401 Unauthorized`
  3. ไม่มีการเปิดเผยข้อมูลภายในระบบในกรณีที่ถูกปฏิเสธ
- **Automation Mapping**: `server/tests/api/test_admin_auth.py`

---

## 2. หมวดหมู่แดชบอร์ดและการตรวจสอบสถานะสด (Dashboard & Real-time Telemetry)

### TC-ADM-DASH-01: การแสดงตัวเลขตัวชี้วัดหลักบนแดชบอร์ด (KPI Cards & Charts)
- **Module / Feature**: Dashboard / KPI Cards
- **Requirement ID**: FR-ADM-01
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. เข้าสู่ระบบด้วยสิทธิ์ Admin อยู่ที่หน้า Dashboard
- **Test Data**: ข้อมูลการสแกนและรายงานในฐานข้อมูลจริง
- **Test Steps**:
  1. เรียก `GET /api/v1/admin/dashboard` และตรวจสอบการ์ด KPI ทั้ง 4 การ์ด (Total Scans, High Risk Detections, Active Users Today, Pending Reports)
  2. ตรวจสอบกราฟแนวโน้ม (Trend Charts)
- **Expected Results**:
  1. ตัวเลขแสดงผลตรงตามข้อมูลจริงในฐานข้อมูล ไม่ใช้ข้อมูล Mock
  2. ค่า `Active Users Today` คำนวณจากการสแกนและส่งรายงานจริงในวันนี้
  3. มีปุ่ม Refresh และแสดงเวลาการอัปเดตล่าสุด (Last Refresh Time)
- **Automation Mapping**: Manual Verification

---

### TC-ADM-DASH-02: การตรวจสุขภาพระบบและการค้นหาข้ามระบบ (Health Plus Search)
- **Module / Feature**: Dashboard / Health and Search
- **Requirement ID**: FR-ADM-01
- **Test Type**: Functional
- **Priority**: P2 (Medium)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ล็อกอินด้วยสิทธิ์ Admin
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `GET /api/v1/admin/health`
  - Endpoint: `GET /api/v1/admin/search?q=slip`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เรียกดูสถานะสุขภาพระบบ
  2. ค้นหาด้วยคำค้นแล้วตรวจสอบผลลัพธ์
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. `GET /health` ตอบ `200 OK` พร้อมสถานะฐานข้อมูล พื้นที่จัดเก็บ โมเดล และคิวงาน
  2. `GET /search` ตอบ `200 OK` พร้อมผลลัพธ์ที่ตรงกับคำค้น
  3. ผู้ใช้ทั่วไปเรียกแล้วได้ `403 Forbidden`
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

### TC-ADM-WS-01: การเชื่อมต่อ WebSocket เพื่อรับข้อมูล Telemetry แบบเรียลไทม์
- **Module / Feature**: Telemetry / WebSocket Connection
- **Requirement ID**: FR-ADM-01
- **Test Type**: Integration
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. เปิดหน้าแดชบอร์ด
  2. WebSocket Endpoint `/api/v1/ws/admin/dashboard?token=<admin_access_token>` พร้อมทำงาน
- **Test Data**: สตรีมข้อมูลสถานะระบบพร้อม Token ของ Admin ใน Query Param
- **Test Steps**:
  1. เชื่อมต่อ WebSocket พร้อม Token ของ Admin
  2. ตรวจสอบข้อมูลโมเดล Active Model และการใช้งานระบบ
  3. ทดสอบเชื่อมต่อด้วย Token ผู้ใช้ทั่วไปหรือ Token ไม่ถูกต้อง
- **Expected Results**:
  1. เชื่อมต่อสำเร็จได้รับข้อความ Broadcast และแดชบอร์ดแสดงสถานะ Live
  2. เมื่อมีการสแกนภาพเกิดขึ้น ตัวเลขเคาน์เตอร์สแกนอัปเดตทันทีโดยไม่ต้องกดรีเฟรชหน้าเว็บ
  3. Token ไม่ใช่ Admin ถูกปิดการเชื่อมต่อด้วยรหัส 1008
  4. หากเครือข่ายหลุด ไฟสถานะการเชื่อมต่อเปลี่ยนเป็นออฟไลน์ และผู้ใช้สามารถกดรีเฟรชเพื่อโหลดข้อมูลล่าสุดได้
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
  2. มีป้ายระบุชัดเจนว่า "Active Production" บนการ์ดโมเดลที่ใช้งานอยู่
  3. แสดงค่า Benchmark Metrics ครบถ้วน: mIoU, aAcc, mAcc, mDice
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

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
  2. เมื่อกดยืนยัน Backend ทำการสลับสถานะในฐานข้อมูล โดยปิดการใช้งานเวอร์ชันเดิมทั้งหมดก่อนเปิดใช้งานเวอร์ชันที่เลือก
  3. ตารางรีเฟรช และโมเดลที่เลือกจะย้ายขึ้นมาอยู่อันดับแรกพร้อมป้าย Active Production ทันที
  4. มีการบันทึกการกระทำลงใน Audit Log
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

### TC-ADM-MOD-03: การทดสอบ Dry-Run และการย้อนเวอร์ชันโมเดล (Dry-Run Plus Rollback)
- **Module / Feature**: Model Registry / Dry-Run and Rollback
- **Requirement ID**: FR-ADM-04
- **Test Type**: Integration
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. อยู่ในหน้า `/admin/models` มีโมเดลมากกว่าหนึ่งเวอร์ชัน
- **Test Data**:
  - Endpoint: `POST /api/v1/admin/models/{model_id}/dry-run`
  - Endpoint: `POST /api/v1/admin/models/{model_id}/deploy` พร้อมเหตุผลสำหรับ Rollback
- **Test Steps**:
  1. กดปุ่ม Dry-Run ที่แถวโมเดลเป้าหมายแล้วรอผลการทดสอบ
  2. กดปุ่ม Rollback ที่การ์ดโมเดลที่ใช้งานอยู่เพื่อเลือกเวอร์ชันสำรอง
  3. กรอกเหตุผลแล้วยืนยันการสลับเวอร์ชัน
- **Expected Results**:
  1. ผล Dry-Run แสดงสถานะสำเร็จพร้อมค่าความหน่วงและหน่วยความจำโดยประมาณ
  2. กรณีไฟล์โมเดลหาย ระบบตอบว่าไม่สำเร็จพร้อมข้อความระบุสาเหตุ
  3. การ Rollback ต้องกรอกเหตุผล มิฉะนั้นระบบไม่อนุญาตให้ยืนยัน
  4. หลัง Rollback สำเร็จ โมเดลสำรองย้ายขึ้นเป็นเวอร์ชันใช้งานพร้อมบันทึก Audit Log
- **Automation Mapping**: Manual Verification

---

## 4. หมวดหมู่การตรวจสอบข้อร้องเรียน (Report Moderation Flow)

### TC-ADM-REP-01: การอนุมัติหรือปัดตกรายงานข้อร้องเรียน (Approve / Reject Report)
- **Module / Feature**: Report Moderation / Decision Making
- **Requirement ID**: FR-ADM-02
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. มีรายการรายงานข้อร้องเรียนที่มีสถานะ `pending` ในระบบ
- **Test Data**: รายงาน ID `REP-101` พร้อม `version` ปัจจุบัน
- **Test Steps**:
  1. ไปที่หน้า `/admin/reports`
  2. แตะเปิดดูรายงาน `REP-101` ผ่าน `GET /api/v1/admin/reports/{report_id}`
  3. เริ่มตรวจด้วย `POST /api/v1/admin/reports/{report_id}/review` พร้อม `version` เพื่อเปลี่ยนเป็น `reviewing`
  4. ตัดสินด้วย `PATCH /api/v1/admin/reports/{report_id}` พร้อม `status`, `version`, `admin_note`
- **Expected Results**:
  1. สถานะของรายงานเปลี่ยนจาก `pending` เป็น `reviewing` แล้วเป็น `approved` ตามลำดับ
  2. บันทึกข้อมูล Admin ผู้ทำการตัดสินลงในระบบ
  3. เลข `version` เพิ่มขึ้นทุกครั้งที่อัปเดตสำเร็จ
  4. การปัดตกหรือเปิดงานใหม่ต้องมี `admin_note` มิฉะนั้นได้ `400 Bad Request`
- **Automation Mapping**: `server/tests/api/test_admin_reports.py`

---

### TC-ADM-REP-02: การป้องกัน Race Condition ด้วย Optimistic Locking (`version` column)
- **Module / Feature**: Report Moderation / Concurrency Control
- **Requirement ID**: FR-ADM-02
- **Test Type**: Functional
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
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. อยู่ในหน้า `/admin/users` มีรายชื่อผู้ใช้แสดงในตาราง
- **Test Data**: ผู้ใช้ `spammer@example.com` พร้อมเหตุผลการระงับ
- **Test Steps**:
  1. ค้นหาผู้ใช้ด้วย `GET /api/v1/admin/users?search=spammer@example.com` แล้วเปิดดูด้วย `GET /api/v1/admin/users/{user_id}`
  2. สั่งระงับด้วย `PATCH /api/v1/admin/users/{user_id}` พร้อม `is_active` เป็น `false` โดยไม่ส่งเหตุผล
  3. ส่งซ้ำพร้อม `reason` ว่า "ยิงสแกนภาพสแปมเพื่อรบกวนระบบ"
- **Expected Results**:
  1. เมื่อไม่กรอกเหตุผล ระบบตอบ Validation Error และไม่อนุญาตให้บันทึก
  2. เมื่อส่ง `is_active` เป็น `false` พร้อมเหตุผล ผู้ใช้ถูกระงับสำเร็จ
  3. บัญชีผู้ใช้นี้จะไม่สามารถล็อกอินเข้าสู่ระบบได้อีก
  4. การดำเนินการถูกบันทึกลงในตาราง `audit_log` พร้อม Admin ID ผู้สั่งแบน
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

### TC-ADM-USR-02: การดูรายละเอียดผู้ใช้และการปลดระงับบัญชี (User Detail Plus Unban)
- **Module / Feature**: User Management / Detail and Unban
- **Requirement ID**: FR-ADM-05
- **Test Type**: Functional
- **Priority**: P2 (Medium)
- **Pre-conditions**:
  1. มีบัญชีผู้ใช้ที่ถูกระงับอยู่ในระบบ
- **Test Data**:
  - Endpoint: `GET /api/v1/admin/users/{user_id}`
  - Endpoint: `PATCH /api/v1/admin/users/{user_id}` พร้อม `is_active` เป็น `true` และเหตุผล
- **Test Steps**:
  1. เปิดดูรายละเอียดผู้ใช้ด้วย `GET /api/v1/admin/users/{user_id}`
  2. สั่งปลดระงับด้วย `PATCH /api/v1/admin/users/{user_id}` พร้อมเหตุผล
- **Expected Results**:
  1. หน้ารายละเอียดแสดงข้อมูลบัญชี สถานะ ประวัติการสแกน และรายงานของผู้ใช้
  2. การปลดระงับต้องกรอกเหตุผล มิฉะนั้นระบบไม่อนุญาตให้บันทึก
  3. หลังปลดระงับสำเร็จ สถานะบัญชีกลับเป็นใช้งานได้ตามปกติ
- **Automation Mapping**: Manual Verification

---

## 6. หมวดหมู่บันทึกตรวจสอบและการเข้าถึง (Audit Logs Plus Accessibility)

### TC-ADM-AUD-01: การกรองบันทึก Audit Log และการแสดงผลต่าง JSON (Audit Filter)
- **Module / Feature**: Audit Log Viewer / Filtering and Diff
- **Requirement ID**: FR-ADM-06, FR-AUDIT-01
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มีประวัติการ Deploy โมเดลหรือตัดสินรายงานในตาราง `audit_log`
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `GET /api/v1/admin/audit-logs?page=1&limit=50&search=&action=&entity_type=`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เปิดหน้าบันทึก Audit Log แล้วดึงข้อมูลแบบไม่กรอง
  2. กรองด้วย `action` และ `entity_type` เช่น `report`
  3. เปิดดูผลต่าง `before_state` และ `after_state` ของรายการที่เปลี่ยนสถานะ
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ตอบ `200 OK` พร้อม `items`, `total`, `page`, `limit`
  2. การกรองตาม `action` ประเภท Entity และคำค้นทำงานถูกต้อง
  3. หน้ารายละเอียดแสดงผลต่าง JSON ของ `status` และ `version` ก่อนหลังชัดเจน
  4. ตารางที่ใช้คือ `audit_log` เอกพจน์
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_admin.py`

---

## 7. หมวดหมู่การเข้าถึงและการแสดงผล (Accessibility Plus Theme)

### TC-ADM-UI-01: ความคมชัดของคู่สีตามมาตรฐาน WCAG 2.1 AA (Contrast Ratio >= 4.5:1)
- **Module / Feature**: Accessibility / Theme Contrast
- **Requirement ID**: NFR-A11Y-01
- **Test Type**: Functional
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
- **Automation Mapping**: Manual Verification

---

### TC-ADM-UI-02: การสลับธีมและการแสดงผล Responsive (Theme Plus Responsive)
- **Module / Feature**: Accessibility / Theme and Layout
- **Requirement ID**: NFR-A11Y-01
- **Test Type**: Functional
- **Priority**: P3 (Low)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ล็อกอิน Admin ค้างไว้
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Light Mode และ Dark Mode
  - หน้าจอ Desktop 1440px, Tablet 768px, Mobile 390px
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. สลับธีมมืดและสว่างแล้วตรวจสอบทุกหน้า
  2. ย่อขยายหน้าจอทั้ง 3 ขนาดแล้วตรวจสอบตารางและ Modal
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ธีมเปลี่ยนครบทุกคอมโพเนนต์โดยคอนทราสต์ยังผ่าน 4.5:1
  2. ตารางมี Scroll แนวนอนหรือจัดเรียงใหม่โดยไม่ล้นจอ
  3. Modal Deploy และ Ban ยังกดยืนยันได้ในจอเล็ก
- **Automation Mapping**: Manual Verification
