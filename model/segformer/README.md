# คู่มือฉบับละเอียด: การสร้างและใช้งานโมเดล SegFormer ตรวจจับภาพหลอกลวง (Scam Image Detection)

พื้นที่นี้ (`model/segformer/`) คือหัวใจหลักของ **AI Inference Service** ในระบบหลังบ้าน (Backend) ของคุณ โดยทำหน้าที่รับรูปภาพมาวิเคราะห์และส่งแผนที่ความร้อน (Heatmap) ที่ระบุจุดตัดต่อดัดแปลงกลับไปยัง Mobile App

การทำงานจะแบ่งเป็น 4 ระยะ (Phases) ดังนี้:

---

## 0: การติดตั้งสภาพแวดล้อม (Environment Setup)
เพื่อให้แน่ใจว่าเวอร์ชันของไลบรารีต่างๆ ทำงานร่วมกันได้อย่างสมบูรณ์แบบ ให้ทำการติดตั้งสภาพแวดล้อมจำลอง (Virtual Environment) ดังนี้:

1. สร้างและเปิดใช้งาน Virtual Environment:
```bash
python -m venv env
source venv/bin/activate
```

2. ติดตั้งแพ็กเกจ (สำหรับ RTX 5050 - สถาปัตยกรรม Blackwell แนะนำให้ใช้ `requirements-v1.txt` แทน):
```bash
pip install -r requirements.txt
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

3. **รันสคริปต์เตรียมข้อมูล**: เปิด `prepare_dataset.sh` แก้ path ให้ตรงกับ dataset ที่ต้องการ แล้วรัน:
```bash
# แก้ path ใน prepare_dataset.sh ก่อนรัน (ส่วน Path Configuration)
./prepare_dataset.sh
```

สคริปต์จะ:
- Activate virtual environment ให้อัตโนมัติ
- Undersample ภาพ Authentic ให้สมดุลกับ Tampered (1:1)
- แบ่ง Train/Val (80/20) พร้อมบันทึก `split.json` สำหรับ reproduce
- เพิ่ม prefix `au_`/`tp_` ป้องกันชื่อไฟล์ชนกัน
- Resize mask ให้ตรงกับรูปอัตโนมัติ

เมื่อต้องการใช้ dataset ตัวอื่น (เช่น copymove) ให้แก้ path ใน `prepare_dataset.sh`:
```bash
TP_DIR="${BASE_DIR}/defacto-copymove/copymove_img/img"
MASK1_DIR="${BASE_DIR}/defacto-copymove/copymove_annotations/donor_mask"
MASK2_DIR="${BASE_DIR}/defacto-copymove/copymove_annotations/probe_mask"
OUT_DIR="${BASE_DIR}/defacto-copymove"
```

---

## 2: การตั้งค่าคอนฟิก (Configuration)
ไฟล์คอนฟิก (เช่น `configs/segformer_mit-b2-v6.py`) กำหนดพฤติกรรมของ AI:
1. เปลี่ยนคลาสให้รู้จักแค่ 2 ชนิด (background กับ forgery)
2. ชี้ Path ของ Dataloader ไปที่โฟลเดอร์ชุดข้อมูลที่เตรียมไว้
3. ปรับค่า Learning Rate แยกส่วน (Backbone เรียนช้า, Decoder เรียนเร็ว)
4. ใช้ CrossEntropyLoss + DiceLoss รวมกันเพื่อให้ตรวจจับพื้นที่ตัดต่อได้ดีขึ้น

*หมายเหตุ: `work_dir` และ `load_from` ไม่ได้กำหนดในไฟล์ config แต่ถูกส่งผ่าน `train.sh` แทน*

---

## 3: การเทรนโมเดล (Transfer Learning)
ใช้ `train.sh` เพื่อเทรนโมเดล ระบบจะจัดการ auto-versioning, activate venv, และส่ง arguments ให้อัตโนมัติ:

```bash
# fine-tune จาก checkpoint ที่กำหนดไว้ใน LOAD_FROM (แก้ path ใน train.sh)
./train.sh

# override checkpoint ผ่าน CLI
./train.sh --load-from ./work_dirs/v1.0.0/best_mIoU_iter_112000.pth

# train ใหม่ตั้งแต่ต้น (ไม่โหลด checkpoint)
./train.sh --no-load
```
**ผลลัพธ์ที่ได้:** ระบบจะสร้างโฟลเดอร์เวอร์ชันใหม่อัตโนมัติ (เช่น `work_dirs/v1.0.1/`) พร้อมไฟล์ `.pth` และผลการประเมิน

---

## 4: การนำไปใช้จริงบน Backend API (Inference)
นำไฟล์ `.pth` ตัวใหม่มาใช้งานในเซิร์ฟเวอร์ ทดสอบรันโมเดลได้ผ่านไฟล์ `predict.py`:

```bash
# รันด้วยค่าเริ่มต้น
python predict.py

# หรือระบุไฟล์รูปภาพ, คอนฟิก, และโมเดลที่ต้องการ
python predict.py --image "test_scam.jpg" --config "configs/segformer_mit-b2-v6.py" --checkpoint "work_dirs/v1.0.1/best_mIoU_iter_112000.pth" --output "result_heatmap.jpg"
```
*หมายเหตุ: สคริปต์จะตรวจสอบ GPU ให้อัตโนมัติ หากไม่มีจะใช้ CPU แทน (สามารถบังคับใช้ CPU ได้โดยเติม `--device cpu`)*

เมื่อรันสำเร็จ สคริปต์จะสร้างภาพ `result_heatmap.jpg` (หรือชื่อไฟล์ที่ระบุใน `--output`) ส่งกลับมาให้ดูว่า AI จับผิดจุดไหนได้บ้าง
