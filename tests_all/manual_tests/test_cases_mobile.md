# ชุดกรณีทดสอบ: แอปพลิเคชันสมาร์ตโฟน (Mobile Application - Flutter)

- **System**: ScamGuard Mobile Client
- **Architecture**: Clean Architecture, BLoC/Cubit State Management
- **Framework**: Flutter SDK 3.x, Dio HTTP Client, Flutter Secure Storage
- **Version**: 1.0.0
- **Status**: Baseline

---

## 1. หมวดหมู่การยืนยันตัวตน (Authentication)

### TC-MOB-AUTH-01: การลงทะเบียนผู้ใช้ใหม่สำเร็จด้วย Email และ Password (Happy Path)
- **Module / Feature**: Authentication / User Registration
- **Requirement ID**: FR-AUTH-01
- **Test Type**: Functional
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. เครื่องสมาร์ตโฟนเชื่อมต่ออินเทอร์เน็ต
  2. แอปเปิดอยู่ที่หน้าลงทะเบียน (Register Screen)
- **Test Data**:
  - Email: `newuser_qa@example.com`
  - Password: `Password123!`
  - Confirm Password: `Password123!`
  - Full Name: `QA New User`
  - system_consent: `true`
  - research_consent: `false`
- **Test Steps**:
  1. กรอก Email ในช่องอีเมล
  2. กรอก Password และ Confirm Password ให้ตรงกัน
  3. กดปุ่ม "สมัครสมาชิก" (Register)
- **Expected Results**:
  1. แอปแสดงสถานะ Loading ขณะส่งข้อมูลไปยัง Backend
  2. ได้รับข้อความยืนยันการลงทะเบียนสำเร็จ
  3. ระบบนำทางผู้ใช้ไปยังหน้าลงชื่อเข้าใช้ (Login Screen) อัตโนมัติ
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

### TC-MOB-AUTH-02: การเข้าสู่ระบบสำเร็จและการบันทึก Token (Login Flow)
- **Module / Feature**: Authentication / User Login
- **Requirement ID**: FR-AUTH-02, FR-AUTH-04
- **Test Type**: Functional
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มีบัญชีผู้ใช้ที่ผ่านการลงทะเบียนแล้วในระบบ
  2. แอปเปิดอยู่ที่หน้า Login
- **Test Data**:
  - Email: `qa_tester@scamguard.local`
  - Password: `Password123!`
- **Test Steps**:
  1. กรอก Email และ Password
  2. กดปุ่ม "เข้าสู่ระบบ" (Login)
- **Expected Results**:
  1. ระบบส่งคำขอไปยัง `POST /api/v1/auth/login`
  2. ได้รับ Access Token และ Refresh Token
  3. Token ถูกจัดเก็บลงใน Flutter Secure Storage โดยไม่หลุดไปเก็บใน SharedPreferences
  4. แอปนำทางเข้าสู่หน้าแรก (Home Screen) ทันที
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

### TC-MOB-AUTH-03: การปฏิเสธการเข้าสู่ระบบเมื่อกรอกรหัสผ่านไม่ถูกต้อง (Negative Test)
- **Module / Feature**: Authentication / Login Error Handling
- **Requirement ID**: FR-AUTH-02
- **Test Type**: Negative
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. แอปอยู่ที่หน้า Login
- **Test Data**:
  - Email: `qa_tester@scamguard.local`
  - Password: `WrongPassword999`
- **Test Steps**:
  1. กรอก Email ถูกต้อง แต่กรอก Password ผิด
  2. กดปุ่ม "เข้าสู่ระบบ"
- **Expected Results**:
  1. แอปแสดง SnackBar หรือ Dialog แจ้งข้อผิดพลาด "อีเมลหรือรหัสผ่านไม่ถูกต้อง"
  2. ไม่มีการบันทึก Token ใดๆ
  3. ผู้ใช้ยังคงอยู่ที่หน้า Login เดิม
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

### TC-MOB-AUTH-04: การออกจากระบบและการล้าง Session (Logout)
- **Module / Feature**: Authentication / Logout
- **Requirement ID**: FR-AUTH-05
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. ผู้ใช้ล็อกอินอยู่ในระบบเรียบร้อยแล้ว
- **Test Data**: N/A
- **Test Steps**:
  1. ไปที่เมนู "การตั้งค่า" (Settings)
  2. แตะปุ่ม "ออกจากระบบ" (Logout)
  3. ยืนยันในกล่องข้อความยืนยัน
