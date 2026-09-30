---
title: "AI Model Training Workflow"
category: concepts
tags: [concepts, ai, training, onnx]
sources: [design/training.md]
updated: 2026-09-16
---

# การออกแบบระบบฝึกสอนโมเดล (Model Training Design)

เอกสารนี้ตอบคำถามว่า **โมเดลถูกสร้างและอัปเดตอย่างไร** ครอบคลุมวงจรชีวิตของ AI ในการเทรน การปรับปรุงอย่างต่อเนื่อง และการนำขึ้นระบบ

## 1. ภาพรวมของระบบ Training

ระบบถูกออกแบบเพื่อรองรับกระบวนการเตรียมข้อมูล การฝึกสอน (Training) การวัดผล และการแปลงโมเดลให้อยู่ในรูปแบบที่พร้อมใช้งาน โดยรองรับทั้งการเทรนรอบแรก (Initial Training) และการเรียนรู้เพิ่มเติม (Incremental Learning) ในอนาคต

## 2. Dataset Design

* การคัดเลือกชุดข้อมูลภาพ (Dataset) ที่ประกอบไปด้วยภาพปกติและภาพตัดต่อ (Forged) หรือชุดข้อมูลมาตรฐาน (CASIA, IMD2020)
* การกำหนดโครงสร้าง Annotation ในรูปแบบ Segmentation Mask (ภาพขาวดำที่ชี้จุดดัดแปลง) เพื่อสอน AI ในระดับพิกเซล

## 3. Data Preprocessing

* **การทำความสะอาดข้อมูล**: การจัดระเบียบโครงสร้างโฟลเดอร์ให้สอดคล้องกับ Dataloader
* **Data Augmentation**: ใช้เทคนิคต่างๆ เช่น `RandomResize`, `RandomCrop`, `RandomFlip` และที่สำคัญคือ `PhotoMetricDistortion` (ปรับแต่งแสง/สี) เพื่อให้โมเดลทนทานต่อการแต่งแสงหลอก
* การแบ่งชุดข้อมูลเป็น Train / Validation / Test Set แบบ **stratified 80:10:10** (คงสัดส่วน class แท้/ปลอม และแหล่งข้อมูลทุกชุด, กำหนด seed คงที่, test set ถูก freeze ห้ามนำมา tune)

## 4. Initial Training

* การนำน้ำหนักเริ่มต้น (Pre-trained Weights) ของโมเดล SegFormer มาใช้งานเพื่อย่นระยะเวลาการเรียนรู้
* การสอนบนชุดข้อมูลหลักทั้งหมด (Base Dataset) เพื่อปรับพื้นฐานโมเดลให้รู้จักลักษณะของรอยตัดต่อดิจิทัล

## 5. Fine-tuning

* การปรับจูนโมเดลกับชุดข้อมูลภาพหลอกลวงแบบเฉพาะเจาะจง
* ใช้ค่า Learning Rate ที่ต่ำลงกว่ารอบแรกเพื่อค่อย ๆ ปรับน้ำหนักโดยไม่ทำลายความรู้เดิม

## 6. Incremental Fine-tuning

* การอัปเดตโมเดลตามรอบทบทวน retrain: ทุก 30 วัน หรือเมื่อมีภาพกลโกงชนิดใหม่ที่ approved + research-consented สะสม ≥ 500 ภาพ (แล้วแต่เงื่อนไขใดถึงก่อน) — เป็นการเรียนรู้ต่อเนื่องโดยไม่ต้องเริ่มต้นเทรนใหม่ทั้งหมดจากศูนย์

## 7. Parameter-wise Fine-tuning

* การกำหนดอัตราการเรียนรู้ (Learning Rate) แยกตามชิ้นส่วนโมเดล เพื่อรักษาฟีเจอร์เดิมแต่ยังปรับตัวเข้ากับโดเมนใหม่ได้
* Backbone (MiT Encoder): ปรับตัวช้าๆ (`lr_mult=0.1`) เพื่อไม่ให้ลืมความรู้การมองภาพรวม
* Decode Head (SegFormer Head): เรียนรู้อย่างรวดเร็ว (`lr_mult=10.0`) เพื่อจับรอยตัดต่อ

## 8. Replay Dataset

