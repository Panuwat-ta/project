# ผลทดสอบอัตโนมัติ Mobile — Issue #73 (ความคืบหน้า)

## 2026-10-02 03:50 +07 — เพิ่ม behavior tests หลายหน้าจอและแก้ Profile dialog lifecycle

- Target: Settings, Image Crop, History Detail, Analysis Loading, Report Scam, Home, User Profile, Privacy Consent, History, Analysis Result, Heatmap Viewer และ Flutter test suite ทั้งชุด
- Command: `cd scam_image_mobile && flutter test --coverage --branch-coverage --reporter=failures-only && flutter analyze lib test`
- Result: PASS
- Summary: Total 456 | Passed 456 | Failed 0 | Skipped 0; `flutter analyze lib test` ผ่านและแสดง `No issues found!`; `git diff --check` ผ่าน
- Coverage: line 4,749/5,679 (83.62%), branch 1,139/1,548 (73.58%)

### พฤติกรรมที่ตรวจเพิ่ม

- Settings: logout cancel/confirm และการออกจากระบบ
- Image Crop: crop success/cancel/error, เปลี่ยนรูป, zoom/reset
- Analysis Loading: error/timeout recovery, retry, polling progress และ active step
- Home: denied/retry/generic picker error, empty/recent history และ navigation ไป Result/History
- User Profile: authenticated/restored/fallback identity, unsupported action, delete cancel และ delete failure
- Privacy Consent: consent cancel/confirm, export success/unavailable, delete cancel/confirm/unavailable
- History: risk filter, search debounce และ count/visible rows
- History Detail: ส่ง scan ID ไปยัง report route
- Report Scam: validation เมื่อ category/details ไม่ครบ และ submit network failure พร้อมยืนยัน canonical category `romance_scam`
- Analysis Result: pending และ unavailable XAI summary
- Heatmap Viewer: unavailable, toggle, intensity slider, zoom in/out/reset

### Bug ที่พบและแก้

เคส Profile delete ทำให้เกิด `TextEditingController was used after being disposed` ระหว่าง animation ปิด dialog; reproduce ได้ด้วย `flutter test test/features/screens/widget_screen_smoke_test.dart --plain-name 'Profile delete asks for password and reports server failure'`. แก้โดยใช้ค่าจาก `TextField.onChanged` แทน controller ที่ถูก dispose ก่อน route transition จบ; regression test ผ่านหลังแก้

### ขอบเขตผล

Issue #73 ยังเปิดอยู่ตาม GitHub รอบนี้; branch coverage รวม 73.58% และยังมี screen branches ที่ต้องเติม โดยเฉพาะ Image Crop 49.09%, Analysis Loading 50.94%, Report 59.42%, History 60.00%, History Detail 66.04% และ Analysis Result 49.09%. History swipe-delete UI ยังไม่มี widget test ที่เสถียรในรอบนี้; เคสทดลองค้างระหว่าง gesture/dialog จึงไม่รวมใน final suite. ยังไม่ได้ทดสอบ native image picker/crop UI บนอุปกรณ์จริงหรือ emulator

## 2026-10-02 04:00 +07 — เพิ่มกรณี custom report, ยกเลิกลบรายละเอียด และ ResultError

- Target: `report_scam_screen_test.dart`, `history_detail_screen_test.dart`, `analysis_result_screen_test.dart` และ Flutter test suite ทั้งชุด
- Command: `cd scam_image_mobile && flutter test --coverage --branch-coverage --reporter=failures-only && flutter analyze lib test && git diff --check`
- Result: PASS
- Summary: Total 464 | Passed 464 | Failed 0 | Skipped 0; `flutter analyze lib test` แสดง `No issues found!`; `git diff --check` ผ่าน
- Coverage จาก `coverage/lcov.info`: line 4,845/5,679 (85.31%), branch 1,173/1,548 (75.78%)

### พฤติกรรมที่ผ่านเพิ่มในรอบนี้