- **Expected Results**:
  1. Secure Storage ถูกล้างค่า Token ทั้งหมด (`delete(key: 'access_token')`)
  2. State ของ AuthBloc เปลี่ยนเป็น `AuthUnauthenticated`
  3. ระบบนำทางกลับสู่หน้า Login ทันที และไม่สามารถกดย้อนกลับ (Back) มาหน้าหลักได้
- **Automation Mapping**: Manual Verification

---

### TC-MOB-AUTH-05: การต่ออายุ Token และการดึงโปรไฟล์ผู้ใช้ (Refresh Plus Me)
- **Module / Feature**: Authentication / Token Refresh
- **Requirement ID**: FR-AUTH-04
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ผู้ใช้ล็อกอินค้างไว้ มี Refresh Token ที่ยังไม่หมดอายุ
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `POST /api/v1/auth/refresh` พร้อม `refresh_token`
  - Endpoint: `GET /api/v1/auth/me` พร้อม Access Token ใหม่
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. รอให้ Access Token หมดอายุหรือบังคับให้หมดอายุ
  2. เปิดแอปใหม่หรือเรียกข้อมูลที่ต้องใช้สิทธิ์
  3. สังเกตการต่ออายุ Token อัตโนมัติและการดึงโปรไฟล์
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. แอปเรียก `POST /api/v1/auth/refresh` และได้รับ `access_token` ใหม่โดยไม่ต้องกรอกรหัสผ่านซ้ำ
  2. Response มีโครงสร้าง `access_token`, `refresh_token`, `token_type`, `user` โดยไม่มีฟิลด์ `expires_in`
  3. เรียก `GET /api/v1/auth/me` สำเร็จและแสดงชื่อผู้ใช้ถูกต้อง
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

