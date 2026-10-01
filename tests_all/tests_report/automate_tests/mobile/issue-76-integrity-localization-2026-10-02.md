## 2026-10-02 06:04 +07 - Issue #76 Mobile full Flutter suite

- Target: `scam_image_mobile/test/` (full Flutter suite)
- Command: `flutter test --coverage --branch-coverage --reporter=failures-only`
- Result: PASS
- Summary: Total: 521 | Passed: 521 | Failed: 0 | Skipped: 0 | Duration: runner ไม่แสดงเวลาใน output ที่บันทึก
- Coverage: Lines 5,207/5,716 (91.10%) | Branches 1,287/1,550 (83.03%); branch coverage สูงกว่า NFR-09 ที่กำหนด 80%

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **Analysis Result preview evidence label**:
  - พฤติกรรมที่ผ่าน: เมื่อมี `heatmapUrl` แสดง HEATMAP; เมื่อมีเฉพาะ `imageUrl` แสดง “ภาพต้นฉบับ”; เมื่อไม่มี URL หรือ URL ว่าง แสดง “ไม่มีภาพตัวอย่าง” และไม่แสดงป้าย Heatmap ที่ไม่มีหลักฐาน
- **History Detail preview evidence label**:
  - พฤติกรรมที่ผ่าน: ป้ายแยก Heatmap กับภาพต้นฉบับตาม URL และไม่มีป้ายผลวิเคราะห์เมื่อไม่มีภาพ
- **History Detail data labels**:
  - พฤติกรรมที่ผ่าน: คะแนนจาก textual factor แสดงเป็น “คะแนนความเสี่ยงข้อความ”; `createdAt` แสดงใต้ “วันที่วิเคราะห์”; source details แสดงใต้ “รายละเอียดการตรวจสอบแหล่งที่มา”
- **AuthBloc error mapping**:
  - พฤติกรรมที่ผ่าน: credential, network และ email-already-registered exceptions ให้ localization key ที่สอดคล้อง แทนการฝังข้อความไทยไว้ใน BLoC; Login/Register แปล key ก่อนแสดงข้อความผู้ใช้
- **Thai/English localization dictionary**:
  - พฤติกรรมที่ผ่าน: key ไทย/อังกฤษครบตรงกัน และชุด key Auth/Onboarding/Heatmap มีข้อความของทั้งสองภาษา; English dictionary ไม่รั่วอักษรไทยตาม assertion เดิม
- **Full mobile regression suite**:
  - พฤติกรรมที่ผ่าน: unit/widget tests ของ BLoC, repository, routing, data, shared widgets และ presentation screens ทำงานครบโดยไม่มี assertion failure

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed)

### Verification เพิ่มเติม

- `flutter analyze lib test`: ผ่าน, `No issues found!`
- `git -c core.whitespace=cr-at-eol diff --check`: ผ่าน โดยคง line ending CRLF ที่ไฟล์ Splash ใช้อยู่เดิม

## 2026-10-02 06:16 +07 - Regression หลังแก้ findings ของ Issue #76

- Target: full `scam_image_mobile/test/`
- Command: `flutter test --coverage --branch-coverage --reporter=failures-only`
- Result: PASS
- Summary: Total: 522 | Passed: 522 | Failed: 0 | Skipped: 0 | Duration: reporter ไม่แสดงเวลา
- Coverage: Lines 5,209/5,718 (91.10%) | Branches 1,286/1,549 (83.02%)

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **Flat result model mapping**: confidence 0.85 ยังคงเป็น typed metric, visual score 25 คงเดิม และ visual details ว่างเมื่อไม่มี narrative จาก server; ไม่มีข้อความไทยที่ model สร้างแทรก
- **Result unavailable visual factor**: ไม่แสดง `0%` เมื่อไม่มี visual factor; แสดง unavailable state แทน
- **Result confidence presentation**: entity confidence 0.82 แสดง “ความมั่นใจว่าถูกดัดแปลง: 82%” ผ่าน dictionary โดยไม่ปะปนกับ evidence alert
- **History confidence vs visual risk**: confidence 10% กับ visual risk 85% แสดงตัวเลข confidence ด้วย neutral text color แทนสีแดงจากอีก metric
- **Localization และชุด regression ทั้งหมด**: dictionaries TH/EN ตรงกันหลังเปลี่ยน key confidence/ลบ unused Safe keys; tests เดิมทั้งหมดผ่าน
- Focused run ก่อน full suite: model, Result, History Detail และ localization ผ่าน 52 tests

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed)

### Verification เพิ่มเติม

- `flutter analyze lib test`: `No issues found!`
- `git -c core.whitespace=cr-at-eol diff --check`: ผ่าน
