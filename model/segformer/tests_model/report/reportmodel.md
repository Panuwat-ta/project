# รายงานผลการประเมินโมเดล SegFormer (ScamGuard)

รายงานนี้แยกหลักฐานออกเป็น 3 ประเภทอย่างชัดเจน:

1. **Common Test** — ชุดทดสอบล็อกเดียวกันสำหรับ `v1.0.0`–`v1.0.5` ใช้จัดอันดับโมเดล
2. **Validation / Training** — ใช้ติดตามการเทรนของแต่ละรุ่นเท่านั้น เพราะ protocol ต่างกัน
3. **Qualitative Demo** — ภาพเลือกมาสาธิตพฤติกรรม ไม่มี ground truth และไม่ใช่ benchmark

ข้อมูลอ้างอิงกลางอยู่ที่ `tests_model/evaluation_manifest.json` ซึ่งตรึง checkpoint, training log, test log และ run ID ของทุกรุ่น ผล Common Test ด้านล่างมาจาก run ที่สำเร็จครบ **2,504/2,504 batches** เท่านั้น จำนวนภาพจริงยังไม่มีใน log จึงไม่อนุมานจาก batch size

## 1. ผลจาก Locked Common Test Set

Dataset identifier: `scamguard-locked-multisource-test-v1`

| อันดับ | เวอร์ชัน | Checkpoint iteration | Test run ID | mIoU (%) | mDice (%) | Forgery IoU (%) | Forgery Dice (%) | Forgery Accuracy (%) |
|:---:|:---:|---:|:---:|---:|---:|---:|---:|---:|
| **1** | **`v1.0.5`** | **197,500** | `20260915_084109` | **91.24** | **95.25** | **83.51** | **91.01** | **89.01** |
| 2 | `v1.0.4` | 495,000 | `20260915_095832` | 81.21 | 88.74 | 64.94 | 78.74 | 79.87 |
| 3 | `v1.0.0` | 112,000 | `20260915_101330` | 48.70 | 51.42 | 2.92 | 5.67 | 2.97 |
| 4 | `v1.0.3` | 160,000 | `20260915_094407` | 47.99 | 50.08 | 1.53 | 3.01 | 1.54 |
| 5 | `v1.0.2` | 132,000 | `20260915_092949` | 47.81 | 49.72 | 1.16 | 2.29 | 1.17 |
| 6 | `v1.0.1` | 152,000 | `20260915_091531` | 47.80 | 49.69 | 1.12 | 2.22 | 1.13 |

ข้อสรุปจากข้อมูลที่เปรียบเทียบได้:

- `v1.0.5` เป็นอันดับหนึ่งทั้ง overall และ Forgery-class metrics บน common test ที่ล็อกไว้
- `v1.0.4` เป็นอันดับสอง และผ่านเกณฑ์ NFR-AI-01 เดิมที่กำหนด mDice ≥ 85%
- `v1.0.0`–`v1.0.3` มี Forgery-class performance ต่ำบน common test แม้ background metrics สูง จึงไม่ควรใช้ overall accuracy เพียงค่าเดียวสรุปคุณภาพ
- ผลนี้ยังไม่มี confidence interval หรือผลจากหลาย random seeds ตามขอบเขตของโครงงาน

กราฟหลัก: `figs/common_test_overall_metrics.*` และ `figs/common_test_forgery_metrics.*`

## 2. Validation และ Training Diagnostics

| เวอร์ชัน | Training run ID | Best validation iteration | Best validation mIoU (%) | Best validation mDice (%) |
|:---:|:---:|---:|---:|---:|
| `v1.0.0` | `20260717_205331` | 112,000 | 72.42 | 81.40 |
| `v1.0.1` | `20260808_051906` | 152,000 | 75.48 | 83.79 |
| `v1.0.2` | `20260809_133842` | 132,000 | 67.99 | 76.55 |
| `v1.0.3` | `20260810_175651` | 160,000 | 72.62 | 81.30 |
| `v1.0.4` | `20260814_062529` | 495,000 | 86.38 | 92.22 |
| `v1.0.5` | `20260910_151223` | 197,500 | 91.31 | 95.29 |

> **Validation sets differ — not for model ranking.** ค่านี้ใช้เลือก checkpoint และวิเคราะห์ convergence ภายใน run เท่านั้น กราฟข้ามรุ่นอยู่ใน `figs/diagnostics/` และระบุข้อจำกัดนี้ไว้บนภาพ

กราฟ `validation_vs_test_miou.*` แสดง validation-to-test gap เพื่อช่วยตรวจ domain shift แต่ไม่ใช้ประกาศผู้ชนะ

