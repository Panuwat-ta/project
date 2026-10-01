# รายงานผลการประเมินโมเดล SegFormer (ScamGuard)

รายงานนี้แยกหลักฐานออกเป็น 3 ประเภทอย่างชัดเจน:

1. **Common Test** — ชุดทดสอบล็อกเดียวกันสำหรับ `v1.0.0`–`v1.0.8` ใช้จัดอันดับโมเดล
2. **Validation / Training** — ใช้ติดตามการเทรนของแต่ละรุ่นเท่านั้น เพราะ protocol ต่างกัน
3. **Qualitative Demo** — ภาพเลือกมาสาธิตพฤติกรรม ไม่มี ground truth และไม่ใช่ benchmark

ข้อมูลอ้างอิงกลางอยู่ที่ `tests_model/evaluation_manifest.json` ซึ่งตรึง checkpoint, training log, test log และ run ID ของทุกรุ่น ผล Common Test ด้านล่างมาจาก run ที่สำเร็จครบ **2,504/2,504 batches** เท่านั้น จำนวนภาพจริงยังไม่มีใน log จึงไม่อนุมานจาก batch size

## 1. ผลจาก Locked Common Test Set

Dataset identifier: `scamguard-locked-multisource-test-v1`

| อันดับ | เวอร์ชัน | Checkpoint iteration | Test run ID | mIoU (%) | mDice (%) | Forgery IoU (%) | Forgery Dice (%) | Forgery Accuracy (%) |
|:---:|:---:|---:|:---:|---:|---:|---:|---:|---:|
| **1** | **`v1.0.8`** | **207,500** | `20260925_232201` | **94.99** | **97.38** | **90.56** | **95.04** | **94.83** |
| 2 | `v1.0.7` | 240,000 | `20260923_164151` | 94.96 | 97.36 | 90.50 | 95.01 | 95.11 |
| 3 | `v1.0.6` | 195,000 | `20260918_092047` | 94.83 | 97.29 | 90.26 | 94.88 | 95.25 |
| 4 | `v1.0.5` | 197,500 | `20260915_084109` | 91.24 | 95.25 | 83.51 | 91.01 | 89.01 |
| 5 | `v1.0.4` | 495,000 | `20260915_095832` | 81.21 | 88.74 | 64.94 | 78.74 | 79.87 |
| 6 | `v1.0.0` | 112,000 | `20260915_101330` | 48.70 | 51.42 | 2.92 | 5.67 | 2.97 |
| 7 | `v1.0.3` | 160,000 | `20260915_094407` | 47.99 | 50.08 | 1.53 | 3.01 | 1.54 |
| 8 | `v1.0.2` | 132,000 | `20260915_092949` | 47.81 | 49.72 | 1.16 | 2.29 | 1.17 |
| 9 | `v1.0.1` | 152,000 | `20260915_091531` | 47.80 | 49.69 | 1.12 | 2.22 | 1.13 |

ข้อสรุปจากข้อมูลที่เปรียบเทียบได้:

- `v1.0.8` มีค่าหลักบน locked common test สูงกว่า `v1.0.6` เล็กน้อย: mIoU +0.16, mDice +0.09, Forgery IoU +0.30 และ Forgery Dice +0.16 percentage points
- `v1.0.8`, `v1.0.7`, `v1.0.6`, `v1.0.5` และ `v1.0.4` ผ่านเกณฑ์ NFR-AI-01 เดิมที่กำหนด mDice ≥ 85%
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
| `v1.0.6` | `20260915_201918` | 195,000 | 94.84 | 97.30 |
| `v1.0.7` | `20260918_191514` | 240,000 | 94.04 | 96.85 |
| `v1.0.8` | `20260923_184557` | 207,500 | 94.97 | 97.37 |

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

ใช้ `tests_model/test_qualitative_onnx.py` ร่วมกันสำหรับแต่ละเวอร์ชัน และสร้างภาพใน `tests_model/v/<version>/<version>_qualitative_onnx_example.{png,svg}` ด้วย input/preprocessing เดียวกัน ภาพแสดง Forgery probability map ด้วย colormap `magma` และ threshold overlay เพื่อเปรียบเทียบพฤติกรรมเชิงคุณภาพ แต่ไม่มี ground-truth mask จึงไม่รายงาน IoU, Dice หรือ accuracy และไม่ใช้จัดอันดับโมเดล

## 5. ประวัติการตั้งค่าหลัก

