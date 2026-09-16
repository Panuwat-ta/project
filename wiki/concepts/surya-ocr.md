---
title: "โมเดล AI — Surya OCR"
category: concepts
tags: [ocr, layout-detection, native-pytorch, text-extraction]
sources: [Document/model/model.md]
updated: 2026-08-06
---

# โมเดล AI — Surya OCR

**Surya-OCR** คือโมเดล Modern OCR ที่ใช้ดึงข้อความและวิเคราะห์โครงสร้าง (Layout Detection) จากรูปภาพที่อัปโหลดเข้ามาระบบ โดยถูกจัดอยู่ใน **Layer 1: Textual Analysis (ชั้นวิเคราะห์ข้อความ)** รันแบบ **Surya OCR v0.5.0 (Native PyTorch)**

---

## ทำไมถึงเลือก Surya OCR?

โมเดลนี้ทำงานบนเวอร์ชัน **0.5.0 (Native PyTorch)** ซึ่งมีคุณสมบัติดังนี้:

1. **Multi-lingual Support:** รองรับการอ่านกว่า 90 ภาษาตาม model card ของผู้พัฒนา Surya v0.5.0 รวมทั้งภาษาไทยและภาษาอังกฤษ (เกณฑ์รับรอง: อ่านไทย/อังกฤษบนภาพ ≥720px ได้ถูกต้อง)
2. **Native PyTorch Inference:** รันโมเดลผ่านสถาปัตยกรรม PyTorch และใช้งานทรัพยากร GPU (CUDA) ได้เต็มประสิทธิภาพโดยตรง
3. **Layout Detection:** สามารถวิเคราะห์โครงสร้างเอกสาร แยกแยะบรรทัด และจัดกลุ่มฟิลด์บนสลิปโอนเงินได้แม่นยำสูง
4. **Robust to Noise:** ทนทานต่อภาพเบลอ ภาพที่ถูกบีบอัด หรือภาพจากสกรีนช็อตผ่านแอปแชต

## อัลกอริทึมและสมการคณิตศาสตร์ (Mathematical Formulation)

Surya-OCR อาศัยสถาปัตยกรรมระดับ Vision-Language Model โดยแบ่งการทำงานเป็นส่วนของการเข้ารหัสภาพ (Vision Encoder) และการถอดรหัสข้อความ (Text Decoder):

1. **Vision Encoder (Feature Extraction):**
   ภาพอินพุต `I` จะถูกแปลงเป็น Sequence ของ Vision Tokens `F_v` ผ่านเครือข่าย Transformer/CNN:
   ```text
   F_v = Encoder_vision(I)
   ```

2. **Text Decoder (Autoregressive Text Generation):**
   การทำนายข้อความ `Y = (y_1, y_2, …, y_T)` อาศัยความน่าจะเป็นแบบมีเงื่อนไข (Conditional Probability) ในการทำนายตัวอักษรถัดไป:
   ```text
   P(Y | I) = Π_t=1^T P(y_t | y_<t, F_v)
   ```
   ฟังก์ชันเป้าหมาย (Objective Function) เพื่อลดค่าข้อผิดพลาดระหว่างการเทรนคือ Cross-Entropy Loss (`L_CE`):
   ```text
   L_CE = - Σ_t=1^T log P(y_t | y_<t, F_v)
   ```

3. **Layout Detection (Bounding Box Regression):**
   เพื่อกำหนดขอบเขต (Bounding Box) ของตัวอักษร โมเดลใช้ฟังก์ชัน Smooth L1 Loss ในการเทียบพิกัด `(x, y, w, h)`:
   ```text
   L_loc(b, b̂) = Σ_{i ∈ {x,y,w,h}} smooth_L_1(b_i - b̂_i)
   ```
   เมื่อ `smooth_L_1(x)` ถูกนิยามเป็น:
   ```text
   smooth_L_1(x) = 0.5 x^2, if |x| < 1; |x| - 0.5, otherwise
   ```

---

## บทบาทในระบบ

1. **Text Recognition:** รับรูปภาพเป็นอินพุตและสกัดออกมาเป็นตัวอักษร (String) พร้อมพิกัดโครงสร้างข้อความ
2. **Scam Keyword Matching:** สตริงที่สกัดได้จะถูกส่งต่อให้ NLP ภายใน Backend API กรองหาคำหลอกลวงหรือ Scam Keywords (เช่น "กู้เงินด่วน", "โอนเงินรับปันผล") เพื่อคำนวณคะแนนความเสี่ยงด้านข้อความ (Textual Score) ต่อไป

---

## หน้าที่เกี่ยวข้อง

- [[concepts/multi-layer-analysis]]
- [[concepts/risk-scoring]]
- [[architecture/ai-inference-service]]
