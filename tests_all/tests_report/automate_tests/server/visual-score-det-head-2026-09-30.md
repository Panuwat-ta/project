## 2026-09-30 17:35 +07 - Visual Risk Score: Det Head (server/tests/utils/test_visual_score.py)

- Target: `server/tests/utils/test_visual_score.py`
- Command: `./venv/bin/python -m pytest tests/utils/test_visual_score.py -v`
- Result: PASS
- Summary: Total: 14 | Passed: 14 | Failed: 0 | Skipped: 0 | Duration: 0.18s

### บริบทของการทดสอบ

ชุดทดสอบนี้คุมสูตร `S_visual` ที่เพิ่งเปลี่ยนใน `server/app/services/onnx_worker.py` (ฟังก์ชัน `visual_score_from_det`) โดยค่าทั้งหมดที่ใช้เป็น input เป็นค่าที่วัดจริงจากการรัน ONNX บนภาพใน `Test-Cases` และภาพกล้องจริงเมื่อ 2026-09-30 ไม่ใช่ค่าสมมติ

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **test_real_camera_photo_is_not_a_false_positive** (3 เคส):
  - พฤติกรรมที่ผ่าน: ภาพกล้องจริงได้ `visual_score` = 0, 2, 0 ตามลำดับ แทนที่จะได้ 100
  - เหตุผลที่ผ่าน: เมื่อส่งค่า det ต่ำ (0.0029, 0.0166, 0.0006) ฟังก์ชันคูณด้วย 100 แล้วปัดเป็นจำนวนเต็ม จึงได้ 0, 2, 0 ตามลำดับ ส่วน `prob_map.max()` ที่ส่งเข้าไปด้วย (0.9988, 0.9955, 0.9989) ถูกข้ามไปเพราะมี det head
  - เทียบกับพฤติกรรมเดิม: สูตร max-prob เดิมให้ 100, 100, 100 ซึ่งเป็น false positive ทั้งสามภาพ

- **test_manipulated_image_is_still_detected** (3 เคส):
  - พฤติกรรมที่ผ่าน: splicing = 100, inpainting = 100, casia = 99
  - เหตุผลที่ผ่าน: ภาพเหล่านี้มี det สูงเกือบ 1.0 (0.9999, 0.9996, 0.9906) คูณ 100 แล้วปัดได้ 100, 100, 99 ตามลำดับ
  - จุดที่สำคัญ: เคส inpainting มี `prob_map.max()` เพียง 0.5038 ซึ่งถ้าใช้สูตรเดิมจะได้คะแนน 50 เท่านั้น แต่ด้วย det head ได้ 100 จึงยังจับภาพถูกดัดแปลงได้ครบ

- **test_borderline_scores_map_linearly** (3 เคส):
  - พฤติกรรมที่ผ่าน: แชท LINE (det 0.4662) = 47, กล้องจริง (det 0.2123) = 21, กล้องจริง (det 0.2257) = 23
  - เหตุผลที่ผ่าน: คะแนนแปรผันตรงกับ det score แบบเชิงเส้น ทำให้ภาพแชทที่มีความสงสัยปานกลางได้ระดับ medium แทนการถูกจัดเป็น high ทั้งหมด

- **test_det_score_overrides_noisy_pixel_maximum**:
  - พฤติกรรมที่ผ่าน: คู่ (det=0.0029, max=0.9988) ได้ 0 และคู่ (det=0.0, max=1.0) ได้ 0
  - เหตุผลที่ผ่าน: นี่คือ regression test หัวใจของบั๊กเดิม โดยพิสูจน์ว่าแม้ `prob_map.max()` จะสูงถึง 1.0 (ค่าสูงสุดของ noise ในพิกเซลราว 12 ล้านจุดของภาพ 12 MP) คะแนนยังเป็น 0 เพราะ det ต่ำ

- **test_low_max_prob_with_high_det_is_still_high**:
  - พฤติกรรมที่ผ่าน: (det=0.9996, max=0.5038) ได้ 100
  - เหตุผลที่ผ่าน: ยืนยันว่า inpainting ไม่หลุดจากการที่ max-prob ต่ำ

- **test_falls_back_to_max_prob_without_det_head**:
  - พฤติกรรมที่ผ่าน: เมื่อส่ง det = None แล้ว max = 0.87 ได้ 87; max = 0.0 ได้ 0
  - เหตุผลที่ผ่าน: ครอบคลุมโมเดล single-output ที่ไม่มี det head ซึ่งยังต้องทำงานได้ด้วยสูตร max-prob เดิม ป้องกัน regression เมื่อเปลี่ยนโมเดล

- **test_score_is_always_clamped_to_0_100**:
  - พฤติกรรมที่ผ่าน: ทดสอบ det ตั้งแต่ -1.0 ถึง 2.0 แล้วได้คะแนนอยู่ในช่วง 0-100 ทุกกรณี; det=1.5 ได้ 100 และ det=-0.5 ได้ 0
  - เหตุผลที่ผ่าน: ยืนยันว่า `min(100, max(0, ...))` ทำงานถูกต้องตาม `Normalize` ใน `Document/model/configs.md` §3

- **test_rounding_matches_normalize_spec**:
  - พฤติกรรมที่ผ่าน: det 0.4652 ได้ 47, det 0.9906 ได้ 99, det 0.5 ได้ 50
  - เหตุผลที่ผ่าน: ยืนยันการปัดเลขตาม `Normalize(y) = min(100, round(y * 100))` โดยเฉพาะกรณี 0.4652 ที่ปัดขึ้นจาก 46.52 เป็น 47

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed)

### 3. การตรวจสอบว่า test จับบั๊กได้จริง (Mutation Check)

เพื่อยืนยันว่าชุดทดสอบนี้ไม่ใช่ผ่านแบบว่างเปล่า จึงแก้โค้ด `visual_score_from_det` ให้กลับไปใช้ `max-prob` ล้วนแบบที่เคยเป็นบั๊ก แล้วรันซ้ำ:

- ผลลัพธ์: **12 failed, 2 passed**
- test ที่จับได้: `test_real_camera_photo_is_not_a_false_positive`, `test_manipulated_image_is_still_detected`, `test_borderline_scores_map_linearly`, `test_det_score_overrides_noisy_pixel_maximum`, `test_low_max_prob_with_high_det_is_still_high`, `test_falls_back_to_max_prob_without_det_head`, `test_score_is_always_clamped_to_0_100`, `test_rounding_matches_normalize_spec`
- หลังคืนโค้ดจริง: **14 passed**

### 4. ผลรันเต็มชุดของ server

- Target: `server/tests`
- Command: `./venv/bin/python -m pytest tests -q`
- Result: PASS
- Summary: Total: 153 | Passed: 153 | Failed: 0 | Skipped: 4 | Duration: 12.73s