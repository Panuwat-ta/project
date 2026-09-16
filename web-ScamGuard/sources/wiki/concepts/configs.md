---
title: "พารามิเตอร์และสมการคณิตศาสตร์ (Configurations & Math)"
category: concepts
tags: [risk-score, equations, loss-function, SegFormer, parameters]
sources: [Document/model/configs.md, Document/model/training.md]
updated: 2026-09-15
---

# การตั้งค่าพารามิเตอร์ อัลกอริทึมและสมการคณิตศาสตร์ที่ใช้ (Configuration, Algorithms, and Mathematical Equations)

เอกสารฉบับนี้รวบรวมสมการคณิตศาสตร์ อัลกอริทึม และค่าการตั้งค่า (Configurations) หลักที่ใช้ในกระบวนการประมวลผล ประเมินผลลัพธ์ และการฝึกสอนโมเดล AI ภายในระบบ Scam Image Detection พร้อมคำอธิบายเหตุผลและหลักการที่อยู่เบื้องหลังการออกแบบแต่ละส่วน

---

## 1. การคำนวณคะแนนความเสี่ยงรวม (Overall Risk Score - Recommended Hybrid Approach)

ระบบประมวลผลคะแนนความเสี่ยงของรูปภาพโดยใช้หลักการ **Maximum Impact (Worst-Case Trigger) ร่วมกับ Multi-Factor Compounding Penalty** ซึ่งเป็นมาตรฐานวิศวกรรมความมั่นคงปลอดภัย (Fraud Detection & Forensics):

```text
S_base = max(S_visual, S_textual, S_source)
```

```text
S_total = min(100, S_base + Σ_i ∈ secondary [S_i ≥ 40] × 5)
```

โดยที่:
* **`S_total`** คือ คะแนนความเสี่ยงรวม (Overall Risk Score) มีค่าตั้งแต่ 0 ถึง 100
* **`S_base`** คือ ค่าคะแนนสูงสุดในบรรดามิติที่ตรวจพบ (`max`) เพื่อเป็นฐานความเสี่ยงหลัก
* **`S_visual`** คือ คะแนนความผิดปกติทางภาพ (Visual Anomaly Score 0–100%) จากโมเดล SegFormer + Heatmap
* **`S_textual`** คือ คะแนนความเสี่ยงด้านข้อความ (Textual Analysis Score 0–100%) จาก Surya-OCR + Pattern Matching
* **`S_source`** คือ คะแนนความเสี่ยงจากแหล่งที่มาของภาพ (Source Reliability Score 0–100%) จาก Reverse Image Search (ที่มา: นโยบาย heuristic v1 — พบ ≥3 แหล่ง = สูง, =2 = ปานกลาง/ไม่แน่ชัด, ≤1 = ต่ำ; ทบทวนเกณฑ์เมื่อมีข้อมูลภาคสนาม)
* **Compounding Penalty:** หากมิติรองใดมีคะแนน `≥ 40` (ระดับ Medium ขึ้นไป) จะบวกเพิ่ม `+5` ต่อมิติ (สูงสุดไม่เกิน 100)
* **Partial Failure:** ถ้ามิติใดล้มเหลวให้ตัดมิตินั้นทิ้งแล้วคำนวณค่าสูงสุดจากมิติที่สำเร็จเท่านั้น

**คำอธิบายและเหตุผลที่ใช้:**
* **แก้ปัญหา Dilution Problem:** ในกรณีที่เป็นภาพตัดต่อหรือภาพสังเคราะห์ชัดเจนแต่ไม่มีข้อความ (`S_visual = 85, S_text = 0`) หรือกรณี Romance Scam การใช้ค่าเฉลี่ยถ่วงน้ำหนักจะทำให้คะแนนรวมถูกฉุดลงจนหลุดเกณฑ์อันตราย แต่ Worst-Case Trigger จะการันตีว่าคะแนนรวมไม่ต่ำกว่ามิติที่อันตรายที่สุด
* **สะท้อนความอันตรายแบบทวีคูณ (Multi-factor Risk):** หากภาพใดพบทั้งการตัดต่อภาพและมีข้อความหลอกลวงพร้อมกัน คะแนนรวมจะได้รับการเพิ่มพิเศษ (Compounding) เพื่อเตือนภัยผู้ใช้อย่างเด็ดขาด
* **การนำเสนอผลแบบคู่ขนาน (UI Breakdown):** นอกเหนือจาก Overall Score แล้ว บน UI จะแจกแจง Progress Bar และคำอธิบายแยกแต่ละมิติ 0–100% เสมอ

