# SegFormer Image Test Cases

## TC-AI-MASK-01 — Quantitative ONNX segmentation with ground-truth masks

- **Test Type:** Automated image regression / quantitative evaluation
- **Priority:** P0
- **Pre-conditions:** ONNX ทั้ง 6 รุ่นและ external weight files อยู่ครบตาม `evaluation_manifest.json`; ใช้ Python environment ที่มี ONNX Runtime
- **Test Data:** 105 image/mask pairs ใน `/home/panuwat/Pictures/Test-Cases/with_mask` จำนวน 15 รูปต่อหมวด: authentic, casia, copymove, face, imd2020, inpainting และ splicing
- **Steps:**
  1. รัน `./Test-Case/run_test_cases.sh` จากโฟลเดอร์ `model/segformer`
  2. ตรวจว่า inventory พบ 105 cases และ 7 หมวด
  3. ตรวจ `output/quantitative/overall.csv`, `per_category.csv` และ `per_image.csv`
  4. เปรียบเทียบทั้ง 6 รุ่นเพื่อดู regression โดยใช้ v1.0.5 เป็น release gate
- **Expected:** ทุกภาพและ mask มีขนาดตรงกัน; inference สำเร็จครบ 105 รูปต่อเวอร์ชัน; metric มาจาก confusion counts ที่รวมทุกพิกเซล; v1.0.5 มี mDice ≥ 85%; ไม่มีการนำผลชุดนี้ไปแทน common locked test ranking
- **Automation Mapping:** `evaluate_with_masks.py`, `test_evaluation_core.py`, `run_test_cases.sh`

## TC-AI-PAIR-01 — Manipulated-image heatmap manual review

- **Test Type:** Qualitative / manual
- **Priority:** P1
- **Pre-conditions:** มี original/manipulated ครบ 30 คู่และ ONNX ตาม manifest
- **Test Data:** `/home/panuwat/Pictures/Test-Cases/pairs`
- **Steps:**
  1. รัน `./Test-Case/run_test_cases.sh`
  2. เปิด `output/qualitative/<version>/pair001.png` ถึง `pair030.png`
  3. เปรียบเทียบตำแหน่ง heatmap บน manipulated กับบริเวณที่มองเห็นว่าเพิ่ม/เปลี่ยนจากต้นฉบับ
  4. บันทึกคู่ที่ heatmap ไม่สัมพันธ์กับจุดตัดต่อเพื่อวิเคราะห์เพิ่มเติม
- **Expected:** สร้างภาพ 30 ภาพต่อเวอร์ชันในโฟลเดอร์แยกของตัวเอง; caption ระบุ ONNX, threshold, inference setting และข้อความว่าไม่มี mask; ผู้ตรวจไม่สรุป IoU/Dice/accuracy จากภาพชุดนี้
- **Automation Mapping:** `render_qualitative_pairs.py` (สร้าง artifact), manual review (ตัดสินผล)

## TC-AI-PAIR-02 — Original-image false-positive manual review

- **Test Type:** Qualitative / manual false-positive check
- **Priority:** P1
- **Pre-conditions:** เหมือน TC-AI-PAIR-01
- **Test Data:** original 30 รูปที่จับคู่กับ manipulated
- **Steps:**
  1. เปิด original heatmap ของทุกคู่และทุกเวอร์ชัน
  2. ตรวจพื้นที่สว่างที่เกิน threshold 40%
  3. ใช้ `qualitative_pair_scores.csv` ช่วยค้นคู่ที่มี peak/area สูง แล้วตรวจภาพจริงด้วยตา
- **Expected:** ได้รายการ false-positive candidates สำหรับ regression investigation; peak/area เป็นเพียงตัวช่วยคัดกรอง ไม่ใช่ accuracy และไม่ถือว่าโมเดลผ่าน/ตกโดยอัตโนมัติ
- **Automation Mapping:** `render_qualitative_pairs.py` (สร้าง artifact), manual review (ตัดสินผล)