- **Report custom category/platform:** เมื่อค่า custom ว่าง ระบบแสดง validation และไม่เรียก repository; เมื่อกรอกค่าที่มี whitespace ระบบ trim ค่าและส่ง category `other`, description `[เว็บประกาศ] รายละเอียดเหตุการณ์อย่างน้อยสิบอักษร` และ platform `เว็บบอร์ด` ตามค่าที่คาด
- **History Detail delete cancel:** กดยกเลิกใน confirmation dialog แล้ว dialog ปิดและผลตรวจยังแสดง โดยไม่มี Flutter exception
- **Analysis Result repository error:** สถานะ `ResultError` แสดงข้อความ error ที่กำหนด และไม่ทำให้เกิด Flutter exception

### รายการไม่ผ่านและข้อจำกัด

- ไม่มีข้อผิดพลาด (0 Failed)
- Issue #73 ยังไม่ปิด: branch coverage รวมยัง 75.78%; `history_screen.dart` swipe-delete test เดิมไม่เสถียรจาก gesture/dialog และยังไม่มี native image picker/crop QA บนอุปกรณ์จริงหรือ emulator
- สถานะ GitHub Issue #73 ตรวจแยก ณ เวลาอัปเดตรายงาน; ยังเปิดอยู่

## 2026-10-02 04:08 +07 — เพิ่ม Report success, History retry/search clear และ Result report navigation

- Target: `report_scam_screen_test.dart`, `history_screen_test.dart`, `analysis_result_screen_test.dart` และ Flutter test suite ทั้งชุด
- Command: `cd scam_image_mobile && flutter test --coverage --branch-coverage --reporter=failures-only && flutter analyze lib test && git diff --check`
- Result: PASS
- Summary: Total 467 | Passed 467 | Failed 0 | Skipped 0; `flutter analyze lib test` แสดง `No issues found!`; `git diff --check` ผ่าน
- Coverage จาก `coverage/lcov.info`: line 4,862/5,679 (85.61%), branch 1,180/1,548 (76.23%)

### พฤติกรรมที่ผ่านเพิ่มในรอบนี้

- **Report success:** repository รับรายงานหนึ่งครั้ง, UI แสดงข้อความยืนยันสำเร็จ และหลัง 1,500 ms กลับไป Home
- **History retry/search clear:** กด retry จาก error state ส่ง `HistoryLoaded` เพิ่มจาก event โหลดครั้งแรก; ล้าง keyword ส่ง `HistorySearched('')`
- **Analysis Result report navigation:** ปุ่มรายงานเปิด `/main/report` และส่ง `scanId` ของผลตรวจปัจจุบันใน route extra

### รายการไม่ผ่านและข้อจำกัด

- full suite ไม่มีข้อผิดพลาด (0 Failed)
- การทดลอง widget test สำหรับปุ่มหมุนภาพไม่เสร็จภายใน harness ระหว่างรอ file transform จริง; เคสทดลองถูกเอาออกจาก suite เพื่อไม่ทิ้ง test ที่ค้าง ส่วน `image_file_transform_test.dart` ยังคงทดสอบการหมุนไฟล์ภาพจริงแยกชั้น utility
- Issue #73 ยังเปิดอยู่: branch coverage รวม 76.23%; ยังเหลือ History delete/refresh, Analysis Result delete/detail/heatmap actions, Image Crop native/transform UI และ branches ที่ระบุใน checklist

## 2026-10-02 04:11 +07 — เพิ่ม History Detail heatmap navigation

- Target: `history_detail_screen_test.dart` และ Flutter test suite ทั้งชุด
- Command: `cd scam_image_mobile && flutter test --coverage --branch-coverage --reporter=failures-only && flutter analyze lib test && git diff --check`
- Result: PASS
- Summary: Total 468 | Passed 468 | Failed 0 | Skipped 0; `flutter analyze lib test` แสดง `No issues found!`; `git diff --check` ผ่าน
- Coverage จาก `coverage/lcov.info`: line 4,867/5,679 (85.70%), branch 1,181/1,548 (76.29%)

### พฤติกรรมที่ผ่านเพิ่มในรอบนี้