### TC-MOB-AUTH-06: การจัดการ Session หมดอายุและการนำทางกลับหน้า Login (Session Timeout)
- **Module / Feature**: Authentication / Session Timeout
- **Requirement ID**: FR-AUTH-04
- **Test Type**: Negative
- **Priority**: P2 (Medium)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ผู้ใช้ล็อกอินค้างไว้
  2. เตรียม Refresh Token ที่หมดอายุหรือไม่ถูกต้อง
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Refresh Token ที่หมดอายุ
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. บังคับให้ Refresh Token หมดอายุ
  2. เปิดแอปและพยายามเรียกข้อมูลที่ต้องใช้สิทธิ์
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. Backend ตอบ `401 Unauthorized` พร้อมข้อความว่า Token ไม่ถูกต้องหรือหมดอายุ
  2. แอปล้าง Token ใน Secure Storage และนำทางกลับหน้า Login
  3. แสดงข้อความแจ้งให้ล็อกอินใหม่
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_auth_flow.py`

---

## 2. หมวดหมู่การรับภาพและการตรวจสอบไฟล์ (Image Input & Validation)

### TC-MOB-IMG-01: การเลือกรูปภาพจาก Photo Gallery
- **Module / Feature**: Image Input / Gallery Picker
- **Requirement ID**: FR-INPUT-01
- **Test Type**: Functional
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. มีรูปภาพตัวอย่างอยู่ในแกลเลอรีของเครื่อง
  2. แอปขอและได้รับสิทธิ์เข้าถึง Photos/Storage แล้ว
- **Test Data**: ภาพสลิปตัวอย่าง `slip_test.png` (ขนาด 1.2 MB)
- **Test Steps**:
  1. ในหน้าหลัก แตะปุ่ม "เลือกรูปภาพจากคลัง" (Choose from Gallery)
  2. เลือกภาพ `slip_test.png`
- **Expected Results**:
  1. ภาพตัวอย่างถูกโหลดขึ้นมาแสดงบนหน้าจอพรีวิวได้อย่างคมชัดและสัดส่วนไม่บิดเบี้ยว
  2. ปุ่ม "เริ่มสแกน" (Start Scan) เปลี่ยนสถานะเป็น Active พร้อมกดได้
- **Automation Mapping**: Manual UI Test

---

### TC-MOB-IMG-02: การจัดการเมื่อผู้ใช้ปฏิเสธสิทธิ์แกลเลอรี (Permission Denied)
- **Module / Feature**: Image Input / Permission Handling
- **Requirement ID**: FR-INPUT-01
- **Test Type**: Negative
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. แอปยังไม่ได้รับสิทธิ์เข้าถึงแกลเลอรี
  2. อยู่ในหน้าหลักของแอป
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - การปฏิเสธสิทธิ์ผ่าน System Dialog
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. แตะปุ่มเลือกรูปภาพจากแกลเลอรี
  2. กดปฏิเสธสิทธิ์ใน System Dialog
  3. สังเกตหน้าจอที่แสดงผล
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. State เปลี่ยนเป็น `HomePermissionDenied`
  2. หน้าจอแสดง `PermissionRequestView` พร้อมคำแนะนำและปุ่มเปิดการตั้งค่า
  3. ไม่เกิดการแครชและไม่เปิดตัวเลือกไฟล์
- **Automation Mapping**: Manual UI Test

---

### TC-MOB-IMG-03: การแจ้งเตือนและบีบอัดไฟล์ภาพขนาดเกินแนะนำ 10MB ฝั่ง Mobile (Client-Side Warning Plus Compress)
- **Module / Feature**: Image Validation / File Size Handling
- **Requirement ID**: FR-INPUT-04
- **Test Type**: Boundary
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. เตรียมไฟล์ภาพขนาด 12.5 MB ในเครื่อง
- **Test Data**: `large_image_12mb.jpg` (ขนาด 12.5 MB)
- **Test Steps**:
  1. เลือกภาพ `large_image_12mb.jpg` จากแกลเลอรี
  2. สังเกตคำเตือนและการบีบอัดก่อนอัปโหลด
- **Expected Results**:
  1. แอปแสดงคำเตือนว่าไฟล์เกินขนาดแนะนำ 10MB ของฝั่ง Mobile และจะทำการบีบอัดก่อนส่ง
  2. ระบบบีบอัดภาพผ่านการตั้งค่า `imageQuality` ก่อนอัปโหลด ไม่ปฏิเสธไฟล์ทันที
  3. ไฟล์ยังถูกส่งไป Backend ได้ หากขนาดหลังบีบอัดไม่เกินลิมิตฝั่ง Server 20MB โดย Server ตอบ 413 ก็ต่อเมื่อเกิน 20MB เท่านั้น
- **Automation Mapping**: Manual UI Test

---

### TC-MOB-IMG-04: การปฏิเสธไฟล์นามสกุลที่ไม่รองรับ
- **Module / Feature**: Image Validation / File Format
- **Requirement ID**: FR-INPUT-04
- **Test Type**: Negative
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. มีไฟล์ที่ไม่ใช่ jpg/jpeg/png/webp อยู่ในเครื่อง (เช่น PDF หรือ GIF)
- **Test Data**: `document.pdf` หรือ `animation.gif`
- **Test Steps**:
  1. พยายามเลือกไฟล์ที่ไม่ใช่รูปภาพที่รองรับ
- **Expected Results**:
  1. ตัวเลือกไฟล์กรองเฉพาะรูปภาพนามสกุล jpg, jpeg, png, webp
  2. หากเลือกไฟล์ผิดประเภท ระบบแจ้งเตือน "รูปแบบไฟล์ไม่รองรับ รองรับเฉพาะ jpg, jpeg, png, webp"
- **Automation Mapping**: Manual UI Test

---

### TC-MOB-IMG-05: การครอบตัดภาพก่อนส่งสแกน (Crop Before Scan)
- **Module / Feature**: Image Input / Crop Editor
- **Requirement ID**: FR-INPUT-02
- **Test Type**: Functional / UI
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. เลือกรูปภาพจากแกลเลอรีแล้ว อยู่ในหน้าตัวอย่างภาพ
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ภาพสลิปทดสอบขนาด 800 KB
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. แตะปุ่มครอบตัดภาพแล้วลากกรอบเลือกเฉพาะส่วนสลิป
  2. ยืนยันการครอบตัดแล้วตรวจสอบภาพตัวอย่าง
  3. กดปุ่มเริ่มสแกน
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. ภาพตัวอย่างแสดงเฉพาะส่วนที่ครอบตัดไว้
  2. ไฟล์ที่ส่งสแกนถูกบีบอัดคุณภาพ 85 ก่อนอัปโหลด
  3. งานสแกนเริ่มได้ตามปกติและได้ `taskId` กลับมา
- **Automation Mapping**: Manual UI Test

---

## 3. หมวดหมู่กระบวนการสแกนและการจัดการสถานะ (Scan BLoC Workflow)

### TC-MOB-SCAN-01: กระบวนการส่งสแกนภาพและการเปลี่ยนสถานะ BLoC สำเร็จ
- **Module / Feature**: Scan Workflow / BLoC State Management
- **Requirement ID**: FR-INPUT-03, FR-SYS-07
- **Test Type**: Integration
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. ผู้ใช้เลือกภาพแล้วในหน้า Preview
  2. เซิร์ฟเวอร์ Backend ทำงานปกติ
- **Test Data**: ภาพสลิปทดสอบ `sample_slip.jpg` (ขนาด 800 KB)
- **Test Steps**:
  1. กดปุ่ม "เริ่มสแกนภาพ"
  2. สังเกตการเปลี่ยนแปลงบนหน้าจอ
- **Expected Results**:
  1. State เปลี่ยนจาก `ScanInitial` -> `ScanUploading` -> `ScanPolling`
  2. หน้าจอแสดง Loading พร้อมแถบความคืบหน้าขณะรอผล
  3. เมื่อ Backend ประมวลผลเสร็จ State เปลี่ยนเป็น `ScanCompleted` พร้อม `taskId`
  4. แอปนำทางไปยังหน้ารายงานผลการวิเคราะห์ (Result Screen) อัตโนมัติ
- **Automation Mapping**: `scam_image_mobile/test/features/scan/presentation/bloc/scan_bloc_test.dart`

---

### TC-MOB-SCAN-02: การแสดงข้อผิดพลาดเมื่ออัปโหลดหรือวิเคราะห์ล้มเหลว (ScanError Path)
- **Module / Feature**: Scan Workflow / Error Handling
- **Requirement ID**: FR-INPUT-03
- **Test Type**: Negative
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ผู้ใช้เลือกภาพแล้ว
  2. Backend ตอบข้อผิดพลาดหรือเครือข่ายขัดข้อง
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - ภาพปกติขนาด 800 KB แต่ Server ตอบ 500 หรือขาดการเชื่อมต่อ
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. กดปุ่มเริ่มสแกน
  2. สังเกต State และข้อความที่แสดง
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. State เปลี่ยนเป็น `ScanError` พร้อมข้อความภาษาไทยที่เข้าใจง่าย
  2. หน้าจอแสดง SnackBar หรือ Dialog แจ้งข้อผิดพลาด
  3. ผู้ใช้สามารถกดลองใหม่ได้โดยไม่ต้องเลือกภาพซ้ำ
- **Automation Mapping**: `scam_image_mobile/test/features/scan/presentation/bloc/scan_bloc_test.dart`

---

### TC-MOB-SCAN-03: การแจ้งเตือนเมื่อรอผลนานเกินกำหนด (ScanTimeout Path)
- **Module / Feature**: Scan Workflow / Timeout Handling
- **Requirement ID**: FR-INPUT-03
- **Test Type**: Boundary
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ผู้ใช้เริ่มสแกนแล้วอยู่ในสถานะ `ScanPolling`
  2. Backend ไม่ตอบกลับภายในเวลาที่กำหนด
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - งานวิเคราะห์ที่ค้างสถานะ processing เกิน Timeout
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เริ่มสแกนและรอจนเกินเวลา Timeout
  2. สังเกตข้อความและการนำทาง
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. State เปลี่ยนเป็น `ScanTimeout`
  2. แสดงข้อความหมดเวลา กรุณาลองใหม่
  3. ระบบหยุด Polling และกลับสู่สถานะพร้อมเริ่มใหม่
- **Automation Mapping**: `scam_image_mobile/test/features/scan/presentation/bloc/scan_bloc_test.dart`

---

### TC-MOB-SCAN-04: การยกเลิกงานสแกนระหว่างรอผล (GAP ฝั่ง Server ยังไม่มี Endpoint)
- **Module / Feature**: Scan Workflow / Cancel Scan
- **Requirement ID**: FR-INPUT-03
- **Test Type**: Functional
- **Priority**: P3 (Low)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ผู้ใช้เริ่มสแกนและอยู่ในสถานะ `ScanPolling`
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - taskId ของงานที่กำลังประมวลผล
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. กดปุ่มยกเลิกขณะรอผล
  2. ตรวจสอบว่าแอปเรียก `DELETE /scan/{id}`
  3. ตรวจสอบฝั่ง Server ว่ามี Endpoint รองรับหรือไม่
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. สถานะนี้เป็น GAP เนื่องจากฝั่ง Server มีเพียง `POST /api/v1/scan/` และ `GET /api/v1/scan/{scan_id}` ยังไม่มี `DELETE /scan/{id}`
  2. หากเรียก Endpoint ดังกล่าวจะได้ `404 Not Found` หรือ `405 Method Not Allowed`
  3. แอปควรหยุด Polling ในฝั่ง Client และกลับสู่ `ScanInitial` แม้ Server จะไม่มี Endpoint ยกเลิก
- **Automation Mapping**: Manual Verification

---

## 4. หมวดหมู่การแสดงผลรายงานคะแนนและ Heatmap (Result & Heatmap)

### TC-MOB-RES-01: การแสดงผลระดับความเสี่ยง 3 ระดับอย่างถูกต้อง (Risk Score Grading)
- **Module / Feature**: Result Display / Risk Scoring
- **Requirement ID**: FR-REPORT-01
- **Test Type**: Functional / UI
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. ได้รับผลการวิเคราะห์จาก Backend
- **Test Data**:
  - Case A: Score 25 (Low Risk)
  - Case B: Score 55 (Medium Risk)
  - Case C: Score 85 (High Risk)
- **Test Steps**:
  1. ตรวจสอบ Badge สีและข้อความระดับความเสี่ยงของแต่ละเคส
- **Expected Results**:
  1. Case A (0–39): แสดงป้ายสีเขียว พร้อมข้อความ "ความเสี่ยงต่ำ (Low Risk)"
  2. Case B (40–69): แสดงป้ายสีส้ม พร้อมข้อความ "ความเสี่ยงปานกลาง (Medium Risk)"
  3. Case C (70–100): แสดงป้ายสีแดง พร้อมข้อความ "ความเสี่ยงสูง (High Risk)"
  4. ไม่พบระดับ Safe ในการแสดงผลระดับความเสี่ยง มีเพียง Low, Medium, High ส่วนคีย์ safe ในไฟล์แปลภาษาเป็นค่าตกค้างที่ไม่ได้ใช้แสดงระดับความเสี่ยง
- **Automation Mapping**: `scam_image_mobile/test/core/utils/risk_level_helper_test.dart`

---

### TC-MOB-RES-02: การเปิด/ปิด และปรับความโปร่งใส Heatmap Overlay (Interactive Heatmap)
- **Module / Feature**: Result Display / Heatmap Interaction
- **Requirement ID**: FR-REPORT-02, FR-REPORT-03
- **Test Type**: Functional / UI
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. อยู่ที่หน้า Result Screen ที่มี Heatmap URL
- **Test Data**: ภาพ Heatmap ความละเอียดสูง
- **Test Steps**:
  1. แตะสวิตช์เปิด/ปิด Heatmap Overlay
  2. เลื่อน Slider ปรับระดับ Opacity จาก 0% ไป 100%
- **Expected Results**:
  1. เมื่อสวิตช์เปิด แผนที่ความร้อนจะซ้อนทับลงบนภาพต้นฉบับตรงพิกัดอย่างแม่นยำ
  2. เมื่อเลื่อน Slider ความเข้มของสี Heatmap เปลี่ยนแปลงอย่างนุ่มนวล (Smooth transition)
  3. เมื่อสวิตช์ปิด Heatmap จะถูกซ่อน เหลือเฉพาะภาพต้นฉบับ
- **Automation Mapping**: Manual UI Test

---

### TC-MOB-RES-03: การแสดงคำอธิบายเชิงเหตุผล (Explainable AI Summary)
- **Module / Feature**: Result Display / XAI Breakdown
- **Requirement ID**: FR-REPORT-04, FR-REPORT-05, FR-SYS-11
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. อยู่ที่หน้า Result Screen
- **Test Data**: ผลการวิเคราะห์ที่มีคะแนนจำแนกและคำอธิบาย XAI จาก Qwen2.5 พร้อมข้อความจาก Surya OCR
- **Test Steps**:
  1. เลื่อนดูการ์ด "รายละเอียดการวิเคราะห์" (Analysis Breakdown)
- **Expected Results**:
  1. แสดงคะแนนจำแนก 3 ด้าน: ข้อความ (Textual Score), แหล่งที่มา (Source Verification), และร่องรอยการตัดต่อ (Visual Anomaly)
  2. แสดงคำที่เข้าข่ายน่าสงสัยจาก Surya OCR พร้อมคำอธิบายภาษาไทยจาก Qwen2.5 ที่สอดคล้องกับพิกัด Heatmap
  3. ไม่แสดงข้อมูลนอกเหนือจากผลการตรวจจับจริง
- **Automation Mapping**: Manual UI Test

---

## 5. หมวดหมู่ประวัติการสแกนและโหมด Offline (History & Offline)

### TC-MOB-HIST-01: การแสดงผลรายการประวัติย้อนหลังพร้อมภาพ Thumbnail
- **Module / Feature**: History / Recent Scans
- **Requirement ID**: FR-HIST-01
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. ผู้ใช้เคยสแกนภาพมาแล้วอย่างน้อย 3 ภาพ
  2. เข้าสู่หน้า "ประวัติการสแกน" (History Screen)
- **Test Data**: ประวัติการสแกนย้อนหลัง
- **Test Steps**:
  1. ตรวจสอบรายการในหน้า History
- **Expected Results**:
  1. แสดงรายการเรียงจากล่าสุดไปหาเก่าสุด
  2. มี Thumbnail รูปภาพแสดงผลถูกต้องทุกรายการ
  3. แสดงระดับความเสี่ยง (Low/Med/High) พร้อมวันที่และเวลาในเขตเวลาไทย (UTC+7)
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_history.py`

