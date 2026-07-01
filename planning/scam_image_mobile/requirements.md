# Requirements: ScamGuard Mobile App
## โครงการ: แอปตรวจสอบรูปภาพหลอกลวง (Scam Image Detection)

---

## 1. Introduction

### 1.1 Purpose
ScamGuard Mobile App เป็นแอปพลิเคชัน Flutter สำหรับผู้ใช้ทั่วไปที่ต้องการตรวจสอบความน่าเชื่อถือของรูปภาพก่อนนำไปใช้ตัดสินใจ โดยเชื่อมต่อกับ Backend API เพื่อวิเคราะห์ความเสี่ยงของภาพและแสดงผลในรูปแบบที่เข้าใจง่าย

### 1.2 Scope
แอปพัฒนาด้วย Flutter รองรับ Android และ iOS ใช้ Dark Mode เป็นธีมหลัก สถาปัตยกรรม Clean Architecture + BLoC State Management ครอบคลุม 16 หน้าจอตาม UI/UX Design ที่กำหนด

---

## 2. Functional Requirements

### REQ-001: Authentication — Splash Screen
- ระบบต้องแสดง Splash Screen พร้อม Logo, ชื่อแอป, Loading Indicator
- ระบบต้องตรวจสอบ Access Token ใน Secure Storage อัตโนมัติ
- หาก Token ยังใช้ได้ → นำทางไป Main Shell
- หาก Token หมดอายุ → ลอง Refresh Token อัตโนมัติ
- หาก Token ไม่มี หรือ Refresh ล้มเหลว → นำทางไป Login Screen
- หากผู้ใช้ยังไม่ยอมรับ Consent → นำทางไป Onboarding Screen

### REQ-002: Authentication — Onboarding & Consent
- ระบบต้องแสดงหน้า Onboarding อธิบายวัตถุประสงค์ของแอป
- ต้องมี Checkbox ยอมรับเงื่อนไขการใช้งาน (บังคับ)
- ต้องมี Checkbox ยินยอมให้นำข้อมูลไปปรับปรุงโมเดล (ไม่บังคับ)
- ปุ่มดำเนินการต่อต้อง Disable หากไม่ยอมรับเงื่อนไขบังคับ
- เมื่อยืนยัน Consent → บันทึกสถานะและนำทางไป Login

### REQ-003: Authentication — Login
- ระบบต้องมีช่อง Email และ Password พร้อม Validation
- ต้องมีปุ่มแสดง/ซ่อนรหัสผ่าน
- ต้องมีปุ่ม Login ด้วย Google
- ต้องมี Link ไปหน้า Register และ Forgot Password
- เมื่อ Login สำเร็จ → บันทึก Token และนำทางไป Main Shell
- ต้องแสดง Error State: ข้อมูลไม่ถูกต้อง, บัญชีถูกระงับ, ไม่มีอินเทอร์เน็ต

### REQ-004: Authentication — Register
- ระบบต้องมีช่อง Display Name, Email, Password, Confirm Password
- ต้องมี Checkbox ยอมรับเงื่อนไข
- Password ขั้นต่ำ 8 ตัวอักษร, ต้องตรงกับ Confirm Password
- เมื่อสมัครสมาชิกสำเร็จ → นำทางไป Main Shell

### REQ-005: Home / Scan Screen
- ระบบต้องแสดงหน้าหลักพร้อม Header ทักทายผู้ใช้
- ต้องมีปุ่มอัปโหลดรูปภาพ (Card หลัก) เปิด File Picker
- รองรับไฟล์ jpg, jpeg, png, webp ขนาดสูงสุด 10 MB
- ต้องแสดงแถบ Safety Tips (Bento Grid)
- ต้องแสดงรายการประวัติการสแกนล่าสุด 3-5 รายการ
- เมื่อเลือกไฟล์สำเร็จ → นำทางไป Image Crop Screen
- หาก Permission ถูกปฏิเสธ → แสดง PermissionRequestView

