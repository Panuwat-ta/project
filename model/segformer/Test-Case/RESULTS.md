# Test Run Results — 2026-09-15

คำสั่งที่ใช้:

```bash
cd /home/panuwat/project/model/segformer/Test-Case
./run_test_cases.sh
```

## Execution summary

- Core unit tests: 3 passed
- Local data inventory integration tests: 3 passed
- ONNX contract tests: 3 passed สำหรับโมเดลทั้ง 6 รุ่น
- Quantitative cases: 630 inferences (105 image/mask pairs × 6 versions)
- Qualitative artifacts: 180 images (30 original/manipulated pairs × 6 versions)
- Runner status: **FAILED release gate** เพราะ v1.0.5 mDice 84.87% ต่ำกว่าเกณฑ์ 85.00% อยู่ 0.13 percentage points

## Local masked Test-Case results

ตัวเลขทั้งหมดเป็นเปอร์เซ็นต์จาก local Test-Case 105 รูป ไม่ใช่ผลจาก common locked test set และไม่ใช้แทนการจัดอันดับอย่างเป็นทางการ

| Version | mIoU | mDice | Forgery IoU | Forgery Dice | Accuracy | FPR |
|---|---:|---:|---:|---:|---:|---:|
| v1.0.0 | 48.41 | 53.19 | 5.90 | 11.14 | 90.98 | 1.09 |
| v1.0.1 | 47.83 | 51.69 | 4.02 | 7.73 | 91.67 | 0.09 |
| v1.0.2 | 49.80 | 55.18 | 7.94 | 14.70 | 91.73 | 0.43 |
| v1.0.3 | 50.28 | 55.98 | 8.87 | 16.30 | 91.75 | 0.51 |
| v1.0.4 | 61.74 | 71.69 | 30.93 | 47.24 | 92.80 | 2.00 |
| v1.0.5 | **75.96** | **84.87** | **56.11** | **71.89** | **96.01** | **0.54** |

v1.0.5 เป็นอันดับหนึ่งของ local set นี้ แต่ยังไม่ผ่าน release gate ที่กำหนดไว้ หมวดที่ควรตรวจต่อจาก `per_category.csv` คือ copymove (Forgery Dice 3.66%), imd2020 (14.65%) และ inpainting (41.44%) ส่วน face ได้ 98.59% และ splicing ได้ 85.22%

ไฟล์รายละเอียดอยู่ใน `output/quantitative/` และภาพตรวจด้วยตาอยู่ใน `output/qualitative/<version>/` ข้อมูล output เป็น local generated artifacts และไม่ถูกเพิ่มเข้า Git

---

# Test Run Results — 2026-09-18 (7 versions, รวม v1.0.6)

คำสั่งที่ใช้:

```bash
cd /home/panuwat/project/model/segformer
./Test-Case/run_test_cases.sh v1.0.6   # รอบแรก: ตรวจเฉพาะ v1.0.6 (PASS, ไม่บังคับ gate)
./Test-Case/run_test_cases.sh          # รอบสอง: รวมทุกรุ่น v1.0.0-v1.0.6 เพื่อสร้าง combined outputs
```

Locked common test ของ v1.0.6 (แยกต่างหาก, ไม่ใช่ local set):

```bash
./venv/bin/python library/mmsegmentation/tools/test.py \
  configs/segformer_mit-b2-v11.py \
  work_dirs/v1.0.6/best_mIoU_iter_195000.pth \
  --work-dir work_dirs/v1.0.6/test_eval \
  --cfg-options test_dataloader.batch_size=16
```

ผล locked common test (`scamguard-locked-multisource-test-v1`, 2504/2504 batches, run `20260918_092047`):
`v1.0.6` ได้ mIoU **94.83** / mDice **97.29** / Forgery IoU **90.26** / Forgery Dice **94.88** / aAcc 99.43
เป็นอันดับหนึ่งเหนือ `v1.0.5` (mIoU 91.24 / Forgery IoU 83.51) และถูกลงทะเบียนใน `tests_model/evaluation_manifest.json` แล้ว

## Execution summary (รอบรวม 7 รุ่น)

- Core unit tests: 6 passed
- ONNX contract tests: 3 passed สำหรับโมเดลทั้ง 7 รุ่น (รวม `segformer_v1_0_6_dynamic.onnx`)
- Quantitative cases: 735 inferences (105 image/mask pairs × 7 versions)
- Qualitative artifacts: 210 images (30 original/manipulated pairs × 7 versions)
- Runner status: **FAILED release gate** เพราะ gate ยังผูกกับ v1.0.5 (mDice 84.87% ต่ำกว่าเกณฑ์ 85.00% อยู่ 0.13 points) ส่วน `v1.0.6` เองได้ mDice 90.17% ซึ่งผ่านเกณฑ์ 85% แล้ว แต่ยังไม่มีการย้าย gate อย่างเป็นทางการ

## Local masked Test-Case results (combined, 2026-09-18)

ตัวเลขทั้งหมดเป็นเปอร์เซ็นต์จาก local Test-Case 105 รูป ไม่ใช่ผลจาก common locked test set และไม่ใช้แทนการจัดอันดับอย่างเป็นทางการ

