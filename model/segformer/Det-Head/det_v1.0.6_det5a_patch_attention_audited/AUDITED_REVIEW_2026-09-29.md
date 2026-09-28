# Det5-A Audited Review — 2026-09-29

## Scope
- SegFormer v1.0.6 frozen
- Det5 patch_attention, 16 x 1024-D local tokens
- Audited Train: 95,635 rows
- Excluded: 135 PSBattles source-original rows with unverified camera-pristine provenance
- No relabel was performed
- Val remains 11,972 clean-v2 rows
- Locked Test 44,031 was NOT opened

## Validation @ 0.5
- Accuracy: 86.385%
- F1: 86.165%
- ROC-AUC: 94.359%
- AP: 95.031%
- Recall: 84.826%
- Specificity: 87.943%
- Macro dataset accuracy: 87.095%

Compared with pre-audit Det5-A, sparse-manipulation recall improved but Authentic specificity fell.
## Development diagnostics @ 0.5
- Fresh camera Authentic 11: 1/11 correct, specificity 9.09%
- Pilot11: 3/11 correct
- Test-Cases165: 143/165 = 86.67%

Validation-only threshold calibration selected 0.631 to recover specificity.
At 0.631:
- Fresh camera Authentic 11: 3/11 correct
- Pilot11: 4/11 correct
- Test-Cases165: 138/165 = 83.64%

## Decision
Reject this audited seed42 candidate before Locked Test.
Do not promote and do not open the 44,031-image Locked Test.
Keep production/shadow on det2-b.
The failure is not threshold-only; next work should investigate real-camera Authentic domain coverage and training stability.
## Multi-seed stability
Audited patch_attention was repeated with seeds 42, 7, and 123.
Val accuracy was tightly grouped at 86.335%–86.385%, but real-world diagnostics failed for all seeds.

Fresh-camera specificity:
- seed42: 9.09%
- seed7: 18.18%
- seed123: 27.27%

Pilot manipulated recall was 0% for all three seeds.
This rules out a single bad seed as the main explanation.

## Authentic domain audit
A 1,000-image sample of the main Authentic Train source had median resolution ~0.274 MP and no camera make/model EXIF in the sample. Fresh camera11 had median ~12.58 MP; 81.8% were >=8 MP.
The training Authentic domain is therefore dominated by low-resolution/web-like inputs and does not represent current smartphone-camera inputs well.