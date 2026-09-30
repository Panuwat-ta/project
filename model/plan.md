ได้ครับ ด้านล่างคือ **Plan ฉบับละเอียดสำหรับปรับปรุง ScamGuard ให้เป็นระบบตรวจสอบภาพตัดต่อที่เรียนรู้จาก Feedback ได้อย่างควบคุม** โดยไม่ใช้แนวคิดว่า “เอา SegFormer ไปเทรนต่อเรื่อย ๆ แล้วจะเก่งขึ้น”



# Plan: ScamGuard Forgery Detection Improvement Pipeline

> หมายเหตุ (อัปเดต 2026-09-23): เอกสารนี้มี 2 track — Track A (หัวข้อ 1-31) คือการสร้าง SegFormer candidate แบบเต็มตัวจาก dataset ผสม ส่วน Track B (หัวข้อ 32-36) คือการต่อ det head ให้ SegFormer v1.0.6 ที่ freeze ไว้ โดยเริ่มจาก bootstrap ด้วย train/val ของ CASIA, Authentic, Splicing, Inpainting, CopyMove, Face, IMD2020, AIForge และ RealText แล้วจึงใช้ verified feedback เพื่อ adaptation หลังเปิดระบบ ทั้งสอง track ใช้วงจร benchmark → manual approve ร่วมกัน และห้ามใช้ Locked Test หรือ Local Test-Case 105 รูปเป็น training data

## 1. เป้าหมายของระบบใหม่

ระบบต้องตอบให้ได้ 2 อย่างจากภาพหนึ่งภาพ

```text
ภาพ
 │
 ▼
Forgery Detection System
 │
 ├── 1. Forgery Score
 │      "ภาพนี้มีโอกาสถูกตัดต่อ 87%"
 │
 └── 2. Forgery Localization
        "บริเวณนี้น่าจะถูกแก้ไข"
        ↓
       Heatmap
```

และเมื่อระบบทำนายผิด:

```text
ผู้ใช้ Feedback
       ↓
PDPA Consent
       ↓
Admin Verify
       ↓
เก็บเป็น Hard Example
       ↓
Dataset Version ใหม่
       ↓
Training Experiment
       ↓
Candidate Model
       ↓
Benchmark เทียบ Baseline
       ↓
ผ่าน → Promote
ไม่ผ่าน → Reject
```

สิ่งที่ **ห้ามทำ** คือ:

```text
❌ Production Model
       ↓
Feedback
       ↓
Train ต่อ
       ↓
Production
       ↓
Train ต่อ
       ↓
Train ต่อ...
```

เพราะจะทำให้เกิด model drift, overfitting และอาจขยายข้อผิดพลาดของโมเดลเดิม

---

# 2. Architecture เป้าหมาย

ผมเสนอให้โครงสร้าง ScamGuard เป็น:

```text
                    User Image
                        │
                        ▼
              ┌───────────────────┐
              │ Image Preprocess  │
              └─────────┬─────────┘
                        │
          ┌─────────────┴─────────────┐
          │                           │
          ▼                           ▼
 ┌─────────────────┐        ┌─────────────────┐
 │ SegFormer       │        │ TruFor          │
 │ Production      │        │ Forensic Model  │
 │ Baseline        │        │                 │
 └────────┬────────┘        └────────┬────────┘
          │                           │
    Segmentation Map           Anomaly Map
          │                    Reliability Map
          │                    Integrity Score
          │                           │
          └─────────────┬─────────────┘
                        ▼
               ┌────────────────┐
               │ Result Fusion  │
               └───────┬────────┘
                       │
           ┌───────────┴───────────┐
           ▼                       ▼
      Forgery Score           Forgery Heatmap
        0–100%                ตำแหน่งตัดต่อ
```

TruFor เหมาะกับการเป็น forensic model เสริม เพราะงานต้นฉบับออกแบบให้คืนทั้ง pixel-level localization map, whole-image integrity score และ reliability map ไม่ได้คืนแค่ mask อย่างเดียว :chatgpt-content-reference{index="2"}

ในระยะแรกผมยัง **ไม่แนะนำให้เอา TruFor มาแทน SegFormer** แต่ให้ใช้เป็นโมเดลอีกมุมหนึ่งก่อน

---

# 3. แยก Production Pipeline กับ Training Pipeline

นี่สำคัญมาก

## Production

ทำหน้าที่ตรวจภาพเท่านั้น:

```text
Image
 ↓
SegFormer + TruFor
 ↓
Forgery Score
+
Forgery Heatmap
 ↓
แสดงผู้ใช้
```

**ไม่มีการ Train ใน Production**

## Training

แยกออกมาอีกระบบ:

```text
Feedback
 ↓
Consent
 ↓
Admin Verify
 ↓
Dataset Builder
 ↓
Training
 ↓
Evaluation
 ↓
Candidate
```

ดังนั้นผู้ใช้ 1 คนกด Feedback ไม่ได้ทำให้โมเดลเปลี่ยนทันที

---

# 4. ขั้นตอน Feedback

สมมติผลตรวจ:

```text
ภาพ A

ScamGuard:
Forgery = 82%
```

แต่ผู้ใช้กด

```text
"ผลตรวจไม่ถูกต้อง"
"ภาพนี้เป็นภาพจริง"
```

ระบบสร้าง Feedback Record:

```text
feedback_id
scan_id
user_id

prediction:
    forgery_score = 0.82
    model_version = baseline-x

user_feedback:
    claimed_label = authentic

consent:
    model_training = true/false
```

**User Feedback ยังไม่ถือเป็น Ground Truth**

ต้องผ่าน Admin ก่อน

```text
User Feedback
     ↓
Pending Review
     ↓
Admin
     ↓
Confirmed / Rejected / Uncertain
```

---

# 5. PDPA Consent ต้องมาก่อน Training

Flow:

```text
ผู้ใช้ Feedback
       ↓
อนุญาตให้นำภาพไปพัฒนาโมเดลหรือไม่?
       │
   ┌───┴────┐
   │        │
  No       Yes
   │        │
   ▼        ▼
เก็บ       Admin Review
Feedback       │
เท่านั้น       ▼
          Training Eligible
```

Consent ควรแยกจากการยินยอมให้ระบบ “สแกนภาพ”

เช่น:

```text
scan_consent
≠
model_training_consent
```

และควรเป็น **รายภาพ**

---

# 6. Admin Verification

Admin ไม่ต้องวาด mask ทันที

ให้เลือกก่อนว่าเป็นอะไร:

```text
Authentic
Localized Manipulation
AI Generated
Content Scam
Uncertain
```

สำหรับโปรเจกต์ **ตรวจภาพตัดต่อ** จะสนใจหลัก ๆ แค่:

```text
Authentic
Localized Manipulation
```

ส่วน

```text
AI Generated
Content Scam
```

ควรแยกไปโมเดล/ระบบอื่น ไม่เอามาปนกับ SegFormer

---

# 7. แยก Feedback เป็น False Positive / False Negative

## กรณี A — False Positive

โมเดลบอก:

```text
Forgery = 82%
```

Admin ยืนยัน:

```text
Authentic
```

กรณีนี้ดีมากสำหรับการฝึก

เพราะเรารู้ว่า:

```text
ไม่มีบริเวณตัดต่อ
```

จึงสร้าง Ground Truth ได้อัตโนมัติ:

```text
Image
+
Mask = 0 ทั้งภาพ
```

เรียกว่า:

```text
Hard Negative
```

เช่น

```text
hard_negative/
├── screenshot_001.png
├── qr_002.png
├── compressed_003.png
├── document_004.png
└── text_heavy_005.png
```

มันจะช่วยสอนโมเดลว่า

```text
JPEG artifact
QR
ตัวอักษร
Screenshot
ขอบวัตถุ
Noise
```

ไม่ได้แปลว่าเป็นรอยตัดต่อเสมอ

---

# 8. กรณี B — False Negative

โมเดลบอก:

```text
Forgery = 5%
```

Admin ยืนยัน:

```text
Localized Manipulation
```

ปัญหาคือเรารู้ว่า

```text
"ภาพปลอม"
```

แต่ยังไม่รู้ว่า

```text
"ปลอมตรงไหน"
```

จึงยังเอาเข้า SegFormer ไม่ได้ทันที

ตรงนี้ใช้ **Teacher Pipeline**

```text
                  Forged Image
                       │
              ┌────────┴────────┐
              ▼                 ▼
         SegFormer           TruFor
              │                 │
          Prob Map       Anomaly Map
                         Reliability
              │                 │
              └────────┬────────┘
                       ▼
                 Compare Maps
                       ↓
                Pseudo Ground Truth
```

---

# 9. กฎสร้าง Pseudo-mask

อย่าบังคับให้ทุก pixel มีคำตอบ

ใช้ mask 3 ค่า:

```text
0   = Background
1   = Forgery
255 = Ignore / ไม่แน่ใจ
```

ตัวอย่าง:

| SegFormer | TruFor | Reliability | Label |
|---:|---:|---:|---|
| 0.94 | 0.91 | สูง | `1` |
| 0.05 | 0.08 | สูง | `0` |
| 0.90 | 0.20 | สูง | `255` |
| 0.30 | 0.35 | ต่ำ | `255` |

