# v13 readiness — อัปเดตหลังเทียบทุกเวอร์ชัน

รายงานล่าสุดอยู่ใน segformer-all-configs-comparison-2026-09-23.md ซึ่งแทนที่รายละเอียด readiness รอบก่อน

- Config v13 สำหรับ candidate v1.0.8 แก้แล้วในโปรเจกต์
- Train/validation/test = 9/9/7 แหล่ง แต่ validation mIoU/mDice ใช้เฉพาะ core 7 แหล่ง อีก 2 แหล่งรายงานแยก
- Seed 42; checkpoint เก็บ best mIoU และ best core_macro_forgery_dice
- ต้องมี forgery_metrics.py ที่ root ของ SegFormer เพิ่มจาก dependencies เดิม
- CPU tests ผ่าน 10/10 จากไฟล์ติดตั้งจริง
- ยังไม่มี dataset ที่ /run/media/panuwat/USB/dataset จึงยังไม่ได้เทรนหรือยืนยันคะแนนดีขึ้น

```bash
cd /home/panuwat/project/model/segformer
./train.sh --config configs/segformer_mit-b2-v13.py --no-load
```
