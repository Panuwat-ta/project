# Test Reports Directory (`tests_report/`)

ไดเรกทอรีนี้มีไว้สำหรับจัดเก็บ **ผลลัพธ์การรัน Test จริงเท่านั้น (Automated Test Execution Results)**
**ห้ามใช้จัดเก็บ Log การทำงานทั่วไปของ Agent หรือบันทึก Manual Review โดยเด็ดขาด**

---

## กฎและข้อกำหนด (Rules)

1. **เก็บเฉพาะผลการรัน Test จริง (Execution Results Only)**
   - บันทึกเฉพาะผลลัพธ์ที่ได้จากการรัน Test Runner หรือ Test Script จริง เช่น `pytest`, `flutter test`, สคริปต์ทดสอบโมเดล AI (`predict_test.py`)
   - **ห้าม** บันทึกการ Manual Review, การเปิดอ่านไฟล์ด้วย `cat`, `sed`, `head`, `view_file` หรือการตรวจเช็กด้วยสายตา
   - **ห้าม** บันทึกการแก้ไขเอกสาร (Docs / Wiki) หรือความคืบหน้างานทั่วไป (ประวัติและ Log การทำงานของ Agent ทั้งหมดให้บันทึกที่ `.agents/log.md` เท่านั้น)
   - หากในงานนั้น **ไม่มีการรัน Test Suite หรือ Test Script จริง ไม่ต้องสร้างหรืออัปเดตไฟล์ใดๆ ในไดเรกทอรีนี้**

2. **โครงสร้างโฟลเดอร์ (Directory Structure)**
   แบ่งตามส่วนประกอบของระบบที่ทำการทดสอบ:
   - `mobile/` - ผลการรันเทสต์ฝั่ง Mobile App (เช่น `flutter test`, `scam_image_mobile/integration_test/`)
   - `server/` - ผลการรันเทสต์ฝั่ง Backend Server (เช่น `pytest server/tests/`)
   - `model/` - ผลการทดสอบ AI Models / Pipeline Inference Scripts
   - `admin/` - ผลการรัน Automated Tests ของ Admin Portal

3. **รูปแบบไฟล์ผลการทดสอบ (Test Record Format)**
   - ใช้ชื่อไฟล์ตามชื่อ Test Suite หรือ Feature เช่น `server/auth_api.md`, `mobile/risk_scoring.md`
   - หากรันซ้ำให้เขียนต่อท้าย (Append) ห้ามเขียนทับประวัติเดิม
   - **ภาษาที่ใช้บันทึก (Language Requirement)**: บันทึกรายละเอียดการวิเคราะห์ผลการทดสอบทั้งหมดเป็น**ภาษาไทย** (คงชื่อฟังก์ชัน ตัวแปร คำสั่ง และศัพท์เทคนิคเป็นภาษาอังกฤษ)
   - **ห้ามเขียนแค่ "PASS/FAIL" หรือ "ผ่านทั้งหมด X tests" เพียงอย่างเดียว**: ต้องแจกแจงรายละเอียดให้ครบ 4 มิติ:
     1. **What passed (มีอะไรผ่านบ้าง)**: ระบุฟังก์ชัน/โมดูลที่ผ่าน
     2. **How and why it passed (ผ่าน ผ่านยังไง)**: อธิบายพฤติกรรมจริงของระบบ และเงื่อนไข Assertions ที่ผ่านเป็นภาษาไทย
     3. **What failed (มีอะไรไม่ผ่านบ้าง)**: ระบุชื่อเทสต์ที่ไม่ผ่าน (หากไม่มี ให้ระบุว่า `ไม่มีข้อผิดพลาด (0 Failed)`)
     4. **How and why it failed (ไม่ผ่าน ไม่ผ่านยังไง)**: อธิบายสาเหตุของข้อผิดพลาด, Expected vs Actual หรือแนบ Stack Trace เป็นภาษาไทย

แม่แบบมาตรฐาน:

```markdown
## YYYY-MM-DD HH:mm +07 - [Test Target / Suite Name]

- Target: <ชื่อไฟล์หรือชุดทดสอบ เช่น server/tests/api/test_auth.py หรือ test/core/utils/risk_level_helper_test.dart>
- Command: `<คำสั่งที่ใช้รัน เช่น pytest server/tests/api/test_auth.py -v หรือ flutter test test/...>`
- Result: PASS หรือ FAIL
- Summary: Total: <จำนวน> | Passed: <ผ่าน> | Failed: <ตก> | Skipped: <ข้าม> | Duration: <เวลาที่ใช้>

### 1. Passed Tests and Runtime Behavior (How it Passed)
- **[Passed Test Case / Function Name 1]**:
  - Verification & Runtime Behavior: <Explain why it passed, e.g. input X produced expected output Y, required columns/fields populated, assertions satisfied>
- **[Passed Test Case / Function Name 2]**:
  - Verification & Runtime Behavior: <Explain actual behavior and passing assertions>

### 2. Failed Tests and Root Cause (How & Why it Failed)
*(If all passed, state: None (0 Failed))*
*(If tests failed, break them down as follows:)*
- **[Failed Test Case / Function Name 1]**:
  - Root Cause: <Explain failure cause, e.g. Expected value A but got value B, timeout, missing field, or schema mismatch>
  - Error Details / Stack Trace:
    ```text
    <Attach failure runner output / assertion error stack trace>
    ```
```