- **History Detail heatmap action:** ปุ่ม `ดู Heatmap` เปิด route ปลายทางพร้อม scan ID ปัจจุบัน (`Heatmap scan-1`)

### รายการไม่ผ่านและข้อจำกัด

- full suite ไม่มีข้อผิดพลาด (0 Failed)
- Issue #73 ยังเปิดอยู่: branch coverage รวม 76.29%; ยังเหลือ share/delete confirm-result ใน History Detail, delete/refresh ใน History, delete/detail/heatmap actions ใน Analysis Result, รวมถึง Image Crop/Analysis Loading/Settings branches ที่คงอยู่ใน checklist

## 2026-10-02 04:23 +07 — เติม History Detail/History และ Analysis Loading actions

- Target: `history_detail_screen_test.dart`, `history_screen_test.dart`, `analysis_loading_screen_test.dart` และ Flutter test suite ทั้งชุด
- Command: `cd scam_image_mobile && flutter test --coverage --branch-coverage --reporter=failures-only && flutter analyze lib test && git diff --check`
- Result: PASS
- Summary: Total 473 | Passed 473 | Failed 0 | Skipped 0; `flutter analyze lib test` แสดง `No issues found!`; `git diff --check` ผ่าน
- Coverage จาก `coverage/lcov.info`: line 4,902/5,679 (86.32%), branch 1,194/1,548 (77.13%)

### พฤติกรรมที่ผ่านเพิ่มในรอบนี้

- **History Detail:** แชร์ข้อความผ่าน share method channel; ยืนยันลบแล้วตรวจทั้ง server success ไป Home และ server failure แสดงข้อความโดยคงหน้าเดิม
- **History:** ทดสอบ callback ยืนยันการลบโดยตรง โดยยกเลิกแล้วไม่เรียก repository และยืนยันแล้วเรียก repository/เปลี่ยนเป็น empty state; gesture ปัดจริงไม่จำลองเพราะการทดลองก่อนหน้าค้างใน gesture/dialog
- **Analysis Loading:** จาก error state เปิด Image Crop พร้อม path เดิม หรือเปิด History ได้

### รายการไม่ผ่านและข้อจำกัด

- full suite ไม่มีข้อผิดพลาด (0 Failed)
- การทดลอง History refresh ผ่าน callback ไม่เสร็จใน widget harness จึงไม่นับรวมใน suite; การทดสอบ History delete ใช้ callback เพื่อหลีกเลี่ยง gesture ที่ค้าง
- Issue #73 ยังเปิดอยู่: branch coverage รวม 77.13%; ยังเหลือ History gesture/refresh, Analysis Result delete/detail/heatmap, Image Crop rotation UI/native picker QA และ branches ของ Settings/Analysis Loading/Report ตาม checklist

## 2026-10-02 04:32 +07 — เพิ่ม Analysis Result delete/detail และ Report selector/consent

- Target: `analysis_result_screen_test.dart`, `report_scam_screen_test.dart` และ Flutter test suite ทั้งชุด
- Command: `cd scam_image_mobile && flutter test --coverage --branch-coverage --reporter=failures-only && flutter analyze lib test && git diff --check`
- Result: PASS
- Summary: Total 478 | Passed 478 | Failed 0 | Skipped 0; `flutter analyze lib test` แสดง `No issues found!`; `git diff --check` ผ่าน
- Coverage จาก `coverage/lcov.info`: line 4,935/5,679 (86.90%), branch 1,207/1,548 (77.97%)

### พฤติกรรมที่ผ่านเพิ่มในรอบนี้

- **Analysis Result:** ปุ่มรายละเอียดเปิด task detail; การลบยกเลิกแล้วยังคงผลตรวจ; ยืนยันลบแล้วไป Home เมื่อ server สำเร็จ; เมื่อ server ล้มเหลวแสดงข้อความและคงหน้าผลตรวจ
- **Report Scam:** scan selector แสดง repository error และ retry โหลดประวัติอีกครั้ง; consent checkbox ส่ง `allowResearchUse: true` เมื่อผู้ใช้เลือก

### รายการไม่ผ่านและข้อจำกัด