---

### TC-MOB-HIST-02: การแตะรายการประวัติเพื่อเปิดดูผลวิเคราะห์เดิม (Tap Navigation)
- **Module / Feature**: History / Navigation
- **Requirement ID**: FR-HIST-02
- **Test Type**: Functional / UI
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. อยู่ในหน้า History Screen
- **Test Data**: แตะที่รายการสแกนลำดับแรก
- **Test Steps**:
  1. แตะที่การ์ดรายการสแกน
- **Expected Results**:
  1. แอปนำทางไปยังหน้า Result Screen ของรายการนั้น
  2. ข้อมูลคะแนน, Heatmap และคำอธิบายโหลดขึ้นมาแสดงตรงตามประวัติเดิม 100%
- **Automation Mapping**: Manual UI Test

---

### TC-MOB-HIST-03: การทำงานในโหมด Offline เมื่อเครือข่ายขัดข้อง (Local Storage Fallback)
- **Module / Feature**: History / Offline Graceful Degradation
- **Requirement ID**: NFR-PERF-03 (Offline, เดิม FR-HIST-03)
- **Test Type**: Negative / Reliability
- **Priority**: P1 (High)
- **Pre-conditions**:
  1. เคยเปิดดูประวัติการสแกนขณะต่อเน็ตมาแล้ว
  2. ปิด Wi-Fi และ Cellular Data (เปิดโหมดเครื่องบิน)
