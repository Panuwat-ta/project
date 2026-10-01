## 2026-10-01 18:30 +07 - Mobile: เปลี่ยนชื่อ field เป็น manipulationConfidence + build APK ใหม่

- Target: `scam_image_mobile` (เต็มชุด `flutter test`), ไฟล์ `lib/core/storage/database_helper.dart`, test 4 ไฟล์
- Command: `flutter test` | `flutter build apk --debug` | `flutter analyze lib/`
- Result: PASS
- Summary: Total: 415 | Passed: 415 | Failed: 0 | Skipped: 0 | Duration: ~10 วินาที (test), ~29 วินาที (build)

### บริบทของการทดสอบ

รอบนี้ปรับ mobile ให้ตรงกับสัญญา API ใหม่หลัง server เปลี่ยนชื่อ field `ai_gen_probability` เป็น `manipulation_confidence`:
- entity/model/datasource/history screen ใช้ `manipulationConfidence`
- SQLite เพิ่ม migration v4 เป็น v5 ที่ rename คอลัมน์ `aiGenProbability` เป็น `manipulationConfidence` ตั้งค่าเดิมเป็น NULL (ไม่ย้ายค่า max-prob เก่ามาใช้)
- localization ไทย/อังกฤษ: "ความม่ันใจว่าถูกดัดแปลง" / "Manipulation confidence"

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **test/core/storage/database_helper_test.dart** (3 เคส) — หลังแก้โค้ดและ test ผ่านครบ:
  - พฤติกรรมที่ผ่าน: schema ล่าสุดมี `manipulationConfidence`; ตารางเก่าที่มี `aiGenProbability` เมื่อ migrate ผ่าน v5 จะถูก rename เป็นชื่อใหม่และไม่มีชื่อเดิมเหลือ; test ที่ migrate ข้ามหลายเวอร์ชัน (v2→v5, v3→v5) ตรวจทั้งชื่อใหม่ที่ต้องมีและชื่อเก่าที่ต้องหาย
  - เหตุผลที่ผ่าน: migration ใช้ `RENAME COLUMN` จริงของ SQLite และตั้งค่าเดิมเป็น NULL ตามที่ออกแบบ

- **test/features/result/data/models/analysis_result_model_test.dart** — หลังแก้ expect ผ่าน:
  - พฤติกรรมที่ผ่าน: `fromJson` อ่าน `manipulation_confidence: 0.85` จาก JSON ของ server ได้ `manipulationConfidence = 0.85`; ป้าย details แสดงเป็น "ความม่ันใจว่าถูกดัดแปลง: 85%"
  - เหตุผลที่ผ่าน: model map key ใหม่ของ server ได้ถูกต้องทั้งค่าและป้ายแสดงผล

- **test/core/storage/local_cache_datasources_test.dart**, **test/features/history/.../history_detail_screen_test.dart**:
  - พฤติกรรมที่ผ่าน: อ่าน/เขียน local cache ด้วยชื่อ field ใหม่ และหน้าประวัติแสดงค่าถูกต้อง
  - เหตุผลที่ผ่าน: เปลี่ยนชื่อ field ทุกจุดที่แตะ entity เดียวกันอย่างครบถ้วน

- **test ที่เหลือทั้งชุด (~400 เคส)**:
  - พฤติกรรมที่ผ่าน: ผ่านทั้งหมด ไม่มี regression นอกเหนือจุดที่เปลี่ยน
  - รวม widget/smoke test ของแอปที่ render ได้โดยไม่มี error

### 2. ข้อผิดพลาดที่พบระหว่างทำและวิธีแก้ (ล้มก่อน 6 เคส แล้วแก้จนผ่านหมด)

ระหว่างทำมี test ล้ม 6 เคส แบ่งเป็น 3 กลุ่ม และแก้ที่ต้นเหตุทั้งหมด (ไม่ได้ปิด test หรือแก้ expect ให้หลวม):

1. **โค้ด production เพิ่มคอลัมน์ผิดชื่อ (1 จุด)**: migration v4 ใน `database_helper.dart` ถูกเปลี่ยนจาก `aiGenProbability` เป็น `manipulationConfidence` ทำให้ตารางที่ migrate จาก v3 ผ่าน v4 แล้วไป v5 มีทั้งสองคอลัมน์ การ rename ที่ v5 จึงไม่เกิดผล
   - วิธีแก้: คืน v4 ให้สร้างชื่อเดิมตามที่ v4 เคยสร้างจริง (`aiGenProbability`) เพราะ v5 จะ rename ให้เอง
   - ผล: database_helper_test 3 เคสผ่าน

