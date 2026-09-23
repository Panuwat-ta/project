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