- **Test Data**: โหมดไม่มีสัญญาณอินเทอร์เน็ต
- **Test Steps**:
  1. เปิดแอปและไปที่หน้าประวัติการสแกน
- **Expected Results**:
  1. แอปไม่เกิดการแครช (No Fatal Crash)
  2. มีข้อความแจ้งเตือนสีส้ม "ทำงานในโหมดออฟไลน์ แสดงข้อมูลจากแคชในเครื่อง"
  3. สามารถเปิดดูรายการประวัติที่ถูกแคชไว้ใน Local Storage ได้
- **Automation Mapping**: Manual Device Test

---

### TC-MOB-HIST-04: การลบประวัติการสแกนออกจากเครื่องและ Server (Delete History)
- **Module / Feature**: History / Delete Scan
- **Requirement ID**: FR-HIST-03
- **Test Type**: Functional
- **Priority**: P1 (High)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. มีประวัติการสแกนอย่างน้อย 1 รายการ
  2. ผู้ใช้ล็อกอินค้างไว้
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - scan_id ของรายการที่ต้องการลบ
  - Endpoint: `DELETE /api/v1/history/{scan_id}`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. ในหน้าประวัติ ปัดหรือกดปุ่มลบที่รายการเป้าหมาย
  2. ยืนยันการลบใน Dialog
  3. เรียก `GET /api/v1/history/{scan_id}` ซ้ำเพื่อยืนยัน
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
1. รายการหายจากหน้าประวัติทันที
2. Server ลบไฟล์ภาพต้นฉบับและ Heatmap เมื่อไม่มีงานอื่นใช้ `image_hash` เดียวกัน
3. เรียกดูรายการเดิมซ้ำได้ `404 Not Found` พร้อม `{"detail": "Scan not found"}`
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_history.py`

---

## 6. หมวดหมู่การแจ้งรายงานข้อร้องเรียน (Scam Report)

### TC-MOB-RPT-01: ผู้ใช้กดยืนยันการรายงานภาพหลอกลวง (User Scam Report Submission)
- **Module / Feature**: Scam Reporting / User Feedback
- **Requirement ID**: FR-RPT-01
- **Test Type**: Functional
- **Priority**: P2 (Medium)
- **Pre-conditions**:
  1. ผู้ใช้อยู่ในหน้ารายงานผลการวิเคราะห์ภาพ
- **Test Data**:
  - scan_id ของผลสแกนที่ต้องการรายงาน
  - category: `fake_slip`
  - description: "สลิปนี้ตัดต่อยอดเงิน ปลอมแปลงการโอนเงินจริง" (ความยาวไม่ต่ำกว่า 10 ตัวอักษร)
- **Test Steps**:
  1. เลื่อนลงมาแตะปุ่ม "รายงานว่าเป็นภาพหลอกลวง" (Report as Scam)
  2. เลือกหมวดหมู่ `fake_slip` และกรอกรายละเอียด
  3. กดปุ่มส่งรายงาน
- **Expected Results**:
  1. แอปส่งคำขอไปยัง `POST /api/v1/reports` พร้อม `scan_id`, `category`, `description`
  2. แสดง Dialog แจ้ง "ส่งรายงานสำเร็จ ข้อมูลจะถูกส่งให้ผู้เชี่ยวชาญตรวจสอบ"
  3. รายงานปรากฏในฐานข้อมูลพร้อมสถานะ `pending` เพื่อให้ Admin พิจารณา
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_history.py`