### REQ-006: Image Preview & Crop Screen
- ระบบต้องแสดงรูปเต็มหน้าจอพร้อมเครื่องมือ Crop
- ต้องมีปุ่มหมุนภาพ, ปุ่มเปลี่ยนรูป
- ต้องมีปุ่ม "เริ่มวิเคราะห์" ที่ชัดเจน
- เมื่อกด Back หลังแก้ไขแล้ว ต้องถามยืนยันก่อนยกเลิก
- เมื่อยืนยัน → ส่งรูปไป Analysis Loading Screen

### REQ-007: Analysis Loading Screen
- ระบบต้องแสดง Circular Progress Indicator พร้อม % ที่อัปเดตได้
- ต้องแสดง Stepper 3 ขั้นตอน: OCR, Source Check, Visual Analysis
- Polling สถานะ API ทุก 3 วินาที จนได้ผลหรือ Timeout (120 วินาที)
- ต้องแสดงข้อความสถานะแต่ละขั้นตอน
- ต้องแสดง Privacy Badge
- เมื่อวิเคราะห์เสร็จ → นำทางไป Analysis Result Screen
- เมื่อ Timeout หรือ Error → แสดง Error State พร้อมปุ่ม Retry

### REQ-008: Analysis Result Screen
- ระบบต้องแสดง Radial Risk Gauge (SVG semicircle) พร้อมคะแนน 0-100
- ต้องแสดง Risk Badge: ต่ำ (เขียว 0-39), ปานกลาง (เหลือง 40-69), สูง (แดง 70-100)
- ต้องแสดง Summary Card อธิบายผลภาษาธรรมดา
- ต้องแสดง Analysis Bento Grid (2 คอลัมน์)
- ต้องมีปุ่ม: ดูรายละเอียด, ดู Heatmap, รายงานภาพต้องสงสัย, แชร์ผลลัพธ์
- ต้องแสดง Multi-layer Analysis: Textual, Source, Visual

### REQ-009: Heatmap Viewer
- ระบบต้องแสดงภาพ Heatmap ซ้อนทับบนรูปต้นฉบับ
- ต้องมี Toggle ระหว่าง Original / Heatmap
- ต้องมี Slider ปรับความโปร่งใส (Opacity)
- ต้องรองรับ Zoom และ Pan
- ต้องมีปุ่มบันทึก/ดาวน์โหลดภาพ
- ต้องมีคำอธิบายสั้น ๆ ว่าสีร้อนหมายถึงอะไร

### REQ-010: History Screen
- ระบบต้องแสดงรายการประวัติการสแกนทั้งหมด
- ต้องมี Search Bar และ Filter (ระดับความเสี่ยง, วันที่)
- แต่ละรายการต้องแสดง Thumbnail, วันที่, คะแนนความเสี่ยง, Progress Bar
- ต้องรองรับ Swipe to Delete
- ต้องรองรับ Pull to Refresh
- ต้องแสดง Empty State เมื่อไม่มีประวัติ
- เมื่อแตะรายการ → นำทางไป History Detail Screen

### REQ-011: History Detail Screen
- ระบบต้องแสดงผลวิเคราะห์ย้อนหลังในรูปแบบเดียวกับ Analysis Result
- หากภาพต้นฉบับถูกลบ → แสดงเฉพาะ Metadata และคะแนน
- ต้องมีปุ่มสแกนภาพใหม่

### REQ-012: Report Scam Screen
- ระบบต้องแสดงรูปภาพที่ต้องการรายงาน
- ต้องมีรายการประเภทเหตุการณ์ (Dropdown/Chip)
- ต้องมีช่องกรอกรายละเอียด (ขั้นต่ำ 10 ตัวอักษร)
- ต้องมีช่องระบุแพลตฟอร์มที่พบ
- ต้องมีช่องแนบข้อมูลเสริม (URL, ชื่อบัญชี)
- ต้องมี Checkbox ยินยอมการใช้ข้อมูล
- ต้องมีปุ่มส่งรายงาน

