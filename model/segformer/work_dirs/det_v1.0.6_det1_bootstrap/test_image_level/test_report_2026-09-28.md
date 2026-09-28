# Det Head v1.0.6+det1-bootstrap — Image-Level Test Report

## Scope
- SegFormer baseline: `v1.0.6` / `best_mIoU_iter_195000.pth`
- Det Head: `work_dirs/det_v1.0.6_det1_bootstrap/det_head.pth`
- Threshold: `0.5` (fixed; not tuned on test)
- Test manifest: `/run/media/panuwat/USB/model/Det-Head/manifests/det-test-v1.csv`
- Samples: 44,031 (14,194 authentic / 29,837 manipulated)
- Image integrity check: 44,031/44,031 readable, 0 skipped

## Overall
- Accuracy: 85.35%
- Balanced accuracy: 86.62%
- Precision: 94.68%
- Recall: 83.04%
- Specificity: 90.20%
- F1: 88.48%
- FPR: 9.80%
- FNR: 16.96%
- ROC-AUC: 93.66%
- Average Precision: 97.05%
- Confusion: TP=24,776 TN=12,803 FP=1,391 FN=5,061

## By dataset (@0.5)
| Dataset | N | Auth | Manip | Accuracy | Recall | Specificity | F1 | ROC-AUC |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| AIForge | 613 | 0 | 613 | 76.18% | 76.18% | N/A | 86.48% | N/A |
| Authentic | 11,833 | 11,833 | 0 | 93.93% | N/A | 93.93% | N/A | N/A |
| CASIA | 1,274 | 742 | 532 | 90.11% | 88.53% | 91.24% | 88.20% | 96.54% |
| CopyMove | 1,860 | 0 | 1,860 | 55.38% | 55.38% | N/A | 71.28% | N/A |
| Face | 8,032 | 16 | 8,016 | 99.88% | 100.00% | 37.50% | 99.94% | 99.97% |
| IMD2020 | 3,727 | 0 | 3,727 | 95.41% | 95.41% | N/A | 97.65% | N/A |
| Inpainting | 2,546 | 0 | 2,546 | 53.93% | 53.93% | N/A | 70.07% | N/A |
| PSBattles | 1,978 | 989 | 989 | 73.81% | 72.60% | 75.03% | 73.49% | 82.36% |
| RealText | 1,378 | 614 | 764 | 57.04% | 68.46% | 42.83% | 63.86% | 60.48% |
| Splicing | 10,790 | 0 | 10,790 | 79.91% | 79.91% | N/A | 88.83% | N/A |

## Interpretation
The overall score is influenced by dataset composition: several test datasets contain only manipulated samples, while `Authentic` contains only authentic samples. Therefore overall accuracy alone is not sufficient for promotion.

Mixed-class datasets show:
- CASIA: strong separation.
- PSBattles: moderate generalization.
- RealText: weak separation and high false-positive rate.
- Face has only 16 authentic negatives, so its very high raw accuracy is not a reliable balanced-domain result.

CopyMove and Inpainting have high false-negative rates (44.62% and 46.07%). The current bootstrap Det Head should remain a candidate and not be promoted until these domain weaknesses are addressed and regression gates are defined.

## Artifacts
- `predictions_threshold_0.5.csv`: per-image score/prediction
- `metrics_threshold_0.5.json`: complete metrics
- `metrics_by_dataset_threshold_0.5.csv`: dataset summary