ดังนั้น:

```text
SegFormer บอกปลอม
+
TruFor บอกปลอม
+
TruFor reliability ดี

→ Forgery
```

ถ้าโมเดลไม่เห็นตรงกัน:

```text
→ Ignore
```

ไม่ใช่

```text
→ Background
```

เพราะถ้าฝืนบอกว่าเป็น background จะสร้าง label noise

TruFor มี reliability map โดยตรง ซึ่งเป็นเหตุผลหนึ่งที่เหมาะกับงานนี้ :chatgpt-content-reference{index="3"}

---

# 10. ถ้าทั้ง SegFormer และ TruFor หาไม่เจอ

นี่เป็นกฎสำคัญที่สุดอย่างหนึ่ง

สมมติ:

```text
Admin:
ภาพนี้ถูกตัดต่อแน่นอน

SegFormer:
ไม่พบ

TruFor:
ไม่พบ
```

**ห้ามสร้าง mask มั่ว**

ให้จัดสถานะ:

```text
LOCALIZATION_UNRESOLVED
```

แล้ว:

```text
ไม่เอาเข้า SegFormer training
```

เก็บไว้ใน:

```text
datasets/
└── unresolved/
```

จนกว่าจะมี Ground Truth ที่น่าเชื่อถือ

เช่นมี

```text
Original image
+
Manipulated image
```

ก็สามารถสร้าง difference mask ภายหลังได้

---

# 11. Hard Example Dataset

หลัง Admin Verify:

```text
dataset_feedback_v001/

├── hard_negative/
│   ├── images/
│   └── masks/
│
├── hard_positive/
│   ├── images/
│   └── masks/
│
├── unresolved/
│
└── manifest.json
```

ตัวอย่าง manifest:

```json
{
  "scan_id": "...",
  "feedback_id": "...",
  "source_hash": "...",

  "original_model": "segformer-baseline",

  "prediction": 0.82,

  "admin_label": "authentic",

  "training_type": "hard_negative",

  "mask_type": "exact",

  "consent": {
    "purpose": "model_training",
    "status": "granted"
  }
}
```

---

# 12. Dataset Versioning

อย่าแก้ Dataset เดิม

ใช้ version:

```text
Dataset V1
   │
   ├── Public Dataset
   ├── Authentic
   ├── CASIA
   ├── Copy-Move
   ├── IMD2020
   └── Inpainting
```

แล้วสร้าง:

```text
Dataset V2

Dataset V1
+
Hard Negative
+
Hard Positive
+
Synthetic
```

ต่อมา:

```text
Dataset V3

Dataset V2
+
Feedback รุ่นใหม่
```

แต่ต้องเก็บ V1, V2 ไว้ทั้งหมด

ปัจจุบัน Dataset Builder ของคุณมีการตรวจคู่ image/mask, สร้าง black mask สำหรับ authentic, deduplicate และป้องกันต้นฉบับเดียวกันหลุดข้าม split อยู่แล้ว :chatgpt-content-reference{index="4"}

ให้ต่อยอดจากตรงนี้

---

# 13. เพิ่ม Synthetic Forgery

Feedback จริงอาจสะสมน้อย ดังนั้นควรสร้าง training example เพิ่มเอง

จาก Authentic Image:

```text
Authentic Image
       │
       ├── Copy Move
       ├── Object Paste
       ├── Text Replacement
       ├── Number Replacement
       ├── Logo / QR Splicing
       ├── Inpainting
       └── Object Removal
```

โปรแกรมเป็นคนทำ manipulation เอง จึงรู้ว่าแก้ตรงไหน

ทำให้ได้:

```text
Synthetic Image
+
Exact Ground Truth Mask
```

เช่น:

```text
Original
"ยอดเงิน 1,000 บาท"

        ↓ program edit

Forged
"ยอดเงิน 10,000 บาท"

        +

Mask
ตำแหน่งเลขที่ถูกแก้
```

นี่เป็น label ที่น่าเชื่อถือกว่า pseudo-mask

และงานวิจัยด้าน modern image manipulation localization ก็ชี้ว่าการขาดข้อมูลคุณภาพสูงเป็นข้อจำกัดสำคัญของงานนี้ และมีการใช้ระบบสร้าง/คัด annotation ขนาดใหญ่เพื่อแก้ปัญหาดังกล่าว :chatgpt-content-reference{index="5"}

---

# 14. Training Dataset Composition

ผมจะ **ไม่ล็อกเปอร์เซ็นต์ตายตัวทันที**

ให้ทดลองหลายสูตร เช่น:

### Experiment A

```text
70% Base exact-mask
15% Hard Negative
10% Synthetic
 5% Pseudo-mask
```

### Experiment B

```text
60% Base
20% Hard Negative
15% Synthetic
 5% Pseudo
```

### Experiment C

```text
65% Base
15% Hard Negative
15% Synthetic
 5% Pseudo
```

เหตุผลที่ pseudo-label ให้น้อย เพราะเป็นข้อมูลที่มี uncertainty สูงสุด

---

# 15. การ Train Candidate

สำคัญมาก:

**อย่าใช้**

```text
Production V1
 ↓ train
V2
 ↓ train
V3
 ↓ train
V4
```

ให้ใช้ controlled experiment

ตัวอย่าง:

```text
Training Recipe R1
      +
Dataset V2
      +
Known Initialization
      ↓
Candidate-2026-01
```

อีก experiment:

```text
Training Recipe R2
      +
Dataset V2
      ↓
Candidate-2026-02
```

แล้วเอามาเทียบ

```text
Baseline
Candidate A
Candidate B
```

บน test เดียวกัน

---

# 16. Baseline ต้อง Immutable

เมื่อได้ Baseline จากแล็ป:

```text
baseline_lab/
├── checkpoint.pth
├── model.onnx
├── config.py
├── metrics.json
├── dataset_manifest.json
└── environment.txt
```

**ห้าม overwrite**

Baseline มีหน้าที่เป็น:

```text
Reference
```

ไม่ใช่:

```text
โมเดลที่เอาไป train ต่อไม่รู้จบ
```

---

# 17. Evaluation แบ่งเป็น 3 ชุด

## A. Locked Test

ห้ามเข้าฝึกเด็ดขาด

```text
Common Locked Test
```

ใช้วัด generalization

## B. Local Test

เช่น test 105 ภาพของ ScamGuard

ปัจจุบัน pipeline ของคุณมีทั้ง Common locked test และ Local Test-Case สำหรับ regression อยู่แล้ว :chatgpt-content-reference{index="6"}

## C. Feedback Test

สร้างใหม่:

```text
feedback_test_v1/
```

ประกอบด้วย:

```text
False Positive ที่เคยเกิด
False Negative ที่เคยเกิด
Hard Screenshots
Hard Copy-Move
Hard Inpainting
Hard Text Manipulation
```

**ห้ามเอาชุดนี้เข้า train**

---

# 18. Metrics ที่ต้องดู

อย่าดูแค่ mDice

สำหรับ ScamGuard ควรมี:

```text
Localization
├── Dice
├── IoU
├── Pixel Precision
└── Pixel Recall

Detection
├── Accuracy
├── Precision
├── Recall
├── F1
└── ROC-AUC

Authentic
└── False Positive Rate

Per Manipulation
├── Copy-Move
├── Splicing
├── Inpainting
├── Text Manipulation
└── Other
```

เพราะอาจเกิดกรณี:

```text
mDice ดีขึ้น

แต่

Authentic FPR
1% → 8%
```

แบบนี้ไม่ควร deploy

---

# 19. Promotion Gate

ตัวอย่าง:

```text
Candidate ต้อง:

Local mDice >= Baseline

Common Test
ไม่ต่ำกว่า Baseline

Authentic FPR
ไม่แย่กว่า Baseline

Hard Negative
ดีขึ้น

Hard Positive
ดีขึ้น

อย่างน้อย 2 หมวดที่เป็นปัญหา
ต้องดีขึ้น

หมวดอื่น
ห้าม regression เกิน threshold
```

และ:

```text
PyTorch
   ≈
ONNX
```

ก่อน deploy

---

# 20. Model Registry

ในระบบควรมี:

```text
Model

baseline-lab
candidate-001
candidate-002
candidate-003
production-v2
```

พร้อม:

```text
model_version
checkpoint_hash
onnx_hash

dataset_version
training_config
git_commit

training_date

mIoU
mDice
FPR

status
```

สถานะ:

```text
training
candidate
rejected
approved
production
archived
```

---

# 21. Admin Portal ที่ต้องเพิ่ม

หน้าใหม่:

```text
Training Feedback
```

แสดง:

```text
Image

Prediction
82% Forgery

User Feedback
"ภาพจริง"

Consent
Granted

Model
baseline-lab

Admin Decision
○ Authentic
○ Local Manipulation
○ AI Generated
○ Content Scam
○ Uncertain
```

ถ้าเลือก:

```text
Authentic
```

ระบบสร้าง:

```text
Hard Negative
```

อัตโนมัติ

ถ้าเลือก:

```text
Localized Manipulation
```

ระบบส่งเข้า:

```text
Pseudo-mask Queue
```

---

# 22. Training Queue

