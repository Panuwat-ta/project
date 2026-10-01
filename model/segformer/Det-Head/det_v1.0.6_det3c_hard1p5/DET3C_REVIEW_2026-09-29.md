# Det Head v3-c Review — 2026-09-29

## Decision

`v1.0.6+det3c-hard1p5` is **not approved for shadow promotion**.
The active server shadow model remains `v1.0.6+det2b-mlp-source-balanced`.
No production ONNX path was changed during this evaluation.

## Training protocol

- SegFormer v1.0.6 backbone and segmentation head remained frozen.
- Base Det Head: det2-b MLP.
- Clean Train: 95,770 images.
- Clean Val: 11,972 images.
- Hard mining used Train only; no Test/Test-Cases/pilot image was mined.
- Train hard examples: 18,977.
- Hard boost: 1.5x with source-balanced sampling and 50/50 class mass.
- Model selection was performed using clean Val only.

## Clean validation

| Metric | det2-b | det3-c |
|---|---:|---:|
| Accuracy | 85.93% | 86.18% |
| F1 | 85.37% | 85.77% |
| ROC-AUC | 94.05% | 94.24% |
| AP | 94.82% | 94.98% |
| Macro dataset accuracy | 85.37% | 86.16% |
## Held-out Test (44,031)

| Metric | det2-b | det3-c | Delta |
|---|---:|---:|---:|
| Accuracy | 89.79% | 89.93% | +0.14 pp |
| Precision | 95.41% | 94.39% | -1.02 pp |
| Recall | 89.23% | 90.53% | +1.29 pp |
| Specificity | 90.97% | 88.69% | -2.28 pp |
| F1 | 92.22% | 92.42% | +0.20 pp |
| Macro dataset accuracy | 85.47% | 86.23% | +0.76 pp |

Large gains were concentrated in CopyMove, Inpainting, PSBattles and Splicing.
The cost was a clear increase in false positives on Authentic images.

## Local Test-Cases (165)

Threshold-0.5 confusion was unchanged from det2-b: TP=103, TN=39, FP=6, FN=17.
Accuracy remained 86.06%; ROC-AUC improved from 94.24% to 94.91%.
Inpainting improved from 66.67% to 73.33%, while the paired set dropped from 80.00% to 78.33%.
SegFormer localization metrics were unchanged, confirming the candidate changed only Det Head behavior.

## Real pilot (11)

The pilot contains 9 verified Original images and 2 internet-sourced manipulated photomontages.
Det2-b: TN=6 FP=3 TP=0 FN=2, accuracy 54.55%.
Det3-c: TN=5 FP=4 TP=0 FN=2, accuracy 45.45%.
Therefore the candidate regressed on the real-pilot operational check and is rejected for shadow promotion.
## Root-cause evidence

Mobile re-encoding is not the main cause of the two manipulated misses:
- test1 original det2-b ≈ 0.0058; uploaded evidence ≈ 0.0027.
- test2 original det2-b ≈ 0.2500; uploaded evidence ≈ 0.2911.

TruFor detects both manipulated examples after upload (≈0.538 and ≈0.588), so forensic signal still exists.
TruFor is diagnostic only and is not treated as ground truth or a production dependency.

Frozen-feature nearest-neighbor analysis exposes representation errors:
- Original3: top-50 SegFormer GAP neighbors are 100% manipulated.
- Original7: top-50 neighbors are 84% manipulated.
- Manipulated2/test1: top-10 and top-20 neighbors are 0% manipulated; top-50 only 2%.
- Manipulated1/test2 is mixed: top-10 60% manipulated, top-50 28%.

This means several hard cases are already on the wrong side in the frozen 1024-D GAP representation.
Further MLP-only tuning has a structural ceiling and can trade false negatives for false positives rather than solve the domain gap.

## Dataset-label finding

Stage B1 currently derives image-level labels from masks: nonzero mask = manipulated, zero mask = authentic.
This is valid for the annotated manipulation operation, but `mask=0` does not prove that an internet/source image has never been edited before entering the dataset.
Manual audit of highest-scoring Train `authentic` examples found visually ambiguous/composite-looking source images.
These rows must not be silently relabeled; they are a provenance/label-semantics audit target.
## Next action locked

Do not continue tuning the 1024-D GAP MLP family against post-selection holdouts.
The next controlled experiment is a new frozen-feature representation: `GAP + GMP` (2048-D).

Implementation status:
- `mlp_gapgmp` added without changing existing Det Head loading behavior.
- `precompute_det_features_gapgmp.py` created as a separate cache builder.
- End-to-end 32/32 smoke cache and 1-epoch training passed.
- Full clean Train/Val feature cache started at `/run/media/panuwat/USB/model/Det-Head/features/v1.0.6-det4-gapgmp`.
- Held-out Test features are intentionally not generated before Val model selection.

Additional audit artifacts:
- `Det-Head/det_v1.0.6_det2b_mlp_source_balanced/domain_label_audit_v1/audit_candidates.csv`
- 3,080 strong train-label/model conflicts queued for review; no automatic relabeling.
- `review_sample_stratified.csv` contains 225 deterministic review candidates.
- Pilot feature-neighbor evidence is under `real_pilot_11_2026-09-29/feature_neighbor_analysis/`.
