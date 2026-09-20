## 2026-09-19 04:40 +07 - [Tiling Shared Module / parity + eval unittest]

- Target: server/tests/utils/test_tiling_parity.py (ใหม่), model Test-Case/test_evaluation_core.py (เดิม, unittest), server tests/utils + test_scan.py (เดิม)
- Command: `python -m pytest tests/utils/ tests/api/test_scan.py -q` (server venv) + `python test_evaluation_core.py` (model venv)
- Result: PASS
- Summary: Total: 27 + 3 | Passed: 26 + 3 | Failed: 0 | Skipped: 1 | Duration: ~0.5 วินาที

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)
- **[test_worker_and_eval_agree_on_tiling / _small_image (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: fake session เดียวกัน tiling ฝั่ง serving กับ OnnxSegmenter ให้ prob map ตรงกันทั้งภาพใหญ่ (700x500, ผ่าน tiling จริง) และภาพเล็ก (100x80, single patch) — พิสูจน์ single truth ข้าม process
- **[test_det_score_matches_and_none_without_head (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: det logit 2.0 ได้ sigmoid ตรงสูตร, โมเดล 1 output ได้ None — worker กับ eval ใช้ฟังก์ชันเดียวกันแล้ว
- **[test_shared_constants_single_truth (ใหม่)]**:
  - พฤติกรรมที่ผ่าน: IMAGENET_MEAN/STD ฝั่ง eval กับ serving เป็น object เดียวกัน (re-export ไม่ใช่สำเนา)
- **[test_evaluation_core.py 3 เคสเดิม (model venv)]**:
  - พฤติกรรมที่ผ่าน: OnnxSegmenter ผ่าน delegation ยังให้ผลเดิม (Ran 3 tests OK)
- **[22 เคสเดิม server]**:
  - พฤติกรรมที่ผ่าน: ผ่านครบ worker import sibling ได้จริง (verify แยก)

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)
- ไม่มีข้อผิดพลาด (0 Failed; 1 skipped ของเดิม)
