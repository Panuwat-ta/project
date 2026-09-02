## 2026-09-02 05:20 +07

- Feature: เกณฑ์คำนวณความเสี่ยงรวม (risk_calculator)
- Type: Lint
- Command: `python3 -m py_compile server/app/utils/risk_calculator.py` และ `dart analyze`
- Result: Pass
- Notes: แก้ `risk_calculator.py:11` จาก 4 ระดับ (`safe <20`) เหลือ 3 ระดับ (`low 0-39`, `medium 40-69`, `high >=70` หรือ `visual>=80`), compile ผ่าน, `dart analyze` ไม่มี error
