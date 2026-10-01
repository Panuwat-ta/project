# ผลทดสอบอัตโนมัติ Mobile — ตรวจสอบฟังก์ชันและ coverage

## 2026-10-02 01:16 +07 - Mobile Flutter test suite

- Target: `scam_image_mobile/test/` ทั้งชุด (59 ไฟล์ทดสอบ)
- Command: `cd scam_image_mobile && flutter test --coverage --branch-coverage --reporter=failures-only`
- Result: PASS
- Summary: Total: 417 | Passed: 417 | Failed: 0 | Skipped: 0 | Duration: ประมาณ 25 วินาที
- Requirement/TC mapping: TC IDs: TC-MOB-01 ถึง TC-MOB-87 (ชุด manual สำหรับการตรวจบนอุปกรณ์) | Requirement IDs: FR-AUTH-01 ถึง FR-AUTH-04, FR-SCAN-01 ถึง FR-SCAN-03, FR-ANALYSIS-01 ถึง FR-ANALYSIS-04, FR-XAI-01, FR-HISTORY-01 ถึง FR-HISTORY-02, FR-PDPA-01, NFR-06, NFR-08; mapping ราย test อัตโนมัติไม่ได้บันทึกในผล runner
- Commit/Build/Env: commit `c3bc72235d6890c962e967360443aedbeecef617` | build `1.0.0+1` | model `ไม่ได้บันทึกในผลรัน` | env `ไม่ได้บันทึกในผลรัน`; ports ไม่ได้บันทึก

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **ชุด Flutter tests ทั้ง 59 ไฟล์**: ผ่านครบ 417 tests โดยไม่มี failed หรือ skipped tests ครอบคลุม unit, BLoC, data/model และ widget tests ตามไฟล์ที่มีใน `test/`; คำสั่งจบด้วย `All tests passed!` และไม่มี failure output
- **Branch coverage**: เก็บผลใน `coverage/lcov.info` ได้ 920 จาก 1,546 branches (59.51%); line coverage 3,575 จาก 5,679 (62.95%)
- **Static analysis**: รัน `flutter analyze` แยกต่างหาก ได้ผล `No issues found!`

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

- Automated tests: ไม่มีข้อผิดพลาด (0 Failed), 0 Skipped
- Coverage target: ไม่ผ่านเกณฑ์ NFR-09 ที่ต้องไม่น้อยกว่า 80% — branch coverage ปัจจุบัน 59.51% ต่ำกว่าเป้าหมาย 20.49 จุดเปอร์เซ็นต์
- Test gap จากการตรวจรายการไฟล์: ยังไม่พบ screen-level widget test เฉพาะสำหรับ `HomeScreen`, `ImageCropScreen`, `NotificationsScreen`, `UserProfileScreen` และ `PrivacyConsentScreen`; การผ่านของ suite จึงไม่ยืนยันพฤติกรรม UI เฉพาะของห้าหน้านี้

การตรวจครั้งนี้ไม่ได้รัน manual cases บนอุปกรณ์จริงหรือ emulator; สถานะทั้ง 87 เคสใน `tests_all/manual_tests/test_cases_mobile.md` ยังคงเป็น `To Do`.

## 2026-10-02 01:41 +07 - Mobile screen-level widget tests

- Target: `scam_image_mobile/test/` ทั้งชุด (60 ไฟล์ทดสอบ)
- Command: `cd scam_image_mobile && flutter test --branch-coverage --reporter=failures-only`
- Result: PASS
- Summary: Total: 422 | Passed: 422 | Failed: 0 | Skipped: 0 | Duration: ประมาณ 26 วินาที
- เพิ่มจากรอบก่อน 5 tests สำหรับ HomeScreen, ImageCropScreen, NotificationsScreen, UserProfileScreen และ PrivacyConsentScreen
- Line coverage จาก `coverage/lcov.info`: 4,087/5,678 (71.98%). แม้เปิด `--branch-coverage` แล้ว LCOV รอบนี้ไม่มี branch records (`BRDA`/`BRF`/`BRH`) จึงไม่รายงาน branch coverage ปัจจุบัน; ค่า 59.51% ข้างต้นเป็นผลจากรอบ 417 tests เวลา 01:16 เท่านั้น
- Static analysis: `flutter analyze lib test` ผ่าน โดยแสดง `No issues found!`

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **HomeScreen renders upload and safety sections and requests history**: แสดง control อัปโหลดและแจ้งเตือน และเรียก HistoryRepository ด้วย page 1, limit 100 ตามที่ HistoryBloc กำหนด
- **ImageCropScreen exposes zoom and reset actions for missing image**: preview ชี้ไปยัง path ที่ส่งเข้าจริง; Zoom เปลี่ยน scale จาก 1.0 เป็น 1.5 และ Reset คืนเป็น 1.0
- **NotificationsScreen shows empty state after empty history loads**: เมื่อ HistoryRepository คืนรายการว่าง หน้าแจ้งเตือนแสดง empty state โดยไม่มี exception
- **UserProfileScreen renders authenticated identity and unsupported action**: ชื่อและอีเมลตรงกับ Authenticated user; action ที่ยังไม่รองรับแจ้งข้อความ coming soon
- **PrivacyConsentScreen reports unavailable when service rejects request**: เมื่อ export service โยน error หน้าแสดงข้อความ unavailable และเรียก repository หนึ่งครั้ง ไม่มี success ปลอม
- **ทั้งชุด Flutter tests**: 422 ผ่าน, 0 failed, 0 skipped; analyzer ไม่พบ issue

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

- Automated tests: ไม่มีข้อผิดพลาด (0 Failed), 0 Skipped
- Branch coverage รอบล่าสุด: ไม่สามารถคำนวณจาก LCOV ที่สร้างได้ เพราะไม่มีข้อมูล branch records; ไม่ถือเป็น test failure และไม่ได้อนุมานค่าแทน
- Manual execution: ไม่ได้รันบนอุปกรณ์จริงหรือ emulator; manual cases 87 เคสยังเป็น `To Do`
