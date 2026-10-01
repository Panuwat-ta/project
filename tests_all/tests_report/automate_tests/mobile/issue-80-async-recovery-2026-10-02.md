## 2026-10-02 06:42 +07 - Offline, retry และ async recovery

- Target: Mobile repositories/BLoC/screens และ full suite
- Command: `flutter test --coverage --branch-coverage --reporter expanded` จาก `scam_image_mobile/`
- Result: PASS
- Summary: Total: 684 | Passed: 684 | Failed: 0 | Skipped: 0 | Duration: 111 วินาทีตาม runner
- Coverage: Lines 5,291/5,794 (91.32%) | Branches 1,330/1,600 (83.13%) จาก LCOV BRDA
- เพิ่ม lifecycle test หลัง full suite; รัน `flutter test test/features/scan/presentation/bloc/scan_bloc_test.dart --reporter expanded` ผ่าน 20/20 ใช้ 0 วินาทีตาม runner; จึงไม่อ้างว่า full suite รอบเดิมรวม test ใหม่นี้

### 1. รายการที่ผ่าน และพฤติกรรมที่ผ่าน

- Scan: คำขอภาพเดิมขณะ upload/polling ไม่อัปโหลดซ้ำ; cancel แล้วเริ่มใหม่ได้; newer upload/cancel ทำให้ response เก่าถูกทิ้ง
- Timeout: deadline แยกจาก polling ทำให้ timeout แม้ไม่มี polling tick; Retry ใช้ canonical task เดิมผ่าน AnalysisResumed โดย repository.submitImage ถูกเรียกครั้งเดียว
- Polling: จำกัด overlapping requests, transient network failure ยังติดตาม task, completion/failure/timeout/cancel/close ยกเลิก timers
- Result: late success/error ของ load เก่าไม่ทับผลใหม่; concurrent polls เรียกครั้งเดียว; task เก่าถูกละทิ้ง; ออกจากหน้าจอหยุด polling และ invalidate response ที่ยังรอ
- History: late search ไม่ทับ query ใหม่; fallback cache เฉพาะ NetworkException; AuthException/404/503/ValidationException คง error เดิมและไม่อ่าน cache; cache write failure ไม่ทิ้ง fresh response
- Report: ระหว่าง pending ส่งเพียงครั้งเดียว; failure ไม่ประกาศ success และ retry สำเร็จได้
- Lifecycle: ส่ง Flutter paused/resumed ขณะมี task แล้ว completion ยังใช้ task เดิม และไม่ submit เพิ่ม
- Regression ทั้ง models/router/storage/network/UI รวมกรณี malformed/partial/missing evidence และ authoritative errors ผ่าน

### 2. รายการที่ไม่ผ่าน และสาเหตุ

- รอบสุดท้าย: ไม่มีข้อผิดพลาด (0 Failed)
- Focused รอบก่อนหน้าหลังเพิ่ม dispose guard: mock ResultBloc ไม่ stub isClosed ทำให้ null แปลงเป็น bool ไม่ได้ตอน unmount; แก้ test mock ให้แทน open bloc จริง แล้ว focused Result ผ่าน 29/29 และ full suite ผ่าน
- Analyzer เคยแจ้ง curly braces ใน guard; แก้แล้ว mobile analyzer รอบสุดท้าย 0 issues

### ขอบเขตหลักฐาน

- Lifecycle test ใช้ Flutter binding จำลอง paused/resumed ไม่ใช่ process kill/OS recreation หรือ physical network switching; native QA และ soak ยังอยู่ #77/#81
- ไม่มีการ resend POST อัตโนมัติ; หาก upload ล้มเหลวก่อนรับ ID การกด Retry โดยผู้ใช้เป็นการร้องขอใหม่และ backend ยังไม่มี idempotency-key contract ที่ยืนยันแล้ว
