---
title: "การคำนวณคะแนนความเสี่ยง (Risk Scoring)"
category: concepts
tags: [risk-score, weighted-average, grading, output]
sources: [design/architecture.md, Document/srs.md]
updated: 2026-08-02
---

# การคำนวณคะแนนความเสี่ยง (Risk Scoring)

ระบบประเมินคะแนนความเสี่ยงของรูปภาพตามแนวทาง **Recommended Hybrid Approach (Worst-Case Trigger with Multi-Factor Breakdown)** ตามมาตรฐานวิศวกรรมความมั่นคงปลอดภัย (Fraud Detection & Forensics) โดยประเมิน 3 มิติแยกอิสระ (0–100%) และรวมผลลัพธ์เป็น **Overall Risk Score** (0–100) พร้อมผลแจกแจงแยกมิติ

---

## 1. การประเมินคะแนนแยกมิติ (Independent Factors - 0–100%)

| มิติการวิเคราะห์ | ตัวแปร | ช่วงคะแนน | บทบาทและการวัดผล |
| :--- | :--- | :--- | :--- |
| **Visual Anomaly** | $S_{visual}$ | 0–100% | วัดระดับการตัดต่อ/สังเคราะห์ภาพโดยตรง (Splicing, Copy-Move, AI Diffusion) ด้วย SegFormer และ Heatmap |
| **Textual Analysis** | $S_{textual}$ | 0–100% | วัดความอันตรายของข้อความ/คีย์เวิร์ดหลอกลวง (Blacklist, คำเร่งโอนเงิน, สัญญาผลตอบแทนสูง) ด้วย Surya-OCR |
| **Source Verification** | $S_{source}$ | 0–100% | วัดประวัติการถูกนำไปใช้ซ้ำบนอินเทอร์เน็ต (Reverse Image Search) ผ่าน Google Vision API |

---

## 2. สูตรคำนวณคะแนนรวม (Overall Risk Score Formulation)

ระบบใช้หลักการ **Maximum Impact (Worst-Case Trigger)** ร่วมกับ **Multi-Factor Compounding Penalty** เพื่อป้องกันปัญหาคะแนนเจือจาง (Dilution Problem) เช่น ภาพตัดต่อชัดเจนแต่ไม่มีข้อความ ($S_{text} = 0$) คะแนนรวมจะไม่ถูกดึงลง:

$$ S_{base} = \max(S_{visual}, S_{textual}, S_{source}) $$

$$ S_{total} = \min\left(100, S_{base} + \sum_{i \in \text{secondary}} [S_i \ge 40] \times 5\right) $$

- **$S_{base}$**: คะแนนความเสี่ยงของมิติที่รุนแรงที่สุด
- **Multi-Factor Compounding**: หากตรวจพบความเสี่ยงระดับปานกลางขึ้นไปในมิติอื่น ($\ge 40$) จะบวกคะแนนเพิ่ม $+5$ ต่อมิติ (สูงสุดไม่เกิน 100)
- **Visual Override Rule**: หากตรวจพบร่องรอยการดัดแปลงภาพในระดับวิกฤต ($S_{visual} \ge 80$) ระบบจะบังคับระดับผลลัพธ์เป็น **High Risk** ทันที

---

## 3. ระดับความเสี่ยง (Risk Grade)

ระบบแบ่งเกณฑ์การตัดสินเป็น 3 ระดับ (3-level Scale):

| ช่วงคะแนน | ระดับ | สี | ความหมายและข้อแนะนำ |
| :--- | :--- | :--- | :--- |
| 0 – 39 | **Low** (เสี่ยงต่ำ) | เขียว/เหลือง | ไม่พบร่องรอยการตัดต่อหรือข้อความหลอกลวงที่ชัดเจน ควรใช้วิจารณญาณประกอบ |
| 40 – 69 | **Medium** (น่าสงสัย) | ส้ม | พบสัญญาณน่าสงสัยระดับปานกลาง หรือพบความเสี่ยงหลายมิติควบคู่กัน |
| 70 – 100 | **High** (อันตราย) | แดง | พบหลักฐานการตัดต่อชัดเจน ข้อความหลอกลวงรุนแรง หรือภาพถูกใช้ซ้ำในหลายแหล่ง ($S_{visual} \ge 80$ ปรับเป็น High อัตโนมัติ) |

---

## 4. การนำเสนอผลบนหน้าจอ (UI Presentation)

1. **ระดับภาพรวม (Overview Banner)**: แสดง Risk Level สูงสุดที่พบ (Low / Medium / High) พร้อมคะแนนรวม Overall Score
2. **รายละเอียดการวิเคราะห์ (Breakdown Cards)**: แสดง Progress Bar และคำอธิบายแยกแต่ละมิติตามที่ตรวจพบจริง:
   - ตรวจพบร่องรอยตัดต่อภาพ: $S_{visual}$% (ระดับความเสี่ยงของภาพ)
   - ตรวจพบข้อความน่าสงสัย: $S_{textual}$% (หรือ "ไม่พบข้อความ")
   - ประวัติแหล่งที่มา: $S_{source}$% (จำนวนแหล่งที่พบบนอินเทอร์เน็ต)
3. **หลักฐานเชิงภาพ (Explainable Heatmap)**: แสดง Mask จุดที่โมเดลตรวจพบความผิดปกติซ้อนทับภาพต้นฉบับ

---

## 5. พฤติกรรมการ Cache

เมื่อคำนวณ Risk Score สำหรับภาพใดแล้ว จะ hash รูปภาพและเก็บไว้ใน **Redis** ถ้ามีการส่งรูปเดิมซ้ำ จะดึงผลลัพธ์จาก **PostgreSQL** ทันทีโดยไม่รัน AI Pipeline ซ้ำ ทำให้ latency ลดจาก 15 วินาทีเหลือต่ำกว่า 3 วินาทีสำหรับภาพที่เคยวิเคราะห์แล้ว

---

## 6. การจัดการ Partial Failure

ถ้าชั้นการวิเคราะห์ใดชั้นหนึ่งล้มเหลว (เช่น Reverse Image Search API timeout) ระบบยังคำนวณคะแนนบางส่วนจากมิติที่ทำงานสำเร็จได้ โดยคำนวณ $\max$ จากมิติที่มีข้อมูลจริง และระบุใน response ว่ามิติใดบ้างที่มีส่วนร่วมในการคำนวณ

---

## 7. ประเด็นสำคัญ

- คะแนนเป็นตัวเลขต่อเนื่อง 0–100 ไม่ใช่ pass/fail
- การใช้ Worst-Case Trigger แก้ปัญหาเรื่อง False Negative จากการเฉลี่ยน้ำหนักได้อย่างสมบูรณ์
- UI แสดงผลทั้งระดับสรุปและ Breakdown แยกมิติครบถ้วน
- การ Cache ขจัดการคำนวณซ้ำบนรูปที่เคยส่งมาแล้ว

---

## หน้าที่เกี่ยวข้อง

- [[concepts/multi-layer-analysis]]
- [[concepts/explainable-ai]]
- [[architecture/backend-api]]
- [[architecture/database-schema]]
- [[requirements/objectives-kpis]]
