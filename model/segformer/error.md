# บันทึกการแก้ปัญหา (Troubleshooting Log)
**Project**: SegFormer on RTX 5050 (Blackwell architecture)

เอกสารนี้รวบรวมปัญหาทั้งหมดที่พบระหว่างการเซ็ตอัปสภาพแวดล้อมสำหรับรันโมเดล SegFormer พร้อมวิธีการแก้ไขอย่างละเอียด เพื่อเก็บไว้เป็นคู่มืออ้างอิง

---

## ปัญหาที่ 1: การ์ดจอใหม่เกินไป (RTX 5050)
**Error ที่พบ:** 
`RuntimeError: CUDA error: no kernel image is available for execution on the device`

**สาเหตุ:** 
PyTorch 2.6.0 (Stable) รุ่นปกติ รองรับสถาปัตยกรรมการ์ดจอสูงสุดถึงแค่รหัส `sm_90` ในขณะที่การ์ดจอซีรีส์ 50 อย่าง RTX 5050 เป็นสถาปัตยกรรม Blackwell รหัส `sm_120` ทำให้ PyTorch รุ่นปกติไม่สามารถโยนงานขึ้นไปรันบนการ์ดจอนี้ได้

**วิธีแก้ไข:**
ต้องเปลี่ยนไปใช้ **PyTorch เวอร์ชัน Nightly** (พรีวิว) ที่มาพร้อมกับ **CUDA 12.8** แทน ซึ่งเป็นเวอร์ชันทดลองล่าสุดที่เริ่มมีการบรรจุความสามารถในการทำงานร่วมกับโค้ด `sm_120` มาให้เรียบร้อยแล้ว
*(ตั้งค่าการติดตั้งโดยเพิ่มแฟล็ก `--pre` และชี้ `--extra-index-url` ไปที่ nightly/cu128)*

---

## ปัญหาที่ 2: ติดตั้ง `mmcv` ไม่ผ่าน / โปรแกรมถามหา C++ Extension
**Error ที่พบ:**
- ระหว่างติดตั้ง: แช่แข็งและพยายามคอมไพล์ C++ โค้ดนานมาก หรือล้มเหลวเพราะหา `nvcc` ไม่เจอ
- ระหว่างรัน: `ModuleNotFoundError: No module named 'mmcv._ext'`

**สาเหตุ:**
ไลบรารี `mmcv` ตัวเต็มจำเป็นต้องมี C++/CUDA extensions ซึ่งปกติต้องดาวน์โหลดไฟล์ที่คอมไพล์สำเร็จรูป (Wheels) มาใช้ แต่เนื่องจากเราใช้ PyTorch Nightly จึงยังไม่มีไฟล์สำเร็จรูปให้โหลด การบังคับให้ระบบคอมไพล์โค้ด C++ เองทั้งหมดบนเครื่องจึงพังเพราะขาดการตั้งค่า Environment ที่ถูกต้อง

**วิธีแก้ไข:**
1. เปลี่ยนไปติดตั้งเฉพาะแพ็กเกจ **`mmcv-lite`** แทน (มีเฉพาะฟังก์ชัน Python ล้วน)
2. แก้ไขโค้ดในไฟล์ `library/mmsegmentation/mmseg/__init__.py` เพื่อดักการทำงานเมื่อมีการเรียกใช้ C++ Extension โดยการฝัง Mock Module เอาไว้ ทำให้ระบบสามารถตรวจสอบและข้ามการทำงานส่วนนี้ไปได้อย่างราบรื่นโดยไม่แครช:
   ```python
   # โค้ดที่เพิ่มเข้าไปในส่วนบนสุดของ mmseg/__init__.py
   import types
   import sys
   import importlib.machinery
   
   class DummyExt(types.ModuleType):
       def __getattr__(self, name):
           if name.startswith('__') and name.endswith('__'):
               raise AttributeError(name)
           def dummy_func(*args, **kwargs):
               raise RuntimeError(f"mmcv._ext is missing. Cannot call {name}")
           return dummy_func
   
   mock_ext = DummyExt('mmcv._ext')
   mock_ext.__spec__ = importlib.machinery.ModuleSpec('mmcv._ext', None)
   sys.modules['mmcv._ext'] = mock_ext
   ```

---

## ปัญหาที่ 3: `mmcv-lite` เวอร์ชันใหม่เกินเพดานที่โปรเจกต์กำหนด
**Error ที่พบ:**
`AssertionError: MMCV==2.2.0 is used but incompatible. Please install mmcv>=2.0.0rc4.`

**สาเหตุ:**
ในโค้ดต้นฉบับของโปรเจกต์ MMSegmentation มีการเขียนเช็คโค้ดดักไว้ไม่ให้รันคู่กับ `mmcv` ที่มีเวอร์ชันตั้งแต่ `2.2.0` ขึ้นไป (กำหนดค่า `MMCV_MAX = '2.2.0'`) แต่เนื่องจากเราใช้เครื่องหมาย `>=2.1.0` ระบบจึงโหลดเวอร์ชัน `2.2.0` ล่าสุดมาติดตั้งให้

**วิธีแก้ไข:**
เข้าไปแก้ไฟล์ `library/mmsegmentation/mmseg/__init__.py` เพื่อปลดล็อกให้รองรับเวอร์ชันที่สูงขึ้น:
```python
# แก้ไขบรรทัด MMCV_MAX จาก '2.2.0' เป็น '2.3.0'
MMCV_MAX = '2.3.0' 
```

---

## สรุป Requirements ที่ถูกต้องสำหรับ RTX 5050 (`requirements-v1.txt`)
หากต้องการสร้าง Environment ใหม่ ให้ใช้ตั้งค่าดังต่อไปนี้เพื่อให้การติดตั้งผ่านฉลุยแบบ 100%:
```txt
--pre
--extra-index-url https://download.pytorch.org/whl/nightly/cu128

torch
torchvision
torchaudio

mmengine>=0.10.0
mmcv-lite>=2.1.0

numpy<2
opencv-python<4.9

ftfy
regex

-e ./library/mmsegmentation
```