---

### TC-MOB-RPT-02: การดึงหมวดหมู่รายงานและการดูรายงานของตนเอง (Report Categories Plus My Reports)
- **Module / Feature**: Scam Reporting / Categories and My Reports
- **Requirement ID**: FR-RPT-01
- **Test Type**: Functional
- **Priority**: P2 (Medium)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ผู้ใช้ล็อกอินค้างไว้
  2. เคยส่งรายงานอย่างน้อย 1 ฉบับ
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - Endpoint: `GET /api/v1/reports/categories`
  - Endpoint: `GET /api/v1/reports/my`
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เปิดฟอร์มรายงานและตรวจสอบรายการหมวดหมู่ที่ดึงจาก Server
  2. เปิดหน้าประวัติรายงานของตนเอง
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
1. หมวดหมู่ที่ได้มี 7 ค่า ได้แก่ `romance_scam`, `online_shopping`, `fake_slip`, `investment`, `identity_theft`, `ai_deepfake`, `other` พร้อมป้ายภาษาไทยและอังกฤษ
2. หน้ารายงานของตนเองแสดงสถานะตัวพิมพ์เล็ก ได้แก่ `pending`, `reviewing`, `approved`, `rejected` พร้อมเลข `version`
- **Automation Mapping**: `tests_all/automate_tests/tests/api/test_history.py`

