## 2026-10-02 06:31 +07 - Auth hardening และ regression ทั้งแอป

- Target: `scam_image_mobile/test/`
- Command: `flutter test --coverage --branch-coverage --reporter expanded` จาก `scam_image_mobile/`
- Result: PASS
- Summary: Total: 670 | Passed: 670 | Failed: 0 | Skipped: 0 | Duration: 25 วินาทีตาม runner
- Coverage: Lines 5,214/5,706 (91.38%) | Branches 1,305/1,563 (83.49%) คำนวณ branch จาก BRDA ใน LCOV
- Flutter 3.47.2 / Dart 3.13.2

### 1. รายการที่ผ่าน และพฤติกรรมที่ผ่าน

- Auth viewport matrix 144 กรณี: สี่หน้า × สาม viewport × text scale สามระดับ × สอง theme × TH/EN ไม่มี layout exception; password toggle มี label และพื้นที่กด >=48dp; landscape จำลอง keyboard inset 120dp
- Onboarding success/failure/retry สองกรณี: ระหว่างรอ persistence ปุ่มถูกปิดและเรียก updateConsents ครั้งเดียว; failure ไม่ mark onboarding/ไม่เปลี่ยน route, ลองใหม่แล้วเปลี่ยนไป Login เมื่อบันทึกสำเร็จ
- Auth concurrent requests: duplicate Login/Register และ Register ขณะ Login pending ไม่เรียก repository เพิ่ม; failure คืนสถานะให้ลองใหม่สำเร็จ
- Regression เดิมของ network/storage/models/repositories/BLoC/router และหน้าจอทั้งหมดผ่าน assertions เดิม; smoke test ตรวจ brand ScamGuard ที่ Splash

### 2. รายการที่ไม่ผ่าน และสาเหตุ

- รอบสุดท้าย: ไม่มีข้อผิดพลาด (0 Failed)
- รอบแรกของ matrix 54 กรณี: ผ่าน 24, ไม่ผ่าน 30 เพราะ Register badge/แถว Login และ Onboarding overflow; แก้ Wrap/scroll/Flexible และลบข้อความ encryption ที่ไม่มีหลักฐาน
- หลังแก้ครั้งแรก: focused matrix+BLoC ผ่าน 62 ไม่ผ่าน 2 เนื่องจาก Onboarding action overflow 12px ที่ scale1.5; เพิ่ม Flexible แล้วผ่าน
- Full suite รอบก่อนสุดท้าย: ผ่าน 669 ไม่ผ่าน 1 เพราะ smoke test ยังหา brand เดิม `Scam Image Detection`; อัปเดต assertion ให้ตรง Splash ที่ใช้ชื่อ ScamGuard แล้วรันใหม่ครบ 670 ผ่าน

### Verification และขอบเขต

- `flutter analyze` ใน mobile: 0 issues ก่อน full suite; ตรวจซ้ำหลังจัดรูปแบบ
- `git -c core.whitespace=cr-at-eol diff --check` ผ่าน; Splash รักษา CRLF
- Widget tests จำลอง MediaQuery/viewport จึงไม่พิสูจน์ TalkBack, predictive back, rotation หรือ keyboard จริงบน Android; รายการเหล่านี้ยังอยู่ Issue #77