ไม่ train ทุกครั้งที่มี feedback

เก็บ:

```text
Feedback #1
Feedback #2
Feedback #3
...
Feedback #500
```

แล้วสร้าง:

```text
Dataset Candidate
```

จากนั้น Admin/ML engineer กด:

```text
Build Dataset
```

แล้ว:

```text
Train Candidate
```

จึงเป็น **Batch Retraining**

ไม่ใช่ Online Learning

---

# 23. Dataset Build Flow

```text
Admin-approved Feedback
          │
          ▼
Check Consent
          │
          ▼
Check Image
          │
          ▼
SHA256 / Deduplicate
          │
          ▼
┌─────────┴─────────┐
│                   │
Authentic          Forged
│                   │
▼                   ▼
Zero Mask        Teacher
                SegFormer
                   +
                 TruFor
                   │
                   ▼
               Pseudo Mask
                   │
           Quality Filtering
                   │
└──────────┬────────┘
           ▼
     Dataset Version
```

---

# 24. Pseudo-mask Quality Gate

ตัวอย่างเงื่อนไขเริ่มต้น:

```text
Teacher Agreement สูง
        AND

TruFor Reliability สูง
        AND

Mask Area
ไม่ผิดปกติ
```

เช่น:

```text
Forgery Area < 0.01%
→ suspicious

Forgery Area > 70%
→ suspicious
```

พวกนี้ไม่ควรฝืนใช้

ให้เป็น:

```text
REVIEW
```

threshold จริงต้องหาโดย validation ไม่ควรยึดค่าที่ผมยกตัวอย่างเป็นค่าตายตัว

---

# 25. TruFor ทำงานแบบ Offline ก่อน

ระยะแรก:

```text
Production:
SegFormer เท่านั้น

Training:
SegFormer + TruFor
```

ก่อน

เพราะง่ายกว่าการยัด TruFor เข้า backend production ทันที

พอทดลองแล้วพบว่า:

```text
SegFormer + TruFor
```

ลด false positive/false negative ได้จริง

ค่อยพิจารณา:

```text
Production Ensemble
```

TruFor ถูกออกแบบสำหรับทั้ง detection และ localization ขณะที่ UnionFormer เป็นอีกแนวทางวิจัยที่รวม RGB/noise/object-consistency และทำ detection/localization ร่วมกัน จึงเหมาะเป็น **R&D challenger** ในอนาคตมากกว่าการเปลี่ยน production ตอนนี้ทันที :chatgpt-content-reference{index="7"}

---

# 26. Research Track แยกออกจาก Production

ควรมี:

```text
Production Track

SegFormer Baseline
        ↓
Controlled Candidate
```

และ:

```text
Research Track

├── TruFor
├── UnionFormer
├── APSC-Net
└── Model อื่น
```

เอามา Benchmark กับ dataset เดียวกัน

ใครดีจริงค่อยพิจารณาเปลี่ยน architecture

ไม่ควรเปลี่ยนเพียงเพราะ paper ใหม่กว่า

---

# 27. Folder Structure ที่ผมเสนอ

```text
model/
└── forgery_detection/

    ├── baseline/
    │   └── segformer/
    │
    ├── teachers/
    │   └── trufor/
    │
    ├── datasets/
    │   ├── base/
    │   ├── feedback/
    │   ├── synthetic/
    │   └── versions/
    │
    ├── dataset_builder/
    │   ├── hard_negative.py
    │   ├── pseudo_mask.py
    │   ├── synthetic.py
    │   └── build_dataset.py
    │
    ├── training/
    │   ├── configs/
    │   └── train_candidate.sh
    │
    ├── evaluation/
    │   ├── locked_test/
    │   ├── feedback_test/
    │   └── compare_models.py
    │
    └── registry/
```

ของเดิมสามารถค่อย ๆ migrate จาก:

```text
model/segformer/
```

ไม่ต้องย้ายทีเดียวทั้งหมด

---

# 28. Database ที่ควรเพิ่ม

โครงสร้างประมาณ:

```text
Scan
 │
 ├── model_version_id
 ├── forgery_score
 └── heatmap_path

ScamReport
 │
 └── Feedback

Feedback
 ├── claimed_label
 ├── prediction_at_scan
 ├── model_version
 ├── admin_label
 ├── review_status
 ├── reviewed_by
 └── reviewed_at

TrainingConsent
 ├── report_id
 ├── purpose
 ├── status
 ├── notice_version
 ├── granted_at
 └── revoked_at

DatasetItem
 ├── source_scan
 ├── source_feedback
 ├── label_type
 ├── mask_type
 ├── dataset_version
 └── consent_event

ModelVersion
 ├── version
 ├── checkpoint
 ├── dataset_version
 ├── metrics
 └── status
```

---

# 29. API ที่ควรเพิ่ม

ตัวอย่าง:

```text
POST
/reports/{id}/feedback

PUT
/reports/{id}/training-consent

GET
/admin/training-feedback

PUT
/admin/training-feedback/{id}/review

POST
/admin/datasets/build

GET
/admin/datasets

POST
/admin/models/register

GET
/admin/models

POST
/admin/models/{id}/promote
```

แต่ **ไม่แนะนำให้ API production สั่ง train จาก frontend โดยตรง**

training ควรอยู่ worker/offline environment

---

# 30. แผนการทำงานเป็น Phase

## Phase 1 — Lock Baseline

ทำก่อนทุกอย่าง

```text
Baseline จาก Lab

↓ Benchmark
↓ Export ONNX
↓ Hash
↓ Config
↓ Dataset manifest
↓ Metrics
↓ Register
```

ผลลัพธ์:

```text
SCAMGUARD_BASELINE_V1
```

---

## Phase 2 — Feedback + Consent

เพิ่ม:

```text
User Feedback
Model Version
Original Prediction
Consent
```

ยัง **ไม่ทำ Training**

เป้าหมายคือเริ่มเก็บข้อมูลให้ถูกก่อน

---

## Phase 3 — Admin Ground Truth

สร้างหน้า:

```text
Feedback Review
```

Admin สามารถยืนยัน:

```text
Authentic
Localized Manipulation
Uncertain
```

เริ่มสะสม Hard Examples

---

## Phase 4 — Hard Negative

ทำก่อน pseudo-mask เพราะง่ายและ Ground Truth ชัด

```text
Confirmed Authentic

→ zero mask

→ Hard Negative
```

จากนั้นสร้าง Candidate แรกโดย:

```text
Base
+
Hard Negative
```

ดูว่า False Positive ลดหรือไม่

---

## Phase 5 — TruFor Teacher

ติดตั้ง TruFor ใน environment แยก

```text
Hard Positive

↓
SegFormer
+
TruFor

↓
Pseudo-mask
```

TruFor ยังไม่เข้า Production

---

## Phase 6 — Synthetic Generator

สร้าง:

```text
Copy-Move
Splicing
Inpainting
Text Edit
Number Edit
QR/Logo
```

พร้อม exact mask

---

## Phase 7 — Dataset Versioning

สร้าง:

```text
dataset-v001
dataset-v002
dataset-v003
```

ทุก version reproducible

---

## Phase 8 — Candidate Training

```text
Dataset Version
+
Training Config
+
Seed
+
Code Commit
        ↓
Candidate
```

---

## Phase 9 — Model Benchmark

```text
Baseline
     VS
Candidate
```

ทดสอบ:

```text
Common Test
Local Test
Feedback Test
Hard Categories
ONNX parity
```

---

## Phase 10 — Manual Promotion

```text
Candidate
 ↓
PASS
 ↓
Admin/ML Approve
 ↓
Production
```

ไม่ automatic deploy

---

# 31. Flow สุดท้ายของ ScamGuard

เมื่อทุก Phase เสร็จ ระบบจะเป็น:

```text
                         ┌──────────────────────┐
                         │      USER IMAGE      │
                         └──────────┬───────────┘
                                    ↓
                         ┌──────────────────────┐
                         │  Forgery Detection   │
                         │       System         │
                         └──────────┬───────────┘
                                    ↓
                         Forgery Score + Heatmap
                                    │
                                    ▼
                              User Result
                                    │
                         Result incorrect?
                                    │
                                    ▼
                               Feedback
                                    │
                             PDPA Consent
                                    │
                                    ▼
                              Admin Verify
                                    │
                ┌───────────────────┴─────────────────┐
                │                                     │
            Authentic                         Manipulated
                │                                     │
                ▼                                     ▼
        Exact Zero Mask                 SegFormer + TruFor
                │                                     │
         Hard Negative                        Pseudo-mask
                │                                     │
                └──────────────────┬──────────────────┘
                                   │
                                   ▼
                          Hard Example Dataset
                                   │
                            Synthetic Data
                                   │
                                   ▼
                           Dataset Version N
                                   │
                                   ▼
                          Training Experiment
                                   │
                                   ▼
                             Candidate Model
                                   │
                    ┌──────────────┴─────────────┐
                    │                            │
                Baseline                    Candidate
                    │                            │
                    └────────── Benchmark ───────┘
                                   │
                        ┌──────────┴──────────┐
                        │                     │
                       PASS                  FAIL
                        │                     │
                        ▼                     ▼
                     Promote                Reject
                        │
                        ▼
                    Production
```