---

## 7. หมวดหมู่ความยินยอมข้อมูลส่วนบุคคล (PDPA Consent)

### TC-MOB-PDPA-01: หน้าจอแสดงความยินยอม (Consent Screen) ในการเปิดแอปครั้งแรก
- **Module / Feature**: Privacy / PDPA Consent
- **Requirement ID**: FR-PDPA-01
- **Test Type**: Functional / Compliance
- **Priority**: P0 (Blocker)
- **Pre-conditions**:
  1. ติดตั้งแอปใหม่ หรือล้าง App Data (First Launch)
- **Test Data**: นโยบายความเป็นส่วนตัวและเงื่อนไขการประมวลผลข้อมูล
- **Test Steps**:
  1. เปิดแอปพลิเคชันขึ้นมาเป็นครั้งแรก
- **Expected Results**:
  1. ปรากฏหน้า Consent Modal บังคับให้อ่านเงื่อนไขการประมวลผลภาพก่อนเข้าใช้งาน
  2. มี Checkbox ให้ยินยอมการนำภาพไปช่วยพัฒนางานวิจัย (Optional)
  3. หากไม่กดยินยอมข้อตกลงพื้นฐาน จะไม่สามารถเข้าใช้งานแอปได้
  4. เมื่อกดยินยอม ค่าความยินยอมจะถูกบันทึกลง Local Settings และไม่แสดงซ้ำอีกในครั้งถัดไป
