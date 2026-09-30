# Mobile Automated Regression & Coverage — 2026-09-20

## 2026-09-20 - Full Flutter regression suite

- Target: `scam_image_mobile/test/` ทั้งหมด
- Command: `flutter analyze` และ `flutter test`
- Result: PASS
- Summary: Total: 368 | Passed: 368 | Failed: 0 | Runner ไม่รายงาน skipped | Runner timestamp at completion: 00:11
- Analyzer: `No issues found`

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **Product integrity / Result / Heatmap**
  - missing heatmap แสดง unavailable state โดยไม่สร้าง simulated anomaly gradient
  - Result ไม่มี faux non-interactive slider และไม่สร้าง Safe/XAI/source finding จากข้อมูลที่ backend ไม่ได้ส่ง
  - `AnalysisResultModel` ปล่อย summary ว่างเมื่อ server/XAI ไม่มีข้อมูล แทนการสร้างข้อความสรุปเอง
- **History**
  - pagination โหลดข้อมูลเกิน 100 รายการได้, ป้องกัน repeated-page loop, search/delete/refresh และ delete completion ทำงานตาม repository result
  - History card ไม่ derive forensic evidence tags จาก risk grade
- **Scan / image flow**
  - upload/polling race, stale response, duplicate poll, timeout, cancel และ progress clamp ผ่าน assertions
  - image rotation เขียนไฟล์จริงและ corrupt image ถูก reject
  - error state คงอยู่เพื่อ recovery โดยไม่ redirect อัตโนมัติ
- **Navigation / adaptivity / accessibility**
  - router-derived primary navigation ใช้ `NavigationBar` บน compact/medium และ `NavigationRail` บน expanded
  - viewport 360×800, 390×844, 412×915, 600×960 และ 840×1180 ที่ text scale 1.3 ไม่มี layout exception; 390×844 ที่ scale 1.5 ผ่านเพิ่มอีกเคส
  - semantics ของ risk badge/gauge และ reduced-motion ของ analysis step ผ่าน widget assertions
  - `ConsentCheckboxTile` interaction/toggle และ integration กับ `PrimaryButton` ผ่านหลังขยาย touch area เป็น 48×48
- **Localization / Settings / Notifications**
  - Thai/English dictionary มี key ชุดเดียวกัน และ English dictionary ไม่มี Thai UI literal ยกเว้นชื่อภาษา
  - theme/language persistence และ storage failure behavior ผ่าน
  - notification terminal-state sync, read/dismiss/clear-all preservation และ short-id safety ผ่าน
- **API / storage / auth regression**
  - Dio multipart, public auth path, token refresh, concurrent 401, multipart retry และ refresh failure ผ่าน
  - SQLite schema/migration/cache round-trip ผ่าน
  - auth/login/register/splash/router guard regressions ผ่านโดยไม่แก้ contract เดิม

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน

ไม่มีข้อผิดพลาดใน final suite (0 Failed)

หมายเหตุระหว่าง implementation: targeted tests เคย fail เมื่อ test เดิมยังคาดข้อความไทยแทน localization key และเคยเรียก path ของ localization test ก่อนสร้าง directory; ทั้งสองกรณีถูกแก้ที่ test contract/path แล้ว final full suite ผ่านครบ 368 tests

## 2026-09-20 - Coverage run

- Command: `flutter test --coverage`
- Result: PASS
- Summary: Total: 368 | Passed: 368 | Failed: 0 | Runner ไม่รายงาน skipped | Runner timestamp at completion: 00:19

### Coverage ที่วัดได้จาก `coverage/lcov.info`

- Overall line coverage: **2908/5637 = 51.59%**
- `main_navigation_shell.dart`: 45/50 = 90.00%
- `adaptive_content.dart`: 7/7 = 100.00%
- `risk_badge.dart`: 35/35 = 100.00%
- `analysis_step_tile.dart`: 61/70 = 87.14%
- `history_screen.dart`: 155/259 = 59.85%
- `analysis_result_screen.dart`: 268/339 = 79.06%
- `heatmap_viewer_screen.dart`: 129/144 = 89.58%
- `report_scam_screen.dart`: 280/378 = 74.07%
- `notifications_cubit.dart`: 47/48 = 97.92%

### การตีความผล coverage

- regression suite ครอบคลุม logic สำคัญของ redesign เช่น navigation authority, responsive constraint, risk semantics, evidence integrity และ notifications ในระดับสูง
- line coverage รวม 51.59% ยังไม่ถึงข้อกำหนด NFR-09 ที่ระบุ branch coverage ≥80% บน CI; ตัวเลขนี้เป็น **line coverage จาก lcov** และไม่ควรถูกตีความว่าเป็น branch coverage
- หน้าจอที่เป็น widget composition ขนาดใหญ่บางไฟล์มี line coverage ต่ำกว่า logic layer แม้ targeted behavior tests ผ่าน ดังนั้นยังมีช่องว่างด้าน coverage ที่ต้องเพิ่มในงานถัดไป

### 2. รายการที่ไม่ผ่านของ coverage run

ไม่มี test failure (0 Failed) แต่ coverage target ตาม NFR-09 ยังไม่ผ่านตามตัวเลขที่วัดได้ จึงต้องบันทึกเป็น quality gap แยกจากสถานะ test suite ที่ผ่านทั้งหมด
