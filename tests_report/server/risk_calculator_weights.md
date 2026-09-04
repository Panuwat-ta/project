## 2026-09-04 09:47 +07 - Risk Calculator Weighted Formula Verification

- Target: server/tests/utils/test_risk_calculator.py
- Command: `/home/panuwat/project/server/venv/bin/pytest tests/utils/test_risk_calculator.py -v`
- Result: PASS
- Summary: Total: 1 | Passed: 1 | Failed: 0 | Skipped: 0 | Duration: 0.01s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **test_risk_score_calculation_weights**:
  - พฤติกรรมที่ผ่าน: ฟังก์ชัน `calculate_risk_score` ใน `app.utils.risk_calculator` คำนวณคะแนนตามสัดส่วนน้ำหนักใหม่ (Textual 20%, Visual 60%, Source 20%) ได้ถูกต้องตรงตามเกณฑ์ทุกเคส:
    1. เคสคะแนนเริ่มต้นต่ำสุด (0, 0, 0) ได้ผลลัพธ์คะแนน 0 และเกรด 'low'
    2. เคสคะแนนสูงสุด (100, 100, 100) ได้ผลลัพธ์คะแนน 100 และเกรด 'high'
    3. เคสสัดส่วนผสม (75 text, 87 visual, 75 source) ประมวลผล `(75×0.20) + (87×0.60) + (75×0.20) = 15.0 + 52.2 + 15.0 = 82.2` ปัดเศษได้ 82 และจัดเกรดเป็น 'high'
    4. เคสมีเฉพาะข้อความ (100 text, 0 visual, 0 source) ได้คะแนน 20 (สะท้อนค่าน้ำหนัก 20%) จัดเกรดเป็น 'low'
    5. เคสมีเฉพาะภาพ (0 text, 50 visual, 0 source) ได้คะแนน 30 (สะท้อนค่าน้ำหนัก 60%) จัดเกรดเป็น 'low'
    6. เคสคะแนนระดับกลาง (50 text, 40 visual, 50 source) ได้คะแนน 44 จัดเกรดเป็น 'medium' (40–69)
    7. เคสพิเศษ visual_score >= 80 (0 text, 80 visual, 0 source) กฎระบบบังคับเกรดเป็น 'high' และดันคะแนนรวมเป็น 70 ทันทีเพื่อความสอดคล้องของ UI

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)
