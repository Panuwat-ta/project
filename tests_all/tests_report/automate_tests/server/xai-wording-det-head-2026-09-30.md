## 2026-09-30 18:05 +07 - ข้อความ XAI: ตัดคำกล่าวอ้าง AI-generation (server/tests/utils/test_xai_wording.py)

- Target: `server/tests/utils/test_xai_wording.py`
- Command: `./venv/bin/python -m pytest tests/utils/test_xai_wording.py -q`
- Result: PASS
- Summary: Total: 14 | Passed: 14 | Failed: 0 | Skipped: 0 | Duration: 4.72s

### บริบทของการทดสอบ

บั๊กเดิม: `ai_gen_probability` รายงานค่าจาก `prob_map.max()` ซึ่งเป็น ~0.99 บนภาพ 12 MP ทุกภาพ ค่านี้ถูกส่งเข้า `inference_service.py` แล้วแปลงเป็นประโยค "โดยมีโอกาสสูง (100%) ที่เป็นภาพสังเคราะห์จากปัญญาประดิษฐ์" ทำให้ข้อความ XAI ขัดแย้งกับตัวเองในประโยคเดียวบนภาพถ่ายจริง

หลักฐานว่าเราไม่มีโมเดลวัด AI-generation: `model/segformer/configs/segformer_mit-b2-v14.py` กำหนด `n=2` (คลาส 0 authentic, คลาส 1 forged) และ Det Head เป็น binary เดียวกัน จึงไม่มีโมเดลใดแยกภาพสังเคราะห์ด้วย AI ออกจากภาพที่ถูกดัดแปลง

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **test_xai_never_claims_ai_generation** (6 เคส: กล้องจริง 3 + ภาพปลอม 3):
  - พฤติกรรมที่ผ่าน: เรียก `fallback_xai_explanation` ด้วยค่า det ที่วัดจริง แล้วยืนยันว่าข้อความที่ได้ไม่มีคำใดในรายการต้องห้าม ได้แก่ "สังเคราะห์จาก AI", "สังเคราะห์จากปัญญาประดิษฐ์", "ภาพ AI", "องค์ประกอบจาก AI"
  - ครอบคลุมทั้งภาพกล้องจริง (to171 det 0.0006, to175 det 0.2123, to180 det 0.2257) และภาพถูกดัดแปลง (splicing det 0.9999, inpainting det 0.9996, casia det 0.9906) เพื่อยืนยันว่าไม่มีการอ้าง AI-generation ในทั้งสองทาง

- **test_real_photo_text_is_self_consistent** (3 เคส):
  - พฤติกรรมที่ผ่าน: ข้อความของภาพกล้องจริงไม่มีคำว่า "ความม่ันใจสูง" และ "ความม่ันใจปานกลาง"
  - เหตุผลที่ผ่าน: เพราะ det ต่ำกว่า 0.40 โค้ดจึงไม่เข้าเงื่อนไขใดเลย จึงไม่ผูกคำพูดกับคะแนน ข้อความจึงเล่าได้แค่เรื่องโครงสร้างพิกเซลกับคำสำคัญ ไม่ขัดกับตัวเอง

- **test_manipulated_text_states_high_confidence**:
  - พฤติกรรมที่ผ่าน: ข้อความมี "ความม่ันใจสูง (100%) ว่าภาพถูกตัดต่อหรือดัดแปลง"
  - เหตุผลที่ผ่าน: det 0.9999 มากกว่าเกณฑ์ 0.70 จึงเข้าเงื่อนไขสูง และคำนวณเปอร์เซ็นต์เป็น `round(0.9999 * 100)` = 100

- **test_borderline_uses_medium_confidence**:
  - พฤติกรรมที่ผ่าน: ข้อความมี "ความม่ันใจปานกลาง (47%) ว่าภาพถูดตัดต่อหรือดัดแปลง"
  - เหตุผลที่ผ่าน: det 0.4662 อยู่ระหว่าง 0.40 ถึง 0.70 จึงเข้าเงื่อนไขกลาง และ `round(0.4662 * 100)` = 47 ตรงกับค่าที่วัดจากการสแกนจริง

