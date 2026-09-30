# Spec: SegFormer Det Head (Track B, ขั้น 1)

อ้างอิง `model/plan.md` หัวข้อ 32-36. เป้าหมายขั้นนี้: ต่อหัว image-level classifier
ให้ SegFormer โดยไม่แตะ `library/` (vendored mmseg 1.2.2) และไม่แตะ config หลัก
(เคยพังจาก static import ใน config เมื่อ 2026-09-18)

## 1. Architecture

- `DetHead`: GAP แยกตาม stage บน backbone feature 4 stages (mit_b2: 64+128+320+512=1024ch)
  concat แล้ว `Linear(1024 -> 1)` ได้ det logit ระดับภาพ (sigmoid ตอน inference)
- ไฟล์ใหม่ `model/segformer/det_head.py` เก็บ `DetHead` + helper โหลด checkpoint
- backbone + seg head แช่แข็ง (`requires_grad=False`) เทรนแค่ det head (~1K params)

## 2. Training (`model/segformer/train_det.py`, standalone ไม่ผ่าน mmseg Runner)

- เหตุผล standalone: feedback มีแค่ image tag ไม่มี mask ใช้ mmseg data pipeline ไม่ได้
- input: โฟลเดอร์ภาพ + CSV `path,label` (label: 1=ตัดต่อ, 0=จริง)
- bootstrap: label ตั้งต้น derive จาก mask (มี forged pixel > 0 → 1) จาก clean tree/with_mask;
  พอมี feedback ผ่าน admin verify แล้วค่อยผสม (ดู Phase 2)
- loss: BCEWithLogitsLoss; ออปชัน distillation: `α*BCE(student, teacher_score) + β*BCE(student, hard_label)`
  โดย teacher score มาจาก TruFor official (`model/TruFor/report/**/*.npz`)
- optimizer: AdamW, LR ต่ำ (1e-4), epoch น้อย + early stopping บน val split
- output: `work_dirs/det_<name>/det_head.pth` + `train_log.json` (config hash, data hash, metrics)

## 3. Export ONNX (`export_onnx_dynamic.py`)

- ขยาย `ONNXWrapper` ให้คืน tuple `(seg_logits, det_logit)`,
  `output_names=["logits", "det_logit"]`, dynamic axes ทั้งสอง output
- det head โหลดจาก `work_dirs/det_<name>/det_head.pth`; ถ้าไม่ระบุให้ export แบบเดิม (1 output)

## 4. Server (`server/app/services/onnx_worker.py`)

- อ่าน `outputs[1]` ถ้ามี (backward compatible: ถ้ามีแค่ output เดียวให้ det=None)
- `det_score = sigmoid(det_logit)` เก็บใน response คู่กับ `visual_risk_score` เดิม
- ยังไม่เปลี่ยนสูตร `total_risk_score` ในขั้นนี้ (รอเช็ค contract กับ mobile)

## 5. Eval

- เพิ่ม metric ระดับภาพ (accuracy/precision/recall @0.5) ต่อ version ในสคริปต์ Test-Case
- gate ขั้นนี้: seg metrics ต้องเท่าเดิม (backbone/seg แช่), det accuracy บน with_mask 105 ภาพรายงานเป็น baseline

## 6. Versioning

- seg checkpoint ไม่เปลี่ยน; det weights version แยก (`v1.0.6+det1`...) ผูก data hash ใน `train_log.json`
