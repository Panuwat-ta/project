# ผลทดสอบอัตโนมัติ Mobile — Issue #71 History Detail overflow

## 2026-10-02 02:31 +07 - History Detail overflow regression และ Flutter suite

- Target: `scam_image_mobile/test/features/history/presentation/screens/history_detail_screen_test.dart` และ Flutter test suite ทั้งชุด (60 ไฟล์)
- Command: `cd scam_image_mobile && flutter test --coverage --branch-coverage --reporter=failures-only && flutter analyze lib test`
- Result: PASS
- Summary: Total: 425 | Passed: 425 | Failed: 0 | Skipped: 0 | Duration: ประมาณ 12 วินาทีสำหรับ test suite; analyzer ผ่านใน 1.2 วินาที
- Coverage: ทั้งชุด line 4,090/5,681 (71.99%), branch 978/1,547 (63.22%); History Detail line 339/385 (88.05%), branch 34/53 (64.15%)

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **long source evidence fits within compact mobile width**: หน้าจอขนาด 320x800 ใน dark mode แสดงหลักฐาน Source ยาว 64 รายการต่อเนื่อง โดย `tester.takeException()` ไม่พบ Flutter layout exception หรือ horizontal overflow.
- **missing evidence labels fit within compact mobile width**: เมื่อไม่มี risk factors ที่ 320x800, ป้าย evidence unavailable ของ OCR, Source และ Visual ไม่ทำให้เกิด `RenderFlex overflow`.
- **History Detail fits in landscape dark mode**: หน้าจอ 800x360 ใน dark mode แสดงหลักฐาน Source ที่มี URL ยาวโดยไม่มี exception.
- **History Detail test suite และ Flutter test suite**: ผ่าน 425/425 tests, ไม่มี failed หรือ skipped; `flutter analyze lib test` แสดง `No issues found!`.
- **Coverage**: LCOV มีข้อมูล branch ของ History Detail 53 branches และพบการทำงาน 34 branches; ตัวเลขนี้วัดจาก test suite หลังแก้ ส่วน coverage ทั้งชุดยังต่ำกว่า NFR-09 ที่กำหนด 80%.

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

- Automated tests: ไม่มีข้อผิดพลาด (0 Failed), 0 Skipped.
- Branch coverage gate NFR-09: ยังไม่ผ่านเกณฑ์ทั้งชุด; ได้ 63.22% (978/1,547) เทียบกับเป้าหมาย 80%. เป็น coverage gap ไม่ใช่ test failure.

### สรุป defect และการแก้

ก่อนแก้ regression test ขนาด 320x800 พบ `RenderFlex overflowed by 85 pixels on the right` ที่ OCR summary row; กรณีไม่มี factors ยังพบ overflow อีกสามตำแหน่งใน header ของ OCR, Source และ Visual จากข้อความ evidence unavailable ที่ไม่มีข้อจำกัดความกว้าง. เปลี่ยน OCR summary จาก `Row` เป็น `Wrap` และจำกัดข้อความ fallback ด้วย `Flexible`; เพิ่ม regression tests สำหรับหลักฐานยาว, ไม่มี factors และ landscape dark mode.

ไม่ได้ทดสอบ manual บนอุปกรณ์จริงหรือ emulator ในรอบนี้.
