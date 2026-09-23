# เปรียบเทียบ SegFormer ทุก config และปรับ v13 สำหรับ v1.0.8

วันที่: 2026-09-23 สถานะ: แก้ config และตรวจ CPU compatibility แล้ว ยังไม่ได้เทรน

## ข้อสรุป

ฐานที่มีหลักฐานดีที่สุดบน local regression set คือ config v11 / โมเดล v1.0.6 ส่วน v12 / v1.0.7 ได้ locked benchmark สูงกว่าเล็กน้อย แต่ local Forgery Dice และ FPR ถอยลง v13 จึงคง loss, LR, crop และ optimizer ของ v11 พร้อมลดขอบเขต synthetic augmentation จาก v12 และเพิ่มการมองเห็น regression รายแหล่งข้อมูลระหว่าง validation

การเทียบไฟล์ไม่สามารถรับรอง hyperparameter ที่ดีที่สุดได้ การปรับ sampling/CopyPaste เป็นสมมติฐานที่ต้องทดสอบ ไม่ใช่สาเหตุที่ยืนยันด้วย ablation แล้ว

## ขอบเขตและวิธีเทียบ

- อ่านและ resolve ด้วย MMEngine ครบ 14 configs: ไฟล์ไม่มีเลขรุ่น และ v1–v13 รวม inherited defaults
- ตรวจ training snapshots อีก 10 ไฟล์ใน work_dirs: โมเดล v1.0.0–v1.0.7 และ 2 test-model directories
- ใช้ training_validation_summary.csv, common_test_summary.csv และ Test-Case/output/quantitative/overall.csv ที่มีอยู่ ไม่ได้รัน benchmark ใหม่
- แยกเลข config ออกจากเลขโมเดล โดยใช้ snapshot ของ training run เป็นหลัก ไม่ใช้ config ใน test_eval มาอนุมานว่าเคยเทรนด้วย config นั้น

## ตาราง config ทุกเวอร์ชันก่อนแก้รอบนี้

LR ด้านล่างเป็นค่าก่อน scheduler; batch effective คำนวณสำหรับ GPU เดียว หมายเหตุ test=val คือไฟล์ config นั้นชี้ test ไปที่ validation ไม่ใช่ผล locked common test ที่ประเมินใหม่ภายหลัง

| Config | train/val/test sources | batch × accumulation | iterations | backbone/head LR | test split | ประเด็นสำคัญ |
|---|---:|---:|---:|---|---|---|
| ไม่มีเลข | 1/1/1 | 8 × 1 | 160,000 | 1e-06 / 0.0001 | val | CASIA; CE+Dice; config ปัจจุบันต่างจาก snapshot ทดลองชื่อเดียวกัน |
| v1 | 1/1/1 | 2 × 1 | 160,000 | 0 / 0.0001 | val | CASIA; CE; backbone LR=0 |
| v2 | 1/1/1 | 8 × 1 | 160,000 | 1e-06 / 0.0001 | val | CASIA; CE+Dice |
| v3 | 1/1/1 | 8 × 1 | 160,000 | 1e-06 / 0.0001 | val | inpainting อย่างเดียว; load v1.0.0 |
| v4 | 2/1/1 | 8 × 1 | 160,000 | 1e-06 / 0.0001 | val | train 2 แหล่ง แต่ val/test เพียง 1 แหล่ง |
| v5 | 2/2/2 | 8 × 1 | 160,000 | 1e-06 / 0.0001 | val | CASIA + inpainting; val ครบ 2 แหล่ง |
| v6 | 6/6/6 | 8 × 1 | 300,000 | 1e-06 / 0.0001 | val | เพิ่มเป็น 6 แหล่ง; ไม่มี authentic แยก |
| v7 | 6/6/6 | 8 × 1 | 500,000 | 1e-06 / 0.0001 | val | เพิ่ม budget เป็น 500k; ไม่ได้ดีที่สุดจากผลจริง |
| v8 | 6/2/2 | 8 × 1 | 100,000 | 5e-07 / 5e-05 | val | CASIA ×5; CE class weight 2.5 / Dice 1.5; val เพียง 2 แหล่ง |
| v9 | 6/2/2 | 16 × 1 | 120,000 | 2e-06 / 0.0002 | val | batch 16; val เพียง 2 แหล่ง; ต้องพิจารณา VRAM |
| v10 | 7/7/7 | 8 × 2 | 200,000 | 2e-06 / 0.0002 | test | clean PNG; เพิ่ม authentic; locked test แยกจริง; accumulate 2 |
| v11 | 7/7/7 | 8 × 2 | 200,000 | 1e-05 / 0.0001 | test | softmax Dice, crop-aware, augmentation เบา, optimizer groups แก้แล้ว |
| v12 | 9/9/7 | 8 × 2 | 250,000 | 1e-05 / 0.0001 | test | เพิ่ม AIForge/RealText, CopyPaste ทุก forged source, 250k |
| v13 | 9/7/7 | 8 × 2 | 250,000 | 1e-05 / 0.0001 | test | ก่อนแก้: CopyPaste จำกัด 3 แหล่ง, ลด new-domain repeats, val 7 แหล่ง |

