# Test-Cases Shadow Evaluation

- Input: `/home/panuwat/Pictures/Test-Cases`
- Samples: 165 (45 authentic / 120 manipulated)
- ONNX: `/home/panuwat/project/model/segformer/Det-Head/det_v1.0.6_det3c_hard1p5/segformer_v1_0_6_det3c_dynamic.onnx`
- Providers: ['CUDAExecutionProvider', 'CPUExecutionProvider']
- Threshold: 0.5

## Det Head image-level

- Accuracy: 0.8606
- Precision: 0.9450
- Recall: 0.8583
- Specificity: 0.8667
- F1: 0.8996
- ROC-AUC: 0.9491
- AP: 0.9817
- TP/TN/FP/FN: 103/39/6/17

## Seg-vs-Det disagreement

{"count": 36, "seg_high_det_low": 26, "seg_low_det_high": 10}

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
- inpainting: 0.7333 (n=15)
- pairs: 0.7833 (n=60)
- splicing: 0.9333 (n=15)

## Runtime

- Mean: 392.1 ms/image
- P50: 206.0 ms
- P95: 1608.3 ms
- Total: 64.9 s

> This is pre-production test data and is not appended to the real-user shadow telemetry log.
