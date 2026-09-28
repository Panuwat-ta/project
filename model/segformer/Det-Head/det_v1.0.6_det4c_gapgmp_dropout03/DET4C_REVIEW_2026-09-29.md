# Det4-c GAP+GMP Review — 2026-09-29

## Scope

- SegFormer baseline: v1.0.6, frozen
- Feature: GAP + GMP from 4 MiT-B2 stages
- Feature size: 2048-D
- Train: 95,770
- Validation: 11,972
- Locked Test 44,031: NOT OPENED
- Pilot11: development diagnostic only

## Validation result

| Metric | det2-b | det4-c |
|---|---:|---:|
| Accuracy | 85.93% | 86.27% |
| F1 | 85.37% | 85.84% |
| ROC-AUC | 94.05% | 94.22% |
| AP | 94.82% | 94.98% |
| Macro dataset accuracy | 85.37% | 86.83% |

At threshold 0.5, det4-c improves overall and macro validation metrics, but the dedicated Authentic validation group specificity falls to about 87.06% from det2-b's 91.62%.

Threshold calibration on Validation found that about 0.585 is required to recover det2-b-level Authentic specificity, but this removes much of the CopyMove/Inpainting gain and lowers F1.
## Feature-neighbor diagnostic

Compared with the old 1024-D GAP feature:

- Original1: Top50 manipulated neighbors 42% -> 30% (improved)
- Original3: 100% -> 80% (improved, still strongly wrong-side)
- Original7: 84% -> 84% (no improvement)
- Manipulated1/test2: Top10 60% -> 30% (worse)
- Manipulated2/test1: Top50 2% -> 4% (essentially unchanged)

## Pilot11 production-like diagnostic

- det2-b: 6/11 correct
- det4-c: 6/11 correct
- Original1 fixed: 0.5616 -> 0.3272
- Original2 regressed: 0.4844 -> 0.7251
- Original3 remains FP: 0.9134 -> 0.9630
- Original7 remains FP: 0.8017 -> 0.8974
- Manipulated1 remains FN: 0.2914 -> 0.2603
- Manipulated2 remains FN: 0.0027 -> 0.0017

## Decision

Do not promote det4-c and do not open the locked 44,031-image Test for this candidate. Keep det2-b active in shadow mode. GAP+GMP is a useful ablation but does not solve the real-world domain/representation issue.

Next work should prioritize label-semantics audit and a representation that preserves local forensic evidence instead of further threshold-only tuning.
