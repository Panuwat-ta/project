---
title: "AI Inference Service"
category: architecture
tags: [AI, inference, PyTorch, ONNX, Semantic Segmentation, Heatmap, segmentation]
sources: [design/architecture.md, design/model.md, design/server.md]
updated: 2026-08-02
---

# AI Inference Service

Container ประมวลผลเฉพาะสำหรับรัน Deep Learning Model แยกจาก API Application เพื่อให้ Scale GPU-intensive Task ได้อย่างอิสระ

---

## บทบาท

AI Inference Service คือ **หน่วย Deploy แยก** (Container) ที่รับ Task วิเคราะห์รูปภาพจาก [[architecture/backend-api|API Application]] และส่งคืน:

- **Segmentation Mask** ระบุพิกเซลที่ถูกดัดแปลง
- **Heatmap** สำหรับ XAI overlay
- **คะแนนตรวจจับภาพ AI-Generated**
- **Visual Risk Score (S_visual)** — สเกลอิสระ 0–100% (เป็นปัจจัยหลักใน Worst-Case Trigger และหาก $\ge 80$ บังคับเป็น High ทันที)

---

## โมเดลที่ทำงานใน Service นี้

### 1. ตรวจจับการตัดต่อภาพ (SegFormer)

- **เทคนิค:** Semantic Segmentation Preprocessing → [[concepts/ai-model-segformer|SegFormer]] Model Inference
- **ผลลัพธ์:** Binary Segmentation Mask + Confidence Heatmap
- **หน้าที่:** ตรวจจับ Splicing, Copy-Move และการแก้ไขพิกเซล

### 2. ตรวจจับภาพสังเคราะห์จาก AI (AI-Gen Classifier)

- **เทคนิค:** CNN หรือ ViT-based Binary Classifier แยกต่างหาก
- **ผลลัพธ์:** ค่าความน่าจะเป็น (0–1) ว่าภาพสร้างจาก Generative AI
- **หน้าที่:** จับภาพจาก GAN, Diffusion Model ที่ไม่มี Splice Artifact แบบดั้งเดิม

### 3. สร้าง Heatmap

- **Input:** ผลลัพธ์ Segmentation จาก SegFormer
- **ผลลัพธ์:** ไฟล์ PNG Heatmap ที่แต่งสีแล้ว พร้อม overlay บนรูปต้นฉบับ
- เก็บใน Cloud Object Storage สำหรับ Mobile App ดึงไปแสดงผล

---

## Inference Pipeline

```
API ส่ง POST { image_bytes, task_id }
        |
  Preprocessing:
    - Decode Image Bytes
    - Resize ตาม Input Size (เช่น 512×512)
    - Normalize ค่าพิกเซล
    - (ถ้าต้องการ) คำนวณ Semantic Segmentation Difference Map
        |
  Forward Pass (SegFormer ONNX Model)
        |
  Post-processing:
    - แปลง Tensor เป็น Segmentation Mask
    - กรอง Noise (ตัดบริเวณผิดปกติขนาดเล็กที่กระจัดกระจาย)
    - คำนวณ Heatmap ความเชื่อมั่นต่อพิกเซล
    - รวม Risk Score จาก Mask Coverage × Confidence
        |
  AI-Gen Classifier Forward Pass แยก
        |
  OCR & Text Extraction (Surya OCR 2 GGUF):
    - รันโมเดล Qwen2.5-VL เพื่อดึงข้อความจากภาพ
    - ส่งมอบ ocr_text ให้ Scam Keyword Matching
        |
  แต่งสี Heatmap และสร้างภาพ Overlay
        |
  อัปโหลด Heatmap PNG ไปยัง Cloud Object Storage
        |
  ส่งคืน { visual_risk_score, mask_url, heatmap_url, ai_gen_score }
```

---

## รายละเอียด Runtime

| ด้าน | รายละเอียด |
| :--- | :--- |
| Framework (Training) | PyTorch |
| Framework (Inference) | ONNX Runtime |
| ความเร็วที่เพิ่มขึ้นจาก ONNX | 2–5 เท่าเทียบ Native PyTorch |
| รูปแบบโมเดล | ไฟล์ `.onnx` เก็บใน Model Weights Store |
| Input Tensor | `[1, 3, 512, 512]` (1 รูป, RGB) |
| Output Tensor | `[1, 2, 512, 512]` (ความน่าจะเป็นต่อพิกเซลทุก Class) |

---

## การจัดการโมเดล

- Model Weight เก็บใน **Model Registry** (Version-controlled File Store)
- Admin Endpoint ของ API Application สั่ง Hot-swap โมเดล: Inference Service โหลด Weight ใหม่โดยไม่ต้อง Restart Container
- Semantic Versioning: `segformer_v1.0.0`, `segformer_v1.1.0` เป็นต้น

---

## การพิจารณา Scaling

- Container นี้ใช้ทรัพยากรมากที่สุดในระบบ (GPU/CPU สำหรับ Model Inference)
- การแยกออกจาก API Application ช่วยให้ Auto-scale เฉพาะ Inference Service ในช่วง High Load
- Redis Cache ใน API Application ลดการเรียก Service นี้สำหรับรูปที่เคยวิเคราะห์แล้ว

---

## หน้าที่เกี่ยวข้อง

- [[concepts/ai-model-segformer]]
- [[concepts/semantic-segmentation]]
- [[concepts/explainable-ai]]
- [[architecture/backend-api]]
- [[architecture/database-schema]]
- [[requirements/objectives-kpis]]