v13 หลังแก้: train/val/test = 9/9/7 แต่ mIoU/mDice สำหรับเลือก checkpoint ยังคำนวณจาก 7 แหล่งหลักเท่านั้น อีก 2 แหล่งรายงานแยก

## โมเดลที่มีผลประเมินจริง

| โมเดล | Config snapshot | best iteration | locked mDice % | local mDice % | local Forgery Dice % | local pixel FPR % |
|---|---|---:|---:|---:|---:|---:|
| v1.0.0 | segformer_mit-b2-v2.py | 112,000 | 51.42 | 53.19 | 11.14 | 1.09 |
| v1.0.1 | segformer_mit-b2-v3.py | 152,000 | 49.69 | 51.69 | 7.73 | 0.09 |
| v1.0.2 | segformer_mit-b2-v5.py | 132,000 | 49.72 | 55.18 | 14.70 | 0.43 |
| v1.0.3 | segformer_mit-b2-v5.py | 160,000 | 50.08 | 55.98 | 16.30 | 0.51 |
| v1.0.4 | segformer_mit-b2-v7.py | 495,000 | 88.74 | 71.69 | 47.24 | 2.00 |
| v1.0.5 | segformer_mit-b2-v10.py | 197,500 | 95.25 | 84.87 | 71.89 | 0.54 |
| v1.0.6 | segformer_mit-b2-v11.py | 195,000 | 97.29 | 90.17 | 81.90 | 0.83 |
| v1.0.7 | segformer_mit-b2-v12.py | 240,000 | 97.36 | 88.78 | 79.34 | 1.08 |

ไม่พบผล benchmark ที่ผูกโดยตรงกับ config v4/v6/v8/v9 หรือ v13 ในตารางโมเดลนี้ จึงไม่แต่งคะแนนให้ config ที่ไม่มีหลักฐาน run ทั้งสอง test-model snapshots ไม่มีแถวผลใน summary ชุดเดียวกัน จึงไม่จัดอันดับร่วม

## สิ่งที่เรียนรู้จากทุกเวอร์ชัน

1. รุ่นที่ FPR ต่ำที่สุดไม่ได้ดีที่สุดเสมอ: v1.0.1 มี local FPR 0.09% แต่ Forgery Dice เพียง 7.73% จึงต้องพิจารณาความสามารถตรวจจับด้วย ไม่เลือกจาก accuracy/FPR อย่างเดียว
2. เพิ่ม iteration อย่างเดียวไม่พอ: v7 เทรน 500k แต่ผล local mDice ของ v1.0.4 ต่ำกว่า v11 ที่ใช้ 200k ทั้งนี้มีหลายปัจจัยต่างกัน จึงไม่ใช่หลักฐานว่า budget มากทำให้แย่
3. เก็บพื้นฐาน v11: softmax Dice สำหรับ 2 คลาส, CE class weight [1, 2.5], Dice weight 1.5, crop ratio 1–2 และ cat_max_ratio 0.99, augmentation เบา, backbone/head LR 1e-5/1e-4, gradient clip 1.0 และ normalization/bias decay 0
4. ไม่ย้อนกลับไปใช้ test=val ของ configs เก่า รุ่นใหม่ใช้ images/test จริงและ official locked evaluator เดิม แต่ validation ของแต่ละรุ่นเก่าไม่ใช่ distribution เดียวกัน จึงไม่ควรจัดอันดับด้วย best validation score อย่างเดียว
5. บาง training snapshots ต่างจากไฟล์ปัจจุบัน เช่น v1.0.5 ใช้ load_from checkpoint v1.0.0 ขณะที่ config v10 ปัจจุบัน resolve ได้ None และ v1.0.2/v1.0.3 ใช้ config ชื่อ v5 แต่ path ข้อมูลใน snapshot ต่างกัน การปรับปรุงระหว่างรุ่นจึงแยก causal effect จากชื่อไฟล์ไม่ได้
6. v12 เปลี่ยน sampling, augmentation, แหล่ง validation, seed และ budget พร้อมกัน ผลที่ดีขึ้นใน CopyMove/IMD2020/Inpainting ยังไม่พิสูจน์ว่าเกิดจาก CopyPaste เพียงอย่างเดียว

