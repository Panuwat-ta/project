# ScamGuard Mobile App

ScamGuard เป็นแอปพลิเคชัน Flutter สำหรับ Android ที่ช่วยให้ผู้ใช้ทั่วไปสามารถตรวจสอบความน่าเชื่อถือของรูปภาพก่อนนำไปใช้ตัดสินใจ เช่น รูปสลิปโอนเงิน หลักฐานการชำระเงิน คิวอาร์โค้ด หรือเอกสารที่ส่งมาทางโซเชียลมีเดีย แอปส่งรูปภาพไปยัง Backend API เพื่อวิเคราะห์และแสดงผลระดับความเสี่ยงในรูปแบบที่เข้าใจง่าย

## ฟีเจอร์หลัก (Key Features)

* **อัปโหลดและวิเคราะห์รูปภาพ**: อัปโหลดรูปภาพสลิปโอนเงินหรือแชทเพื่อตรวจสอบความเสี่ยง 
* **ผลลัพธ์ที่เข้าใจง่าย**: แสดงผลในรูปแบบคะแนนความเสี่ยง (Risk Score) พร้อม Heatmap ชี้จุดที่น่าสงสัย
* **ประวัติการตรวจสอบ**: บันทึกและเรียกดูประวัติการตรวจสอบย้อนหลังได้ตลอดเวลา
* **การรายงาน (Report)**: ผู้ใช้สามารถช่วยรายงานภาพต้องสงสัยหรือรูปแบบกลโกงใหม่ๆ
* **ระบบความปลอดภัยและความเป็นส่วนตัว**: การจัดการ Consent และข้อมูลผู้ใช้อย่างรัดกุมตามหลัก Privacy-by-design
* **รองรับ 2 ภาษา (Localization)**: รองรับการใช้งานภาษาไทยและภาษาอังกฤษ

## สถาปัตยกรรม (Architecture)

แอปพลิเคชันใช้ **Clean Architecture** แบ่งออกเป็น 3 ชั้นในแต่ละฟีเจอร์:
- **Presentation Layer**: Flutter widgets, BLoC/Cubit, Screens
- **Domain Layer**: Entities, Repository interfaces, Use cases
- **Data Layer**: Repository implementations, Remote datasources, Models

**State Management**: ใช้ `flutter_bloc` (BLoC pattern + Cubit)
**Routing**: ใช้ `go_router`
**Dependency Injection**: ใช้ Custom ServiceLocator (`injection_container.dart`)

## โครงสร้างโฟลเดอร์หลัก

```
lib/
  core/
    constants/     (โทเคนสี, ตัวอักษร, Spacing)
    di/            (ServiceLocator - Dependency Injection)
    errors/        (Exception และ Failure handling)
    localization/  (ระบบหลายภาษา)
    network/       (Dio Client, API Endpoints, Interceptors)
    router/        (การตั้งค่า Route ด้วย go_router)
    storage/       (Secure Storage เก็บ Token)
    theme/         (Light/Dark Theme)
    utils/         (Utility functions)
    widgets/       (Shared UI components ที่ใช้ร่วมกัน)
  features/
    auth/          (เข้าสู่ระบบ, สมัครสมาชิก, จัดการ Session)
    history/       (ประวัติการสแกน)
    notifications/ (การแจ้งเตือน)
    report/        (การรายงานรูปภาพ)
    result/        (แสดงผลลัพธ์แบบ Heatmap/Gauge)
    scan/          (สแกนภาพ, อัปโหลดภาพ)
    settings/      (ตั้งค่าระบบ, ธีม, เปลี่ยนภาษา)
  main.dart        (จุดเริ่มต้นของแอป)
```

## การติดตั้งและการใช้งาน (Getting Started)

### ความต้องการของระบบ (Prerequisites)
- Flutter SDK `^3.12.2` (หรือเวอร์ชันที่รองรับ)
- Dart SDK
- Android Studio / Xcode (สำหรับทดสอบบน Emulator / Simulator)

### ขั้นตอนการติดตั้ง

1. **โคลนโปรเจกต์**
   ```bash
   git clone <repository_url>
   cd scam_image_mobile
   ```

2. **ติดตั้ง Dependencies**
   ```bash
   flutter pub get
   ```

3. **รันแอปพลิเคชัน (Development)**
   รันแอปพลิเคชันโดยสามารถกำหนด URL ของ API Backend ผ่าน Environment Variable ได้:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://localhost:8000
   ```
   *(หมายเหตุ: ค่าเริ่มต้นหากไม่ได้กำหนด `API_BASE_URL` คือ `http://localhost:8000`)*

### การ Build สำหรับ Production

**Android (APK):**
```bash
flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com
```

**Android (App Bundle):**
```bash
flutter build appbundle --dart-define=API_BASE_URL=https://api.yourdomain.com
```


## การทดสอบ (Testing)

โปรเจกต์นี้มี Unit Test และ Widget Test ในโฟลเดอร์ `test/`
คำสั่งสำหรับการรันเทสต์ทั้งหมด:
```bash
flutter test
```

## ไลบรารีหลักที่ใช้งาน (Dependencies)
* **flutter_bloc**: State management
* **go_router**: Navigation และ Routing
* **dio**: Network / HTTP Client
* **flutter_secure_storage**: เก็บ Token อย่างปลอดภัย (Encrypted)
* **image_picker** & **image_cropper**: เลือกและจัดการรูปภาพ
* **google_fonts**: ใช้งานฟอนต์ Sarabun และ Inter
* **share_plus**: แชร์ผลลัพธ์
* **flutter_svg**: แสดงผลไอคอนแบบ SVG