## แก่นของ Plan นี้

ไม่ใช่:

> **“ทำให้ SegFormer ยิ่งเทรนยิ่งเก่ง”**

แต่เป็น:

> **“ทำให้ ScamGuard เก็บความผิดพลาดจากการใช้งานจริงอย่างถูกต้อง → เปลี่ยนความผิดพลาดเหล่านั้นเป็นข้อมูลคุณภาพสูง → สร้าง Candidate ใหม่ → พิสูจน์ด้วย Benchmark ก่อนเปลี่ยน Production”**

ดังนั้นสิ่งที่ “พัฒนาต่อเนื่อง” จริง ๆ คือ **Dataset + Evaluation + Training Process** ไม่ใช่การปล่อยให้ SegFormer เรียนต่อจากตัวเองแบบไม่มีจุดสิ้นสุด

 และผมแนะนำให้เริ่มพัฒนาจริงตามลำดับ **Baseline Lock → Feedback/Consent → Admin Review → Hard Negative → Dataset Versioning → Candidate Training** ก่อน ส่วน **TruFor + pseudo-mask** ค่อยเพิ่มหลังจาก 5 ส่วนแรกทำงานถูกต้อง เพราะจะลดความซับซ้อนและทำให้ตรวจได้ง่ายว่าการปรับแต่ละขั้นช่วยโมเดลจริงหรือไม่.

---

# 32. Track B: SegFormer Det Head (Base-dataset Bootstrap + Feedback Adaptation)

Track นี้ต่างจาก Track A ตรงที่ไม่เทรน SegFormer ทั้งตัว แต่ต่อหัว image-level classifier (det head) เพิ่มบน SegFormer v1.0.6 แล้ว freeze backbone + seg head เดิมทั้งหมด เพื่อให้ heatmap และพฤติกรรม localization ของ baseline ไม่เปลี่ยน

Track B แบ่งเป็น 2 ระยะ:

```text
Stage B1 — Pre-launch Bootstrap
ใช้ TRAIN/VAL ของ dataset เดิม 9 แหล่ง
CASIA + Authentic + Splicing + Inpainting + CopyMove + Face + IMD2020 + AIForge + RealText
→ สร้าง image-level label จาก ground-truth mask
→ train เฉพาะ det head
→ ได้ det-v1 สำหรับใช้ก่อนมี feedback จริง

Stage B2 — Post-launch Feedback Adaptation
Verified Feedback + PDPA Consent + Admin Verify
→ ใช้เป็น hard examples ปรับ det head ต่อแบบ controlled candidate
→ benchmark
→ manual approve/reject
```

ความสัมพันธ์กับ Track A: Track B ไม่แทน Track A (Track A ยังใช้สร้าง candidate แบบเต็มตัวและแก้ localization) แต่เป็นเส้นทางที่เบากว่าสำหรับปรับ image-level forgery score โดยไม่แตะ seg head เดิม ถ้า localization พลาดเพราะ feature ไม่เห็นร่องรอย การจูน det head อย่างเดียวไม่สามารถแก้ได้ ต้องกลับไป Track A หรือพิจารณา architecture อื่น

งานที่ต้องทำครั้งเดียวก่อนเริ่ม Track B:

```text
1. ต่อ det head ให้ SegFormer v1.0.6
2. Freeze backbone + seg head
3. สร้าง image-level label จาก train/val ของ dataset เดิม
4. Export ONNX 2 outputs (seg logits + det_logit)
5. Server อ่าน det score + กฎรวมคะแนน
6. Eval ระดับภาพโดยใช้ validation/test ที่แยกจาก training
```

---

# 33. สถาปัตยกรรม Det Head

```text
SegFormer Backbone (frozen)
        │
        ├── SegformerHead (frozen) → seg logits → heatmap (เหมือนเดิม)
        │
        └── Det Head (trainable)
                │
                ├── Global Average Pool (บน feature backbone/decoder)
                ├── Linear → 1 logit
                │
                └── sigmoid → det score 0–1
```

นโยบาย freeze เดียวกับ TruFor Phase 3:

```text
Frozen: backbone + seg head
Trainable: det head เท่านั้น
```

ผลที่ได้:
- heatmap ไม่เปลี่ยน (seg head ถูกแช่)
- พารามิเตอร์ที่ขยับน้อย เทรนเร็ว ลืมของเก่ายาก
- det ตัดสินจาก feature ระดับภาพ ไม่ใช่เนื้อหาภาพดิบโดยตรง

ข้อจำกัด: det เก่งได้แค่เท่าที่ feature ข้างล่างเห็น ถ้า localization พลาดสนิท (เช่น inpainting ที่วัดได้ F1 0.017) จูน det อย่างเดียวแก้ไม่ได้ ต้องกลับไป Track A หรือเปลี่ยน architecture

---

# 34. นโยบาย Dataset + Guardrail ของ Track B

## Stage B1 — Pre-launch Bootstrap

ก่อนมี feedback จริง ให้ใช้เฉพาะ TRAIN/VAL split ของ dataset เดิม 9 แหล่ง:

```text
CASIA
Authentic
Splicing
Inpainting
CopyMove
Face
IMD2020
AIForge
RealText
```

กฎสร้าง image-level label:

```text
mask มี forgery pixel อย่างน้อย 1 pixel → manipulated (1)
mask เป็นศูนย์ทั้งภาพ                 → authentic (0)
```

ข้อบังคับ:

```text
1. ใช้ TRAIN สำหรับ train det head
2. ใช้ VAL สำหรับ model selection / early stopping
3. ห้ามใช้ Locked Common Test เป็น training หรือ tuning data
4. ห้ามใช้ Local Test-Case 105 รูปเป็น training หรือ tuning data
5. รักษา split/group ของต้นฉบับเพื่อป้องกัน leakage
6. balance authentic/manipulated และตรวจ source imbalance ก่อน train โดยเฉพาะ AIForge/RealText ที่มี distribution ต่างจาก 7 แหล่งเดิม
7. backbone + seg head ของ v1.0.6 ต้อง frozen ตลอด Stage B1
```

## Stage B2 — Post-launch Feedback Adaptation

หลังระบบเปิดจริง feedback ที่นำมา train ได้ต้องผ่านครบ:

```text
Admin Verify (authentic / manipulated ที่ยืนยันแล้ว)
        AND
PDPA Consent รายภาพสำหรับ training
        AND
Deduplicate ด้วย image_hash/source_hash
```

Guardrail สำหรับ feedback adaptation:

```text
1. ปุ่ม Train เปิดเมื่อมี verified feedback เพียงพอและมีความหลากหลาย
2. ค่าเริ่มต้นเช่นคลาสละ 50 ภาพเป็นเพียง minimum bootstrap ไม่ใช่เกณฑ์ถาวร
3. split feedback แบบ group-safe เพื่อกันภาพต้นฉบับเดียวกันข้าม train/val
4. Learning rate ต่ำ + epoch น้อย + early stopping บน feedback val
5. ใช้ Local/Hard-case regression ตรวจ candidate ระหว่างพัฒนา
6. Locked Common Test ใช้กับ candidate ที่เลือกแล้วก่อน promotion ไม่ใช้เป็น feedback loop
7. ห้าม auto deploy — ต้อง admin/ML approve ก่อนเสมอ
```

ความเสี่ยงหลักคือ feedback มี sampling bias เพราะเป็นเคสที่ผู้ใช้เลือกมารายงาน ดังนั้น Stage B2 ควร anchor กับข้อมูลฐานที่ freeze ไว้บางส่วนหรือใช้ replay subset ที่สมดุล เพื่อกัน det head drift ออกจาก distribution เดิม

---

# 35. Web Training Job (Stage B2: Admin กดเทรนจากเว็บ)

Stage B1 bootstrap เป็นงานเตรียม baseline det head ก่อนเปิดระบบ ไม่จำเป็นต้องเริ่มจากปุ่มบนเว็บ ส่วนหลังเปิดระบบ Stage B2 ห้ามเทรนใน request เดียวกัน ต้องใช้คิวงาน:

```text
Admin กด Train (เมื่อ verified feedback ผ่าน guardrail)
        ↓
สร้าง Training Job
  - snapshot feedback IDs
  - dataset/source hash
  - base seg version
  - current det version
  - train config + seed
        ↓
Worker รันเบื้องหลัง
  - สร้าง group-safe train/val split
  - เทรน det head (backbone + seg แช่)
  - Evaluate: feedback val + Local/Hard-case regression
        ↓
เลือก Candidate
        ↓
Final gate: Locked Common Test + ONNX parity
        ↓
แจ้งผล + เปรียบเทียบ det production
        ↓
  ┌─────┴─────┐
  │           │
Approve      Reject
  │           │
  ▼           ▼
Promote     Archive/ทิ้ง candidate
Det version
```

ข้อจำกัดเครื่องจริง: GPU 4GB ถูก API server ใช้เต็มอยู่แล้ว ช่วง worker เทรนต้องจอง GPU (หยุด server ชั่วคราวเหมือนตอนทดสอบ TruFor) หรือจัดคิวนอกเวลา ต้องออกแบบ worker ให้จอง GPU ได้ก่อนรัน

