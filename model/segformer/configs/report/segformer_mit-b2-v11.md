# SegFormer v11 — การทดลองปรับปรุงจาก v10

สถานะ: config ผ่าน CPU compatibility checks; ยังไม่มีผลเทรน v11 ยืนยันว่าคะแนนดีขึ้น

## วิธีรัน

```bash
cd /home/panuwat/project/model/segformer
./train.sh --config configs/segformer_mit-b2-v11.py --no-load
```

`train.sh` สร้าง work directory รุ่นถัดไปอัตโนมัติ ส่วน `./train.sh` โดยไม่ระบุ
`--config` ยังเลือก v10 อยู่ ให้ตรวจ config ที่ส่งเข้า training จาก log ด้วย
(ข้อความ banner ของ train.sh ปัจจุบันพิมพ์ก่อน parse `--config` จึงอาจยังแสดง v10)

เริ่ม backbone จาก MiT-B2 ImageNet pretrained และสร้าง head ใหม่ (`load_from=None`,
`resume=False`) ตั้ง seed 42 แต่ไม่ได้เปิด deterministic CUDA algorithms
คง batch 8, gradient accumulation 2 และ 200,000 data iterations เท่า v10
บน GPU เดียว effective batch คือ 16 และมีประมาณ 100,000 optimizer updates

Validation ทุก 5,000 iterations และเปลี่ยนเป็นทุก 2,500 ตั้งแต่ milestone 150,000
ด้วย `dynamic_intervals=[(150000, 2500)]` รวมประมาณ 50 ครั้งตลอดการเทรน
การบันทึก checkpoint ตามรอบยังเป็นทุก 2,500 iterations; best mIoU อัปเดตเมื่อมีผล validation

## สิ่งที่ปรับและเหตุผลของการทดลอง

| ส่วน | v10 | v11 | จุดประสงค์ |
|---|---|---|---|
| Sampling | CASIA ×5; หมวดอื่น ×1 | CASIA ×5, copymove ×4, inpainting ×3, IMD2020 ×2 | เพิ่มโอกาสเรียนรู้แหล่งข้อมูลที่มีภาพ train น้อยกว่า |
| Resize | ratio 0.5–2.0 | ratio 1.0–2.0, square resize | ลดการย่อภาพเหลือ 256px และคงขนาดพอสำหรับ crop 512px |
| Crop ภาพตัดต่อ | ไม่ตรวจสัดส่วนคลาส | `cat_max_ratio=0.99` | พยายามเลือก crop ที่มีทั้งสองคลาส |
| Crop authentic | crop ปกติ | crop ปกติเช่นเดิม | เก็บตัวอย่าง background สำหรับควบคุม false positives |
| Augmentation | JPEG 40–95, blur/noise/color ค่อนข้างแรงและปรับสีซ้ำ | JPEG 60–95, ลด blur/noise/color, ตัด PhotoMetricDistortion ซ้ำ | ทดลองรักษาร่องรอยขนาดเล็กมากขึ้น |
| Backbone/head LR | 2e-6 / 2e-4 | 1e-5 / 1e-4 | ให้ backbone ปรับเข้ากับโดเมนเร็วขึ้น และลดความแรงของ head |
| Weight decay | กฎกว้างทับ normalization | normalization/bias ได้ decay 0 | ใช้กฎ optimizer ที่ตรวจสอบได้กับพารามิเตอร์จริง |
| Gradient | ไม่ clip | max norm 1.0 | จำกัดขนาด gradient ก่อน update |
| Warmup | เริ่ม 0.0001% ของ LR | เริ่ม 1% ของ LR | ลดช่วงเริ่มต้นที่ LR ใกล้ศูนย์; warmup ยังคง 3,000 iterations |
| Dice | sigmoid โดย default | softmax สองคลาส | สอดคล้องกับ background/forgery ที่เป็นคลาส mutually exclusive |
| CrossEntropy | เฉลี่ยรวมตำแหน่ง ignore | `avg_non_ignore=True` | เฉลี่ยตามพิกเซลที่ใช้สอนจริง |

ค่า LR ในตารางเป็นค่าก่อน warmup/decay ไม่ใช่ LR ทุก iteration
RepeatDataset เพิ่มความถี่การสุ่ม ไม่เพิ่มจำนวนรูปที่ไม่ซ้ำ
น้ำหนัก loss คงเดิม: CE 1.0, Dice 1.5, class weight [1.0, 2.5]

RandomCrop ลองใหม่ได้จำกัด 10 ครั้ง จึงไม่ได้รับประกันว่าจะมี Forgery ในทุก crop
โดยเฉพาะรอยปลอมเล็กมากหรือ mask เต็มภาพ ตาม [implementation ของ MMSegmentation](https://github.com/open-mmlab/mmsegmentation/blob/main/mmseg/datasets/transforms/transforms.py)
กฎ optimizer ใช้ explicit head BN keys เพราะ `custom_keys` มีลำดับก่อน norm rules
และเลือก substring ที่ยาวที่สุด ตาม [MMEngine](https://mmengine.readthedocs.io/en/latest/api/generated/mmengine.optim.DefaultOptimWrapperConstructor.html)

## วิธีตัดสินผล

1. เลือก checkpoint ด้วย validation เดิมที่ย่อทั้งภาพเป็น 512×512; เก็บ best mIoU ตามเดิม
2. ตรวจ Forgery IoU/Dice รายแหล่งข้อมูล และ FPR ของ authentic เพิ่มเติมบน validation
3. วัด tiled ONNX บน validation ชุดเดียวกันด้วย เพราะ whole-image และ production tiles เป็นคนละ protocol
4. เมื่อเลือกค่าจบแล้วค่อยประเมิน locked common test; เก็บ 105 local Test-Case เป็น regression set ห้ามนำเข้า train

v11 เปลี่ยนหลายปัจจัยพร้อมกัน ผลเปรียบเทียบจึงบอกได้ว่าชุดการตั้งค่ารวมดีขึ้นหรือไม่
หากต้องการพิสูจน์เฉพาะผลของ initialization ต้องเทียบ v10 สอง run ที่เปลี่ยนแค่น้ำหนักเริ่มต้น
ความทนต่อ JPEG/blur หนักและ recall ของรอยเล็กเป็น tradeoff ที่ต้องตรวจใน validation

## ตรวจความเข้ากันได้ก่อนเทรน

```bash
cd /home/panuwat/project/model/segformer
NO_ALBUMENTATIONS_UPDATE=1 venv/bin/python tests_model/report/test_training_config_v11.py -v
```

ตรวจ config merge/serialization, split เดิม, sampling/crop, optimizer groups จริง,
pipeline กับภาพ train จริงหมวดละหนึ่งภาพ และ CPU forward/backward ด้วย synthetic fixture
ไม่ได้ดาวน์โหลด pretrained weights หรือทดสอบ CUDA/AMP และ VRAM ขณะเทรนเต็ม batch