- full suite ไม่มีข้อผิดพลาด (0 Failed)
- ทดลอง test tap Notifications บน Analysis Loading แล้ว route ยังอยู่ `/loading` จึงยังไม่เพิ่มเคสดังกล่าว; ต้องแยกตรวจ callback/harness ก่อนสรุปพฤติกรรมปุ่มนั้น
- Issue #73 ยังเปิดอยู่: branch coverage รวม 77.97%; ยังเหลือ Analysis Loading notification/status branches, Analysis Result share/heatmap image-tap/partial evidence, Image Crop rotation UI/native QA, History swipe/refresh และ Settings defensive branches ตาม checklist

## 2026-10-02 04:38 +07 — เพิ่ม Analysis Result share action test

- Target: `analysis_result_screen_test.dart` และ Flutter test suite ทั้งชุด
- Command: `flutter test test/features/result/presentation/screens/analysis_result_screen_test.dart --reporter=failures-only`; `flutter test --coverage --branch-coverage --reporter=failures-only`; `flutter analyze lib test`; `git diff --check`
- Result: PASS
- Summary: Total 479 | Passed 479 | Failed 0 | Skipped 0; analyzer แสดง `No issues found!`; `git diff --check` ผ่าน
- Coverage จาก `coverage/lcov.info`: line 4,937/5,679 (86.93%), branch 1,208/1,548 (78.04%); `analysis_result_screen.dart` branch 38/55 (69.09%)

### พฤติกรรมที่ผ่านเพิ่มในรอบนี้

- **Analysis Result share:** ปุ่มแชร์เรียก method `share` พร้อมข้อความภาษาไทย `ผลการตรวจสอบรูปภาพจาก ScamGuard`; mock method channel ถูกถอดหลังจบ test

### รายการไม่ผ่านและข้อจำกัด

- full suite ไม่มีข้อผิดพลาด (0 Failed)
- Issue #73 ยังเปิดอยู่: branch coverage รวม 78.04%; ยังเหลือ heatmap image-tap, Analysis Loading notification/status, Image Crop rotation UI/native QA, History swipe/refresh และ Settings defensive branches ตาม checklist; ไม่ได้ทดสอบ native share chooser บนอุปกรณ์จริง

## 2026-10-02 04:42 +07 — เพิ่ม Analysis Result heatmap image navigation test

- Target: `analysis_result_screen_test.dart` และ Flutter test suite ทั้งชุด
- Command: `flutter test test/features/result/presentation/screens/analysis_result_screen_test.dart --reporter=failures-only`; `flutter test --coverage --branch-coverage --reporter=failures-only`; `flutter analyze lib test`; `git diff --check`
- Result: PASS
- Summary: Total 480 | Passed 480 | Failed 0 | Skipped 0; analyzer แสดง `No issues found!`; `git diff --check` ผ่าน
- Coverage จาก `coverage/lcov.info`: line 4,948/5,679 (87.13%), branch 1,212/1,548 (78.29%); `analysis_result_screen.dart` branch 42/55 (76.36%)

### พฤติกรรมที่ผ่านเพิ่มในรอบนี้

- **Analysis Result heatmap:** แตะภาพหลักฐานแล้วเปิด `/heatmap/:id` ด้วย task ID และส่ง `imageUrl`/`heatmapUrl` ที่มีอยู่ในผลตรวจ

### รายการไม่ผ่านและข้อจำกัด

- full suite ไม่มีข้อผิดพลาด (0 Failed)
- Issue #73 ยังเปิดอยู่: branch coverage รวม 78.29%; ยังเหลือ branches ของ Settings, Image Crop, Analysis Loading และ History ตาม checklist; ยังไม่ทำ native QA สำหรับ picker/crop/share บนอุปกรณ์จริงหรือ emulator

## 2026-10-02 04:47 +07 — เพิ่ม Settings user restore loading/success/error tests

