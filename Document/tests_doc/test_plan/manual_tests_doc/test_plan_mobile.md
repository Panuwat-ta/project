# แผนการทดสอบ: แอปพลิเคชันสมาร์ตโฟน (Mobile Application Test Plan)

- **System / Component**: ScamGuard Mobile Client
- **Architecture**: Clean Architecture, BLoC/Cubit State Management, Repository Pattern
- **Tech Stack**: Flutter 3.x, Dart, Dio HTTP Client, Flutter Secure Storage, Hive
- **Target Platform**: Android เท่านั้นสำหรับรุ่นแรก (Android 5.0+ / API 21+ ขึ้นไปตาม flutter.minSdkVersion; ทดสอบหลักบน Android 10+ ถึง 14 / API 29-34) ส่วนระบบ iOS จัดอยู่นอกขอบเขต (Future Release)
- **Document Version**: 1.0.0
- **Status**: Approved

---

## 1. ขอบเขตการทดสอบ (Scope of Testing)

### 1.1 สิ่งที่อยู่ในขอบเขต (In-Scope)
1. **Authentication Flow**: การลงทะเบียน, การเข้าสู่ระบบด้วย JWT, การเก็บรักษา Token ลงใน Secure Storage, และการรีเฟรช Token อัตโนมัติ
2. **Image Capture & Selection**: การเลือกภาพจากแกลเลอรี, การถ่ายภาพจากกล้อง, การตรวจสอบขนาดไฟล์ (<= 10MB) และนามสกุลไฟล์ (.jpg, .jpeg, .png)
3. **Image Cropping**: เครื่องมือคร็อปและหมุนภาพก่อนส่งตรวจสอบ
4. **Scan Submission**: การอัปโหลดไฟล์ผ่าน Multipart HTTP ไปยัง Backend พร้อมส่งค่า Consent
5. **Result & Forensic Visualization**: การแสดงคะแนนความเสี่ยง (Risk Score) 3 ระดับ (Low 0-39, Medium 40-69, High 70-100) การซ้อนทับภาพ Heatmap Overlay และตัวปรับ Opacity
6. **Multi-Factor Breakdown**: การแจกแจงคะแนน 3 มิติ (Textual OCR, Source Verification, Visual Anomaly)
7. **XAI Explanation**: การแสดงผลคำอธิบายเหตุผลภาษาไทยจาก Qwen2.5-1.5B
8. **Scan History & Offline Cache**: การเรียกดูประวัติการสแกนย้อนหลัง การทำงานแบบ Local Storage เมื่อเน็ตเวิร์กขาดการเชื่อมต่อ
9. **Scam Report Submission**: การส่งรายงานข้อร้องเรียนผลการตรวจสอบผิดพลาด
10. **UI/UX & Accessibility**: รองรับ Dark Mode / Light Mode, Responsive layout บนหน้าจอขนาดต่างๆ และ Touch target >= 48x48dp บนอุปกรณ์ Android

### 1.2 สิ่งที่อยู่นอกขอบเขต (Out-of-Scope)
1. **การรองรับระบบปฏิบัติการ iOS**: โครงการระยะที่ 1 (v1) กำหนดขอบเขตชัดเจนว่ามุ่งเน้นเฉพาะระบบปฏิบัติการ Android เท่านั้น โดยเวอร์ชัน iOS ถูกจัดอยู่ในแผนการพัฒนาในอนาคต (Future Release) ตามเอกสารขอบเขตโครงการและ Wiki
2. **การประมวลผลโมเดล AI ในระดับชิปเซ็ตสมาร์ตโฟน**: ระบบใช้ Server-side AI Inference Pipeline ทั้งหมด ไม่มีการทำ On-Device Deep Learning บนเครื่องผู้ใช้
3. **ระบบการชำระเงิน**: ระบบไม่มีธุรกรรมทางการเงินหรือระบบ In-App Purchase

---

## 2. กลยุทธ์และวิธีการทดสอบ (Testing Strategy)

### 2.1 สภาพแวดล้อมการทดสอบ (Test Environment)
- **อุปกรณ์ทดสอบจริง (Physical Devices)**:
  - Android Devices: Samsung Galaxy S21 / Google Pixel 6 / Google Pixel 7 (Android 12, 13, 14)
- **เครื่องจำลอง (Emulators)**:
  - Android Emulator: Pixel 5 (API 33), Pixel 6 (API 34)
- **Backend Environment**: Staging API Server (`https://api-staging.scamguard.local`) และ Local Docker Environment (`http://10.0.2.2:8000` สำหรับ Android Emulator)

### 2.2 ระดับและประเภทการทดสอบ (Test Levels & Types)
1. **Unit & Widget Testing**: ตรวจสอบ State Transitions ของ BLoC/Cubit, Data Sources, Repository mapping และ UI Widgets
2. **Integration Testing**: ตรวจสอบการรับส่งข้อมูลระหว่าง Mobile Client กับ Backend API ผ่าน Mock Server และ Real API Server
3. **Manual Functional Testing**: ดำเนินการตามชุดกรณีทดสอบใน `tests_all/manual_tests/test_cases_mobile.md`
4. **Usability & Boundary Testing**: ทดสอบการหมุนหน้าจอ, การสลับแอปไปมา (App Lifecycle), การตัดการเชื่อมต่อสัญญาณเน็ตเวิร์กชั่วคราว, และขนาดตัวอักษรของระบบ

---

## 3. เกณฑ์การตรวจรับ (Entry & Exit Criteria)

### 3.1 เกณฑ์การเริ่มต้นทดสอบ (Entry Criteria)
- ซอร์สโค้ด Mobile ผ่านการรัน `flutter analyze` โดยไม่มีข้อผิดพลาดระดับ Error
- มีการกำหนด Endpoint ชี้ไปยังเซิร์ฟเวอร์ที่เปิดบริการอยู่
- ชุดทดสอบ Unit Test ขั้นต่ำผ่าน 100%

### 3.2 เกณฑ์การสิ้นสุดการทดสอบ (Exit Criteria)
- กรณีทดสอบระดับ P0 (Blocker) และ P1 (Critical) ใน `tests_all/manual_tests/test_cases_mobile.md` ผ่าน 100%
- กรณีทดสอบระดับ P2 ผ่านไม่น้อยกว่า 95%
- ไม่พบข้อผิดพลาดที่ทำให้แอปเกิดการแครช (Crash-free Sessions >= 99.5%)
- ไม่มีข้อความที่แสดงผลผิดพลาดหรือการตัดคำที่ไม่ถูกต้อง (Localization Integrity)

---

## 4. ความเชื่อมโยงไปยังชุดกรณีทดสอบจริง
- **เอกสารกรณีทดสอบละเอียด**: `tests_all/manual_tests/test_cases_mobile.md`
- **ตารางความสอดคล้องความต้องการ**: `tests_all/rtm.md` (หมวดหมู่ FR-AUTH, FR-INPUT, FR-REPORT, FR-HIST, FR-RPT)
