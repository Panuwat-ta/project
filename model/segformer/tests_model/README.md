# SegFormer Test Assets and Reports

โฟลเดอร์นี้เก็บ artefact สำหรับตรวจสอบโมเดล โดยแยกผลเชิงปริมาณที่ใช้จัดอันดับออกจากภาพสาธิตอย่างชัดเจน ไม่เก็บ checkpoint หรือ dataset ขนาดใหญ่เพิ่มในโฟลเดอร์นี้

## นิยามผลประเมิน

- **Validation** — metrics ระหว่างการเทรน ใช้เลือก checkpoint และวิเคราะห์ convergence ภายใน run เท่านั้น ชุดข้อมูล/protocol ต่างกันระหว่างเวอร์ชันจึงห้ามใช้จัดอันดับข้ามรุ่น
- **Common Test** — locked test set เดียวกันสำหรับ `v1.0.0`–`v1.0.5` เป็นแหล่งเดียวที่ใช้เปรียบเทียบและจัดอันดับในรายงาน โดยรับเฉพาะ log ที่จบครบ 2,504 batches
- **Qualitative Demo** — ภาพเลือกมาดู heatmap/prediction ไม่มี sampling protocol และไม่ใช่ benchmark หรือ accuracy
- **Qualitative ONNX Example** — ภาพสาธิต ONNX ที่ไม่มี ground-truth mask จึงไม่รายงาน IoU, Dice หรือ accuracy

จำนวนภาพจริงของ common test ยังไม่ถูกบันทึกไว้ใน log ค่า `sample_count` ใน manifest จึงเป็น `null` ห้ามคำนวณจำนวนภาพจาก batch size

## โครงสร้าง

- `evaluation_manifest.json` — source of truth ของ dataset ID, version, checkpoint, ONNX, training/test log และ run ID
- `img/` — ภาพสำหรับ smoke test และ qualitative demo
- `output/` — inference output เฉพาะเครื่อง; ไม่ควร commit
- `report/plot_training.py` — ตรวจ manifest/log แล้วสร้างรายงานทั้งหมด
- `report/test_plot_training.py` — unit tests ของ parser และ metric regression
- `report/figs/` — common-test plots, diagnostics และ CSV summaries
- `report/reportmodel.md` — รายงานสรุปภาษาไทย
- `v/<version>/` — loss, validation และ Qualitative ONNX Example ของแต่ละเวอร์ชัน
- `test.sh` — entry point สำหรับตรวจ log และสร้าง plot/report ทั้งหมดผ่าน `report/plot_training.py --clean`
- `test_qualitative_onnx.sh` — เรียก `test_qualitative_onnx.py` ครบทุกเวอร์ชันตามลำดับ
- `add-v-mode.sh` — ตรวจและลงทะเบียนโมเดลเวอร์ชันใหม่แบบอัตโนมัติ
- `test_train/test-model.sh` — test-set evaluation ของ `v1.0.5`; ต้องมี dataset และ GPU ตามสคริปต์

## คำสั่งใช้งาน

จาก `/home/panuwat/project/model/segformer`:

```bash
MPLCONFIGDIR=/tmp/matplotlib-scamguard venv/bin/python -m unittest tests_model/report/test_plot_training.py
./tests_model/test.sh
./tests_model/test_qualitative_onnx.sh
```

`test.sh` ส่ง `--clean` ให้ generator เพื่อลบเฉพาะไฟล์ที่ generator เป็นเจ้าของและชื่อไฟล์ legacy ที่ถูกแทนที่ แล้วสร้าง PNG 200 DPI, SVG และ CSV ใหม่ ไม่แก้ checkpoint, test log หรือ deployment config

## Outputs

ผลหลักใน `report/figs/`:

- `common_test_overall_metrics.{png,svg}`
- `common_test_forgery_metrics.{png,svg}`
- `validation_vs_test_miou.{png,svg}`
- `qualitative_demo.{png,svg}`
- `common_test_summary.csv`
- `training_validation_summary.csv`
- `diagnostics/` — validation/loss ข้าม run พร้อมคำเตือนว่าไม่ใช้จัดอันดับ

แต่ละ `v/<version>/` มี:

- `test_qualitative_onnx.py` — entry point สำหรับทดสอบ ONNX เฉพาะเวอร์ชันนั้น
- `<version>_loss.{png,svg}`
- `<version>_metrics.{png,svg}`
- `<version>_qualitative_onnx_example.{png,svg}`

รันทดสอบ ONNX แยกเวอร์ชันได้จาก `model/segformer/` เช่น:

```bash
MPLCONFIGDIR=/tmp/matplotlib-scamguard venv/bin/python tests_model/v/v1.0.5/test_qualitative_onnx.py
```

สคริปต์ของแต่ละรุ่นเรียก plotting/preprocessing core เดียวกัน เพื่อให้ผลต่างเกิดจาก ONNX model ไม่ใช่ implementation ที่ต่างกัน

## ขั้นตอนเพิ่มโมเดลรุ่นใหม่

1. รัน evaluation บน locked common test ชุดเดิมให้สำเร็จครบ 2,504/2,504 batches และเก็บ log
2. เลือก checkpoint จาก validation ภายใน run; อย่าใช้ validation ต่างชุดจัดอันดับข้ามรุ่น
3. รัน `add-v-mode.sh` โดยระบุ checkpoint, ONNX, training log/run ID และ test log/run ID
4. สคริปต์จะตรวจ path, log completeness, checkpoint iteration และ path ซ้ำ ก่อนเพิ่ม manifest และ regression metrics
5. สคริปต์จะสร้าง `v/<version>/test_qualitative_onnx.py`, รัน unit tests และสร้างรายงานทั้งหมด
6. ตรวจผลใน `report/figs/` และ `v/<version>/` แล้วอัปเดต `report/reportmodel.md` จาก `common_test_summary.csv`

ตัวอย่าง:

```bash
./tests_model/add-v-mode.sh \
  --version v1.0.6 \
  --checkpoint work_dirs/v1.0.6/best_mIoU_iter_200000.pth \
  --onnx-model work_dirs/v1.0.6/segformer_v1_0_6_dynamic.onnx \
  --training-log work_dirs/v1.0.6/TRAIN_RUN/vis_data/scalars.json \
  --training-run-id TRAIN_RUN \
  --test-log work_dirs/v1.0.6/test_eval/TEST_RUN/TEST_RUN.log \
  --test-run-id TEST_RUN
```

รายการสีและรายการ ONNX tests อ่านจาก manifest อัตโนมัติ จึงไม่ต้องแก้ `plot_training.py`, `test_plot_training.py` หรือ `test_qualitative_onnx.sh` เมื่อเพิ่มรุ่นตามขั้นตอนนี้

ถ้ามี dataset manifest ที่นับจำนวนภาพจริงได้ ให้แก้ `dataset.sample_count` จากข้อมูลนั้น ห้ามอนุมานจาก batch size

การเปลี่ยน `ONNX_MODEL_PATH` หรือเลื่อน model เป็น Production ต้องทำในงาน deployment แยก หลังผ่าน ONNX parity, end-to-end และ performance verification