- **Automation Mapping**: Manual UI Test

---

## 8. หมวดหมู่ภาษาและธีม (Localization & Theme Mode)

### TC-MOB-UI-01: การสลับภาษาระหว่างภาษาไทยและภาษาอังกฤษ (i18n)
- **Module / Feature**: Settings / Localization
- **Requirement ID**: FR-SET-01
- **Test Type**: Functional / UI
- **Priority**: P2 (Medium)
- **Pre-conditions**:
  1. อยู่ในหน้าการตั้งค่า (Settings)
- **Test Data**: สลับระหว่าง ภาษาไทย (TH) และ ภาษาอังกฤษ (EN)
- **Test Steps**:
  1. เปลี่ยนภาษาเป็น "English"
  2. ตรวจสอบข้อความบนหน้าจอหลักและหน้าผลการสแกน
  3. ปิดแอปและเปิดใหม่
- **Expected Results**:
  1. ข้อความและปุ่มทั้งหมดเปลี่ยนเป็นภาษาอังกฤษทันทีโดยไม่ต้อง Restart เครื่อง
  2. เมื่อเปิดแอปใหม่ ค่าภาษายังคงจำไว้เป็น English (Persistence)
- **Automation Mapping**: Manual UI Test

---

### TC-MOB-UI-02: การสลับโหมดมืด/โหมดสว่าง (Dark & Light Mode)
- **Module / Feature**: Settings / Theme Management
- **Requirement ID**: FR-SET-02
- **Test Type**: UI / Visual
- **Priority**: P2 (Medium)
- **Pre-conditions**:
  1. อยู่ในหน้าการตั้งค่า
- **Test Data**: Light Mode และ Dark Mode
- **Test Steps**:
  1. แตะสลับ Theme เป็น Dark Mode
  2. ตรวจสอบคอนทราสต์และความคมชัดของตัวหนังสือ
- **Expected Results**:
  1. พื้นหลังเปลี่ยนเป็นโทนมืด ข้อความเปลี่ยนเป็นสีสว่าง อ่านง่าย ไม่กลืนกับพื้นหลัง
  2. สีของ Badge ความเสี่ยง (เขียว/ส้ม/แดง) ยังคงมีคอนทราสต์ชัดเจนตามมาตรฐาน WCAG AA
  3. ปิดแอปและเปิดใหม่ การตั้งค่าโหมดมืดยังคงอยู่
- **Automation Mapping**: Manual UI Test

---

### TC-MOB-NOTIF-01: การแจ้งเตือนเมื่องานวิเคราะห์เสร็จ (GAP รอ FCM Phase 2)
- **Module / Feature**: Notifications / Background Task Completion
- **Requirement ID**: FR-SYS-10
- **Test Type**: Functional
- **Priority**: P3 (Low)
- **Pre-conditions (เงื่อนไขก่อนเริ่มทดสอบ)**:
  1. ผู้ใช้เริ่มสแกนแล้วสลับแอปไปพื้นหลัง
- **Test Data (ข้อมูลที่ใช้ทดสอบ)**:
  - งานสแกนที่ใช้เวลาประมวลผลนาน
- **Test Steps (ขั้นตอนการทดสอบ)**:
  1. เริ่มสแกนแล้วย่อแอปลงพื้นหลัง
  2. รอจนงานวิเคราะห์เสร็จ
  3. ตรวจสอบการแจ้งเตือนที่ได้รับ
- **Expected Results (ผลลัพธ์ที่คาดหวัง)**:
  1. สถานะนี้เป็น GAP เนื่องจากยังไม่มีการเชื่อมต่อ Firebase Cloud Messaging ในระบบปัจจุบัน
  2. ปัจจุบันแอปแสดงผลเฉพาะเมื่อเปิดค้างในหน้า Loading ผ่าน `ScanPolling` จนเป็น `ScanCompleted`
  3. หากมี FCM ใน Phase 2 ต้องแตะการแจ้งเตือนแล้วเปิดหน้ารายงานผลได้ถูกต้อง
- **Automation Mapping**: Manual UI Test
