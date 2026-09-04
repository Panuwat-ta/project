## 2026-09-04 09:51 +07 - Hybrid Worst-Case Risk Calculator Verification

- Target: server/tests/utils/test_risk_calculator.py
- Command: `/home/panuwat/project/server/venv/bin/pytest tests/utils/test_risk_calculator.py -v`
- Result: PASS
- Summary: Total: 1 | Passed: 1 | Failed: 0 | Skipped: 0 | Duration: 0.01s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **test_hybrid_worst_case_and_multi_factor**:
  - พฤติกรรมที่ผ่าน: ฟังก์ชัน `calculate_risk_score` ใน `app.utils.risk_calculator` ประมวลผลลอจิก Hybrid Worst-Case & Multi-Factor Breakdown ได้อย่างแม่นยำครบทั้ง 8 Assertion:
    1. เคสค่าศูนย์ (0, 0, 0): ให้คะแนน 0, เกรด 'low', primary_factor เป็น 'none', และ is_multi_risk เป็น False
    2. เคส Visual เดี่ยวรุนแรง (0 text, 85 visual, 0 source): แก้ปัญหา Score Dilution สำเร็จ คะแนนคงที่ 85 เต็มตามความเสี่ยงด้านภาพ ไม่ถูกฉุดด้วยค่า 0 ของข้อความ ได้เกรด 'high' และ primary_factor เป็น 'visual'
    3. เคส Text เดี่ยวรุนแรง (90 text, 0 visual, 0 source): ได้คะแนน 90, เกรด 'high', primary_factor เป็น 'textual'
    4. เคสความเสี่ยงซ้ำซ้อน 2 มิติ (50 text, 80 visual, 0 source): ฐานคะแนนสูงสุด 80 บวกค่า Compounding Penalty +5 คะแนน สะท้อนความเสี่ยงรวมเป็น 85 และระบุ is_multi_risk เป็น True
    5. เคสความเสี่ยงซ้ำซ้อน 3 มิติ (50 text, 80 visual, 60 source): ฐานคะแนนสูงสุด 80 บวกค่า Compounding Penalty 2 มิติรอง (+10 คะแนน) สะท้อนคะแนนรวมเป็น 90
    6. เคสระดับความเสี่ยงปานกลาง (20 text, 55 visual, 10 source): คะแนน 55 จัดเป็นเกรด 'medium' ถูกต้องตามช่วง (40–69)
    7. เคสขอบเขตคะแนนสูงสุด (100, 100, 100): จำกัดคะแนนรวมที่ 100 และจัดเกรด 'high'
    8. โครงสร้าง Breakdown: ส่งคืนคะแนนแยกทั้ง 3 มิติ (`visual_score`, `text_score`, `source_score`) แบบเต็ม 100% อิสระ

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
ไม่มีข้อผิดพลาด (0 Failed)
