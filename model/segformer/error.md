# การแก้ไขปัญหาการติดตั้ง MMCV (Troubleshooting MMCV Installation)

หากคุณใช้งานการ์ดจอรุ่นใหม่ (เช่น สถาปัตยกรรม Blackwell, RTX 50-series) อาจพบปัญหาในการคอมไพล์แพ็กเกจ `mmcv` เนื่องจากไลบรารี CUDA หรือ PyTorch เวอร์ชันปกติยังไม่รองรับเต็มรูปแบบ 

คุณสามารถแก้ไขปัญหานี้ได้โดยวิธีการดังต่อไปนี้:

## วิธีที่ 1: ใช้ mmcv-lite (แนะนำ)
`mmcv-lite` เป็นเวอร์ชันที่ตัดส่วนของ Custom CUDA Ops ออกไป ทำให้สามารถติดตั้งได้ทันทีโดยไม่ต้องพึ่งพากระบวนการคอมไพล์ C++ / CUDA ซึ่งเพียงพอต่อการรันโมเดล SegFormer

```bash
# ถอนการติดตั้ง mmcv ตัวเก่าออกก่อน (หากเคยพยายามติดตั้งแล้ว)
pip uninstall mmcv mmcv-lite -y

# ติดตั้ง mmcv-lite
pip install mmcv-lite==2.1.0
```

## วิธีที่ 2: ใช้ PyTorch Nightly ร่วมกับ mmcv-lite
หากเวอร์ชัน PyTorch ปกติยังไม่รู้จักการ์ดจอของคุณ ให้เปลี่ยนไปใช้เวอร์ชัน Nightly ควบคู่กัน

```bash
# 1. ติดตั้ง PyTorch Nightly
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu121

# 2. จากนั้นติดตั้ง mmcv-lite
pip install mmcv-lite==2.1.0
```

## วิธีที่ 3: คอมไพล์จาก Source (สำหรับผู้ใช้งานขั้นสูง)
หากมีความจำเป็นต้องใช้ CUDA Ops แบบเต็มรูปแบบจาก `mmcv` คุณต้องติดตั้ง CUDA Toolkit เวอร์ชันใหม่ล่าสุดในเครื่องให้เรียบร้อย และทำการคอมไพล์ด้วยตนเอง:

```bash
pip install ninja
git clone -b 2.1.0 https://github.com/open-mmlab/mmcv.git
cd mmcv
MMCV_WITH_OPS=1 pip install -e .
```
