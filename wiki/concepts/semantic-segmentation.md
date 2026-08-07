---
title: "Semantic Segmentation"
category: concepts
tags: [Semantic Segmentation, SegFormer, forgery, pixel-analysis]
sources: [design/architecture.md, design/model.md, doc/srs.md]
updated: 2026-08-07
---

# Semantic Segmentation

เทคนิคทางคอมพิวเตอร์วิทัศน์ (Computer Vision) ที่ทำการจำแนกประเภทของแต่ละพิกเซลในรูปภาพ ว่าเป็นภาพพื้นหลัง (Background) หรือเป็นรอยที่ถูกดัดแปลงตัดต่อ (Forgery)

---

## หลักการทำงาน

ระบบประเมินความเสี่ยงและตรวจสอบร่องรอยการตัดต่อในระดับพิกเซลด้วยโมเดล Deep Learning (SegFormer) โดยวิเคราะห์บริบทของภาพทั้งในระดับโครงสร้างรวม (Global Context) และรายละเอียดระดับขอบเขตพิกเซล (Local Details)

**ขั้นตอน:**

1. รูปภาพดิบจะถูกส่งเข้าโมเดล SegFormer
2. โมเดลสกัด Features ในหลายระดับความละเอียด (Hierarchical Features)
3. Decoder ของโมเดลจะรวม Features เข้าด้วยกัน และทำการทำนาย (Prediction) ว่าแต่ละพิกเซลในภาพมีความน่าจะเป็นที่จะเป็นรอยตัดต่อมากน้อยเพียงใด
4. ผลลัพธ์ที่ได้จะเป็น Probability Map ที่สามารถนำไปพล็อตเป็นภาพแผนที่ความร้อน (Heatmap) แสดงบริเวณที่น่าสงสัย

---

## ประเภทการปลอมแปลงที่ตรวจจับได้

| ประเภทการปลอมแปลง | คำอธิบาย |
| :--- | :--- |
| Splicing | นำบริเวณจากรูปอื่นมาวาง (มักมีความผิดปกติของสัญญาณพิกเซลและขอบเขต) |
| Copy-Move | คัดลอกบริเวณในรูปเดิมแล้วย้ายไปที่อื่น (โมเดลสามารถเรียนรู้ความซ้ำซ้อน) |
| Retouching | แก้ไขพิกเซลเฉพาะจุด (เช่น เปลี่ยนตัวเลขบนสลิปโอนเงิน) |

---

## Semantic Segmentation ในระบบนี้

เทคนิคนี้เป็นกลไกหลักที่ใช้โดย [[architecture/ai-inference-service|AI Inference Service]] ผ่านโมเดล [[concepts/ai-model-segformer|SegFormer]] 

กระบวนการ:

1. API ส่งภาพไปยัง AI Inference Service
2. ภาพถูกป้อนเข้าสู่กระบวนการ Semantic Segmentation ด้วยโมเดล SegFormer
3. SegFormer สร้าง Segmentation Mask / Probability Map ออกมา
4. Mask ถูกแปลงเป็น [[concepts/explainable-ai|Heatmap]] สำหรับแสดงผลให้ผู้ใช้เห็นจุดเสี่ยง

---

## ประเด็นสำคัญ

- แตกต่างจาก Image Classification ที่บอกแค่ว่า "มี" หรือ "ไม่มี" การตัดต่อ แต่ Semantic Segmentation จะชี้ตำแหน่งพิกเซล (Localization) ให้เห็นชัดเจน
- ใช้ [[concepts/model-training|Differential Learning Rates]] ในการ Train โมเดลให้มีความแม่นยำสูง
- ได้ผลดีกับประเภทภาพหลอกลวงที่พบบ่อยที่สุด: สลิปที่ถูกแก้ไขตัวเลข, ใบเสร็จปลอม, รูปโปรไฟล์ที่เปลี่ยนใบหน้า

---

## หน้าที่เกี่ยวข้อง

- [[concepts/ai-model-segformer]]
- [[concepts/multi-layer-analysis]]
- [[concepts/explainable-ai]]
- [[architecture/ai-inference-service]]
