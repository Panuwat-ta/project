# Det5-A Patch Attention — Pre-Audit Review

## Scope
- SegFormer v1.0.6 frozen; no backbone fine-tuning.
- Local representation: 4x4 grid = 16 patches/image.
- Each patch token = 1024-D concatenated 4-stage MiT-B2 feature.
- Head: patch attention + image-level classifier.
- Train: 95,770 clean-v2 rows; Val: 11,972 clean-v2 rows.
- Source-balanced sampling, seed 42, threshold 0.5.
- Label Audit was not yet complete when this representation experiment was trained.
- Locked Test 44,031 was NOT opened.

## Validation
| Metric | det2-b | det4-c | Det5-A |
|---|---:|---:|---:|
| Accuracy | 85.93% | 86.27% | 86.37% |
| F1 | 85.37% | 85.84% | 85.73% |
| ROC-AUC | 94.05% | 94.22% | 94.33% |
| AP | 94.82% | 94.98% | 95.07% |
| Macro dataset accuracy | 85.37% | 86.83% | 85.78% |
| Overall specificity | 89.70% | — | 90.83% |
| Overall recall | 82.15% | — | 81.90% |
## Validation by important dataset
- Authentic: 91.19% (det2-b 91.62%).
- CopyMove: 58.26% (det2-b 57.43%).
- Inpainting: 71.50% (det2-b 70.67%).
- PSBattles: 80.08% (det2-b 80.84%).
- RealText: 82.37% (det2-b 78.02%).
- Splicing: 91.17% (det2-b 90.00%).

## Development diagnostics
### Fresh real-camera authentic 11
- det2-b: 3/11 authentic correct; specificity 27.27%.
- Det5-A: 6/11 authentic correct; specificity 54.55%.
- These images were not used for training.

### Existing Pilot11
- det2-b: 6/11 correct.
- Det5-A: 6/11 correct.
- Original1 improved: 0.5616 -> 0.2135.
- Original2 regressed: 0.4844 -> 0.9169.
- Original3 remains FP: 0.9134 -> 0.6194.
- Original7 remains FP: 0.8017 -> 0.9222.
- Manipulated1 improved: 0.2914 -> 0.4850, but remains below 0.5.
- Manipulated2: 0.0027 -> 0.0164, still a strong FN.
### Test-Cases 165
- det2-b: 142/165 = 86.06%.
- Det5-A: 143/165 = 86.67%.
- Det5-A precision 97.12%, recall 84.17%, specificity 93.33%, F1 90.18%.
- Compared with det2-b, false positives decrease but recall decreases slightly.

## Current decision
Det5-A is the preferred Det5 representation candidate before Label Audit completion.
It provides evidence that local spatial features help, especially on fresh camera negatives,
without changing the SegFormer localization backbone.

Do NOT promote to production/shadow yet. Do NOT open the locked 44,031-image Test yet.
First finish the remaining semantics review and rebuild an audited training manifest, then
retrain the selected Det5 architecture from scratch on the audited Train set and select
again using the existing clean Validation protocol.
