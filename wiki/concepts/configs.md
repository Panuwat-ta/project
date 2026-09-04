---
title: "พารามิเตอร์และสมการคณิตศาสตร์ (Configurations & Math)"
category: concepts
tags: [risk-score, equations, loss-function, SegFormer, parameters]
sources: [Document/model/configs.md, Document/model/training.md]
updated: 2026-08-08
---

# การตั้งค่าพารามิเตอร์ อัลกอริทึมและสมการคณิตศาสตร์ที่ใช้ (Configuration, Algorithms, and Mathematical Equations)

เอกสารฉบับนี้รวบรวมสมการคณิตศาสตร์ อัลกอริทึม และค่าการตั้งค่า (Configurations) หลักที่ใช้ในกระบวนการประมวลผล ประเมินผลลัพธ์ และการฝึกสอนโมเดล AI ภายในระบบ Scam Image Detection พร้อมคำอธิบายเหตุผลและหลักการที่อยู่เบื้องหลังการออกแบบแต่ละส่วน

---

## 1. การคำนวณคะแนนความเสี่ยงรวม (Overall Risk Score - Recommended Hybrid Approach)

ระบบประมวลผลคะแนนความเสี่ยงของรูปภาพโดยใช้หลักการ **Maximum Impact (Worst-Case Trigger) ร่วมกับ Multi-Factor Compounding Penalty** ซึ่งเป็นมาตรฐานวิศวกรรมความมั่นคงปลอดภัย (Fraud Detection & Forensics) ตามโค้ดใน `server/app/utils/risk_calculator.py`:

$$ S_{base} = \max(S_{visual}, S_{textual}, S_{source}) $$

$$ S_{total} = \min\left(100, S_{base} + \sum_{i \in \text{secondary}} [S_i \ge 40] \times 5\right) $$

โดยที่:
* **$S_{total}$** คือ คะแนนความเสี่ยงรวม (Overall Risk Score) มีค่าตั้งแต่ 0 ถึง 100
* **$S_{base}$** คือ ค่าคะแนนสูงสุดในบรรดามิติที่ตรวจพบ ($\max$) เพื่อเป็นฐานความเสี่ยงหลัก
* **$S_{visual}$** คือ คะแนนความผิดปกติทางภาพ (Visual Anomaly Score 0–100%) จากโมเดล SegFormer + Heatmap
* **$S_{textual}$** คือ คะแนนความเสี่ยงด้านข้อความ (Textual Analysis Score 0–100%) จาก Surya-OCR + Pattern Matching
* **$S_{source}$** คือ คะแนนความเสี่ยงจากแหล่งที่มาของภาพ (Source Reliability Score 0–100%) จาก Reverse Image Search
* **Compounding Penalty:** หากมิติรองใดมีคะแนน $\ge 40$ (ระดับ Medium ขึ้นไป) จะบวกเพิ่ม $+5$ ต่อมิติ (สูงสุดไม่เกิน 100)

**คำอธิบายและเหตุผลที่ใช้:**
* **แก้ปัญหา Dilution Problem:** ในกรณีที่เป็นภาพตัดต่อหรือภาพสังเคราะห์ชัดเจนแต่ไม่มีข้อความ ($S_{visual} = 85, S_{text} = 0$) หรือกรณี Romance Scam การใช้ค่าเฉลี่ยถ่วงน้ำหนักจะทำให้คะแนนรวมถูกฉุดลงจนหลุดเกณฑ์อันตราย แต่ Worst-Case Trigger จะการันตีว่าคะแนนรวมไม่ต่ำกว่ามิติที่อันตรายที่สุด
* **สะท้อนความอันตรายแบบทวีคูณ (Multi-factor Risk):** หากภาพใดพบทั้งการตัดต่อภาพและมีข้อความหลอกลวงพร้อมกัน คะแนนรวมจะได้รับการเพิ่มพิเศษ (Compounding) เพื่อเตือนภัยผู้ใช้อย่างเด็ดขาด
* **การนำเสนอผลแบบคู่ขนาน (UI Breakdown):** นอกเหนือจาก Overall Score แล้ว บน UI จะแจกแจง Progress Bar และคำอธิบายแยกแต่ละมิติ 0–100% เสมอ

