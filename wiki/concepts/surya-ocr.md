---
title: "โมเดล AI — Surya OCR 2"
category: concepts
tags: [ocr, vlm, layout-detection, llama-cpp, text-extraction]
sources: [doc/model/model.md]
updated: 2026-08-06
---

# โมเดล AI — Surya OCR 2

**Surya-OCR 2** คือโมเดล Modern OCR ที่ใช้ดึงข้อความและวิเคราะห์โครงสร้าง (Layout Detection) จากรูปภาพที่อัปโหลดเข้ามาระบบ โดยถูกจัดอยู่ใน **Layer 1: Textual Analysis (ชั้นวิเคราะห์ข้อความ)**

---

## ทำไมถึงเลือก Surya OCR 2?

โมเดลนี้ทำงานบนสถาปัตยกรรม Vision-Language Model (VLM) ในรูปแบบ **GGUF Format** (`datalab-to/surya-ocr-2-gguf`) ซึ่งมีคุณสมบัติดังนี้:

1. **Multi-lingual Support:** รองรับการอ่านกว่า 90 ภาษา รวมทั้งภาษาไทยและภาษาอังกฤษ
2. **GGUF Optimized:** แปลงน้ำหนักโมเดลให้มีขนาดเล็กลง (Quantization) กินทรัพยากรน้อย แต่ยังคงความแม่นยำ เหมาะกับการรันบน Local Server ผ่าน `llama.cpp`
3. **Layout Detection:** สามารถวิเคราะห์โครงสร้างเอกสาร แยกแยะบรรทัด และจัดกลุ่มฟิลด์บนสลิปโอนเงินได้ถูกต้อง
4. **Robust to Noise:** ทนทานต่อภาพเบลอ ภาพที่ถูกบีบอัด หรือภาพจากสกรีนช็อตผ่านแอปแชต

---

## บทบาทในระบบ

1. **Text Recognition:** รับรูปภาพเป็นอินพุตและสกัดออกมาเป็นตัวอักษร (String) พร้อมพิกัดโครงสร้างข้อความ
2. **Scam Keyword Matching:** สตริงที่สกัดได้จะถูกส่งต่อให้ NLP ภายใน Backend API กรองหาคำหลอกลวงหรือ Scam Keywords (เช่น "กู้เงินด่วน", "โอนเงินรับปันผล") เพื่อคำนวณคะแนนความเสี่ยงด้านข้อความ (Textual Score) ต่อไป

---

## หน้าที่เกี่ยวข้อง

- [[concepts/multi-layer-analysis]]
- [[concepts/risk-scoring]]
- [[architecture/ai-inference-service]]