---

# 36. Det Weight Versioning

seg checkpoint ไม่เปลี่ยน version ส่วนน้ำหนัก det แยก version ต่างหาก:

```text
seg: v1.0.6 (frozen, ไม่ขยับ)
det: v1.0.6+det1-bootstrap
     → v1.0.6+det2-feedback
     → v1.0.6+det3-feedback ...
```

Registry ต้องผูก:

```text
det_version
seg_version (ที่แช่อยู่)
training_dataset_hash (base bootstrap หรือ feedback snapshot)
train_config (LR, epochs, seed)
metrics (Accuracy, Precision, Recall, F1, ROC-AUC, PR-AUC, FPR/FNR + regression gates)
onnx_hash / ONNX parity result
status (training / candidate / approved / production / rejected / archived)
```

ข้อดี: rollback ได้เฉพาะ det โดย heatmap และ seg ไม่กระทบ และรู้เสมอว่า det แต่ละรุ่นเรียนจาก dataset/bootstrap หรือ feedback snapshot ชุดไหน
---

# 39. Track B1.1 — Domain/Label Semantics Correction (2026-09-29)

ผลจาก det2-b → det3-c แสดงว่า MLP-only hard mining ช่วย benchmark บาง domain แต่ไม่แก้ real-world domain gap อย่างสม่ำเสมอ

สถานะ:

```text
Production shadow: v1.0.6 + det2-b (คงเดิม)
det3-c hard×1.5: research candidate — reject for shadow promotion
Fusion into total risk: disabled
```

หลักฐานสำคัญ:
- det3-c Val/Test ดีขึ้นเล็กน้อยและลด FN บน CopyMove/Inpainting
- แต่ Authentic specificity ลดลง และ real pilot 11 รูปลดจาก 6/11 เป็น 5/11
- `test1/test2` ไม่ได้พลาดเพราะ Mobile re-encode; score ต่ำตั้งแต่ไฟล์ต้นฉบับ
- TruFor ยังเห็น forensic signal ใน `test1/test2` แต่ใช้เป็น diagnostic เท่านั้น
- SegFormer GAP nearest-neighbor วาง Original3/Original7/test1 ผิดฝั่งตั้งแต่ feature representation

ดังนั้นห้ามแก้รอบถัดไปด้วย threshold tuning หรือ MLP hard-boost อย่างเดียว
## 39.1 Label semantics guardrail

Stage B1 เดิมใช้ `mask=0 → authentic` ซึ่งหมายถึง “ไม่มี manipulation ที่ annotation ชุดนั้นระบุ” ไม่ได้พิสูจน์ว่า source image ไม่เคยถูกแก้ไขมาก่อน

ตั้งแต่รอบถัดไปให้เก็บ provenance เพิ่ม:

```text
label_id
label_source = mask | paired_edit | verified_human
label_confidence
source_dataset
source_image_id / group_id
known_operation (ถ้ามี)
review_status = trusted | needs_review | exclude
```

ห้าม relabel จาก Det score หรือ TruFor score อัตโนมัติ
คะแนน model ใช้จัดลำดับ review ได้ แต่ ground truth ต้องมาจาก provenance/annotation/verification ที่ตรวจสอบได้

Queue audit ปัจจุบัน:
- Train conflict candidates: 3,080 รูป
- Stratified manual-review sample: 225 รูป
- ที่เก็บ: `work_dirs/det_v1.0.6_det2b_mlp_source_balanced/domain_label_audit_v1/`

11 รูป pilot ที่ดูผลแล้วให้เปลี่ยนสถานะเป็น development diagnostic set ไม่ใช่ final unbiased holdout สำหรับรุ่นใหม่
รอบ final real-world gate ถัดไปต้องเก็บภาพใหม่ที่โมเดล/การออกแบบ candidate ยังไม่เคยเห็นผลมาก่อน
## 39.2 Next model experiment

ก่อนเพิ่ม backbone ใหม่ ให้ทดสอบว่าปัญหามาจาก `GAP` ที่ทิ้ง spatial/extreme feature มากเกินไปหรือไม่

Candidate feature representation:

```text
SegFormer stage features (frozen)
        ├─ Global Average Pool
        └─ Global Max Pool
             ↓
concat 4 stages = 2048-D
             ↓
MLP Det Head
```

เปรียบเทียบกับ GAP 1024-D เดิมโดยเลือกจาก clean Val เท่านั้น
ถ้า GAP+GMP ยังวาง real-world hard cases ผิดฝั่ง ให้หยุด Track-B head-only และไปทดสอบ independent image-level feature branch / Track A แทน

Dataset work สำหรับรุ่นใหม่ต้องเพิ่ม independent, verified examples ของ:
- authentic screenshots / screen photos / electronics / high-texture scenes
- manipulated web photomontage/composite
- resize / JPEG recompression / PNG re-encode / screenshot-like transforms จาก TRAIN เท่านั้น

ห้ามนำ 44,031 held-out Test, Test-Cases 165 หรือ pilot 11 เข้า training/tuning
TruFor ใช้เป็น diagnostic/optional soft teacher หลัง provenance check เท่านั้น ไม่ใช้เป็น ground truth อัตโนมัติ

## 2026-09-29 — Det4 GAP+GMP ablation result

Det4 tested a richer frozen-v1.0.6 representation: GAP + GMP from the four MiT-B2 stages (2048-D) instead of GAP-only 1024-D.

Result:
- det4-a Val accuracy 86.24%
- det4-b (unbalanced) Val accuracy 85.78%
- det4-c (dropout 0.3) Val accuracy 86.27%
- det4-c improved Val macro metrics, but Authentic specificity at threshold 0.5 fell to ~87.06%
- raising threshold to ~0.585 recovered det2-b-level Authentic specificity but removed much of the hard-dataset gain
- Pilot11 remained 6/11; both web photomontage positives were still false negatives
- GAP+GMP neighbor audit improved Original1/Original3 somewhat, but Original7 and test1 remained on the wrong side of the feature space

Decision:
- reject det4-c before locked Test
- do not open the 44,031-image locked Test for det4-c
- keep det2-b active in shadow mode
- next priority: label-semantics audit + local/spatial forensic representation; do not continue threshold-only tuning

## 2026-09-29 — Label Audit v2 + Det5 local feature

- Label Audit conflict queue remains Train-only: 3,080 rows; no automatic relabel.
- Provenance is resolved for all 3,080 rows in `audit_review_queue_v4.csv`.
- 1,718 manipulated conflict rows have masks; 1,369 (79.69%) contain <1% forged pixels.
- Sparse manipulation is therefore a major cause of low image-level Det score and must not be treated as label error by score alone.
- `build_train_manifest_from_audit.py` refuses to build a new Train manifest while audit rows are pending.

### Det5 representation
- SegFormer v1.0.6 remains frozen.
- Each of four backbone stages is adaptive-pooled to a 4x4 aligned grid.
- Stage channels are concatenated per location: 16 local tokens x 1024-D per image.
- Cache dtype: float16; labels remain float32.
- Candidate heads: `patch_attention` and `patch_topk` (MIL-style).
- Det5 smoke tests passed for precompute, train, save/load, and online forward.
- Full Train/Val local-token cache may be precomputed before audit completion because features are label-independent; final candidate training must use the reviewed manifest.
- Do not open locked Test 44,031 until a Det5 candidate passes clean Val plus real-camera/web-manipulation diagnostics.
## 2026-09-29 — Det5 pre-audit result

- Full local-token cache completed: Train 95,770 and Val 11,972, shape `(N,16,1024)`, float16, zero rows 0, finite true.
- Det5-A `patch_attention`: best Val accuracy 86.368% at epoch 20.
- Det5-B `patch_topk`: best Val accuracy 85.817% at epoch 25.
- Det5-A Val: F1 85.73%, ROC-AUC 94.33%, AP 95.07%, specificity 90.83%, recall 81.90%.
- Fresh real-camera authentic diagnostic: det2-b 3/11 -> Det5-A 6/11 correct.
- Existing Pilot11: det2-b 6/11 -> Det5-A 6/11; Manipulated1 score improved 0.291 -> 0.485 but remained FN.
- Test-Cases165: det2-b 86.06% -> Det5-A 86.67%; Det5-A specificity 93.33%, recall 84.17%.
- Locked Test 44,031 remains unopened.

Label Audit v5 verifies 2,945/3,080 conflict rows using GT masks or explicit PSBattles pairing.
The remaining 135 rows are PSBattles source-original negatives: reference-original provenance is known, but camera-pristine/no-prior-edit provenance is not established.
They remain pending semantics review; the audited-manifest guard correctly refuses to build final Train data while these are pending.

Decision: Det5-A is the preferred representation candidate, but it remains pre-audit and non-promotable. Production/shadow stays on det2-b.

## 2026-09-29 — Det5 audited result and real-camera domain gap