### REQ-013: Notifications Screen
- ระบบต้องแสดงรายการแจ้งเตือน: งานวิเคราะห์เสร็จ, งานล้มเหลว, Scam Alert
- เมื่อแตะ Notification งานวิเคราะห์ → เปิด Result Screen
- ต้องรองรับการล้างรายการแจ้งเตือน
- ต้องแสดง Empty State เมื่อไม่มีแจ้งเตือน

### REQ-014: Settings Screen
- ระบบต้องแสดงหัวข้อ: โปรไฟล์, ความปลอดภัย, การแจ้งเตือน, ภาษา, Theme, Privacy, ล้าง Cache, ออกจากระบบ
- ต้องมีปุ่มออกจากระบบพร้อมยืนยัน
- ต้องลบ Token และ Cache เมื่อออกจากระบบ

### REQ-015: User Profile Screen
- ระบบต้องแสดงข้อมูลผู้ใช้: ชื่อ, Email, รูปโปรไฟล์
- ต้องรองรับการแก้ไขชื่อที่แสดง

### REQ-016: Privacy & Consent Screen
- ระบบต้องแสดง Toggle สำหรับ Consent แต่ละประเภท
- ต้องมีปุ่มขอรับสำเนาข้อมูล และลบบัญชี
- การลบบัญชีต้องมีหน้ายืนยันซ้ำ
- ผู้ใช้ถอน Research Consent ได้โดยไม่กระทบการใช้งานพื้นฐาน

---

## 3. Non-Functional Requirements

### REQ-NF-001: Performance
- แอปเปิดถึงหน้าแรกภายใน 3 วินาที
- เลือกไฟล์และเข้า Preview ภายใน 1 วินาที
- บีบอัดภาพอัตโนมัติเมื่อไฟล์ > 10 MB

### REQ-NF-002: Security
- Token เก็บใน Flutter Secure Storage เท่านั้น
- ใช้ HTTPS ทุก API Call
- ลบ Token ทุกครั้งเมื่อออกจากระบบ
- ไม่แสดง Stack Trace หรือข้อความ Error เทคนิคต่อผู้ใช้

### REQ-NF-003: Accessibility
- ปุ่มต้องมีพื้นที่แตะอย่างน้อย 44×44 px
- สีสถานะต้องมีข้อความประกอบเสมอ
- ปุ่ม Icon ต้องมี Semantic Label
- รองรับ Dynamic Font Size เท่าที่ Layout ยังไม่พัง

### REQ-NF-004: Theme & Localization
- รองรับ Dark Mode (ค่าเริ่มต้น) และ Light Mode
- รองรับภาษาไทยเป็นภาษาหลัก
- Font Sarabun สำหรับภาษาไทย/อังกฤษ, Inter สำหรับตัวเลขข้อมูล

### REQ-NF-005: Error Handling
- ทุกหน้าที่เรียก API ต้องมี: Loading State, Error State, Empty State
- Error State ต้องมีปุ่ม Retry เมื่อแก้ได้
- Error State ต้องมีปุ่ม Open Settings เมื่อเกี่ยวกับ Permission

---

## 4. Design Constraints

### 4.1 Design System (จาก HTML Design)
- **Primary Dark Background:** `#0F1720` (bg-dark)
- **Surface Dark:** `#162230` (surface-dark)
- **Primary Accent:** `#006685` (Light) / `#6cd2ff` (Dark inverse-primary)
- **Danger:** `#DC2626` / Error: `#ba1a1a`
- **Warning:** `#d68900` (tertiary-container)
- **Success:** `#006e2d` (secondary)
- **Font:** Sarabun (ทั้งหมด), Inter (ตัวเลข/code)

### 4.2 Architecture Constraints
- Clean Architecture: Presentation → Domain → Data
- State Management: flutter_bloc (BLoC/Cubit)
- HTTP Client: dio
- Secure Storage: flutter_secure_storage
- Image Picker: image_picker
- Router: go_router

### 4.3 Bottom Navigation (4 tabs)
1. หน้าหลัก (home)
2. ประวัติ (history)
3. แจ้งรายงาน (flag)
4. ตั้งค่า (settings)