## สิ่งที่แก้ใน v13 รอบนี้

| รายการ | v13 ก่อนแก้ | v13 หลังแก้ | เหตุผล |
|---|---|---|---|
| Validation coverage | 7 แหล่ง | 9 แหล่ง; คะแนนรวมหลักใช้ 7 | เห็น regression ของ AIForge/RealText โดยไม่ให้จำนวนภาพไปเปลี่ยนคะแนนเลือก checkpoint หลัก |
| Metric | mIoU/mDice รวม | เพิ่ม Forgery Dice/FPR รายแหล่งและ core macro Forgery Dice | เห็นหมวดเล็กที่คะแนนรวมกลบ |
| Checkpoint | best mIoU | best mIoU และ best core macro Forgery Dice | เก็บ candidate 2 เกณฑ์เพื่อคัดด้วย validation ก่อนเปิด test |
| Seed | 44 | 42 ตาม v11 | ลดการเปลี่ยนค่าที่ไม่จำเป็น ไม่ใช่ seed ที่พิสูจน์ว่าดีที่สุด |
| Test workers | 8 | 4 | ให้สอดคล้องกับข้อจำกัด RAM ที่ config v12 บันทึกไว้; ไม่เปลี่ยนสูตร metric |
| คำอธิบาย | counts ดูเหมือน inventory ปัจจุบัน | ระบุ historical counts และ gate เป็น manual | แยกหลักฐานจริงออกจากเป้าหมาย |

คง sampling ของ v13 ที่เตรียมไว้: CASIA ×5, authentic ×1, splicing ×1, inpainting ×3, copymove ×4, face ×1, IMD2020 ×3, AIForge ×6, RealText ×4; CopyPaste p=0.20 เฉพาะ copymove/imd2020/inpainting; ไม่ synthesize authentic

คง budget 250k ตาม v12, batch 8/accumulate 2 = effective 16 บน GPU เดียว และ 125k optimizer updates โดยประมาณ เก็บ initial pretrained backbone และไม่ warm-start โมเดลเก่า ไม่มีหลักฐานเพียงพอให้เปลี่ยน architecture, loss weight หรือเพิ่ม batch/augmentation แรงกว่าเดิม

## ความหมายของ metric ใหม่

- mIoU/mDice/aAcc/mAcc ใช้สูตร IoUMetric เดิมกับ core 7 แหล่งเท่านั้น
- core_macro_forgery_dice เฉลี่ย Forgery Dice ของ 6 แหล่งที่มี forgery โดยให้น้ำหนักเท่ากัน ไม่รวม authentic ซึ่งไม่มี foreground; เพิ่มจำนวนรูปในหมวดใหญ่ไม่เพิ่มน้ำหนักหมวดนั้นใน macro
- authentic_fpr และ <source>_fpr เป็น FP/(FP+TN) ระดับพิกเซล หน่วยเปอร์เซ็นต์ ไม่ใช่อัตราเตือนผิดระดับภาพ
- source ที่ไม่มี background จะมี FPR=NaN และ source ที่ไม่มีทั้ง ground truth/predicted foreground จะมี Dice=NaN ไม่แปลงเป็น 100% หลอก ๆ; authentic จึงไม่เข้าค่า macro
- source metadata มาจาก img_path ภายใต้ root ที่ระบุ ถ้า source หาย/ไม่รู้จักจะหยุดแจ้งข้อผิดพลาด ไม่เงียบแล้วให้คะแนนชุดที่ไม่ครบ
- Validation metric ไม่ได้ใช้ production tiled ONNX จึงต้องตรวจ tiled validation แยกก่อนตัดสิน deploy; ไม่เปลี่ยน official test evaluator

