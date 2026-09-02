# รายการและรายละเอียดโมเดล AI ในระบบ ScamGuard (AI Models Directory)

เอกสารฉบับนี้รวบรวมรายละเอียด บทบาทหน้าที่ สถาปัตยกรรม และการทำงานของโมเดลปัญญาประดิษฐ์ (AI Models) ทั้งหมดที่ติดตั้งและใช้งานภายในระบบ Scam Image Detection เพื่อใช้เป็นเอกสารอ้างอิงกลางของโปรเจกต์

---

## 1. ภาพรวมโมเดลทั้งหมดในระบบ (Models Summary)

| ลำดับ | ชื่อโมเดล | บทบาทหน้าที่ | สถาปัตยกรรม / เทคโนโลยี | รูปแบบไฟล์ (Format) | โฟลเดอร์จัดเก็บ | การจัดสรรทรัพยากร |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **SegFormer (mit-b2)** | ตรวจจับรอยตัดต่อภาพระดับพิกเซล และสร้าง Heatmap | Transformer-based Semantic Segmentation | `.onnx` (ONNX Runtime) | `model/segformer/` | GPU (CUDA Execution Provider) |
| **2** | **Surya OCR (v0.5.0)** | สกัดข้อความภาษาไทยและภาษาอังกฤษออกจากภาพ | Vision Transformer OCR (Detection + Recognition) | PyTorch Weights (Hugging Face) | `model/surya/` | CPU / GPU (PyTorch Native) |
| **3** | **Qwen2.5-1.5B-Instruct** | สร้างข้อความคำอธิบายผลทางนิติวิทยาศาสตร์ (XAI) เป็นภาษาไทย | Small Language Model (SLM) Decoder-only | `.gguf` (Quantization: Q4_K_M) | `model/Qwen2.5-1.5B/` | CPU / GPU (llama-cpp-python) |

---

## 2. รายละเอียดของแต่ละโมเดล (Model Specifications)

### 2.1 SegFormer (โมเดลตรวจจับการตัดต่อและสร้าง Heatmap)

* **โฟลเดอร์:** `model/segformer/`
* **สถาปัตยกรรม:** SegFormer โดยใช้โครงสร้าง Encoder แบบ Hierarchical Transformer (Mix Transformer: MiT-B2) ร่วมกับ Lightweight All-MLP Decoder
* **หน้าที่หลัก:**
  1. วิเคราะห์ร่องรอยการดัดแปลงภาพระดับพิกเซล (Digital Manipulation) เช่น Splicing, Copy-Move, การลบ หรือแก้ไขตัวเลข/ข้อความ
  2. สร้างแผนที่ความน่าจะเป็น (Probability Map) เพื่อแปลงเป็น **แผนที่ความร้อน (Heatmap)** แสดงบริเวณที่มีความเสี่ยงสูง (สีแดง) ไปจนถึงบริเวณปลอดภัย (สีน้ำเงิน) ตามแนวทาง Explainable AI (XAI)
  3. คำนวณค่า **Visual Risk Score (0–100)** และ **AI-Generated Probability**
* **เทคนิคการประมวลผล (Tiling Inference):**
  * เพื่อป้องกันการสูญเสียรายละเอียดพิกเซลขนาดเล็ก ระบบไม่ใช้การย่อขนาดภาพ (Resize) ทั้งใบ
  * ใช้งานเทคนิค **Overlapping Tiling Inference** ตัดภาพเป็นบล็อกขนาด `512x512` พิกเซล โดยมีส่วนเหลื่อม (Overlap) `64` พิกเซล ป้อนเข้าโมเดล แล้วนำ Probability Map ของแต่ละบล็อกมาถัวเฉลี่ยน้ำหนักคืนสู่ขนาดภาพจริง
* **สภาพแวดล้อมการทำงาน:**
  * ฝั่ง Serving รันผ่าน **ONNX Runtime** บน Subprocess แยกอิสระ (`onnx_worker.py`) เพื่อป้องกันปัญหา CUDA Driver Conflict กับไลบรารีอื่น

---

### 2.2 Surya OCR (โมเดลตรวจจับและอ่านข้อความหลายภาษา)

