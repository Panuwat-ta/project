---
title: "Error Level Analysis (ELA)"
category: concepts
tags: [ELA, JPEG, compression, forgery, pixel-analysis]
sources: [design/architecture.md, design/model.md, doc/srs.md]
updated: 2026-08-02
---

# Error Level Analysis (ELA)

เทคนิคนิติวิทยาศาสตร์ภาพถ่ายที่ตรวจจับบริเวณที่ถูกดัดแปลงโดยอาศัยความไม่สม่ำเสมอของ JPEG Compression Artifact

---

## หลักการทำงานของ ELA

ภาพ JPEG ใช้การบีบอัดแบบ Lossy ทุกครั้งที่บันทึก artifact ของการบีบอัดจะสะสมเพิ่มขึ้น สิ่งสำคัญคือ ทุกส่วนของภาพ JPEG ที่ **ไม่ถูกแก้ไข** จะเสื่อมสภาพในอัตราเดียวกันเมื่อบันทึกซ้ำ

เมื่อภาพ **ถูกดัดแปลง** (เช่น วางตัวเลขใหม่ทับสลิป หรือเปลี่ยนใบหน้า) บริเวณที่แก้ไขถูกบันทึกด้วย compression level ที่แตกต่างจากส่วนอื่น การ Re-save ภาพที่ถูกดัดแปลงด้วย quality level ที่กำหนดจะเผยให้เห็นความไม่สอดคล้องนี้

**ขั้นตอน:**
1. Re-save ภาพด้วย JPEG quality ที่กำหนด (เช่น 95%)
2. คำนวณ Pixel-wise Difference ระหว่างภาพต้นฉบับกับภาพที่ Re-save แล้ว
3. ขยายค่า Difference เพื่อให้มองเห็นชัดขึ้น
4. บริเวณที่เปลี่ยนแปลงมาก = น่าจะถูกดัดแปลง

---

## ประเภทการปลอมแปลงที่ ELA ตรวจจับได้

| ประเภทการปลอมแปลง | คำอธิบาย |
| :--- | :--- |
| Splicing | นำบริเวณจากรูปอื่นมาวาง |
| Copy-Move | คัดลอกบริเวณในรูปเดิมแล้วย้ายไปที่อื่น |
| Retouching | แก้ไขพิกเซลเฉพาะจุด (เช่น เปลี่ยนตัวเลขบนสลิป) |

---

## ELA ในระบบนี้

ELA คือสัญญาณหลักที่ใช้โดย [[architecture/ai-inference-service|AI Inference Service]] โมเดล [[concepts/ai-model-segformer]] ถูก Train ให้จดจำรูปแบบ ELA และสร้าง Segmentation Mask ระดับพิกเซล

กระบวนการ:
1. API ส่งภาพไปยัง AI Inference Service
2. AI Inference Service ทำ ELA Preprocessing (Re-save + คำนวณ Difference Map)
3. ผลลัพธ์ ELA (Difference Map) ถูกส่งเข้าโมเดล SegFormer
4. SegFormer สร้าง Segmentation Mask
5. Mask ถูกแปลงเป็น [[concepts/explainable-ai|Grad-CAM Heatmap]] สำหรับผู้ใช้

---

## ข้อจำกัด

- **การ Re-compress หลายครั้ง** — ถ้าภาพถูก compress ซ้ำหลายรอบ (เช่น ส่งต่อผ่านแอปแชท) สัญญาณ ELA เสื่อมลงและอาจให้ False Negative
- **PNG และ Lossless Format** — ELA ได้ผลดีที่สุดกับภาพ JPEG รูปแบบ Lossless ไม่มี Compression Artifact แบบเดียวกัน
- **ภาพ AI-Generated ทั้งหมด** — ไม่ได้ "ถูกตัดต่อ" ในแบบดั้งเดิม ELA เพียงอย่างเดียวจึงตรวจจับไม่ได้ ต้องใช้โมเดล AI-Gen Detection แยกต่างหาก

---

## ประเด็นสำคัญ

- ELA ใช้ฟิสิกส์ของการ JPEG Compression เพื่อทำให้การแก้ไขพิกเซลมองเห็นได้
- เป็นขั้นตอน Preprocessing ที่ป้อนให้กับโมเดล SegFormer ไม่ใช่ตัวตรวจจับอิสระ
- ได้ผลดีกับประเภทภาพหลอกลวงที่พบบ่อยที่สุด: สลิปที่ถูกแก้ไขตัวเลข, ใบเสร็จปลอม, รูปโปรไฟล์ที่เปลี่ยนใบหน้า
- เสื่อมประสิทธิภาพบนภาพที่ถูก Re-compress มาก — ปัญหาที่รับรู้ในระบบตรวจจับ ELA ทุกระบบ

---

## หน้าที่เกี่ยวข้อง

- [[concepts/ai-model-segformer]]
- [[concepts/multi-layer-analysis]]
- [[concepts/explainable-ai]]
- [[architecture/ai-inference-service]]
