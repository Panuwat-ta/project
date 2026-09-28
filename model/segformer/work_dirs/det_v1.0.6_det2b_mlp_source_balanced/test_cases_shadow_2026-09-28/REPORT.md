# Test-Cases Shadow Evaluation

- Input: `/home/panuwat/Pictures/Test-Cases`
- Samples: 165 (45 authentic / 120 manipulated)
- ONNX: `/home/panuwat/project/model/segformer/work_dirs/det_v1.0.6_det2b_mlp_source_balanced/segformer_v1_0_6_det2b_dynamic.onnx`
- Providers: ['CUDAExecutionProvider', 'CPUExecutionProvider']
- Threshold: 0.5

## Det Head image-level

- Accuracy: 0.8606
- Precision: 0.9450
- Recall: 0.8583
- Specificity: 0.8667
- F1: 0.8996
- ROC-AUC: 0.9424
- AP: 0.9795
- TP/TN/FP/FN: 103/39/6/17

## Seg-vs-Det disagreement

{"count": 34, "seg_high_det_low": 25, "seg_low_det_high": 9}

## SegFormer localization (with_mask 105)

- mIoU: 0.8314
- mDice: 0.9017
- Forgery IoU: 0.6935
- Forgery Dice: 0.8190
- Pixel Accuracy: 0.9713

## Per dataset Det accuracy

- authentic: 1.0000 (n=15)
- casia: 1.0000 (n=15)
- copymove: 0.8000 (n=15)
- face: 1.0000 (n=15)
- imd2020: 0.8667 (n=15)
- inpainting: 0.6667 (n=15)
- pairs: 0.8000 (n=60)
- splicing: 0.9333 (n=15)

## Runtime

- Mean: 413.0 ms/image
- P50: 211.3 ms
- P95: 1708.5 ms
- Total: 68.5 s

> This is pre-production test data and is not appended to the real-user shadow telemetry log.

## Detailed error analysis

- Det errors: 23/165 = 6 FP + 17 FN.
- All 6 false positives are from `pairs/originals`.
- False negatives: pairs 6, CopyMove 3, IMD2020 2, Inpainting 5, Splicing 1.
- CASIA 15/15, Face 15/15, and with-mask Authentic 15/15 were correct at threshold 0.5.
- Seg-vs-Det disagreement: 34 cases.
  - Seg high / Det low: 25 cases; Det was correct in 17 and Seg was correct in 8.
  - Seg low / Det high: 9 cases; Det was correct in all 9.

## Matched pair check

- 30 original/manipulated pairs were compared directly.
- Manipulated det score was higher than its paired original in 29/30 pairs (96.67%).
- Mean det score: original 0.2521, manipulated 0.7585.

## SegFormer regression check

Compared with the previous v1.0.6 local105 baseline, the production two-output ONNX result differs only by tiny numerical amounts:

| Metric | previous v1.0.6 | current two-output ONNX | delta (pp) |
|---|---:|---:|---:|
| mIoU | 83.144645% | 83.142511% | -0.002134 |
| mDice | 90.173975% | 90.172507% | -0.001468 |
| Forgery IoU | 69.353856% | 69.349809% | -0.004047 |
| Forgery Dice | 81.904077% | 81.901255% | -0.002822 |
| Pixel Accuracy | 97.134186% | 97.133958% | -0.000228 |

This confirms no practical segmentation regression from adding Det Head v2-b to the ONNX graph.