* **โฟลเดอร์:** `model/surya/`
* **สถาปัตยกรรม:** โมเดล OCR ยุคใหม่ที่พัฒนาบนโครงสร้าง Vision Transformer เฉพาะทาง
* **หน้าที่หลัก:**
  1. **Text Detection:** ค้นหาและตีกรอบพิกัดของข้อความ (Bounding Boxes / Text Lines) ภายในรูปภาพ
  2. **Text Recognition:** ถอดรหัสตัวอักษรภาษาไทยและภาษาอังกฤษจากภาพ แม้ในภาพที่มีสัญญาณรบกวน (Noise), มีลวดลายพื้นหลังซับซ้อน หรือตัวอักษรเอียง
  3. ส่งมอบข้อความ (`ocr_text`) ให้ระบบทำการตรวจสอบคำสำคัญที่มีความเสี่ยงต่อการหลอกลวง (Scam Keywords Matching) เช่น "ด่วน", "โบนัส", "กู้เงิน", "อนุมัติไว", "ได้เงินจริง" เพื่อนำไปคำนวณ **Text Risk Score (0–100)**
* **จุดเด่น:**
  * มีความแม่นยำในภาษาไทยสูงกว่าระบบ OCR แบบดั้งเดิม (เช่น Tesseract)
  * จัดการโครงสร้างเอกสารและตำแหน่งข้อความในภาพได้อย่างถูกต้อง

---

### 2.3 Qwen2.5-1.5B-Instruct (โมเดลสร้างข้อความอธิบายผลลัพธ์ XAI)

* **โฟลเดอร์:** `model/Qwen2.5-1.5B/`
* **ไฟล์โมเดล:** `qwen2.5-1.5b-instruct-q4_k_m.gguf` (~986 MB)
* **สถาปัตยกรรม:** Small Language Model (SLM) พัฒนาโดย Qwen / Alibaba Cloud
* **หน้าที่หลัก:**
  1. ทำหน้าที่เป็น **Text Generator (NLG)** สำหรับการอธิบายผลการตรวจจับทางนิติวิทยาศาสตร์ดิจิทัล (Explainable AI - XAI)
  2. รับข้อมูลสรุปผลจากการวิเคราะห์เชิงตัวเลข (ตำแหน่งความผิดปกติจาก Heatmap, Visual Score, OCR Keywords, AI-Gen Prob) แล้วเรียบเรียงเป็นภาษาไทยที่สุภาพ เข้าใจง่าย กระชับ 2–3 บรรทัด สำหรับแสดงผลบน Mobile App
  3. อธิบายเจาะจงว่าความผิดปกติอยู่ส่วนใดของภาพ (เช่น มุมขวาบน, กึ่งกลางภาพ) และมีลักษณะอย่างไร (เช่น รอยต่อไม่เป็นธรรมชาติ, คุณภาพพิกเซลบีบอัดซ้อนทับกันหลายชั้น)
* **รูปแบบการประมวลผล (Inference Engine):**
  * รันผ่าน **GGUF (llama-cpp-python)**
  * **ประหยัดทรัพยากร:** ใช้ RAM/VRAM เพียงประมาณ 1.0–1.5 GB
  * **On-Premise 100%:** ข้อมูลรูปภาพและผลการสแกนไม่ถูกส่งออกไปยังคลาวด์ภายนอก สอดคล้องกับข้อกำหนด PDPA
  * **ตอบสนองรวดเร็ว:** สามารถสร้างข้อความสั้น 60–100 โทเค็นได้ภายในเวลา 1–2 วินาที แม้รันบน CPU

---

## 3. แผนผังการทำงานร่วมกันของโมเดล (Multi-Layer AI Pipeline)

```text
[รูปภาพที่ผู้ใช้ส่งสแกน (Input Image)]
              │
              ├───► [1. SegFormer (ONNX)]
              │         │
              │         ├──► สร้าง Heatmap Overlay (พิกัดจุดแดงความเสี่ยงสูง)
              │         └──► คำนวณ Visual Risk Score + AI-Gen Prob
              │
              ├───► [2. Surya OCR (PyTorch)]
              │         │
              │         ├──► สกัดข้อความภาษาไทย/อังกฤษ (OCR Text)
              │         └──► ตรวจจับคำเสี่ยงหลอกลวง (Scam Keywords) -> Text Score
              │
              ▼
[XAI Feature Aggregator & Quadrant Analyzer]
  (รวมพิกัดตำแหน่งที่ผิดปกติจาก Heatmap + คะแนนความเสี่ยง + คำเสี่ยง)
              │
              ▼
    [3. Qwen2.5-1.5B-Instruct (GGUF)]
              │
              ▼
[ข้อความคำอธิบายภาษาไทย XAI (Dynamic Explanation Text)]
  "AI ตรวจพบความผิดปกติบริเวณมุมขวาบนของภาพ ซึ่งมีลักษณะของการตัดต่อที่ไม่เป็นธรรมชาติ..."
              │
              ▼
[ส่งผลลัพธ์กลับไปยัง Mobile App (Flutter) และ Database (PostgreSQL)]
```

---

## 4. แนวทางการบริหารจัดการหน่วยความจำ (Hardware & Resource Sizing)

