---
title: "AI Inference Service"
category: architecture
tags: [AI, inference, PyTorch, ONNX, Semantic Segmentation, Heatmap, segmentation]
sources: [design/architecture.md, design/model.md, design/server.md]
updated: 2026-08-02
---

# AI Inference Service

หน่วยประมวลผล AI ที่รันเป็น **ONNX Worker subprocess** ภายใน Backend เดียวกัน

---

## บทบาท

AI Inference Service คือ **ONNX Worker subprocess** ที่ถูกเรียกจาก [[architecture/backend-api|API Application]] และส่งคืน:

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

### 3. สร้าง Heatmap (Mask-to-Heatmap Overlay)

- **Input:** Probability map ระดับพิกเซลจาก SegFormer ONNX (tiling 512 + overlap 64)
- **วิธี:** แปลง prob map เป็นภาพสีแล้วซ้อนทับบนภาพต้นฉบับ
- **ผลลัพธ์:** ไฟล์ `{image_hash}_heatmap.jpg` เก็บที่ `{LOCAL_UPLOAD_DIR}/heatmaps/` เสิร์ฟผ่าน `/uploads` static mount ให้ Mobile App ดึงไปแสดงผล

---

## Inference Pipeline

```
scan_service เรียก inference_service
        |
  Preprocessing:
    - ยืนยันไฟล์รูปจริง + ดึง EXIF (จำกัดภาพสูงสุด 100M พิกเซล)
    - normalize เป็น PNG ก่อนส่ง AI
        |
  Forward Pass (SegFormer ONNX):
    - tiling 512x512 overlap 64, softmax 2 classes
    - prob map เต็ม resolution ต้นฉบับ
        |
  Post-processing:
    - คำนวณ visual_risk_score และ ai_gen_probability จากค่า max ของ prob map
    - แผนที่ความร้อนแบบ mask-to-heatmap overlay
    - ใช้ SegFormer ตัวเดียวใน pipeline
        |
  OCR และ Text Extraction (Surya OCR v0.5.0):
    - รองรับภาษาไทยและอังกฤษ
    - ส่งมอบข้อความ OCR ให้ Scam Keyword Matching
        |
  XAI reasoning (Qwen2.5-1.5B สำหรับสร้างคำอธิบายภาษาไทย)
        |
  บันทึกรูปต้นฉบับและ Heatmap ลง Storage
        |
  ส่งคืนคะแนนภาพ, ความน่าจะเป็น AI-Gen, บริเวณผิดปกติ, Heatmap และข้อความ OCR
```

---

## รายละเอียด Runtime

| ด้าน | รายละเอียด |
| :--- | :--- |
| Framework (Training) | PyTorch |
| Framework (Inference) | ONNX Runtime |
| ความเร็วที่เพิ่มขึ้นจาก ONNX | 2–5 เท่าเทียบ Native PyTorch |
| รูปแบบโมเดล | ไฟล์ ONNX (tile 512 / overlap 64) |
| Input Tensor | ภาพ RGB ขนาด 512x512 ต่อ tile |
| Output Tensor | 2 classes ต่อ tile (authentic / tampered) |
| OCR | Surya OCR v0.5.0 (Native PyTorch) |
| XAI reasoning | Qwen2.5-1.5B สำหรับสร้างคำอธิบายภาษาไทย |
| Heatmap | แผนที่ความร้อนแบบ mask-to-heatmap overlay |
| Topology | ONNX Worker subprocess ภายใน Backend เดียวกัน |

---

## การจัดการโมเดล

- Model Weight แบบ ONNX; ตาราง model_versions เก็บ registry พร้อม metrics
- Admin deploy ผ่าน endpoint deploy/dry-run — worker โหลดโมเดลใหม่เมื่อ subprocess ถัดไปเริ่ม
- Semantic Versioning: `segformer_v1.0.0`, `segformer_v1.1.0` เป็นต้น

---

## การพิจารณา Scaling

- Subprocess นี้ใช้ทรัพยากรมากที่สุดในระบบ (GPU/CPU สำหรับ Model Inference)
- การแยกเป็น subprocess ช่วยแยกภาระงาน AI ออกจากการตอบสนอง request หลักของ FastAPI
- Redis Cache (SHA-256, TTL 30 วัน) ใน API Application ลดการเรียก subprocess นี้สำหรับรูปที่เคยวิเคราะห์แล้ว

---

## หน้าที่เกี่ยวข้อง

- [[concepts/ai-model-segformer]]
- [[concepts/semantic-segmentation]]
- [[concepts/explainable-ai]]
- [[architecture/backend-api]]
- [[architecture/database-schema]]
- [[requirements/objectives-kpis]]
