# Test Results Directory (`tests_all/`)

ไดเรกทอรีนี้มีไว้สำหรับจัดเก็บ **ผลลัพธ์การรัน Test จริงเท่านั้น (Automated Test Execution Results)**
**ห้ามใช้จัดเก็บ Log การทำงานทั่วไปของ Agent หรือบันทึก Manual Review โดยเด็ดขาด**

---

## กฎและข้อกำหนด (Rules)

1. **เก็บเฉพาะผลการรัน Test จริง (Execution Results Only)**
   - บันทึกเฉพาะผลลัพธ์ที่ได้จากการรัน Test Runner หรือ Test Script จริง เช่น `pytest`, `flutter test`, สคริปต์ทดสอบโมเดล AI (`predict_test.py`)
   - **ห้าม** บันทึกการ Manual Review, การเปิดอ่านไฟล์ด้วย `cat`, `sed`, `head`, `view_file` หรือการตรวจเช็กด้วยสายตา
   - **ห้าม** บันทึกการแก้ไขเอกสาร (Docs / Wiki) หรือความคืบหน้างานทั่วไป (ประวัติและ Log การทำงานของ Agent ทั้งหมดให้บันทึกที่ `.agents/log.md` เท่านั้น)
   - หากในงานนั้น**ไม่มีการรัน Test Suite หรือ Test Script จริง ไม่ต้องสร้างหรืออัปเดตไฟล์ใดๆ ในไดเรกทอรีนี้**

2. **โครงสร้างโฟลเดอร์ (Directory Structure)**
   แบ่งตามส่วนประกอบของระบบที่ทำการทดสอบ:
   - `mobile/` - ผลการรันเทสต์ฝั่ง Mobile App (เช่น `flutter test`, `scam_image_mobile/integration_test/`)
   - `server/` - ผลการรันเทสต์ฝั่ง Backend Server (เช่น `pytest server/tests/`)
   - `model/` - ผลการทดสอบ AI Models / Pipeline Inference Scripts
   - `admin/` - ผลการรัน Automated Tests ของ Admin Portal

3. **รูปแบบไฟล์ผลการทดสอบ (Test Record Format)**
   - ใช้ชื่อไฟล์ตามชื่อ Test Suite หรือ Feature เช่น `server/auth_api.md`, `mobile/risk_scoring.md`
   - หากรันซ้ำให้เขียนต่อท้าย (Append) ห้ามเขียนทับประวัติเดิม
   - รูปแบบเนื้อหา:

```markdown
## YYYY-MM-DD HH:mm +07 - [Test Target / Suite Name]

- Target: <ชื่อไฟล์หรือชุดทดสอบ เช่น server/tests/api/test_auth.py>
- Command: `<คำสั่งที่รันจริง เช่น pytest server/tests/api/test_auth.py -v>`
- Result: PASS หรือ FAIL
- Summary: Total: <จำนวน> | Passed: <ผ่าน> | Failed: <ตก> | Skipped: <ข้าม> | Duration: <เวลาที่ใช้>
- Details:
  <กรณี PASS: สรุปผลสั้นๆ เช่น 15 tests passed>
  <กรณี FAIL: แนบ Failure output / Stack trace / Assertion error เพื่อนำไปวิเคราะห์แก้ไข>
```