## การเลือก candidate หลังเทรน

1. ดู best mIoU และ best core macro Forgery Dice พร้อม per-source Dice/FPR บน validation; เทียบ v1.0.6 ด้วย protocol และแหล่งข้อมูลเดียวกัน รวม AIForge/RealText แยก
2. เลือก final checkpoint และ threshold จาก validation แล้ว freeze ก่อนรัน locked test ไม่เลือกจากคะแนน test ระหว่างหลาย checkpoint
3. ตรวจเป้าหมายเดิม: local mDice >=90.17%, locked mDice >=97.29%, local IMD2020 Forgery Dice >50%, local FPR <=1.0%; ค่าเหล่านี้เป็น manual promotion criteria ไม่ใช่ข้อบังคับของ CheckpointHook และ macro checkpoint อาจมี FPR สูงกว่าเดิมได้ ต้องตรวจจริง
4. local 105 รูปถูกใช้วิเคราะห์แล้ว จึงเป็น regression set; ต้องมี holdout ใหม่หรือ seed ซ้ำที่วางแผนล่วงหน้าก่อนอ้าง generalization หรือผลดีที่สุดอย่างมั่นใจ

## ผลตรวจและข้อจำกัด

ชุดทดสอบใหม่ผ่าน 10/10: config dump/reload, registry/evaluator/checkpoint compatibility, confusion ที่คำนวณคำตอบด้วยมือ, core pooled metrics เทียบ IoUMetric เดิม, extra-domain independence, equal-domain macro, ignore pixels/zero denominators, unknown/missing/overlapping roots, evaluate lifecycle, augmentation binary/authentic และ CPU forward/backward พร้อม optimizer parameter groups จริง

ข้อมูลภาพใน test suite เป็น synthetic fixtures เพื่อทดสอบโค้ด ไม่ใช่หลักฐานความแม่นยำ ใช้ BN และ OptimWrapper แทน SyncBN/CUDA AMP เฉพาะ CPU test และปิด pretrained download ใน test เท่านั้น config สำหรับเทรนจริงยังคง AMP/pretrained ตามเดิม

ยังไม่พบ /run/media/panuwat/USB/dataset จึงยังไม่ตรวจ dataset integrity, actual image loader, GPU memory หรือ CUDA AMP และยังไม่ได้เทรน/benchmark ใหม่ การสร้าง config พร้อมไม่ได้แปลว่า model training พร้อมจนกว่า dataset จะ mount ครบ

## ไฟล์และคำสั่ง

- configs/segformer_mit-b2-v13.py — config ที่แก้
- forgery_metrics.py — metric ที่ config import; ต้องอยู่คู่กับโปรเจกต์
- tests_model/report/test_training_config_v13.py — CPU tests

```bash
cd /home/panuwat/project/model/segformer
NO_ALBUMENTATIONS_UPDATE=1 PYTHONDONTWRITEBYTECODE=1 venv/bin/python tests_model/report/test_training_config_v13.py -v
./train.sh --config configs/segformer_mit-b2-v13.py --no-load
```

ต้องระบุ --config เพราะ train.sh ยัง default v10 และ banner พิมพ์ก่อน parse arguments; สคริปต์เลือกเลข work_dirs อัตโนมัติ ไม่ได้แก้ train.sh ในงานนี้

สำเนาไฟล์ส่งมอบต้องวาง config ใน configs/ และ forgery_metrics.py ที่ root ของ SegFormer; config อ้างอิง library/ และ forgery_aug.py ที่มีอยู่ในโปรเจกต์ ไม่ใช่ standalone

## แหล่งหลักฐานในโปรเจกต์

- model/segformer/configs/*.py และ work_dirs/*/segformer*.py
- model/segformer/tests_model/report/figs/training_validation_summary.csv
- model/segformer/tests_model/report/figs/common_test_summary.csv
- model/segformer/Test-Case/output/quantitative/overall.csv
- model/segformer/report/segformer-test-audit-2026-09-23.md
- library/mmsegmentation/mmseg/evaluation/metrics/iou_metric.py และ mmengine/hooks/checkpoint_hook.py ใน venv ที่ติดตั้งจริง
- model/segformer/configs/report/segformer_mit-b2-v11.md และ wiki/concepts/model-training.md