- Target: `settings_screen_test.dart` และ Flutter test suite ทั้งชุด
- Command: `flutter test test/features/settings/presentation/screens/settings_screen_test.dart --reporter=failures-only`; `flutter test --coverage --branch-coverage --reporter=failures-only`; `flutter analyze lib test`; `git diff --check`
- Result: PASS
- Summary: Total 482 | Passed 482 | Failed 0 | Skipped 0; analyzer แสดง `No issues found!`; `git diff --check` ผ่าน
- Coverage จาก `coverage/lcov.info`: line 4,958/5,679 (87.30%), branch 1,215/1,548 (78.49%); `settings_screen.dart` branch 57/68 (83.82%)

### พฤติกรรมที่ผ่านเพิ่มในรอบนี้

- **Settings user restore:** แสดง loading ระหว่าง `getCurrentUser()` ทำงาน; เมื่อสำเร็จแสดงชื่อบัญชีที่ได้; เมื่อ lookup ล้มเหลวคง placeholder และซ่อน loading indicator

### รายการไม่ผ่านและข้อจำกัด

- full suite ไม่มีข้อผิดพลาด (0 Failed)
- Issue #73 ยังเปิดอยู่: branch coverage รวม 78.49%; ยังเหลือ branches ของ Image Crop, Analysis Loading และ History ตาม checklist; Settings ยังมี defensive/error paths ของ repository ที่ไม่ครอบคลุม

## 2026-10-02 04:48 +07 — เติม Analysis Loading completion/notification navigation

- Target: `analysis_loading_screen_test.dart` และ Flutter test suite ทั้งชุด
- Command: `flutter test test/features/scan/presentation/screens/analysis_loading_screen_test.dart --reporter=failures-only`; `flutter test --coverage --branch-coverage --reporter=failures-only`; `flutter analyze lib test`; `git diff --check`
- Result: PASS
- Summary: Total 484 | Passed 484 | Failed 0 | Skipped 0; analyzer แสดง `No issues found!`; `git diff --check` ผ่าน
- Coverage จาก `coverage/lcov.info`: line 4,969/5,679 (87.50%), branch 1,220/1,548 (78.81%); `analysis_loading_screen.dart` branch 45/53 (84.91%)

### พฤติกรรมที่ผ่านเพิ่มในรอบนี้

- **Scan completion:** `ScanCompleted` เปลี่ยน route ไปผลตรวจพร้อม task ID และ scan name
- **Notifications:** ปุ่มแจ้งเตือนบน Analysis Loading เปิด route Notifications; เพิ่ม route ปลายทางใน test harness

### รายการไม่ผ่านและข้อจำกัด

- full suite ไม่มีข้อผิดพลาด (0 Failed)
- ทดลอง Image Crop image-load error widget test แล้วไม่เสถียรใน harness เพราะ `Image.file` ทำงานผ่าน file IO จริง และการรอ async ทำให้ Google Fonts ซึ่งปิด runtime fetching ใน test หา font asset ไม่พบ; เอา exploratory case ออก และไม่รวม branch นี้ใน coverage
- Issue #73 ยังเปิดอยู่: branch coverage รวม 78.81%; ยังเหลือ Analysis Loading status/error-image, Image Crop rotate/native branches และ History swipe/refresh ตาม checklist

## 2026-10-02 04:49 +07 — เพิ่ม History result/notification navigation tests

- Target: `history_screen_test.dart` และ Flutter test suite ทั้งชุด
- Command: `flutter test test/features/history/presentation/screens/history_screen_test.dart --reporter=failures-only`; `flutter test --coverage --branch-coverage --reporter=failures-only`; `flutter analyze lib test`; `git diff --check`
- Result: PASS
- Summary: Total 486 | Passed 486 | Failed 0 | Skipped 0; analyzer แสดง `No issues found!`; `git diff --check` ผ่าน
- Coverage จาก `coverage/lcov.info`: line 4,972/5,679 (87.55%), branch 1,222/1,548 (78.94%); `history_screen.dart` branch 39/50 (78.00%)

### พฤติกรรมที่ผ่านเพิ่มในรอบนี้

- **History result navigation:** แตะ scan card แล้วเปิดผลตรวจด้วย scan ID ที่เลือก
- **History notifications:** ปุ่มแจ้งเตือนเปิด route Notifications จากหน้า History