---

## 2. เกณฑ์การตัดสินระดับความเสี่ยง (Risk Grading Thresholds)

เมื่อคำนวณคะแนน `S_total` ออกมาแล้ว ระบบจะนำไปจัดกลุ่มระดับความเสี่ยงตามเงื่อนไข (Threshold Configuration) ดังนี้:

```text
Risk Grade = Low (เสี่ยงต่ำ), if 0 ≤ S_total ≤ 39 ; Medium (น่าสงสัย), if 40 ≤ S_total ≤ 69 ; High (อันตราย), if S_total ≥ 70
```

**คำอธิบายและเหตุผลที่ใช้:**
* **ช่วงเสี่ยงต่ำ (0 -- 39):** มีสัญญาณอ่อนบางจุดที่ตรวจพบ แต่ยังไม่ถึงระดับที่ควรกังวล ผู้ใช้งานควรทราบแต่ไม่จำเป็นต้องดำเนินการใดเป็นพิเศษ
* **ช่วงน่าสงสัย (40 -- 69):** มีบางชั้นตรวจพบความผิดปกติ แต่ไม่ชัดเจนทุกชั้น หรือพบหลักฐานแบบอ่อนๆ ผู้ใช้งานควรพิจารณาประกอบกับวิจารณญาณส่วนตัว
* **ช่วงอันตราย (70 -- 100):** ผลวิเคราะห์ส่วนใหญ่ชี้ไปในทิศทางเดียวกันว่าภาพถูกปรับแต่งหรือมีข้อความหลอกลวงที่ชัดเจน ภาพนี้มีความเสี่ยงสูงที่จะเป็นสแกม (กรณี `S_visual ≥ 80` ระบบจะขึ้นเป็น High ทันที)

---

## 3. การคำนวณคะแนนความเสี่ยงทางภาพ (`S_visual`)

การได้มาซึ่งคะแนน `S_visual` จากโมเดล SegFormer อาศัยความน่าจะเป็นของการเป็นรอยตัดต่อ (Confidence Score) และสัดส่วนพื้นที่ที่พบความผิดปกติ (Mask Coverage):

```text
S_visual = Normalize(Confidence × Mask Coverage)
```

**คำอธิบายและเหตุผลที่ใช้:**
* **Confidence Score:** คือค่าเฉลี่ยความน่าจะเป็นของพิกเซลที่ถูก flag ว่าดัดแปลง (มีค่าความน่าจะเป็น 0–1)
* **Mask Coverage:** คือสัดส่วนจำนวนพิกเซลที่ถูก flag เทียบกับพิกเซลทั้งหมดของภาพ (0–1)
* **Normalize:** นิยามตายตัว `Normalize(y) = min(100, round(y × 100))` — แปลงผลคูณ (ช่วง 0–1) เป็นคะแนน 0–100 (ฉบับ canonical ดู `Document/model/configs.md` §3)
* **หลักการคิด:** หากมีการแก้ไขภาพด้วยความเนียนที่ต่ำ (Confidence สูง) และแก้พื้นที่เยอะ (Coverage สูง) คะแนนความเสี่ยงทางภาพ (`S_visual`) จะยิ่งมีค่าสูงขึ้น ในขณะที่รอยแก้เล็กๆ แม้ Confidence สูง ก็จะมีผลต่อคะแนนลดลงบ้างตามสัดส่วน
* **ตัวอย่างคำนวณ:** Confidence เฉลี่ย 0.9, Coverage 0.2 → `0.9 × 0.2 = 0.18` → `Normalize(0.18) = 18` → `S_visual = 18` (Low)

---

## 4. สมการสำหรับการฝึกสอนโมเดลและการตั้งค่า Loss Function (Training Configurations)

เพื่อเพิ่มความแม่นยำในการเทรนโมเดลจำแนกพิกเซล (Semantic Segmentation) ระบบใช้ **Loss Function** แบบผสมผสานระหว่าง Binary Cross-Entropy (BCE) และ Dice Loss:

```text
L = L_BCE + L_Dice
```

การปรับน้ำหนักของโมเดล (Weight Update) ใช้เทคนิค **Differential Learning Rates** ผ่าน AdamW Optimizer โดยมีการตั้งค่าตัวคูณ (Multiplier) ที่แตกต่างกัน:

1. **Backbone Configuration (เรียนรู้ช้า):** `lr_mult = 0.1`
```text
θ_backbone^(t+1) = θ_backbone^(t) - (η × 0.1) × (∂L / ∂θ_backbone)
```