---

## 2. เกณฑ์การตัดสินระดับความเสี่ยง (Risk Grading Thresholds)

เมื่อคำนวณคะแนน $S_{total}$ ออกมาแล้ว ระบบจะนำไปจัดกลุ่มระดับความเสี่ยงตามเงื่อนไข (Threshold Configuration) ดังนี้:

$$
\text{Risk Grade} = 
\begin{cases} 
\text{Low (เสี่ยงต่ำ)} & \text{if } 0 \le S_{total} \le 39 \\
\text{Medium (น่าสงสัย)} & \text{if } 40 \le S_{total} \le 69 \\
\text{High (อันตราย)} & \text{if } S_{total} \ge 70 
\end{cases}
$$

**คำอธิบายและเหตุผลที่ใช้:**
* **ช่วงเสี่ยงต่ำ (0 -- 39):** มีสัญญาณอ่อนบางจุดที่ตรวจพบ แต่ยังไม่ถึงระดับที่ควรกังวล ผู้ใช้งานควรทราบแต่ไม่จำเป็นต้องดำเนินการใดเป็นพิเศษ
* **ช่วงน่าสงสัย (40 -- 69):** มีบางชั้นตรวจพบความผิดปกติ แต่ไม่ชัดเจนทุกชั้น หรือพบหลักฐานแบบอ่อนๆ ผู้ใช้งานควรพิจารณาประกอบกับวิจารณญาณส่วนตัว
* **ช่วงอันตราย (70 -- 100):** ผลวิเคราะห์ส่วนใหญ่ชี้ไปในทิศทางเดียวกันว่าภาพถูกปรับแต่งหรือมีข้อความหลอกลวงที่ชัดเจน ให้ถือว่าภาพนี้มีความเสี่ยงสูงที่จะเป็นสแกม (กรณี $S_{visual} \ge 80$ ระบบจะขึ้นเป็น High ทันที)

---

## 3. การคำนวณคะแนนความเสี่ยงทางภาพ ($S_{visual}$)

การได้มาซึ่งคะแนน $S_{visual}$ จากโมเดล SegFormer อาศัยความน่าจะเป็นของการเป็นรอยตัดต่อ (Confidence Score) และสัดส่วนพื้นที่ที่พบความผิดปกติ (Mask Coverage):

$$ S_{visual} = \text{Normalize}(\text{Confidence} \times \text{Mask Coverage}) $$

**คำอธิบายและเหตุผลที่ใช้:**
* **Confidence Score:** คือค่าความมั่นใจของ AI ว่าพิกเซลนั้นๆ ถูกดัดแปลงจริงหรือไม่ (มีค่าความน่าจะเป็น 0 - 1)
* **Mask Coverage:** คือขนาดของพื้นที่ (Bounding Box หรือ Segmentation Mask) ที่พบการตัดต่อ เทียบกับพื้นที่ทั้งหมดของภาพ
* **หลักการคิด:** หากมีการแก้ไขภาพด้วยความเนียนที่ต่ำ (Confidence สูง) และแก้พื้นที่เยอะ (Coverage สูง) คะแนนความเสี่ยงทางภาพ ($S_{visual}$) จะยิ่งมีค่าสูงขึ้น ในขณะที่รอยแก้เล็กๆ แม้ Confidence สูง ก็จะมีผลต่อคะแนนลดลงบ้างตามสัดส่วน
* *(ค่าที่ได้จะถูกปรับสเกล (Normalize) ให้อยู่ในช่วง 0-100 ก่อนนำไปคำนวณ)*

---

## 4. สมการสำหรับการฝึกสอนโมเดลและการตั้งค่า Loss Function (Training Configurations)

เพื่อเพิ่มความแม่นยำในการเทรนโมเดลจำแนกพิกเซล (Semantic Segmentation) ระบบใช้ **Loss Function** แบบผสมผสานระหว่าง Binary Cross-Entropy (BCE) และ Dice Loss:

$$ L = L_{BCE} + L_{Dice} $$

การปรับน้ำหนักของโมเดล (Weight Update) ใช้เทคนิค **Differential Learning Rates** ผ่าน AdamW Optimizer โดยมีการตั้งค่าตัวคูณ (Multiplier) ที่แตกต่างกัน:

