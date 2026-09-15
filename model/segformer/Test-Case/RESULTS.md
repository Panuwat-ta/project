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
