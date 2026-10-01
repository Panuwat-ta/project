# SegFormer Test Cases

ชุดนี้รัน ONNX จริงจาก `tests_model/evaluation_manifest.json` และแยกการทดสอบออกเป็น 3 ระดับชัดเจน:

1. **Unit / contract tests** — ตรวจสูตร metric, inventory, tiling และสัญญา input/output ของ ONNX โดยไม่ใช้คะแนนจากรูปจริงตัดสินความแม่นยำ
2. **Quantitative image regression** — ใช้ 105 ภาพที่มี ground-truth mask ครบ 7 หมวด แล้วรายงาน mIoU, mDice, per-class IoU/Dice, Accuracy และ False Positive Rate
3. **Qualitative manual review** — ใช้ 30 คู่ original/manipulated ที่ไม่มี mask เพื่อดู heatmap ด้วยตาเท่านั้น ห้ามเรียกผลส่วนนี้ว่า accuracy, IoU หรือ Dice

ชุด 105 รูปนี้เป็น local Test-Case/regression set ไม่แทนที่ common locked test set จำนวน 2,504 batches ที่ใช้จัดอันดับโมเดลอย่างเป็นทางการใน `tests_model/report/` เพื่อป้องกันการเลือกโมเดลจาก test set ขนาดเล็กโดยไม่ตั้งใจ

## ข้อมูลทดสอบ

- Masked cases: `/run/media/panuwat/USB/model/Test-Cases/with_mask`
- Qualitative pairs: `/run/media/panuwat/USB/model/Test-Cases/pairs`
- โมเดลและ checkpoint metadata: `../tests_model/evaluation_manifest.json`

ตัว evaluator แบบมี mask ใช้ inference แบบเดียวกับ production: tile 512×512, overlap 64, ImageNet normalization, softmax class 1 และประกอบ probability map กลับเป็นขนาดภาพจริง

ภาพ qualitative ขนาดใหญ่มากจะถูกลดด้านยาวเหลือไม่เกิน 1,024 px เพื่อให้สร้างรายงานได้ในเวลาที่เหมาะสม ข้อนี้มีผลเฉพาะภาพสาธิตและถูกบันทึกใน caption/summary ไม่ได้ใช้คำนวณ quantitative metrics

## วิธีรัน

รันทั้งหมดทุกเวอร์ชัน:

```bash
cd /home/panuwat/project/model/segformer
./Test-Case/run_test_cases.sh
```

รันเฉพาะบางเวอร์ชัน:

```bash
./Test-Case/run_test_cases.sh v1.0.8
./Test-Case/run_test_cases.sh v1.0.6 v1.0.7 v1.0.8
```

รันเฉพาะ quantitative หรือ qualitative:

```bash
/home/panuwat/project/server/venv/bin/python Test-Case/evaluate_with_masks.py
/home/panuwat/project/server/venv/bin/python Test-Case/render_qualitative_pairs.py
```

ค่า release gate เริ่มต้นใช้เฉพาะ v1.0.5: local Test-Case mDice ต้องไม่น้อยกว่า 85% หากรันเวอร์ชันเก่าโดยไม่รวม v1.0.5 runner จะเก็บผลเพื่อ regression comparison โดยไม่บังคับ gate

## ผลลัพธ์

ผลทั้งหมดอยู่ใน `Test-Case/output/`:

```text
output/
├── quantitative/
│   ├── per_image.csv
│   ├── per_category.csv
│   ├── overall.csv
│   └── summary.json
└── qualitative/
    ├── qualitative_pair_scores.csv
    ├── summary.json
    ├── v1.0.6/pair001.png ... pair030.png
    ├── v1.0.7/pair001.png ... pair030.png
    └── v1.0.8/pair001.png ... pair030.png
```

ไฟล์สรุปปัจจุบันมีผลที่เก็บไว้ของ `v1.0.6`–`v1.0.8` (105 ภาพและ 30 คู่ต่อรุ่น) การรันแบบเลือกรุ่นจะเขียนทับ CSV/summary รวม จึงควรสำรองผลก่อนรันหรือส่งทั้งสามรุ่นเพื่อสร้างผลรวมใหม่

รายละเอียดขั้นตอนตรวจด้วยคนและ Expected Results อยู่ใน `manual_test_cases.md`

## เมื่อเพิ่มโมเดลเวอร์ชันใหม่

ใช้ `../tests_model/add.sh` เพิ่มโมเดลเข้า manifest ก่อน จากนั้น `run_test_cases.sh` จะค้นพบเวอร์ชันใหม่อัตโนมัติ ไม่ต้องแก้ Python ในโฟลเดอร์นี้ หากต้องการเปลี่ยน release gate ให้ส่ง `--release-version` ตอนเรียก `evaluate_with_masks.py` และทบทวนเกณฑ์ในเอกสารนี้ก่อน