- Label Audit v6 resolved all 3,080 conflict rows without automatic relabel.
- 2,945 rows retain dataset labels supported by GT mask/pair evidence.
- 135 PSBattles source-original rows are marked uncertain and excluded from high-confidence Train because source-original does not prove camera-pristine provenance.
- Audited Train: 95,635 rows (47,768 Authentic / 47,867 Manipulated).
- Det5 patch_attention audited was trained from scratch with seeds 42, 7, 123.
- Val accuracy was stable at ~86.33–86.38%, but all three seeds failed fresh-camera and web-photomontage diagnostics.
- Locked Test 44,031 remains unopened for Det5 audited.
- Production/shadow remains v1.0.6 + det2-b.

### New priority: real-camera-authentic-v1
- Current 11 fresh camera images remain protected diagnostic holdout; never train on them.
- Main Authentic Train source sample median resolution ~0.274 MP versus fresh camera11 ~12.58 MP.
- Build a separate verified direct-camera Authentic dataset with session/device-separated splits.
- Validator: `model/segformer/Det-Head/validate_camera_authentic_incoming.py` rejects byte/pixel duplicates with the protected camera11 holdout.
- Dataset spec: `model/segformer/Det-Head/dataset_specs/real-camera-authentic-v1.md`.
- Do not resume Det5 promotion until real-camera domain coverage exists and passes Val + external diagnostics.
## 2026-09-29 — Det5 audit/weighting follow-up + Det6

- Label Audit closed 3,080/3,080 conflict rows: 2,945 keep by dataset/GT evidence; 135 PSBattles source-original rows remain semantics-uncertain and are excluded from the audited Train manifest. No relabel was performed.
- Audited Train: 95,635 rows (47,768 label0 / 47,867 label1); Val remains 11,972.
- Det5-A audited hard-exclusion reached 86.385% Val but regressed real-camera Authentic to 1/11 and Pilot11 to 3/11; rejected before locked Test.
- Weak-label loss experiments on the 135 uncertain PSBattles rows: weight0.25 Val 86.510%; weight0.50 Val 86.535%. The Val-selected weight0.50 candidate regressed real-camera to 3/11 and Pilot11 to 5/11; rejected before locked Test.
- Verified hard-negative sampler boost using 591 zero-GT-mask Train conflicts: boost1.5 Val 86.560%, boost2.0 Val 86.226%; specificity worsened, so no external diagnostic/locked Test was opened.
- Verified hard-negative loss weight1.5 Val 86.377% and also reduced specificity; weight2.0 was not run because the direction was already adverse.
- Conclusion: stop threshold/weight micro-tuning. Current evidence points back to representation/local-resolution limitations.
- Det6 experiment started: frozen SegFormer v1.0.6, aligned 8x8 grid, 64 local tokens x 1024-D, patch-attention head. Train/Val only; Locked Test 44,031 remains unopened.

## 2026-09-29 — Det6 full-data result + reproducible Det search loop

### Det6-A result (full data, 95,635 rows, 22 epochs, early stop at best epoch 16)
- Val accuracy 86.176% (Det5-A 86.385%, Det2-B 85.925%).
- External diagnostics scored with the new reproducible script: camera11 specificity 18.18% (Det5-A 9.09%, Det2-B 27.27%), Pilot11 accuracy 45.45% (Det5-A 27.27%, Det2-B 54.55%), Test-Cases165 accuracy 87.27% (Det5-A 86.67%, Det2-B 86.06%).
- Det6 local resolution (64 tokens) helped over Det5 (16 tokens) but is still below the deployed Det2-B on real-camera Authentic. Not promoted; Locked Test 44,031 remains unopened.

### New tooling (previously missing; prior diagnostics were run ad-hoc and were not reproducible)
- `Det-Head/eval_det_diagnostics.py` — scores any Det head on the three development diagnostics (camera11 11, pilot11 11, testcases165 165) in one SegFormer pass; supports pooled, Det5/Det6 local-token and variant heads. Verified to reproduce the earlier ad-hoc numbers exactly (det2b camera11 27.27%, det5a 9.09%, det6a 18.18%). Also fixed a real manifest bug: `Test-Cases/pairs/manipulated` holds 22 `.jpg` + 8 `.png`, so a `*.jpg`-only glob silently produced 157 instead of 165 rows.
- `Det-Head/det_head_variants.py` — four aggregation heads (`token_stats`, `token_stats_coarse`, `token_stats_topk`, `spatial_pyramid`) that reduce the cached local tokens to global statistics.
- `Det-Head/train_det_screen.py` — screening trainer on a fixed-seed stratified subsample; 37 s/epoch versus 2.3 h/epoch full-data, so a candidate costs ~8 min instead of ~2.3 h. Metrics are computed in-repo (`binary_ranking_metrics`) and were verified against the previous sklearn values to 2.8e-08; sklearn is not in `requirements.txt` and the old bare `except Exception` had been silently nulling f1/auc/ap.
- `Det-Head/run_det_loop.py` + `Det-Head/search_plan_2026-09-29.json` — train → diagnose → gate → leaderboard driver. The gate requires camera11 specificity, pilot11 accuracy and testcases accuracy to each be at least the production Det2-B level; Val is recorded but never used to accept a candidate.

### Loop outcome: 0 of 12 candidates passed
- Across the 12 candidates, `pearson r(Val ROC-AUC, camera11 specificity) = -0.037` and `r(Val AP, camera11 specificity) = -0.037`. The best-Val candidate (token_stats lr3e-4, AUC 92.96%) had one of the worst camera11 results (9.09%). This is the third independent confirmation that Val accuracy does not select a usable Det head.
- The tested hypothesis was that the Authentic signal is global rather than local, suggested by the token-count ordering Det2-B 1 token 27.27% > Det6 64 tokens 18.18% > Det5 16 tokens 9.09%. Four global-aggregation heads plus regularisation, seed and hard-negative variants were screened; none beat the local-attention control or reached the production level. The hypothesis is not supported.
- Screening used 24,999 stratified rows over 12 epochs, so screening Val accuracy is NOT comparable to the full-data baseline Val column; the three diagnostic columns ARE comparable because every head was scored by the same script on the same files.
- Production unchanged: `server/.env` `ONNX_MODEL_PATH` still points to the Det2-B ONNX, no production file was modified, and the loop contains no access to the Locked Test.
- Evidence: `Det-Head/search_runs/2026-09-29/` (`REPORT.md`, `leaderboard.csv`, `results.json`, per-candidate logs).

### Conclusion
The search loop is reproducible and its answer is negative: no head architecture reachable from the current training set closes the real-camera Authentic gap, and Det2-B remains the best available Det head. The blocker is the training data, not the head. Next step is the data work specified in `Det-Head/dataset_specs/real-camera-authentic-v1.md`, after which this loop should be re-run. Further search on the current data is not worth budget.


## 2026-09-29 — Domain correction: the 11 "image-Authentic" files are two domains

### Provenance correction
The user confirmed on 2026-09-29 that the folder `Test-Cases/image-Authentic` is not one domain:
- `to2`–`to10` (9 files) are direct mobile-camera photos. 4096x3072 / 12.58 MP, 12 EXIF tags each including GPS.
- `to1` is a LINE chat capture (1080x1920) and `to11` is a screen capture (1197x632). Both carry zero EXIF tags and no GPS.

This corrects the earlier reading of `Test-Cases/image-Authentic` as a single "camera11" real-camera set. EXIF `Make`/`Model` on the 9 camera files is the literal string `"--"`, so those captures were re-saved with metadata stripped; the camera/screen-capture distinction rests on the user's confirmation plus the EXIF-tag-count split (12 vs 0), which `Det-Head/eval_det_diagnostics.py` now verifies on every load.

### Diagnostic split
- `camera9` — the 9 real-camera photos. Now the gated real-camera metric.
- `chatshot2` — `to1` + `to11`. Scored on every candidate but **never gated**; n=2 cannot separate a regression from noise.

New baseline after the split (`Det-Head/diagnostics_split_2026-09-29`):

| head | camera9 spec | chatshot2 acc | chatshot2 mean | pilot11 acc | testcases acc | Val acc |
|---|---|---|---|---|---|---|
| det2b (production) | **33.33%** | 0/2 | 0.7117 | **54.55%** | **86.06%** | 85.93% |
| det5a | 11.11% | 0/2 | 0.7558 | 27.27% | 86.67% | 86.38% |
| det6a | 22.22% | 0/2 | 0.8604 | 45.45% | 87.27% | 86.18% |

Specificity rises when the two non-camera files are removed (det2b 27.27% → 33.33%, det6a 18.18% → 22.22%, det5a 9.09% → 11.11%) but the ranking is unchanged, so the earlier conclusion stands.

### The larger finding: chat/screenshot is a stated use case with zero training representation
`.agents/PRODUCT.md` names "สกรีนช็อตแชท" and "สกรีนช็อตที่ดัดแปลงเนื้อหา" as primary user-facing cases, and `AGENTS.md` sets the scope to all scam images. But the audited Train manifest (95,635 rows) contains 10 datasets — authentic, psbattles, realtext, casia, face, copymove, inpainting, splicing, imd2020, aiforge — and **none is a chat or screenshot source**. The 165-image Test-Cases set likewise has none.

All three heads score 0/2 on the two authentic chat captures, with mean scores 0.7117 (det2b), 0.7558 (det5a) and 0.8604 (det6a). The deployed head already calls an unedited LINE chat 71% likely-manipulated. This is a confirmed false-positive source on a stated use case, and it is a larger gap than the camera resolution gap, because unlike the camera domain the chat domain has **no** training representation at all rather than a mismatched one.

