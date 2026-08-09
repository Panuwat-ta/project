---
title: "โมเดล AI — SegFormer"
category: concepts
tags: [SegFormer, transformer, semantic-segmentation, MiT, ONNX, deep-learning]
sources: [design/model.md]
updated: 2026-08-02
---

# โมเดล AI — SegFormer

โมเดล Deep Learning หลักที่ใช้ตรวจจับการตัดต่อภาพในระดับพิกเซล SegFormer เป็นสถาปัตยกรรม Transformer ที่ออกแบบมาสำหรับงาน Semantic Segmentation โดยเฉพาะ

---

## ทำไมถึงเลือก SegFormer?

งานหลักคือการหาว่า *พิกเซลใด* ถูกดัดแปลง — ซึ่งเป็นปัญหา **Semantic Segmentation** ไม่ใช่แค่ Classification ธรรมดา SegFormer ถูกเลือกเพราะ:

- ออกแบบมาสำหรับงาน Semantic Segmentation (การระบุป้ายกำกับระดับพิกเซล) โดยเฉพาะ
- ไม่ใช้ Positional Encoding แบบซับซ้อน ทำให้เร็วขึ้นและ generalize ได้ดีกว่า Vision Transformer รุ่นเก่า
- จัดการทั้ง **Global Context** (โครงสร้างภาพโดยรวม) และ **Local Details** (รายละเอียดพิกเซลละเอียด) ผ่าน Multi-scale Features
- เบากว่าโมเดล ViT-based ทั่วไป
- แปลงเป็น ONNX ได้ง่ายหลัง training ใน PyTorch

**ข้อจำกัด:** ใช้ RAM/VRAM สูงกว่า CNN แบบดั้งเดิม ยอมรับได้ในระดับ Server Inference แต่เป็นแรงผลักดันให้วางแผน On-device Quantization ในอนาคต

---

## สถาปัตยกรรม

```
รูปภาพ Input (RGB เช่น 512×512)
        |
  Preprocessing: Resize + Normalize
        |
  MiT Encoder (Mix Transformer Encoder)
  ├── ดึง Feature หลายระดับความละเอียด (Hierarchical)
  ├── Efficient Self-Attention (ไม่ใช้ Fixed Positional Encoding)
  └── ส่งออก Multi-scale Feature Maps (F1, F2, F3, F4)
        |
  All-MLP Decoder (SegFormer Decoder)
  ├── รวม Feature จาก Encoder หลายระดับ
  └── สร้าง Probability Map ระดับพิกเซล
        |
  Pixel Prediction

  ├── Class 0: พิกเซลดั้งเดิม
  └── Class 1: พิกเซลที่ถูกดัดแปลง
        |
  Post-processing:
  ├── Segmentation Mask (binary, ขนาดเท่า input)
  ├── Heatmap (ค่าความเชื่อมั่นต่อพิกเซล)
  └── Risk Score (รวมจาก mask coverage × confidence)
```

### อัลกอริทึมและสมการคณิตศาสตร์ (Mathematical Formulation)

1. **Efficient Self-Attention:**
   $X \in \mathbb{R}^{H \times W \times C}$ จะถูกแปลงให้แบนราบ (Flatten) เป็น Sequence $N = H \times W$
   โดยลดมิติของ Key และ Value ด้วยอัตราส่วน $R$ เพื่อลดภาระการคำนวณ:
   $$K' = \text{Reshape}\left(\frac{N}{R}, C \cdot R\right)(K) \cdot W_K$$
   $$V' = \text{Reshape}\left(\frac{N}{R}, C \cdot R\right)(V) \cdot W_V$$
   $$ \text{Attention}(Q, K', V') = \text{Softmax}\left( \frac{Q (K')^T}{\sqrt{d_k}} \right) V' $$

2. **Mix-FFN (Mix Feed-Forward Network):**
   ใช้ 3x3 Convolution แทน Positional Encoding แบบตายตัว เพื่อพิจารณาตำแหน่งจากบริบทภาพ:
   $$x_{out} = \text{MLP}(\text{GELU}(\text{Conv}_{3\times3}(\text{MLP}(x_{in})))) + x_{in}$$

---

## รูปแบบข้อมูล

| ขั้นตอน | รูปแบบ | คำอธิบาย |
| :--- | :--- | :--- |
| Input | Tensor `[B, 3, H, W]` | เช่น `[1, 3, 512, 512]` สำหรับ 1 ภาพ |
| Encoder output | Multi-scale feature maps | การแทนค่าแบบลำดับชั้น |
| Decoder output | Tensor `[B, 2, H, W]` | ความน่าจะเป็นต่อพิกเซลทุก class |
| Segmentation Mask | PNG ขาวดำ | ขาว = ถูกดัดแปลง, ดำ = ดั้งเดิม |
| Heatmap | Float array | ค่าความเชื่อมั่นต่อพิกเซล (0.0–1.0) |
| Risk Score | Float 0–100 | คำนวณจาก mask coverage และ confidence |

---

## Versioning และการ Deploy

- Version โมเดลใช้ Semantic Versioning เช่น `segformer_v1.0.0`
- Train ใน PyTorch แล้ว export เป็น **ONNX format** สำหรับ Production Inference
- ONNX Runtime ให้ความเร็ว Inference 2–5 เท่าเทียบกับ Native PyTorch
- น้ำหนักโมเดลเก็บใน **Model Registry** (Version-controlled file store)
- Admin สามารถ deploy โมเดลเวอร์ชันใหม่ผ่าน Admin Portal โดยไม่ต้อง Redeploy service

---

## ข้อจำกัดที่รู้จัก

1. **การ Re-compress ซ้ำหลายครั้ง** — ความแม่นยำลดลงถ้าภาพถูก compress หลายรอบ (เช่น ส่งต่อผ่านแอปแชท) เพราะ artifact จาก compression บดบัง Semantic Segmentation signal
2. **ภาพ AI-Generated ทั้งหมด** — SegFormer ตรวจจับ *การตัดต่อ* ระดับพิกเซล ภาพ synthetic ทั้งหมดไม่มี splice artifact แบบดั้งเดิม ต้องใช้ AI-Gen classifier แยกต่างหาก

---

## แผนพัฒนาในอนาคต

- **Ensemble Model** — เพิ่มโมเดลตรวจจับภาพ AI-Generated ควบคู่กับ SegFormer
- **Model Quantization** (INT8/FP16) — เพื่อ Inference บนอุปกรณ์มือถือโดยตรง ขจัดการรอ Network Round-trip

---

## หน้าที่เกี่ยวข้อง

- [[concepts/semantic-segmentation]]
- [[concepts/explainable-ai]]
- [[concepts/multi-layer-analysis]]
- [[architecture/ai-inference-service]]
- [[decisions/technology-choices]]
