## 2026-09-19 03:10 +07 - [RiskScore Module / test_risk_calculator.py + test_risk_module.py]

- Target: server/tests/utils/test_risk_calculator.py และ server/tests/utils/test_risk_module.py (ใหม่)
- Command: `source venv/bin/activate && python -m pytest tests/utils/test_risk_calculator.py tests/utils/test_risk_module.py -q` ( workdir: `server/`)
- Result: PASS
- Summary: Total: 7 | Passed: 7 | Failed: 0 | Skipped: 0 | Duration: ~0.24 วินาที

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **[test_hybrid_worst_case_and_multi_factor (ของเดิม)]**:
  - พฤติกรรมที่ผ่าน: สูตร Hybrid Worst-Case + Multi-Factor Compounding + Visual Override ยังให้ผลเดิมทั้ง 8 เคส ( worst-case ไม่ถูกค่า 0 ฉุด, compounding +5, grade bands) แสดงว่า refactor ย้าย code ไม่เปลี่ยน behavior
- **[test_grade_for_matches_calculator_on_full_grid (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: ไล่ grid 0-100 step 5 ครบ 9,261 จุด `grade_for(stored_total, visual)` ตรงกับ `calculate_risk_score(t,v,s)["grade"]` ทุกจุด เป็นหลักฐานว่า read path ของ admin/mobile ไม่มีวัน diverge จาก scan path
- **[test_visual_override_equivalence_on_stored_totals (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: เคส `v=85` (total ถูก clamp เป็น 85) และ `v=80+t=50` (total 85) อ่าน grade ผ่าน `grade_for` ได้ high ถูกต้องโดยไม่ต้องคำนวณสูตรซ้ำ
- **[test_canonical_contract_keys (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: dict ที่คืนมี keys ครบ `total_risk_score/grade/primary_factor/is_multi_risk/breakdown{visual,textual,source}` และ grade อยู่ใน low/medium/high เท่านั้น
- **[test_build_text_analysis_keyword_heuristic / _caps_at_100 (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: ข้อความ "ด่วน ลงทุน คลิกเลย" ได้ (75, [ด่วน,ลงทุน,คลิก]) ข้อความเปล่าได้ (0, []) และ cap ที่ 100 เมื่อเจอ 6 keywords — behavior เดิมจาก scan_service ถูกย้ายมาไม่เปลี่ยน
- **[test_build_source_score_matches_settings_default (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: คืนค่าเท่ากับ `settings.DEFAULT_SOURCE_SCORE` (20) ผูก single truth กับ config ไม่ hardcode ซ้ำ

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- ไม่มีข้อผิดพลาด (0 Failed)