### Changes made
- `Det-Head/eval_det_diagnostics.py` — `AUTHENTIC_PROVENANCE` declares each file's domain; `_exif_tag_count` verifies the declaration (camera needs >= 8 EXIF tags, chatshot needs 0) and refuses to score a file with no declared provenance. Verified in both directions and for the undeclared-file case.
- `Det-Head/run_det_loop.py` — gate uses `camera9_specificity` (floor 0.3333); `chatshot2` moved to `REPORT_ONLY_METRICS` and printed but never gated; leaderboard gained chatshot columns.
- `Det-Head/det_head_variants.py`, `Det-Head/validate_camera_authentic_incoming.py` — renamed the stale `camera11` references.
- `Det-Head/dataset_specs/chat-screenshot-v1.md` — new spec for the chat/screenshot domain: ground truth, interface coverage (LINE first, since that is where the 2 known images came from), target 300 pilot / 1,000+ with a minimum of 150 label1, split by conversation and capture session rather than by row.
- `Det-Head/dataset_specs/real-camera-authentic-v1.md` — corrected to state the folder is two domains and points at the new spec.
- New evidence: `Det-Head/diagnostics_split_2026-09-29/`. Production is unchanged; Locked Test 44,031 remains unopened.

### Next steps, in priority order
1. Collect chat/screenshot data per `dataset_specs/chat-screenshot-v1.md`. This is now the highest-value gap.
2. Collect real-camera Authentic data per `dataset_specs/real-camera-authentic-v1.md`, preserving EXIF.
3. Re-run `Det-Head/run_det_loop.py` only after at least one of those datasets exists. Re-running on the current data has already produced 0/12 and is not worth further budget.

## 2026-09-30 — First gate-passing Det head: det7a (data change, not architecture)

### Discovery: screenshot data already on disk, and a measured false-positive problem
Before asking for new data, the local tree was searched. `Pictures/dataset_raw/phishing-screenshots` holds 8,370 full-page desktop web screenshots (1920x1080) that appear in no training manifest.

Measured on the deployed det2b head, unmodified screenshots are being flagged heavily: 45.5% (91/200) and 48.4% (31/64) of authentic screenshots scored >= 0.5 as manipulated, mean score ~0.48. The 336 phishing-site screenshots, also unmodified images, were flagged 32% of the time. The head has no usable representation of the screenshot/UI domain, and the audited Train manifest (95,635 rows, 10 datasets) contains no screenshot source at all.

### Label-semantics trap that was avoided
`metadata.csv` labels rows `phishing` (1) / `legitimate` (0). That is a phishing-site label, not a content-manipulation label; a screenshot of a phishing site is still an unmodified image. Mapping the 328 phishing rows to Det label 1 would have taught the head to call untouched screenshots manipulated and made the false positives worse. `Det-Head/build_webshot_authentic_manifest.py` writes every row as Det label 0, keeps the source label in a separate `source_label` column, and asserts the invariant. Output: 7,394 rows (85 duplicates and 891 blank/captcha/error pages dropped, 0 holdout overlap), at `/run/media/panuwat/USB/model/Det-Head/manifests/det-train-v4-webshot.csv`.

### Result: 3/3 seeds pass the external gate
Full data 103,029 rows (95,635 + 7,394), `token_stats` head (401,665 params), source-balanced, 30 epochs, patience 6.

| seed | Val acc | camera9 | chatshot2 | pilot11 | testcases | gate |
|---|---|---|---|---|---|---|
| det2b (production) | 85.93% | 33.33% | 0/2 | 54.55% | 86.06% | baseline |
| 42 | 86.29% | 55.56% | 1/2 | 72.73% | 86.06% | PASS |
| 7 | 86.26% | 77.78% | 2/2 | 72.73% | 86.67% | PASS |
| 123 | 86.00% | 55.56% | 2/2 | 72.73% | 87.27% | PASS |

camera9 across seeds 0.5556-0.7778, mean 0.6296; the worst seed still beats production by 22.2 points. This is the first candidate in 17 attempts to pass, and the first to pass on the full-data protocol rather than only screening.

### Why the first attempt at adding the data failed, and the fix
Round 1 (`Det-Head/search_plan_webshot_2026-09-29.json`, w00-w03) added the screenshots with plain random sampling. Screenshot false positives collapsed (camera9 22.22% -> 88.89%, chatshot2 0/2 -> 2/2) but every candidate lost testcases accuracy. The per-dataset breakdown showed a *recall* loss rather than new false positives: testcases fp was identical at 7 in both w00 and w03 while fn rose 19 -> 20, driven by inpainting recall 0.60 -> 0.47 and pairs 0.83 -> 0.77. Sparse edits were already the known weak case from the 2026-09-29 label audit, and 7,394 extra label0 rows tilted the boundary toward authentic.

Round 2 applied `--source-balanced` (`Det-Head/search_plan_webshot_round2_2026-09-29.json`, x01-x04), giving each (label,dataset) group equal expected sampling mass. x01 and x02 both passed, and x02 was retrained on the full protocol.

### Tooling added
- `Det-Head/build_webshot_authentic_manifest.py` — builds the label-0 Authentic screenshot manifest with the semantics assertion.
- `Det-Head/train_det_screen.py --extra-cache` — concatenates a second cache so a new domain is added without recomputing the existing 12.5 GB cache. USB was at 96% capacity, so recomputing a combined 13.5 GB cache was not viable.
- `--source-balanced` is now honoured in screening mode, restricted to the subsampled rows via `_write_subset_rows`; using the full manifest would emit indices the Subset never returns.
- `run_det_loop.py` gained per-candidate `source_balanced`, `epochs` and `extra_cache`.
- `train_det_screen.py` now records `source_groups`; the det7a run predates the fix, so its 15 sampler groups were reconstructed from the same manifests and seed and written back into its `train_log.json` with a note.

### Limitations, stated plainly
- camera9 has 9 images, so one image moves the metric 11.1 points. The 4 still-flagged images (to5 0.911, to7 0.697, to8 0.637, to10 0.597) share no measurable brightness, contrast or edge profile with the 5 handled correctly, which looks like noise at n=9.
- chatshot2 has 2 images and stays report-only; 1 image is worth 50 points there.
- The added data is desktop web screenshots at a uniform 1920x1080 from an English-language crawler. It does not cover mobile LINE captures, and chatshot2 improved for the general reason "a UI screenshot is usually authentic", not because LINE was represented.
- pilot11 recall on the 2 manipulated images is 0.0 for every seed, unchanged from production. Manipulated-chat detection is untouched by this work.
- production is unchanged (`server/.env` `ONNX_MODEL_PATH` still det2b), Locked Test 44,031 was never opened, and no commit was made.

### Next steps, in order
1. Collect mobile LINE and screen captures per `Det-Head/dataset_specs/chat-screenshot-v1.md`; this is now the largest known gap.
2. Promotion is a human decision. If approved: ONNX export, PyTorch/ONNX parity, seg-metric regression check, then shadow rollout. Not automatic.
3. Do not re-open architecture search on the current data; it produced 0/16 and the data change is what moved the numbers.

## 2026-09-30 — real-camera-authentic-v1 ingested; det7b passes gate on every diagnostic

### Data collected and ingested
`/home/panuwat/Pictures/Det-Head/image-Authentic` holds 157 new real-camera images (plus 11 copies of the protected holdout that are correctly not in any manifest). All 157 are from a single device (`realme-gt-neo2-5g`) across 9 sessions, median 15.93 MP, 166/168 with EXIF preserved. Split 125 train / 16 camera-val / 16 camera-test by the collector.

Corrections applied:
- The three v5 manifests pointed at `image-level/real-camera-authentic-v1/...` which no longer exists after the folder restructure; the 157 paths were remapped to `image-Authentic/<stem>.jpg` and the originals backed up as `*.stale-path-backup`.
- `validate_camera_authentic_incoming.py` reported 11 holdout overlaps in the folder; verified that no manifest row references any of them, so camera9/chatshot2 remain protected.

### Data moved off USB
The whole Det-Head data root was copied to `/home/panuwat/Pictures/Det-Head`. This removed the I/O bottleneck: full-data training went from 180 s/epoch (USB) to 43 s/epoch (NVMe), so a 30-epoch run now takes ~21 min instead of ~90. NVMe has 58 GB free, USB has 38 GB free at 96%.

### det7b: det7a plus 125 real-camera rows
| | det2b (production) | det7a | det7b |
|---|---|---|---|
| Val accuracy | 85.93% | **86.29%** | 86.06% |
| Val ROC-AUC | 94.05% | 94.42% | 94.27% |
| camera9 specificity | 33.33% | 55.56% | **88.89%** |
| chatshot2 accuracy | 0/2 | 1/2 | **2/2** |
| pilot11 accuracy | 54.55% | 72.73% | 72.73% |
| testcases accuracy | 86.06% | 86.06% | **87.27%** |
| testcases specificity | 86.67% | 88.89% | **91.11%** |
| camera-val 16 (report-only) | 62.50% | 81.25% | **100.00%** |
| gate | baseline | PASS | **PASS** |

