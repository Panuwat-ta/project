# Spec: SegFormer Det Head (Track B, ขั้น 1)

อ้างอิง `model/plan.md` หัวข้อ 32-36. เป้าหมายขั้นนี้: ต่อหัว image-level classifier
ให้ SegFormer โดยไม่แตะ `library/` (vendored mmseg 1.2.2) และไม่แตะ config หลัก
(เคยพังจาก static import ใน config เมื่อ 2026-09-18)

## 1. Architecture

- `DetHead`: GAP แยกตาม stage บน backbone feature 4 stages (mit_b2: 64+128+320+512=1024ch)
  concat แล้ว `Linear(1024 -> 1)` ได้ det logit ระดับภาพ (sigmoid ตอน inference)
- ไฟล์ใหม่ `model/segformer/Det-Head/det_head.py` เก็บ `DetHead` + helper โหลด checkpoint
- backbone + seg head แช่แข็ง (`requires_grad=False`) เทรนแค่ det head (~1K params)

## 2. Training (`model/segformer/Det-Head/train_det.py`, standalone ไม่ผ่าน mmseg Runner)

- เหตุผล standalone: feedback มีแค่ image tag ไม่มี mask ใช้ mmseg data pipeline ไม่ได้
- input: โฟลเดอร์ภาพ + CSV `path,label` (label: 1=ตัดต่อ, 0=จริง)
- bootstrap: label ตั้งต้น derive จาก mask (มี forged pixel > 0 → 1) จาก clean tree/with_mask;
  พอมี feedback ผ่าน admin verify แล้วค่อยผสม (ดู Phase 2)
- loss: BCEWithLogitsLoss; ออปชัน distillation: `α*BCE(student, teacher_score) + β*BCE(student, hard_label)`
  โดย teacher score มาจาก TruFor official (`model/TruFor/report/**/*.npz`)
- optimizer: AdamW, LR ต่ำ (1e-4), epoch น้อย + early stopping บน val split
- output: `Det-Head/det_<name>/det_head.pth` + `train_log.json` (config hash, data hash, metrics)

## 3. Export ONNX (`model/segformer/export_onnx_dynamic.py`)

- ขยาย `ONNXWrapper` ให้คืน tuple `(seg_logits, det_logit)`,
  `output_names=["logits", "det_logit"]`, dynamic axes ทั้งสอง output
- det head โหลดจาก `Det-Head/det_<name>/det_head.pth`; ถ้าไม่ระบุให้ export แบบเดิม (1 output)

## 4. Server (`server/app/services/onnx_worker.py`)

- อ่าน `outputs[1]` ถ้ามี (backward compatible: ถ้ามีแค่ output เดียวให้ det=None)
- `det_score = sigmoid(det_logit)` เก็บใน response คู่กับ `visual_risk_score` เดิม
- ยังไม่เปลี่ยนสูตร `total_risk_score` ในขั้นนี้ (รอเช็ค contract กับ mobile)

## 5. Eval

- เพิ่ม metric ระดับภาพ (accuracy/precision/recall @0.5) ต่อ version ในสคริปต์ Test-Case
- gate ขั้นนี้: seg metrics ต้องเท่าเดิม (backbone/seg แช่), det accuracy บน with_mask 105 ภาพรายงานเป็น baseline

## 6. Versioning

- seg checkpoint ไม่เปลี่ยน; det weights version แยก (`v1.0.6+det1`...) ผูก data hash ใน `train_log.json`

## 7. Cached feature training (recommended for frozen v1.0.6)

เมื่อ backbone ถูก freeze feature ของรูปเดิมจะไม่เปลี่ยนระหว่าง epoch ดังนั้นให้ใช้
`Det-Head/precompute_det_features.py` คำนวณ pooled 4-stage feature ขนาด 1024 มิติครั้งเดียว
แล้วใช้ `Det-Head/train_det.py --feature-cache ...` เทรนเฉพาะ `Linear(1024 -> 1)`.

Feature cache เก็บเป็น NumPy memmap (`float32`) แยก `train/` และ `val/`:
- `features.npy` shape `(N, 1024)`
- `labels.npy` shape `(N, 1)`
- `teachers.npy` shape `(N, 1)` สำหรับ optional distillation
- `paths.csv` สำหรับ provenance
- `metadata.json` ผูก cache กับ SHA-1 ของ SegFormer checkpoint

`Det-Head/train_det.py` จะปฏิเสธ cache ทันทีถ้า checkpoint SHA-1 ไม่ตรงกับ checkpoint ที่ระบุ.
โหมด online เดิมยังคงไว้เพื่อ regression comparison และ fallback.

## 8. Det Head v2 (2026-09-28)

`det1` ใช้ Linear(1024 -> 1) เป็น baseline. `det2` เพิ่ม nonlinear capacity โดยไม่แก้ SegFormer:
- `LayerNorm(1024)`
- `Linear(1024 -> 256) -> GELU -> Dropout`
- `Linear(256 -> 64) -> GELU -> Dropout`
- `Linear(64 -> 1)`
- รวมประมาณ 280,961 parameters

ก่อนเทรน v2 ทำ global Train/Val/Test leakage audit ทั้ง file SHA และ decoded-pixel SHA.
กติกา clean split: same-label duplicate เก็บ `test > val > train`; conflicting-label duplicate quarantine ทุกฝั่ง.
feature cache clean สร้างจาก cache เดิมโดยตัด row ที่ leak ออก ไม่ต้องรัน SegFormer ซ้ำ.

`--source-balanced` ใช้ sqrt inverse frequency ต่อ `(label,dataset)` และ normalize ให้ label 0/1
มี expected sampling mass 50/50 เพื่อลด source dominance โดยไม่ oversample dataset เล็กแบบสุดโต่ง.
`--feature-in-ram` โหลด cache ~0.5 GB เข้า RAM เพื่อลด random I/O จาก USB.