* กลยุทธ์การนำรูปภาพส่วนหนึ่งจากฐานข้อมูลดั้งเดิมมาผสมกับข้อมูลชุดใหม่ในระหว่างการทำ Incremental Training
* เพื่อป้องกันปัญหา Catastrophic Forgetting (การที่ AI ลืมวิธีตรวจจับกลโกงแบบเก่า หลังจากเรียนรู้กลโกงแบบใหม่)

## 9. Validation

* การประเมินผลระหว่างการเทรนในแต่ละรอบ (Epoch) ด้วยชุดข้อมูล Validation Set
* คอยตรวจสอบค่า Loss เพื่อดูพัฒนาการของโมเดลว่าไม่ได้กำลังจดจำคำตอบ (Overfitting)

## 10. Model Evaluation

* การวัดผลประสิทธิภาพบน Test Set เพื่อคัดเลือกโมเดลที่ดีที่สุด ด้วยมาตรวัด (Metrics) เช่น:
  * **IoU (Intersection over Union)**: วัดความทับซ้อนของพื้นที่ตรวจพบเทียบกับพื้นที่จริง
  * **mDice**: การหาความสมดุลระหว่างความแม่นยำและความครอบคลุม
  * **mIoU**: ค่าเฉลี่ย IoU ของทุกคลาส โดย IoU วัดสัดส่วนพื้นที่ซ้อนทับระหว่าง mask ที่ทำนายกับ ground truth ต่อพื้นที่รวม (intersection / union); ไม่ใช่สัดส่วนพิกเซลที่ทายถูกทั้งหมด (pixel accuracy)

> **ผลการเทรน v1.0.6 (config `segformer_mit-b2-v11.py`, fresh training):** ครบ 200,000 iters (จบ 2026-09-17) ได้ best validation mIoU **94.84** / mDice **97.30** @iter 195,000 และเป็นอันดับหนึ่งบน locked common test (`scamguard-locked-multisource-test-v1`, รัน 2026-09-18) ด้วย mIoU **94.83** / Forgery IoU **90.26** — deploy เป็น Production แล้วเมื่อ 2026-09-18 (รุ่นก่อนหน้าคือ `v1.0.5`, ดู [[concepts/ai-model-segformer]])

### ผลรายเวอร์ชัน (Test Case ระดับโมเดล)

**ตารางที่ 1 — คะแนน validation ตอนเทรน** (ที่มา: `model/segformer/tests_model/report/reportmodel.md` §ตาราง best mIoU):

| เวอร์ชัน | best iter | val mIoU (%) | val mDice (%) |
|---|---:|---:|---:|
| `v1.0.0` | 112,000 | 72.42 | 81.40 |
| `v1.0.1` | 152,000 | 75.48 | 83.79 |
| `v1.0.2` | 132,000 | 67.99 | 76.55 |
| `v1.0.3` | 160,000 | 72.62 | 81.30 |
| `v1.0.4` | 495,000 | 86.38 | 92.22 |
| `v1.0.5` | 197,500 | **91.31** | **95.29** |

**ตารางที่ 2 — Locked common test** (`scamguard-locked-multisource-test-v1`, รัน 2026-09-15, ที่มา: reportmodel.md §1):

| อันดับ | เวอร์ชัน | mIoU (%) | mDice (%) | Forgery IoU (%) |
|:---:|---|---:|---:|---:|
| **1** | **`v1.0.5`** | **91.24** | **95.25** | **83.51** |
| 2 | `v1.0.4` | 81.21 | 88.74 | 64.94 |
| 3 | `v1.0.0` | 48.70 | 51.42 | 2.92 |
| 4 | `v1.0.3` | 47.99 | 50.08 | 1.53 |
| 5 | `v1.0.2` | 47.81 | 49.72 | 1.16 |
| 6 | `v1.0.1` | 47.80 | 49.69 | 1.12 |

> [!NOTE]
> มีชุดประเมินที่สามคือ local Test-Cases set (105 ตัวอย่าง ใน `spreadsheets/quantitative/overall.csv`): `v1.0.5` ได้ mIoU 75.96 / mDice 84.87 — ต่ำกว่าเกณฑ์ 85.00% อยู่ 0.13 (ดู gate ใน [[planning/task-tracking]]) อย่าสลับตัวเลขกันทั้งสามชุด: validation (ตาราง 1) ≠ locked common test (ตาราง 2) ≠ local set