| Version | mIoU | mDice | Forgery IoU | Forgery Dice | Accuracy | FPR |
|---|---:|---:|---:|---:|---:|---:|
| v1.0.0 | 48.41 | 53.19 | 5.90 | 11.14 | 90.98 | 1.09 |
| v1.0.1 | 47.83 | 51.69 | 4.02 | 7.73 | 91.67 | 0.09 |
| v1.0.2 | 49.80 | 55.18 | 7.94 | 14.70 | 91.73 | 0.43 |
| v1.0.3 | 50.28 | 55.98 | 8.87 | 16.30 | 91.75 | 0.51 |
| v1.0.4 | 61.74 | 71.69 | 30.93 | 47.24 | 92.80 | 2.00 |
| v1.0.5 | 75.96 | 84.87 | 56.11 | 71.89 | 96.01 | 0.54 |
| v1.0.6 | **83.14** | **90.17** | **69.35** | **81.90** | **97.13** | **0.83** |

`v1.0.6` เป็นอันดับหนึ่งของ local set นี้ และผ่านเกณฑ์ 85% แล้ว รายหมวดจาก `per_category.csv`:
copymove Forgery Dice 65.86% (เดิม v1.0.5 ได้ 3.66%),
imd2020 42.13% (เดิม 14.65%),
inpainting 84.79% (เดิม 41.44%),
casia 83.92%, splicing 91.13%, face 98.89%,
authentic FPR 0.01% หมวดที่ยังอ่อนที่สุดคือ imd2020

สำเนาสำหรับคนอ่านอยู่ใน `spreadsheets/quantitative/` (overall/per_category/per_image/summary) และ `spreadsheets/qualitative/` (combined + แยก 7 ไฟล์รายเวอร์ชัน)

---

# Test Run Results — 2026-09-23 (v1.0.7)

คำสั่งหลักที่ใช้รูปแบบเดียวกับรุ่นก่อน:

```bash
cd /home/panuwat/project/model/segformer
./Test-Case/run_test_cases.sh v1.0.7
```

Locked common test ใช้ checkpoint `best_mIoU_iter_240000.pth` และชุด `scamguard-locked-multisource-test-v1` เดิมครบ **2504/2504 batches** (run `20260923_164151`): mIoU **94.96**, mDice **97.36**, Forgery IoU **90.50**, Forgery Dice **95.01**, Forgery Accuracy **95.11**, aAcc **99.44**. เทียบ `v1.0.6` เพิ่มขึ้น +0.13 mIoU, +0.07 mDice, +0.24 Forgery IoU และ +0.13 Forgery Dice percentage points.

ONNX parity ระหว่าง PyTorch checkpoint กับ `segformer_v1_0_7_dynamic.onnx` ผ่าน: output shape ตรงกัน `(1, 2, 64, 80)`, finite ทั้งคู่, max absolute difference `4.0531e-06`, mean absolute difference `1.1682e-06`, และ `allclose(rtol=1e-4, atol=1e-4)` เป็น True.

## Execution summary

- Core unit + data inventory: **6/6 passed**
- ONNX contract tests: **3/3 passed**
- Quantitative masked cases: **105/105 completed**
- Qualitative pairs: **30/30 completed**
- Runner status: **PASS** สำหรับการรันเฉพาะ `v1.0.7` (ไม่บังคับ legacy release gate ของ v1.0.5)

## Local masked Test-Case comparison

| Version | mIoU | mDice | Forgery IoU | Forgery Dice | Accuracy | FPR |
|---|---:|---:|---:|---:|---:|---:|
| v1.0.6 | 83.14 | 90.17 | 69.35 | 81.90 | 97.13 | 0.83 |
| v1.0.7 | 81.13 | 88.78 | 65.76 | 79.34 | 96.72 | 1.08 |

รายหมวด `v1.0.7`: CopyMove Forgery Dice **74.62%** (v1.0.6: 65.86%), IMD2020 **49.62%** (42.13%), Inpainting **88.02%** (84.79%), Splicing **91.73%** (91.13%); แต่ CASIA ลดเป็น **72.57%** (83.92%) และ Face ลดเป็น **96.56%** (98.89%). Authentic FPR เพิ่มจาก **0.01%** เป็น **0.19%**.

ตาม promotion gate ที่ระบุใน config v12: locked mDice ≥ 97.29 **ผ่าน** (97.36), local IMD2020 Forgery Dice > 50% **ยังไม่ผ่าน** (49.62), และ overall FPR ≤ 1.0% **ยังไม่ผ่าน** (1.08). ดังนั้นผลทดสอบถูกบันทึกครบแล้ว แต่ยังไม่มีการเปลี่ยน production deployment จาก `v1.0.6`.

สำเนาสำหรับคนอ่านถูกอัปเดตใน `spreadsheets/quantitative/` เป็น 8 รุ่น (840 image rows) และ `spreadsheets/qualitative/` เป็น 240 pair rows พร้อมไฟล์ `qualitative_pair_scores_v1.0.7.csv`.