125 label0 camera rows improved camera9 by 33.3 points over det7a, recovered chatshot2 to 2/2, and simultaneously raised testcases accuracy and specificity. Val accuracy fell slightly, which the r=-0.037 finding says is uninformative. The single remaining camera9 false positive is `to5` at 0.739.

### Limitations that must travel with this number
- camera9 is 9 images; 88.89% is 8/9 and one image is worth 11.1 points.
- camera-val 16 is 100% but comes from the same single device and the same collection as the 125 training rows, so it is a within-collection holdout rather than independent evidence. It must not be read as general real-camera coverage.
- The device is one model. Whether the camera9 gain generalises to iPhone or Samsung input is untested and is the main open risk.
- The 125 camera rows are label 0 only; there are no manipulated-camera examples.
- chatshot2 is still 2 images; pilot11 recall on the 2 manipulated images is still 0.0.

### Incident
The first det7b run was killed by `systemd-oomd` after epoch 10 because a concurrent `eval_det_diagnostics.py` on 15.93 MP images caused memory pressure on a machine that was already swapping. Rerun alone with 2 workers and it completed 30 epochs. Lesson recorded: do not run diagnostics while full-data training is in progress on this machine.

## 2026-09-30 — Cross-device holdout added as a gate; det7b confirmed 3/3 seeds

### New holdout: cameraxdev104
`/home/panuwat/Pictures/inport/2` (104 files) was copied to `Pictures/Det-Head/image-Authentic1/` as `to169.jpg`..`to272.jpg`, keeping the original `IMG_*` name and derived session date in the manifest for provenance. Verified: 104/104 byte-identical after copy, all decode, 0 duplicates within the set, 0 overlap with the protected camera9/chatshot2 holdout, 0 byte overlap with the existing 168-file collection, and 0 decoded-pixel overlap with the 125 rows already used for training.

The set is a different capture pipeline from the training collection: 12.58 MP (4096x3072 x60, 3072x4096 x44), 44 sessions, versus 15.93 MP from a single device for the training rows. EXIF Make/Model is stripped to `"--"` on all 104, so the second device cannot be named from metadata; the differing resolution profile is the only device evidence. Manifest: `manifests/det-camera-xdev-v1.csv`, all label 0, holdout only.

### Why it is now a gated metric
`camera9` has 9 images, so one image moves it 11.1 points and it varied 0.6667-0.8889 across three seeds. `cameraxdev104` has 104 images, so one image is worth 0.96 points, and it comes from a pipeline that was never trained on. It is added to `GATED_METRICS` in `run_det_loop.py`, raising the production floor to 0.2981 for that metric. The production head passes its own floor on all four metrics at exact float equality.

### Cross-device result: the gain generalises
| | det2b (production) | det7a | det7b (seed 42) |
|---|---|---|---|
| cameraxdev104 specificity | 29.81% (73/104 FP) | 58.65% | **86.54% (14/104 FP)** |

det7b is trained only on 15.93 MP realme rows and reaches 86.54% on 12.58 MP images from a different pipeline, a +56.7 point gain over production with two-proportion z = 8.29 and Wilson 95% CI 0.770-0.911. This rules out the device-memorisation risk that was the main open concern after the first det7b result.

It also exposes a production problem that was previously invisible: **the deployed head flags 73 of 104 authentic photos (70.19%) as manipulated** on this set. No cross-device real-camera set existed before, so camera9's 33.33% was the only signal and did not convey the severity.

### det7b multiseed, with the stricter gate
| seed | Val | camera9 | cameraxdev104 | pilot11 | testcases | gate |
|---|---|---|---|---|---|---|
| det2b (production) | 85.93% | 33.33% | 29.81% | 54.55% | 86.06% | baseline |
| 42 | 86.06% | 88.89% | 86.54% | 72.73% | 87.27% | PASS |
| 7 | 86.27% | 66.67% | 77.88% | 63.64% | 87.27% | PASS |
| 123 | 86.46% | 66.67% | 77.88% | 72.73% | 87.88% | PASS |

cameraxdev104 min 0.7788 / mean 0.8077; the worst seed still clears the production floor by 48.1 points. testcases mean 0.8747, above every previous candidate and above production.

### Operational note found while running this
Full-data training reads the whole feature cache each epoch. The cache is ~14 GB on a 15.6 GB machine with ~6.5 GB available, so it cannot stay resident in page cache and every epoch re-reads from disk (~420 GB over 30 epochs). Epoch time varied from 43 s to 155 s purely with swap pressure: seed123 took 26 min while swap had 2.6 GB free, seed7 took 69 min when swap was completely full. This is a capacity problem, not a configuration problem, and it was not anticipated before starting. Mitigation for future runs: shrink the token cache (64x1024 to 16x1024 fits in RAM), quantise it, or add RAM.

### Remaining limitations
- `cameraxdev104` is a single collection from a single unknown device. A third device would confirm further.
- `camera9` at n=9 remains fragile and is now the least reliable gated metric; `cameraxdev104` carries most of the real-camera signal.
- The 125 camera training rows are label 0 only; there are still no manipulated-camera examples.
- pilot11 recall on the 2 manipulated images is 0.0 for all three seeds. Nothing in this work improved manipulated-photo or manipulated-chat detection.
- chatshot2 is still 2 images and report-only.
- Production unchanged, Locked Test 44,031 unopened, no commit.

## 2026-09-30 — det7b ONNX export works at 512, and a dynamic-axes defect was found and guarded

### Export fixed and passing at the tile size
`export_onnx_dynamic.py` used `det_head.load_det`, which only knows the pooled archs and raised `ValueError: unknown Det Head arch: token_stats` for det7b. It now uses `eval_det_diagnostics.load_any_det`, which dispatches on the arch recorded in the checkpoint meta and therefore covers the pooled, Det5/Det6 local-token and token_stats families.

Export produced `Det-Head/det_v1.0.6_det7b_webshot_camera/segformer_v1_0_6_det7b_dynamic.onnx` with 2 outputs (`logits`, `det_logit`) and dynamic H/W. Parity at 512 on real images from four domains: seg max abs diff 3.7e-05, det logit abs diff 1.4e-05. PASS.

### Defect: the fixed-grid local-token head has no working dynamic axes
Parity at other input sizes fails, and the cause is not numerical noise.

| input | seg max abs diff | det logit abs diff | ONNX token count |
|---|---|---|---|
| 512 | 3.1e-05 | 9.1e-06 | 64 (correct) |
| 640 | 7.0e-05 | **0.689** | 100 |
| 896x640 | 6.7e-05 | **0.355** | - |
| 1024 | 6.5e-05 | **0.285** | 256 |
| 1280 | 6.7e-05 | **0.660** | - |
| 1536 | 5.1e-05 | **0.017** | 576 |

The traced graph bakes in the token grid derived from the export-time input size, so at other sizes it emits 100/256/576 tokens instead of 64. `TokenStatsHead.forward_tokens` guards with `tokens.shape[1] != self.num_tokens`, but that is a Python check that runs only while tracing, so at runtime the graph feeds 576 tokens through a head sized for 64 and returns a plausible wrong number.

Scope is narrow and was verified rather than assumed: the seg branch of the same graph is correct at every size (max abs diff <= 7.0e-05), and the production pooled det2b head is correct at every size (det logit abs diff <= 4.4e-06) because it reduces to a single token. Only the local-token family is affected.

An attempt to fix it with `F.interpolate(size=(8,8), mode="area")` was made and reverted: it is bit-identical in PyTorch (max abs diff 0.0 on real backbone features at 512/640/1024/1536, and the trained head's output was unchanged to 0.0 on real images) and it lowers to a dynamic `Resize` op, but it produced the same 100/256/576 token counts, so the pooling op is not the cause. The change was reverted to keep the training-validated code path untouched, and the limitation is documented in `det6_local.local_stage_tokens` and `det5_local.local_stage_tokens`.

### Production impact today: none, and now guarded
`tiling.det_score_image` and `tiling.iter_tiles` both resize to `ONNX_TILE_SIZE` (512), which is the traced size, so current serving is correct. The hazard is that changing the tile size with a 2-output model would silently return wrong det scores. `server/app/services/tiling.py` now defines `DET_EXPORT_TILE_SIZE = 512` and `det_score_image` returns `None` with a stderr message when a 2-output model is called with any other tile size, because a wrong det score is worse than no det score. Verified: 512 returns a score, 640 and 1024 return `None`, and the pooled det2b path is unaffected. Server suite 139 passed / 4 skipped / 0 failed.

### Status
det7b is exportable and parity-clean at the size production actually uses, but it carries a constraint that the pooled det2b head does not: the ONNX det output is only valid at 512. Promotion therefore has a real cost, namely that changing `ONNX_TILE_SIZE` becomes a breaking change. The open alternative is to keep the pooled architecture and fix the false positives with data or loss only, which the 16-candidate architecture search did not achieve.

Not done: seg-metric regression on the exported graph (blocked behind the multi-resolution parity failure; should be run at 512 only if promotion proceeds), shadow rollout, any `ONNX_MODEL_PATH` change, any commit. Locked Test 44,031 unopened.