* **SegFormer:** ทำงานบน GPU โดยใช้ ONNX Runtime ผ่าน CUDA Execution Provider (ใช้ VRAM ประมาณ 1.5–2.0 GB ในช่วง Tiling Inference)
* **Surya OCR:** ทำงานบน Native PyTorch โดยปิด cuDNN เพื่อป้องกัน Driver Conflict กับ CUDA 12
* **Qwen2.5-1.5B (GGUF):** กำหนดให้รันบน CPU (`n_gpu_layers=0`) เพื่อหลีกเลี่ยงการแย่งชิง VRAM กับ SegFormer และ Surya OCR ทำให้เซิร์ฟเวอร์ที่มี GPU ขนาดเล็ก (เช่น 4 GB – 6 GB) สามารถรันทุกโมเดลพร้อมกันได้อย่างมีเสถียรภาพ

---

## 5. วิธีดาวน์โหลดโมเดลเข้าสู่ระบบ (Download Instructions)

### 5.1 วิธีดาวน์โหลด Surya OCR (Text Detection & Recognition)

โมเดลของ Surya OCR ประกอบด้วย 2 โมเดลย่อย ได้แก่ `vikp/surya_det3` (Detection) และ `vikp/surya_rec2` (Recognition) จัดเก็บแคชไว้ที่โฟลเดอร์ `model/surya/` ผ่านการกำหนดตัวแปรสภาพแวดล้อม `HF_HOME=/home/panuwat/project/model/surya`

#### วิธีที่ 1: ดาวน์โหลดผ่าน Python Script (แนะนำ - โหลดอัตโนมัติพร้อมแคชลงโฟลเดอร์)

```bash
cd /home/panuwat/project/server
HF_HOME=/home/panuwat/project/model/surya venv/bin/python3 -c "
from surya.model.detection.model import load_model as load_det_model, load_processor as load_det_processor
from surya.model.recognition.model import load_model as load_rec_model
from surya.model.recognition.processor import load_processor as load_rec_processor

print('Downloading Surya OCR detection model...')
load_det_processor()
load_det_model()

print('Downloading Surya OCR recognition model...')
load_rec_processor()
load_rec_model()

print('Surya OCR models downloaded successfully to model/surya/!')
"
```

#### วิธีที่ 2: ดาวน์โหลดผ่าน Hugging Face CLI

```bash
# กำหนด HF_HOME ไปยังโฟลเดอร์ model/surya ก่อนสั่งดาวน์โหลด
export HF_HOME=/home/panuwat/project/model/surya

# ดาวน์โหลดโมเดลตรวจจับกรอบข้อความ (Detection)
huggingface-cli download vikp/surya_det3

# ดาวน์โหลดโมเดลอ่านตัวอักษร (Recognition)
huggingface-cli download vikp/surya_rec2
```

---

### 5.2 วิธีดาวน์โหลด Qwen2.5-1.5B-Instruct (GGUF สำหรับ XAI)

โมเดล Qwen2.5-1.5B เวอร์ชัน GGUF ใช้ไฟล์ `qwen2.5-1.5b-instruct-q4_k_m.gguf` (ขนาดประมาณ 1.1 GB) จัดเก็บไว้ที่โฟลเดอร์ `model/Qwen2.5-1.5B/`

#### วิธีที่ 1: ดาวน์โหลดผ่าน Python `huggingface_hub` (แนะนำ - เสถียรและเร็ว)

```bash
cd /home/panuwat/project/server
venv/bin/python3 -c "
from huggingface_hub import hf_hub_download

file_path = hf_hub_download(
    repo_id='Qwen/Qwen2.5-1.5B-Instruct-GGUF',
    filename='qwen2.5-1.5b-instruct-q4_k_m.gguf',
    local_dir='/home/panuwat/project/model/Qwen2.5-1.5B'
)
print(f'Successfully downloaded to: {file_path}')
"
```

#### วิธีที่ 2: ดาวน์โหลดผ่าน Hugging Face CLI

```bash
mkdir -p /home/panuwat/project/model/Qwen2.5-1.5B
cd /home/panuwat/project/model/Qwen2.5-1.5B

huggingface-cli download Qwen/Qwen2.5-1.5B-Instruct-GGUF \
  qwen2.5-1.5b-instruct-q4_k_m.gguf \
  --local-dir .
```

#### วิธีที่ 3: ดาวน์โหลดตรงผ่าน `wget` หรือ `curl`

```bash
mkdir -p /home/panuwat/project/model/Qwen2.5-1.5B
cd /home/panuwat/project/model/Qwen2.5-1.5B

wget -c "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf"
```