## 11. Hyperparameters & Hardware Optimization

* **VRAM Optimization**: ใช้ `AmpOptimWrapper` (Mixed Precision) เพื่อลดการใช้หน่วยความจำ ทำให้เทรนบนอุปกรณ์ที่มี VRAM จำกัดได้อย่างเต็มประสิทธิภาพ
* **Optimizer & Scheduler**: ใช้ AdamW ร่วมกับ LinearLR (Warmup) และ PolyLR
* **Loss Function**: ใช้ `Binary Cross-Entropy Loss (BCE)` ควบคู่กับ `DiceLoss` (`use_sigmoid=True`) เพื่อแก้ปัญหา Class Imbalance (พื้นที่รอยปลอมแปลงเล็กมากเมื่อเทียบกับพื้นหลัง — canonical ตรงกับ `design/training.md` และ `Document/model/training.md`)
* **บทเรียนจาก config v10 (`segformer_mit-b2-v10.py`, โมเดล v1.0.5):** ชุดข้อมูล clean tree ฝั่ง PNG lossless (`img_suffix='.png'`, 7 แหล่ง: casia/authentic/splicing/inpainting/copymove/face/imd2020 รวมเป็น `ConcatDataset` ทั้ง val และ test) — `class_weight=[1.0, 2.5]` + `DiceLoss loss_weight=1.5` — batch 8 + `accumulative_counts=2` (effective 16 บน VRAM 8GB) — งบ 200,000 iters + `save_best='mIoU'` (ดู [[concepts/configs]])

## 12. Checkpoint & Version Management

* การจัดเก็บสถานะน้ำหนักโมเดล (Model State Dict) ทุกครั้งที่มีผลลัพธ์ที่ดีขึ้นบน Validation Set เป็นไฟล์นามสกุล `.pth` หรือ `.pt`
* **Automated Version Increment**: ระบบมีการจัดการเวอร์ชันของโมเดลอัตโนมัติ (เช่น `v1.0.1`, `v1.1.0`) โดยจะเข้าไปอ่านประวัติการเทรนใน `work_dirs` เพื่อหาเวอร์ชันที่สูงที่สุด แล้วบวกเพิ่ม 1 ให้เสมอ ช่วยป้องกันการเขียนทับผลรันรอบก่อนหน้า และรับประกันว่าจะไม่มีการย้อนกลับไปใช้เลขเวอร์ชันเดิมที่น้อยกว่า

## 13. Export ONNX

* ขั้นตอนการนำไฟล์ Checkpoint (.pth) ที่ดีที่สุด มาแปลงร่าง (Export) ให้อยู่ในฟอร์แมต ONNX
* ช่วยเพิ่มความเร็วในการทำ Inference ลดการพึ่งพาไลบรารีขนาดใหญ่ในฝั่ง Backend

## 14. Model Deployment

* กระบวนการนำไฟล์ ONNX และไฟล์การตั้งค่าที่เกี่ยวข้อง (Config) จัดเก็บลงใน Model Registry หรือส่งต่อให้ API Server

## 15. Hot Reload

* กลไกของฝั่ง Backend Server ในการโหลดไฟล์โมเดลเวอร์ชันใหม่เข้าสู่ระบบ และนำไปใช้ประมวลผลคำขอใหม่ทันที โดยไม่ต้องปิด/เปิด Server ใหม่ (Zero-downtime)

## 16. Rollback

* แผนสำรองในการปรับย้อน (Revert) ไปใช้งานโมเดลเวอร์ชันก่อนหน้าทันที หากพบว่าโมเดลตัวใหม่สร้างผลลัพธ์ผิดพลาด (False Positive) อย่างรุนแรงในสภาพแวดล้อมจริง (Production)

## 17. Training Workflow

* ภาพรวมผังงาน (Workflow) แบบอัตโนมัติ (เช่น MLOps หรือ CI/CD สำหรับ AI) เพื่อจัดการตั้งแต่ การรับข้อมูลชุดใหม่ -> การทดสอบการเทรน -> การแพ็กเกจจิ้งไฟล์ -> จนถึงการ Deploy อย่างเป็นระบบ