2. **test ยังใช้ชื่อ field เก่า (3 ไฟล์)**: `analysis_result_model_test.dart`, `history_detail_screen_test.dart`, `local_cache_datasources_test.dart` มีบรรทัดอ้าง `aiGenProbability` รวม 11 จุด ทำให้ compile ล้ม
   - วิธีแก้: เปลี่ยนเป็น `manipulationConfidence` / `manipulation_confidence` ตามชั้นที่อ้าง

3. **expect ป้ายแสดงผลเก่า (1 จุด)**: expect ข้อความ details มี `0.85` แต่โค้ดใหม่แสดงเป็น `85%`
   - วิธีแก้: เปลี่ยน expect ให้ตรวจ `85%` และ `ความม่ันใจว่าถูกดัดแปลง` ซึ่งเป็นพฤติกรรมใหม่ที่ถูกต้อง ไม่ใช่การหลอก test

### 3. ผล build APK

- Command: `flutter build apk --debug`
- Result: ผ่าน ใช้เวลา 28.7 วินาที
- Output: `build/app/outputs/flutter-apk/app-debug.apk` (สร้างใหม่ ต.ค. 1 18:xx แทนไฟล์เดิม 17:46)
- ไฟล์นี้นำไปติดตั้งบนอุปกรณ์ Android ได้ทันที

### 4. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed)

### 5. หมายเหตุ

- APK เป็น build ชนิด debug เหมาะสำหรับทดสอบ ไม่ใช่ release
- ไม่มีอุปกรณ์ Android เชื่อมต่อ (`flutter devices` พบแค่ Linux และ Chrome) จึงทดสอบแบบ unit/widget เท่านั้น ไม่ได้รันบนอุปกรณ์จริงหรือ emulator
- server ต้องรันด้วย det7b (ตาม `server/.env` ปัจจุบัน) mobile จึงจะได้ค่า `manipulation_confidence` กลับมา

### 6. ผลทดสอบบนอุปกรณ์จริง (RMX3370, Android 13, arm64)

- อุปกรณ์: RMX3370 (Realme) ผ่าน USB (`f9a12239`)
- ติดตั้ง: `adb install -r build/app/outputs/flutter-apk/app-debug.apk` สำเร็จ
- เปิดแอป: `MainActivity` เป็น topResumedActivity, `FATAL EXCEPTION` = 0 (error ใน log มีแค่ system noise ของ Oppo)
- เครือข่าย: มือถือ ping `10.202.12.70` ได้ (0% loss) และ `curl http://10.202.12.70:8000/health` ตอบ `{"status":"ok",...}` — ตรงกับ `API_BASE_URL` ใน mobile `.env`
- Integration test (`integration_test/app_test.dart`) บนเครื่องจริง: **ผ่าน** (`All tests passed!`) ครอบคลุม onboarding → login → home → history → settings → logout โดยยิง API จริง (`/api/v1/history` ปรากฏใน log)

#### ปัญหาที่พบระหว่างทดสอบบนเครื่องและวิธีแก้

1. **`flutter install` ถอนแอปเก่าแล้วล้ม**: คำสั่งพยายามติดตั้ง `app-release.apk` ที่ไม่มีอยู่ (build ไว้แค่ debug) หลังจากถอนเวอร์ชันเก่าออกไปแล้ว ทำให้แพ็กเกจหายจากเครื่องชั่วคราว
   - วิธีแก้: ติดตั้งด้วย `adb install -r app-debug.apk` โดยตรงแล้วยืนยันด้วย `pm list packages`
2. **integration test ล้มครั้งแรกเพราะ DB ว่าง**: test login ด้วย `test@example.com` แต่ตาราง users ถูกล้างเหลือ 0 แถว (ตามคำสั่งลบข้อมูลทดสอบ) แอปจึงค้างที่หน้าจอ login และหาไอคอน upload บนหน้า Home ไม่เจอ
   - วิธีแก้: สร้าง `test@example.com` ชั่วคราวผ่าน `/api/v1/auth/register` แล้วรันใหม่จึงผ่าน หลังเสร็จลบ user 104 ออก (0 scans เพราะ test แค่ navigate) คืนสถานะ DB ว่าง
3. **พบ user 103 (`test1@scamguard.com`) เกินมา 1 คน**: ไม่มี scans ผูกอยู่ ลบออกแล้ว users เหลือ 0 ตามเดิม

#### ข้อจำกัดของการทดสอบบนเครื่อง

- ไม่ได้ทดสอบ flow สแกนภาพจริงบนเครื่อง (integration test ปัจจุบันครอบคลุมแค่ auth + navigation) การสแกนภาพจริงตรวจสอบผ่าน API โดยตรงแล้ว (กล้องจริง 16 low / splicing 100 high)
- ต้องสร้าง user ทดสอบชั่วคราวเพื่อรัน integration test ทุกครั้งที่ DB ว่าง
