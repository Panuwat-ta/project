## 2026-09-30 18:50 +07 - เปลี่ยนชื่อ field เป็น manipulation_confidence + ข้อความ XAI ไม่อ้างระดับพิกเซล

- Target: `server/tests` (เต็มชุด), `server/tests/utils/test_xai_wording.py`, `scam_image_mobile/lib/`
- Command: `./venv/bin/python -m pytest tests -q` | `flutter analyze lib/`
- Result: PASS
- Summary: Total: 176 | Passed: 176 | Failed: 0 | Skipped: 3 | Duration: 12.78s (flutter analyze: No issues found)

### บริบทของการทดสอบ

รอบนี้เปลี่ยนชื่อ field จาก `ai_gen_probability` เป็น `manipulation_confidence` ทั้งระบบ และแก้ข้อความ XAI ไม่ให้อ้างการวิเคราะห์ระดับพิกเซล เนื่องจาก S_visual มาจาก Det Head ซึ่งประเมินภาพรวม การเปลี่ยนแปลงนี้กระทบสัญญา API, schema ฐานข้อมูล, mobile entity และชื่อคอลัมน์ใน SQLite ฝั่ง mobile

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **test_xai_never_claims_ai_generation** (6 เคส):
  - พฤติกรรมที่ผ่าน: ข้อความ XAI ที่สร้างจากค่า det จริง (กล้องจริง 3 ภาพ + ภาพปลอม 3 ภาพ) ไม่ปรากศัพท์ของคำกล่าวอ้างการสังเคราะห์ด้วย AI ได้แก่ "สังเคราะห์จาก AI", "สังเคราะห์จากปัญญาประดิษฐ์", "ภาพ AI", "องค์ประกอบจาก AI"
  - หลักฐานรองรับ: `model/segformer/configs/segformer_mit-b2-v14.py` กำหนด `n=2` (authentic/forged) และ Det Head เป็น binary เดียวกัน จึงไม่มีโมเดลใดที่วัดการสังเคราะห์ด้วย AI แยก

- **test_text_does_not_claim_pixel_level_analysis** (7 เคส) — test ที่เพิ่มในรอบนี้:
  - พฤติกรรมที่ผ่าน: ข้อความไม่มี "โครงสร้างพิกเซล", "พิกเซลมีความเป็นธรรมชาติ", "พิกเซลสม่ำเสมอ" ในทุกกรณี รวมภาพกล้องจริง ภาพปลอม และภาพที่อยู่ในระดับกลาง
  - เหตุผลที่ผ่าน: โค้ดถูกแก้จาก "โครงสร้างพิกเซลของภาพมีความสม่ำเสมอ" เป็น "ผลการวิเคราะห์ภาพอยู่ในระดับต่ำ (...)" ซึ่งสอดคล้องกับ Det Head ที่ประเมินภาพรวม

- **test_text_reports_level_alongside_score** — test ที่เพิ่มในรอบนี้:
  - พฤติกรรมที่ผ่าน: ข้อความมี "ระดับสูง (100/100)", "ระดับปานกลาง (47/100)", "ระดับต่ำ (0/100)" ครบตามเกณฑ์ 70 / 40
  - เหตุผลที่ผ่าน: เพิ่มการแสดงคะแนนในวงเล็บเพื่อให้ผู้ใช้ตรวจสอบค่าได้เอง แทนการรับรองด้วยคำว่า "AI ตรวจพบ" ซึ่งเป็นการอ้างโดยไม่มีตัวเลขประกอบ

- **test_real_photo_text_is_self_consistent** (3 เคส):
  - พฤติกรรมที่ผ่าน: ข้อความของภาพกล้องจริงไม่มี "ความม่ันใจสูง" และ "ความม่ันใจปานกลาง"
  - เหตุผลที่ผ่าน: det ต่ำกว่า 0.40 จึงไม่เข้าเงื่อนไขใด ข้อความจึงไม่ผูกคำพูดกับคะแนน

- **test_manipulated_text_states_high_confidence** / **test_borderline_uses_medium_confidence**:
  - พฤติกรรมที่ผ่าน: splicing ได้ "ความม่ันใจสูง (100%)" และแชท LINE ได้ "ความม่ันใจปานกลาง (47%)"
  - เหตุผลที่ผ่าน: ค่า det 0.9999 และ 0.4662 อยู่คนละช่วงของเกณฑ์ คำนวณเปอร์เซ็นต์ด้วย `round(ค่า * 100)`