1. **Backbone Configuration (เรียนรู้ช้า):** `lr_mult = 0.1`
$$ \theta_{backbone}^{(t+1)} = \theta_{backbone}^{(t)} - (\eta \times 0.1) \frac{\partial L}{\partial \theta_{backbone}} $$

2. **Classification Head Configuration (เรียนรู้เร็ว):** `lr_mult = 10.0`
$$ \theta_{head}^{(t+1)} = \theta_{head}^{(t)} - (\eta \times 10.0) \frac{\partial L}{\partial \theta_{head}} $$
*(โดย $\eta$ คือค่า Base Learning Rate ของระบบ)*

**คำอธิบายและเหตุผลที่ใช้:**
* **การผสม BCE และ Dice Loss:** 
  * $L_{BCE}$ ช่วยบังคับให้โมเดลประเมินค่าความน่าจะเป็นของแต่ละพิกเซลได้อย่างแม่นยำ 
  * $L_{Dice}$ ช่วยรักษารูปทรงและขอบเขต (Boundary) ของรอยตัดต่อให้คมชัด ลดปัญหาความไม่สมดุลของข้อมูลระหว่างบริเวณพิกเซลจริงที่มีมาก กับพิกเซลรอยแก้ที่มีน้อย
* **Differential Learning Rates:** ระบบต้องการเก็บความสามารถเดิมในการสกัดจุดเด่นของภาพ (Feature Extraction) จากโมเดลที่พรีเทรนมาแล้วเอาไว้ (ป้องกัน Catastrophic Forgetting) จึงสั่งให้แกนหลัก (Backbone) เรียนรู้ช้าสุดๆ (`0.1`) แต่ขณะเดียวกันเราต้องการให้ส่วนประมวลผลปลายทาง (Classification Head) ปรับตัวเข้าหาความรู้ใหม่และข้อมูลภาพสลิปใบเสร็จใหม่ๆ จึงให้เรียนรู้เร็วถึง (`10.0`) เท่า

---

## 5. สมการประเมินประสิทธิภาพโมเดล (Evaluation Metrics)

ระบบอาศัยการวัดผลทั้งในระดับภาพรวมและระดับพิกเซล เพื่อนำมาตั้งค่า Validation Checkpoint

* **Accuracy:**
$$ \text{Accuracy} = \frac{TP + TN}{TP + TN + FP + FN} $$

* **F1-Score (ใช้จัดการ Imbalanced Data):**
$$ \text{F1-Score} = 2 \times \frac{\text{Precision} \times \text{Recall}}{\text{Precision} + \text{Recall}} $$

* **IoU (Intersection over Union) / Dice Coefficient (สำหรับระดับพิกเซล):**
$$ \text{IoU} = \frac{TP}{TP + FP + FN} $$
$$ \text{Dice} = \frac{2TP}{2TP + FP + FN} $$

**คำอธิบายและเหตุผลที่ใช้:**
* **ค่า TP, TN, FP, FN:** TP (ตรวจถูกว่าเป็นภาพปลอม), TN (ตรวจถูกว่าเป็นภาพจริง), FP (ตรวจผิดว่าเป็นภาพปลอม ทั้งที่จริง), FN (ตรวจหลุดว่าเป็นภาพจริง ทั้งที่ปลอม)
* **ข้อจำกัดของ Accuracy:** ความแม่นยำรวม (Accuracy) มักหลอกตาในกรณีที่ภาพสแกม (Scam) ในชุดข้อมูลมีน้อยมาก (Imbalanced Data) ตัวอย่างเช่น มีภาพแท้ 95 ภาพ ภาพสแกม 5 ภาพ โมเดลตอบภาพแท้เสมอ ก็จะได้ Accuracy 95% ทันที
* **การใช้ F1-Score, IoU, mDice:** จึงมีความจำเป็นในการใช้ F1-Score (ทั้งระดับภาพรวมและระดับพิกเซล) เพื่อบังคับให้โมเดลต้องหาความสมดุลระหว่างความไว (Recall) และความแม่นยำ (Precision) ทำให้การวัดผลภาพสแกมและการพ่นสี Heatmap ของรอยตัดต่อ มีความน่าเชื่อถือที่สุด