| เวอร์ชัน | Config | ฐานข้อมูล/แนวทาง |
|:---:|:---|:---|
| `v1.0.0` | `segformer_mit-b2-v2.py` | CASIA 2.0, train from scratch |
| `v1.0.1` | `segformer_mit-b2-v3.py` | Fine-tune สำหรับ Defacto Inpainting |
| `v1.0.2` | `segformer_mit-b2-v5.py` | CASIA 2.0 + Defacto |
| `v1.0.3` | `segformer_mit-b2-v5.py` | CASIA 2.0 + Defacto, ปรับโครงสร้างข้อมูล |
| `v1.0.4` | `segformer_mit-b2-v7.py` | รวม 6 ชุดข้อมูล, checkpoint ที่ 495k |
| `v1.0.5` | `segformer_mit-b2-v10.py` | Balanced multi-dataset, checkpoint ที่ 197.5k |
| `v1.0.6` | `segformer_mit-b2-v11.py` | Fresh training (`load_from=None`) 7 แหล่ง PNG lossless, repeat casia5/inpainting3/copymove4/imd2020x2, lr 1e-5 head x10, checkpoint ที่ 195k |
| `v1.0.7` | `segformer_mit-b2-v12.py` | เพิ่ม aiforge/realtext, CopyPasteForgery, rebalance CASIA/IMD2020, 250k iterations; best checkpoint 240k; locked test ยังคง 7 แหล่งเดิม |
| `v1.0.8` | `segformer_mit-b2-v13.py` | ปรับ sampling และขอบเขต CopyPasteForgery, ใช้ 7 แหล่งเดิมเลือก checkpoint; best mIoU checkpoint 207.5k จาก 250k iterations |

ผล demo ในอดีตเคยชี้สัญญาณ domain shift ของ `v1.0.4` แต่ไม่เพียงพอจะสรุปว่าโมเดลล้มเหลวทั่วไป `v1.0.8` สูงสุดบนชุดล็อกเดียวกัน แต่ local masked regression 105 ภาพได้ mDice 87.06%, Forgery Dice 76.27% และ FPR 1.86% เทียบกับ `v1.0.6` ที่ได้ 90.17%, 81.90% และ 0.83% ตามลำดับ จึงต้องพิจารณา regression รายโดเมนแยกจาก locked ranking

## 6. สถานะ Production

- Production ปัจจุบันคือ `v1.0.6` (deploy 2026-09-18 ผ่าน `POST /api/v1/admin/models/14/deploy` พร้อม audit log; รุ่นก่อนหน้าคือ `v1.0.5`)
- `v1.0.7` ผ่าน locked common test และ ONNX parity แล้ว แต่ยัง **ไม่ถูก deploy**; local promotion checks ยังไม่ครบตามเป้า: IMD2020 Forgery Dice 49.62% (< 50%) และ overall FPR 1.08% (> 1.0%)
- `v1.0.8` ผ่าน locked test และ ONNX parity แต่ไม่ผ่าน promotion gate 3/4 ข้อ: local mDice 87.06% (< baseline 90.17%), IMD2020 Forgery Dice 47.73% (ต้อง >50%) และ overall FPR 1.86% (ต้อง ≤1%); จึงยังไม่ควรแทน `v1.0.6` ใน production
- หลักฐานการ deploy เดิมของ `v1.0.6`: PyTorch–ONNX parity (CPU-vs-CPU max diff 8.3e-06), dry-run ผ่าน (latency 4303ms / memory 202MB / compatibility Passed), end-to-end scan ผ่าน API สำเร็จ, ล้าง Redis `scan_result:*` ค้างเก่า 7 keys แล้ว
- Rollback: deploy `v1.0.5` (id 12) กลับได้ทันทีผ่าน endpoint เดียวกัน

## 7. Artefacts ที่สร้างซ้ำได้

- `evaluation_manifest.json` — source of truth สำหรับ version/checkpoint/ONNX/log/run/dataset
- `report/figs/common_test_summary.csv` — overall และ per-class common-test metrics
- `report/figs/training_validation_summary.csv` — จำนวน log points, validation runs และ best validation
- `report/test_onnx_models.py` — ตรวจไฟล์, input/output contract, dynamic shape, deterministic output และ probability ของ ONNX ทุกรุ่น
- `report/figs/*.png` — raster 200 DPI
- `report/figs/*.svg` — vector สำหรับรายงาน
- `tests_model/v/<version>/` — loss, validation และ Qualitative ONNX Example รายรุ่น

รันซ้ำและทดสอบ parser ตามคำสั่งใน `tests_model/README.md`