## 3. Qualitative Demo (n=3)

| ภาพสาธิต | `v1.0.0` max forgery probability / visual score (%) | `v1.0.4` max forgery probability / visual score (%) |
|:---|---:|---:|
| Photoshop splicing | 98.47 | 20.52 |
| Complex montage | 83.24 | 43.07 |
| Authentic natural image | 2.75 | 3.36 |

ภาพทั้งสามถูกเลือกเพื่อดูตำแหน่ง heatmap และพฤติกรรมเชิงคุณภาพ ไม่มี sampling protocol หรือ ground-truth mask จึง **ห้ามเรียกว่า benchmark, accuracy หรือผลทดสอบทางสถิติ** ความแตกต่างจาก common test สะท้อนว่าภาพตัวอย่างจำนวนน้อยไม่สามารถใช้สรุปความสามารถทั่วไปของโมเดลได้

กราฟ canonical มีไฟล์เดียวต่อ format: `figs/qualitative_demo.png` และ `figs/qualitative_demo.svg`

## 4. Qualitative ONNX Example

แต่ละเวอร์ชันมี `tests_model/v/<version>/test_qualitative_onnx.py` สำหรับรัน ONNX เฉพาะรุ่น และสร้างภาพ `<version>_qualitative_onnx_example.{png,svg}` ด้วย input/preprocessing เดียวกัน ภาพแสดง Forgery probability map ด้วย colormap `magma` และ threshold overlay เพื่อเปรียบเทียบพฤติกรรมเชิงคุณภาพ แต่ไม่มี ground-truth mask จึงไม่รายงาน IoU, Dice หรือ accuracy และไม่ใช้จัดอันดับโมเดล

## 5. ประวัติการตั้งค่าหลัก

| เวอร์ชัน | Config | ฐานข้อมูล/แนวทาง |
|:---:|:---|:---|
| `v1.0.0` | `segformer_mit-b2-v2.py` | CASIA 2.0, train from scratch |
| `v1.0.1` | `segformer_mit-b2-v3.py` | Fine-tune สำหรับ Defacto Inpainting |
| `v1.0.2` | `segformer_mit-b2-v5.py` | CASIA 2.0 + Defacto |
| `v1.0.3` | `segformer_mit-b2-v5.py` | CASIA 2.0 + Defacto, ปรับโครงสร้างข้อมูล |
| `v1.0.4` | `segformer_mit-b2-v7.py` | รวม 6 ชุดข้อมูล, checkpoint ที่ 495k |
| `v1.0.5` | `segformer_mit-b2-v10.py` | Balanced multi-dataset, checkpoint ที่ 197.5k |

ผล demo ในอดีตเคยชี้สัญญาณ domain shift ของ `v1.0.4` แต่ไม่เพียงพอจะสรุปว่าโมเดลล้มเหลวทั่วไป ผล common test ปัจจุบันแสดงว่า `v1.0.4` เป็นอันดับสองและ `v1.0.5` ปรับ Forgery-class performance ขึ้นอย่างชัดเจน

## 6. สถานะ Production

- Production ปัจจุบันยังคงเป็น `v1.0.0`; งานรายงานนี้ **ไม่เปลี่ยน** `ONNX_MODEL_PATH` หรือ deploy model
- `v1.0.5` เป็น candidate ที่ดีที่สุดจาก common test และ export ONNX แล้ว
- การเลื่อน `v1.0.5` เป็น Production เป็นงานแยก ต้องตรวจ PyTorch–ONNX numerical parity, end-to-end behavior, latency/memory บนเครื่องเป้าหมาย และอนุมัติการเปลี่ยน deployment configuration

## 7. Artefacts ที่สร้างซ้ำได้

- `evaluation_manifest.json` — source of truth สำหรับ version/checkpoint/ONNX/log/run/dataset
- `report/figs/common_test_summary.csv` — overall และ per-class common-test metrics
- `report/figs/training_validation_summary.csv` — จำนวน log points, validation runs และ best validation
- `report/test_onnx_models.py` — ตรวจไฟล์, input/output contract, dynamic shape, deterministic output และ probability ของ ONNX ทุกรุ่น
- `report/figs/*.png` — raster 200 DPI
- `report/figs/*.svg` — vector สำหรับรายงาน
- `tests_model/v/<version>/` — loss, validation และ Qualitative ONNX Example รายรุ่น

รันซ้ำและทดสอบ parser ตามคำสั่งใน `tests_model/README.md`
