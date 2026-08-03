# เริ่มพัฒนา Server อย่างไร

โมเดล SegFormer ฝึกเสร็จและอยู่ใน `../model/segformer/` แล้ว ดังนั้นให้เริ่มจากทำ **Backend API ที่รันได้และทดสอบได้ก่อน** พร้อมกำหนดสัญญาการเชื่อมต่อกับโมเดลให้ชัดเจน จากนั้นจึงเพิ่มฐานข้อมูล ระบบผู้ใช้ และการวิเคราะห์ภาพส่วนอื่นทีละส่วน

โปรเจกต์นี้ใช้ **Python + FastAPI** เป็น API หลัก, **PostgreSQL** เป็นฐานข้อมูล, **Redis** สำหรับ cache/งานเบื้องหลัง และใช้ SegFormer ที่เทรนแล้วสำหรับตรวจหาบริเวณภาพที่ถูกดัดแปลง

> สถานะปัจจุบัน: มี checkpoint `.pth` แล้ว แต่ยังไม่พบไฟล์ `.onnx` ใน `model/` จึงควรเชื่อมด้วย MMsegmentation/PyTorch ในช่วงแรก หรือ export เป็น ONNX ก่อนนำไปใช้ใน ONNX Runtime

## โมเดลที่ให้ใช้

- checkpoint ที่ต้องใช้: `../model/segformer/work_dirs/v1.0.0/best_mIoU_iter_112000.pth`
- ไฟล์ config ที่คู่กับ checkpoint: `../model/segformer/work_dirs/v1.0.0/segformer_mit-b2-v2.py`
- ผลประเมินที่บันทึกไว้: v1.0.0 มีค่า mIoU สูงสุด **72.42%**
- สคริปต์ทดสอบ: `../model/segformer/predict.py`

ก่อนเริ่มเขียน API ให้ทดสอบ checkpoint บนรูปตัวอย่างให้ได้ผลก่อน:

```bash
cd ../model/segformer
python predict.py \
  --config work_dirs/v1.0.0/segformer_mit-b2-v2.py \
  --checkpoint work_dirs/v1.0.0/best_mIoU_iter_112000.pth \
  --image <path-to-image> \
  --output result_boxed.jpg
```

เอกสารประกอบที่ควรอ่าน:

- [howto.md](howto.md) — คู่มือสร้าง Backend แบบละเอียด
- [../wiki/architecture/backend-api.md](../wiki/architecture/backend-api.md) — บทบาทและ API ของ Backend
- [../design/server.md](../design/server.md) — รายละเอียดโครงสร้างและ API ที่ออกแบบไว้
- [../model/segformer/README.md](../model/segformer/README.md) — วิธีทดสอบโมเดล SegFormer

## ลำดับที่แนะนำ

1. สร้าง FastAPI เปล่า ๆ พร้อม `GET /health` เพื่อยืนยันว่า server รันได้
2. แยกโค้ดเป็น `api`, `services`, `repositories`, `models` และ `schemas` ตั้งแต่ต้น เพื่อไม่ให้ business logic ปนกับ endpoint
3. ตั้งค่า `.env` และเชื่อม PostgreSQL ผ่าน SQLAlchemy + Alembic migration
4. ทำ Auth ให้ครบ: สมัครสมาชิก, เข้าสู่ระบบ, JWT และการตรวจสิทธิ์ Admin
5. ทำ `POST /api/v1/scan` โดยรับไฟล์รูป บันทึกข้อมูลการสแกน และเรียก SegFormer checkpoint ที่มีอยู่
6. ห่อการเรียกโมเดลไว้ใน `inference_service.py` เพื่อให้ endpoint ไม่ผูกกับ MMsegmentation โดยตรง
7. เพิ่มการวิเคราะห์ที่ทำใน API ได้รวดเร็ว เช่น SHA-256 hash, EXIF และ OCR แล้วรวมผลกับผลจากโมเดลเป็น risk score
8. เพิ่ม Redis cache, object storage, rate limit, logging และ tests ก่อน deploy

## เริ่มทำ Phase 1

จากโฟลเดอร์ `server/` สร้าง virtual environment และติดตั้ง dependency ขั้นต่ำ:

```bash
python -m venv .venv
source .venv/bin/activate
pip install fastapi "uvicorn[standard]" pydantic-settings
```

สร้างโครงสร้างเริ่มต้น:

```text
server/
├── app/
│   ├── main.py              # สร้าง FastAPI และ health check
│   ├── core/                # config, security, database
│   ├── api/v1/              # endpoint แต่ละกลุ่ม
│   ├── schemas/             # request/response validation
│   ├── services/            # business logic
│   ├── repositories/        # database queries
│   └── models/              # SQLAlchemy models
├── tests/
├── requirements.txt
└── .env.example
```

ตัวอย่าง `app/main.py` ขั้นต่ำ:

```python
from fastapi import FastAPI

app = FastAPI(title="ScamGuard API", version="0.1.0")

@app.get("/health")
async def health_check():
    return {"status": "ok"}
```

รัน development server:

```bash
uvicorn app.main:app --reload --port 8000
```

จากนั้นเปิด `http://127.0.0.1:8000/docs` เพื่อลองเรียก API ผ่าน Swagger UI และเปิด `http://127.0.0.1:8000/health` เพื่อตรวจสอบสถานะ

## เป้าหมายของแต่ละช่วง

| ช่วง | สิ่งที่ควรส่งมอบ |
| --- | --- |
| Foundation | `/health`, config, database connection, โครงสร้างโปรเจกต์ |
| Auth | register/login, JWT, user role |
| Scan + Model | upload image, สร้าง scan record, เรียก SegFormer และคืน mask/ภาพผลลัพธ์ |
| Analysis | image hash, EXIF, OCR/คำเสี่ยง, รวม risk score |
| AI serving | export ONNX (ถ้าต้องการ), เร่งความเร็ว inference, จัดการ GPU/CPU fallback |
| Production | cache, storage, migration, tests, Docker, monitoring |

## หลักสำคัญ

- เก็บ secret, URL ฐานข้อมูล และ key ภายนอกไว้ใน `.env` เท่านั้น และ commit เฉพาะ `.env.example`
- ให้ endpoint ทำหน้าที่รับ/ส่ง HTTP ส่วนตรรกะการทำงานอยู่ใน `services/`
- เริ่มจาก checkpoint ที่มีอยู่ก่อน และห่อการเรียกไว้ใน `inference_service.py`; หากต้องเปลี่ยนเป็น ONNX Runtime ภายหลังจะกระทบเฉพาะ service นี้
- งานวิเคราะห์ภาพอาจใช้เวลานาน จึงควรออกแบบให้ `POST /scan` สร้างงานและ `GET /scan/{id}` ใช้ตรวจสถานะ/ผลลัพธ์
- เขียน test สำหรับ health, authentication และ upload validation ตั้งแต่เริ่ม เพื่อกัน API เสียเมื่อเพิ่มความสามารถใหม่

เมื่อ Phase 1 สำเร็จ จุดถัดไปที่เหมาะสมที่สุดคือทำ database model `users` พร้อม endpoint `POST /api/v1/auth/register` และ `POST /api/v1/auth/login`.