- **test_low_confidence_phrase_is_omitted_not_zero_claimed**:
  - พฤติกรรมที่ผ่าน: ข้อความไม่มี "0%" แต่ยังคงมีประโยค "ไม่พบข้อความหรือคำสำคัญที่เกี่ยวข้องกับการหลอกลวง"
  - เหตุผลที่ผ่าน: โค้ดไม่มีเงื่อนไขสำหรับค่าต่ำ จึงไม่ผูกคำพูดเลย ซึ่งถูกต้องเพราะโมเดลไม่ได้ยืนยันว่า "ไม่มีการดัดแปลง" เพียงแต่ไม่พบหลักฐาน

- **test_reported_probability_follows_det_not_pixel_max**:
  - พฤติกรรมที่ผ่าน: `reported` เท่ากับ det 0.0006 และไม่เท่ากับค่าสูงสุดของพิกเซล 0.9988
  - เหตุผลที่ผ่าน: ยืนยันว่า `ai_gen_probability` ในผลลัพธ์ถูกเปลี่ยนไปอ่าน det score แล้ว และ `visual_score_from_det` ยังคืน 0 สำหรับคู่ค่านี้

- **test_seo_keys_unchanged**:
  - พฤติกรรมที่ผ่าน: คำสำคัญที่ส่งเข้ามายังปรากฏครบในข้อความ และข้อความยาวเพียงพอ
  - เหตุผลที่ผ่าน: ยืนยันว่าการแก้ถ้อยคำไม่ได้ทำให้โครงสร้างข้อความเสีย

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed)

### 3. การตรวจสอบว่า test จับบั๊กได้จริง (Mutation Check)

แก้ข้อความใน `fallback_xai_explanation` กลับไปเป็นของเดิม "โดยมีโอกาสสูง ({ai_pct}%) ที่เป็นภาพสังเคราะห์จากปัญญาประดิษฐ์" แล้วรันซ้ำ:

- ผลลัพธ์: **4 failed, 10 passed**
- test ที่จับได้: `test_xai_never_claims_ai_generation`, `test_manipulated_text_states_high_confidence`
- หลังคืนโค้ดจริง: **14 passed**

### 4. ผลรวมการตรวจสอบของรอบนี้

- Target: `server/tests/utils/test_xai_wording.py` + `server/tests/utils/test_visual_score.py`
- Command: `./venv/bin/python -m pytest tests/utils/test_xai_wording.py tests/utils/test_visual_score.py -q`
- Result: PASS
- Summary: Total: 28 | Passed: 28 | Failed: 0 | Skipped: 0 | Duration: 4.67s

- Target: `server/tests` (เต็มชุด)
- Command: `./venv/bin/python -m pytest tests -q`
- Result: PASS
- Summary: Total: 168 | Passed: 168 | Failed: 0 | Skipped: 3 | Duration: 8.67s

- Target: `scam_image_mobile/lib/features/result/data/models/analysis_result_model.dart`
- Command: `flutter analyze lib/features/result/data/models/analysis_result_model.dart`
- Result: PASS
- Summary: No issues found (ran in 0.7s)

### 5. การตรวจสอบ end-to-end ผ่าน API จริง

| ภาพ | total_risk | grade | visual | ai_gen_probability | ข้อความ XAI |
|---|---|---|---|---|---|
| กล้องจริง to172 | 0 | low | 0 | 0.002786271089011335 | "โครงสร้างพิกเซลของภาพมีความสม่ำเสมอ ... และไม่พบข้อความหรือคำสำคัญ" |
| inpainting ปลอม | 100 | high | 100 | 0.9995617462183949 | "ความผิดปกติระดับสูง ... โดยมีความม่ันใจสูง (100%) ว่าภาพถูกตัดต่อหรือดัดแปลง" |

ข้อความของภาพกล้องจริงไม่มีประโยคที่ขัดแย้งกับตัวเองแล้ว และภาพถูกดัดแปลงยังถูกจับพร้อมคำอธิบายที่ถูกต้อง