# ผลทดสอบอัตโนมัติ Mobile — Issue #72 NotificationsScreen harness

## 2026-10-02 02:55 +07 - Notification flows และ Flutter suite

- Target: `scam_image_mobile/test/features/notifications/presentation/screens/notifications_screen_test.dart` และ Flutter test suite ทั้งชุด (61 ไฟล์)
- Command: `cd scam_image_mobile && flutter test --coverage --branch-coverage --reporter=failures-only && flutter analyze lib test`
- Result: PASS
- Summary: Total: 432 | Passed: 432 | Failed: 0 | Skipped: 0 | Duration: ประมาณ 15 วินาทีสำหรับ test suite; analyzer ผ่านใน 2.2 วินาที
- Coverage: ทั้งชุด line 4,243/5,681 (74.69%), branch 1,013/1,547 (65.48%); `notifications_screen.dart` line 193/204 (94.61%), branch 45/51 (88.24%)

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

Widget tests 8 เคสใน harness ใหม่ใช้ `_MockHistoryBloc` และ stream ที่ควบคุมได้ ไม่เรียก HistoryRepository จริงหรือรอ `HistoryBloc` async load; setup ใช้ pump เฟรมที่จำเป็นแทนการ settle ตามจังหวะของ bloc:

- **HistoryEmpty**: แสดงหัวข้อและคำอธิบายสถานะว่าง และไม่ส่ง `HistoryLoaded` ซ้ำ.
- **HistoryDataLoaded**: สร้างรายการ completed, high-risk และ failed; รายการ processing ไม่กลายเป็น notification; title/body และ type ใน NotificationsCubit ตรงกับ input.
- **Today / Yesterday / Earlier**: แสดงกลุ่มตามวันครบทั้งสามกลุ่มจากวันที่ของ fixture.
- **HistoryError**: เมื่อ history stream ส่ง error หลังมีข้อมูลแล้ว รายการเดิมยังแสดงและอยู่ใน NotificationsCubit.
- **Tap with scanId**: แตะรายการแล้วเปลี่ยน `isRead` เป็น true และเปิด `/result/:scanId` ด้วยค่า scanId ที่ส่งมา.
- **Tap without scanId**: แตะรายการแล้วเปลี่ยนเป็น read โดยยังอยู่หน้า Notifications.
- **Dismiss**: swipe รายการแล้วนำออกจากทั้ง state และ UI พร้อมแสดง empty state.
- **Clear All**: ล้างรายการทั้งหมดใน state และแสดง empty state.
- **Repeatability**: รัน test file นี้แยก 5 รอบ รอบละ 8 tests ผ่านครบ 40/40; full suite ผ่าน 432/432 และ `flutter analyze lib test` แสดง `No issues found!`.

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

- Final automated tests: ไม่มีข้อผิดพลาด (0 Failed), 0 Skipped.
- ระหว่างสร้าง harness รอบแรก test setup ล้มเพราะไม่ได้ลงทะเบียน Mocktail fallback สำหรับ `HistoryEvent`; ลงทะเบียน fake event แล้วรันชุดเดิมผ่าน รอบนี้เป็นข้อผิดพลาดของ test setup ที่แก้แล้ว ไม่ใช่ failure ของ Flutter suite สุดท้าย.
- Coverage gate NFR-09 ทั้งชุดยังไม่ผ่าน: branch 65.48% (1,013/1,547) ต่ำกว่าเป้าหมาย 80%; branch coverage ของ NotificationsScreen คือ 88.24% (45/51).

ไม่ได้รัน manual test บนอุปกรณ์จริงหรือ emulator ในรอบนี้.
