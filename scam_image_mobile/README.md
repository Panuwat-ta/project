# ScamGuard Mobile App

ScamGuard เป็นแอปพลิเคชัน Flutter สำหรับ Android ที่ช่วยให้ผู้ใช้ทั่วไปสามารถตรวจสอบความน่าเชื่อถือของรูปภาพก่อนนำไปใช้ตัดสินใจ เช่น ภาพที่ใช้ในการหลอกลวงทุกประเภท เช่น romance scam ภาพตัดต่อ เอกสารปลอม ภาพ AI-generated และสกรีนช็อต/สลิปปลอม แอปส่งรูปภาพไปยัง Backend API เพื่อวิเคราะห์และแสดงผลระดับความเสี่ยงในรูปแบบที่เข้าใจง่าย

## ฟีเจอร์หลัก (Key Features)

* **อัปโหลดและวิเคราะห์รูปภาพ**: อัปโหลดรูปภาพสลิปโอนเงินหรือแชทเพื่อตรวจสอบความเสี่ยง 
* **ผลลัพธ์ที่เข้าใจง่าย**: แสดงผลในรูปแบบคะแนนความเสี่ยง (Risk Score) พร้อม Heatmap ชี้จุดที่น่าสงสัย
* **ประวัติการตรวจสอบ**: บันทึกและเรียกดูประวัติการตรวจสอบย้อนหลังได้ตลอดเวลา
* **การรายงาน (Report)**: ผู้ใช้สามารถช่วยรายงานภาพต้องสงสัยหรือรูปแบบกลโกงใหม่ๆ
* **ระบบความปลอดภัยและความเป็นส่วนตัว**: Token ใช้ secure storage; Privacy preferences ปัจจุบันเก็บบนอุปกรณ์และยังไม่เปลี่ยน server consent; export/delete usage ยังไม่รองรับ
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
- Flutter SDK `3.47.2` / Dart `3.13.2` (เวอร์ชันที่ตรวจในรอบ hardening นี้; ดู Dart constraint ใน pubspec.yaml)
- Dart SDK
- Android Studio สำหรับ Android Emulator (v1 รองรับ **Android เท่านั้น** ไม่ต้องใช้ Xcode/Simulator)

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
   สร้างไฟล์ `.env` จากตัวอย่าง หากยังไม่มี แล้วแก้ `API_BASE_URL` ให้ตรงกับอุปกรณ์:
   ```bash
   test -f .env || cp .env.example .env
   python3 tool/run_dev.py -- --device-id <device-id>
   ```
   runner อ่านเฉพาะ `API_BASE_URL` จาก `.env`, ตรวจ URL และส่งค่าเป็น Dart define สำหรับ `APP_ENV=development`; ไม่ source ทั้งไฟล์และไม่ bundle `.env` หรือ key อื่นในแอป หากต้องใช้ไฟล์จากตำแหน่งอื่น ให้เพิ่ม `--env-file <path>` ก่อน `--`

   Android Emulator ใช้ `http://10.0.2.2:8000/api/v1`; เครื่องจริงใช้ LAN address ของ backend ที่มือถือเข้าถึงได้ และห้ามใช้ `localhost`/`127.0.0.1` แทน host backend ตรวจ config โดยไม่แสดง URL ได้ด้วย `python3 tool/run_dev.py --check-config`

   สำหรับ profile บนเครื่องจริง ใช้ `python3 tool/run_dev.py -- --profile --device-id <device-id>` Development HTTP อนุญาตเฉพาะ debug/profile; staging/production ต้อง HTTPS ทุก build mode และใช้ release pipeline ที่กำหนดไว้ด้านล่าง


### การ Build สำหรับ Production

ต้องกำหนด `SCAMGUARD_PRODUCTION_API_URL` เป็น HTTPS URL จริงก่อน build; คำสั่งตัวอย่างไม่ใช่ production configuration ที่ยืนยันแล้ว ห้ามใส่ token/password ใน dart defines เพราะค่าที่ compile เข้าแอปอ่านจาก artifact ได้

Production build ต้องตั้ง environment: `SCAMGUARD_APPLICATION_ID`, `SCAMGUARD_KEYSTORE_PATH`, `SCAMGUARD_KEY_ALIAS`, `SCAMGUARD_STORE_PASSWORD`, `SCAMGUARD_KEY_PASSWORD` จาก secure local environment/CI secrets โดยไม่ commit key/password

เมื่อขาด identity/signing build จะหยุด ไม่ใช้ debug key แทน; `SCAMGUARD_ALLOW_UNSIGNED_QUALITY_BUILD=true` ใช้เฉพาะ compile gate ที่สร้าง unsigned artifact และไม่ใช่ Release Candidate

**Android (APK):**
```bash
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL="$SCAMGUARD_PRODUCTION_API_URL"
```

**Android (App Bundle):**
```bash
flutter build appbundle --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL="$SCAMGUARD_PRODUCTION_API_URL"
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