2. **Classification Head Configuration (เรียนรู้เร็ว):** `lr_mult = 10.0`
```text
θ_head^(t+1) = θ_head^(t) - (η × 10.0) × (∂L / ∂θ_head)
```
*(โดย `η` คือค่า Base Learning Rate ของระบบ)*

**คำอธิบายและเหตุผลที่ใช้:**
* **การผสม BCE และ Dice Loss:** 
  * `L_BCE` ช่วยบังคับให้โมเดลประเมินค่าความน่าจะเป็นของแต่ละพิกเซลได้อย่างแม่นยำ 
  * `L_Dice` ช่วยรักษารูปทรงและขอบเขต (Boundary) ของรอยตัดต่อให้คมชัด ลดปัญหาความไม่สมดุลของข้อมูลระหว่างบริเวณพิกเซลจริงที่มีมาก กับพิกเซลรอยแก้ที่มีน้อย
* **Differential Learning Rates:** ระบบต้องการเก็บความสามารถเดิมในการสกัดจุดเด่นของภาพ (Feature Extraction) จากโมเดลที่พรีเทรนมาแล้วเอาไว้ (ป้องกัน Catastrophic Forgetting) จึงสั่งให้แกนหลัก (Backbone) เรียนรู้ช้าสุดๆ (`0.1`) แต่ขณะเดียวกันเราต้องการให้ส่วนประมวลผลปลายทาง (Classification Head) ปรับตัวเข้าหาความรู้ใหม่และข้อมูลภาพสลิปใบเสร็จใหม่ๆ จึงให้เรียนรู้เร็วถึง (`10.0`) เท่า

> **ค่าที่ใช้จริงใน config v10 (`segformer_mit-b2-v10.py` → โมเดล v1.0.5):** `CrossEntropyLoss loss_weight=1.0, class_weight=[1.0, 2.5]` + `DiceLoss loss_weight=1.5` — batch 8 + `accumulative_counts=2` (effective 16 บน VRAM 8GB) — AdamW `lr=2e-5` + LinearLR warmup 3,000 iters + PolyLR — งบ `max_iters=200,000`, `val_interval=2,500`, `save_best='mIoU'` — ผล: best validation mIoU **91.31** @iter 197,500 (รายละเอียดผลดู [[concepts/model-training]])

---

## 5. สมการประเมินประสิทธิภาพโมเดล (Evaluation Metrics)

ระบบอาศัยการวัดผลทั้งในระดับภาพรวมและระดับพิกเซล เพื่อนำมาตั้งค่า Validation Checkpoint

* **Accuracy:**
```text
Accuracy = (TP + TN) / (TP + TN + FP + FN)
```

* **F1-Score (ใช้จัดการ Imbalanced Data):**
```text
F1-Score = 2 × (Precision × Recall) / (Precision + Recall)
```

* **IoU (Intersection over Union) / Dice Coefficient (สำหรับระดับพิกเซล):**
```text
IoU = TP / (TP + FP + FN)
```
```text
Dice = 2TP / (2TP + FP + FN)
```

**คำอธิบายและเหตุผลที่ใช้:**
* **ค่า TP, TN, FP, FN:** TP (ตรวจถูกว่าเป็นภาพปลอม), TN (ตรวจถูกว่าเป็นภาพจริง), FP (ตรวจผิดว่าเป็นภาพปลอม ทั้งที่จริง), FN (ตรวจหลุดว่าเป็นภาพจริง ทั้งที่ปลอม)
* **ข้อจำกัดของ Accuracy:** ความแม่นยำรวม (Accuracy) มักหลอกตาในกรณีที่ภาพสแกม (Scam) ในชุดข้อมูลมีน้อยมาก (Imbalanced Data) ตัวอย่างเช่น มีภาพแท้ 95 ภาพ ภาพสแกม 5 ภาพ โมเดลตอบภาพแท้เสมอ ก็จะได้ Accuracy 95% ทันที
* **การใช้ F1-Score, IoU, mDice:** จึงมีความจำเป็นในการใช้ F1-Score (ทั้งระดับภาพรวมและระดับพิกเซล) เพื่อบังคับให้โมเดลต้องหาความสมดุลระหว่างความไว (Recall) และความแม่นยำ (Precision) ทำให้การวัดผลภาพสแกมและการพ่นสี Heatmap ของรอยตัดต่อ มีความน่าเชื่อถือที่สุด
