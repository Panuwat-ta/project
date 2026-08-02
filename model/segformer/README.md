# คู่มือฉบับละเอียด: การสร้างและใช้งานโมเดล SegFormer ตรวจจับภาพหลอกลวง (Scam Image Detection)

พื้นที่นี้ (`model/segformer/`) คือหัวใจหลักของ **AI Inference Service** ในระบบหลังบ้าน (Backend) ของคุณ โดยทำหน้าที่รับรูปภาพมาวิเคราะห์และส่งแผนที่ความร้อน (Heatmap) ที่ระบุจุดตัดต่อดัดแปลงกลับไปยัง Mobile App

การทำงานจะแบ่งเป็น 4 ระยะ (Phases) ดังนี้:

---

## 0: การติดตั้งสภาพแวดล้อม (Environment Setup)
เพื่อให้แน่ใจว่าเวอร์ชันของไลบรารีต่างๆ ทำงานร่วมกันได้อย่างสมบูรณ์แบบ ให้ทำการติดตั้งสภาพแวดล้อมจำลอง (Virtual Environment) ดังนี้:

1. สร้างและเปิดใช้งาน Virtual Environment:
```bash
python -m venv env
source env/bin/activate
```

2. ติดตั้งแพ็กเกจ (สำหรับ RTX 5050 - สถาปัตยกรรม Blackwell แนะนำให้ใช้ `requirements-v1.txt` แทน):
```bash
# สำหรับการ์ดจอทั่วไป
pip install -r requirements.txt
mim install "mmcv==2.1.0"

# สำหรับ RTX 5050 (ใช้ PyTorch Nightly และ mmcv-lite แก้ปัญหาติดตั้งไม่ผ่าน)
pip install -r requirements-v1.txt
```
*หมายเหตุ: หากพบปัญหาในการติดตั้ง mmcv บนการ์ดจอรุ่นใหม่ๆ สามารถอ่านรายละเอียดการแก้ไขได้ในไฟล์ `error.md`*

---

## 1: การเตรียมข้อมูลสอน AI (Dataset Preparation)
AI จะไม่รู้ว่า "รอยตัดต่อ" คืออะไรจนกว่าเราจะสอนมัน คุณต้องสร้างชุดข้อมูล (Dataset) ตัวอย่าง โดยต้องมีภาพ 2 ประเภทคู่กันเสมอ:
1. **ภาพต้นฉบับ (Images):** ภาพถ่ายปกติทั่วไปและภาพที่มีการตัดต่อหลอกลวง
2. **ภาพหน้ากาก (Masks/Annotations):** ภาพขาวดำล้วนๆ ที่มีขนาดเท่ากับภาพต้นฉบับเป๊ะๆ 
   - **พิกเซลสีดำ (ค่า 0):** คือบริเวณที่ปกติ
   - **พิกเซลสีขาว (ค่า 1):** คือบริเวณที่มีการดัดแปลงหรือตัดต่อ

Google Drive: [dataset](https://drive.google.com/file/d/1jxQS3HwH0DHHHaCtf_prKPj6fMUpZ5jp/view?usp=sharing)

3. **รันสคริปต์เตรียมข้อมูล**: เพื่อจัดแบ่งชุดข้อมูลเข้าสู่โฟลเดอร์สำหรับเทรนโดยอัตโนมัติ ให้รันคำสั่ง:
```bash
python prepare_dataset.py
```

---

## 2: การตั้งค่าคอนฟิก (Configuration)
เราจะใช้ไฟล์คอนฟิกเป็นตัวคุมพฤติกรรมของ AI (เช่น `configs/segformer_mit-b2-v2.py`) 
มันถูกเขียนทับ (Override) ค่าพื้นฐานเพื่อ:
1. เปลี่ยนคลาสให้รู้จักแค่ 2 ชนิด (ปกติ กับ ตัดต่อ) 
2. ชี้ Path ของ Dataloader ไปที่โฟลเดอร์ชุดข้อมูลที่เราเตรียมไว้ (เช่น `data/dataset_CASIA2.0/`)
3. ในบางเวอร์ชันมีการปรับค่า Learning Rate แยกส่วน (Parameter-wise Fine-tuning) เพื่อให้ปรับตัวเข้ากับโดเมนใหม่ได้ดีขึ้น
4. **Automated Version Increment**: ในเวอร์ชัน v2 มีสคริปต์ตรวจจับโฟลเดอร์เวอร์ชันใน `work_dirs/` และบวกเลขเวอร์ชันใหม่โดยอัตโนมัติ ทำให้การรันแต่ละรอบไม่เกิดการเขียนทับผลลัพธ์เก่า

---

## 3: การเทรนโมเดล (Transfer Learning)
เราจะเอา "สมองเดิม" ของ AI มาสอน "ความรู้ใหม่"
เปิด Terminal ตรวจสอบว่าอยู่ในโฟลเดอร์ `model/segformer/` แล้วรันคำสั่ง:

```bash
# เทรนด้วยคอนฟิก v2 (รองรับการบวกเวอร์ชันอัตโนมัติ)
python library/mmsegmentation/tools/train.py configs/segformer_mit-b2-v2.py

# การหยุดและกลับมาทำต่อ
python library/mmsegmentation/tools/train.py configs/segformer_mit-b2-v2.py --resume
```
**ผลลัพธ์ที่ได้:** เมื่อกระบวนการเสร็จสิ้น ระบบจะสร้างไฟล์ `.pth` ภายในโฟลเดอร์เวอร์ชันใหม่ (เช่น `work_dirs/v1.0.0/`) พร้อมผลการประเมิน

---

## 4: การนำไปใช้จริงบน Backend API (Inference)
ตอนนี้คุณได้ AI ที่ฉลาดและพร้อมทำงานแล้ว ให้นำไฟล์ `.pth` ตัวใหม่ มาใช้งานในเซิร์ฟเวอร์

สามารถทดสอบรันโมเดลได้ผ่านไฟล์ `predict.py` ซึ่งรองรับการส่งพารามิเตอร์ผ่าน Command Line เพื่อให้ใช้งานได้ยืดหยุ่น:
```bash
# รันด้วยค่าเริ่มต้น (รูป test_scam.jpg, โมเดล v2.0.0)
python predict.py

# หรือระบุไฟล์รูปภาพ, คอนฟิก, และโมเดลที่ต้องการ
python predict.py --image "test_scam.jpg" --config "configs/segformer_mit-b2-v1.py" --checkpoint "work_dirs/segformer_v1.0.0/best_mIoU_iter_128000.pth" --output "result_heatmap.jpg"
```
*หมายเหตุ: สคริปต์จะตรวจสอบ GPU ให้อัตโนมัติ หากไม่มีจะใช้ CPU แทน (สามารถบังคับใช้ CPU ได้โดยเติม `--device cpu`)*

เมื่อรันสำเร็จ สคริปต์จะสร้างภาพ `result_heatmap.jpg` (หรือชื่อไฟล์ที่ระบุใน `--output`) ส่งกลับมาให้ดูว่า AI จับผิดจุดไหนได้บ้าง