- **test_low_confidence_phrase_is_omitted_not_zero_claimed**:
  - พฤติกรรมที่ผ่าน: ข้อความไม่มี "0%" เพราะโมเดลไม่ได้ยืนยันว่า "ไม่มีการดัดแปลง" เพียงแต่ไม่พบหลักฐาน

- **test_reported_probability_follows_det_not_pixel_max**:
  - พฤติกรรมที่ผ่าน: ค่าที่รายงานเท่ากับ det 0.0006 และไม่เท่ากับค่าสูงสุดของพิกเซล 0.9988

- **test_seo_keys_unchanged**:
  - พฤติกรรมที่ผ่าน: คำสำคัญที่ส่งเข้ามายังปรากฏครบในข้อความหลังเปลี่ยนถ้อยคำ

- **test_api_scan_contract** และ test ใน `tests/api/`:
  - พฤติกรรมที่ผ่าน: การเปลี่ยนชื่อ field ไม่ทำให้ test ที่ตรวจ response contract ล้ม ทั้งหมดเปลี่ยนเป็นชื่อใหม่อย่างสอดคล้องกัน

### 2. การตรวจสอบ migration จริงบนฐานข้อมูล

- Target: PostgreSQL ผ่าน Alembic
- Command: `./venv/bin/alembic upgrade head` และ `./venv/bin/alembic downgrade -1`
- Result: PASS

- **upgrade**: `ai_gen_probability` ถูก rename เป็น `manipulation_confidence` และคอลัมน์กลายเป็น nullable
- **ผลบนข้อมูล**: scans ทั้งหมด 70 แถวมีค่า NULL (ค่าเดิม 24 แถวที่เคยเป็น ~0.99 ถูกตั้งเป็น NULL ตามที่ออกแบบไว้ เพราะค่าเดิมเป็น max-prob ระดับพิกเซลที่ไม่มีความหมายภายใต้ชื่อใหม่)
- **downgrade**: ทดสอบ rollback แล้วคอลัมน์กลับเป็น `ai_gen_probability` ได้สำเร็จ โดยต้องแก้โค้ด migration ระหว่างทำเพราะพบข้อบกพร่อง 2 จุด:
  1. `op.alter_column` ต้องระบุ `table_name` เสมอ ไม่เช่นนั้นจะตีความชื่อคอลัมน์เดิมเป็นชื่อตารางและเกิด `relation "ai_gen_probability" does not exist`
  2. `downgrade` ต้อง `DROP NOT NULL` ก่อน เพราะค่าของแถวเดิมเป็น NULL แต่คอลัมน์เดิมเป็น NOT NULL
- สถานะสุดท้าย: `alembic current` = `f1a2b3c4d5e6 (head)`

### 3. การตรวจสอบ end-to-end หลังเปลี่ยนชื่อ

สร้างผู้ใช้ทดสอบชั่วคราวแล้วสแกนผ่าน API จริง:

| ภาพ | total_risk | grade | visual | manipulation_confidence | ข้อความ XAI |
|---|---|---|---|---|---|
| กล้องจริง to173 | 16 | low | 16 | 0.1647842442616728 | "ผลการวิเคราะห์ภาพอยู่ในระดับต่ำ (16/100) ไม่พบร่องรอยการดัดแปลงที่ชัดเจนบริเวณกึ่งกลางของภาพ" |
| splicing ปลอม | 100 | high | 100 | 0.9998632812024536 | "ผลการวิเคราะห์ภาพอยู่ในระดับสูง (100/100) พบร่องรอยการตัดต่อหรือดัดแปลงภาพอย่างเด่นชัด... ความม่ันใจสูง (100%)" |

ตรวจ API response แล้วไม่มี field `ai_gen_probability` และมี `manipulation_confidence` พร้อมค่าที่ถูกต้อง

### 4. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

ไม่มีข้อผิดพลาด (0 Failed)

### 5. หมายเหตุ

- ระหว่างทำพบว่า test 5 เคสล้มก่อนแก้ เพราะฐานข้อมูลยังไม่มีคอลัมน์ใหม่ (`UndefinedColumnError: column scans.manipulation_confidence does not exist`) เมื่อรัน `alembic upgrade head` แล้วผ่านทั้งหมด จึงยืนยันว่าสาเหตุคือ migration ยังไม่ถูกรัน ไม่ใช่ข้อผิดพลาดของโค้ด
- ค่าใน Redis ที่ล้างไป 9 key ถูกระบุด้วยเงื่อนไขสองชั้น คือ payload ต้องมี field ชื่อเก่า และ key ต้องอยู่ใน namespace ของโมเดลที่ใช้อยู่ (`b3348172feb4`) เพื่อไม่กระทบ cache ของโมเดลเก่าที่ยังใช้ rollback ได้