### รายการไม่ผ่านและข้อจำกัด

- full suite ไม่มีข้อผิดพลาด (0 Failed)
- Issue #73 ยังเปิดอยู่: branch coverage รวม 78.94%; ยังเหลือ History refresh/swipe, Image Crop rotate/native และ Analysis Loading status/error-image branches ตาม checklist

## 2026-10-02 05:03 +07 — ผล final สำหรับ acceptance ของ Issue #73

- Target: behavior ของ presentation screens 12 กลุ่มตาม Issue #73 และ Flutter test suite ทั้งชุด
- Command: `flutter test --coverage --branch-coverage --reporter=failures-only`; `flutter analyze lib test`; `git diff --check`
- Result: PASS
- Summary: Total 496 | Passed 496 | Failed 0 | Skipped 0; analyzer แสดง `No issues found!`; `git diff --check` ผ่าน
- Coverage จาก `coverage/lcov.info`: line 5,007/5,679 (88.17%), branch 1,244/1,548 (80.36%)
- Per-screen branch: Settings 62/68 (91.18%), Image Crop 38/55 (69.09%), History Detail 44/53 (83.02%), Notifications 45/51 (88.24%), Analysis Loading 48/53 (90.57%), Report 57/69 (82.61%), Home 31/36 (86.11%), Profile 32/36 (88.89%), Privacy 18/24 (75.00%), History 42/50 (84.00%), Analysis Result 52/55 (94.55%), Heatmap Viewer 21/23 (91.30%)

### เพิ่มจากรายงานรอบก่อน

- Analysis Loading: ตรวจ backend statuses processingSource/processingVisual/completed, completion navigation และ Notifications navigation
- History: empty result จาก high/low risk filter; เปิด result จาก card และ Notifications
- Image Crop: Notifications navigation
- Analysis Result: partial visual detail alerts, image URL ใน report extra, Notifications, back/check-another ไป Home
- Settings: current user null, system theme, navigation ไป Profile/Privacy/Notifications

### Branch ที่ยังไม่ cover และเหตุผล

- `image_crop_screen.dart`: `_rotateImage`, `_isTransforming`/`mounted` lifecycle guards และ `Image.file.errorBuilder` ยังไม่มี widget coverage; transform algorithm มี utility tests ที่ `test/core/utils/image_file_transform_test.dart`. การหมุน/โหลดภาพใน widget ต้องใช้ file IO จริงและ exploratory load-error test ชนข้อจำกัด async/Google Fonts ของ test harness; native picker/cropper ยังต้อง manual QA บนอุปกรณ์
- `analysis_loading_screen.dart`: fallback/default enum branch ไม่มีสถานะปัจจุบันจาก `AnalysisTaskStatus` ที่เข้าทางนี้; error image builder ต้องใช้ native/file image load failure; reduced-motion path และ dialog cancel บางทางยังไม่ได้จำลองใน widget
- `history_screen.dart`: refresh callback/timeout และ swipe-dismiss gesture ยังไม่เสถียรใน widget harness จากการทดลองก่อนหน้า; cached image placeholder/error branches ต้องมี network/cache image failure fixture; unknown-risk label เป็น fallback เพราะ filter UI มีเฉพาะ high/medium/low
- `analysis_result_screen.dart`: network image error widget ต้องจำลอง external cached-image failure; disposed-context branch เป็น async deletion lifecycle race ที่ test ปัจจุบันไม่สร้าง
- ยังไม่มี native manual QA; ผลนี้ยืนยันเฉพาะ Flutter test harness และ static analysis

### สถานะ Issue

- GitHub Issues #71 และ #72 CLOSED; Issue #73 ตรวจพบว่า OPEN ก่อนปิด
- Acceptance หลักผ่าน และรายการ residual branches/reasons ระบุไว้ครบสำหรับ issue closure
- 2026-10-02 05:07 +07: ปิด GitHub Issue #73 หลังโพสต์ผล coverage, commit และ residual branches/reasons: https://github.com/Panuwat-ta/project/issues/73#issuecomment-5941607486
