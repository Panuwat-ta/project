# Test-Cases Shadow Evaluation

- Input: `/home/panuwat/Pictures/Test-Cases`
- Samples: 165 (45 authentic / 120 manipulated)
- ONNX: `/home/panuwat/project/model/segformer/Det-Head/det_v1.0.6_det7b_webshot_camera/segformer_v1_0_6_det7b_dynamic.onnx`
- Providers: ['CUDAExecutionProvider', 'CPUExecutionProvider']
- Threshold: 0.5

## Det Head image-level

- Accuracy: 0.8727
- Precision: 0.9626
- Recall: 0.8583
- Specificity: 0.9111
- F1: 0.9075
- ROC-AUC: 0.9537
- AP: 0.9830
- TP/TN/FP/FN: 103/41/4/17

## Seg-vs-Det disagreement

{"count": 36, "seg_high_det_low": 27, "seg_low_det_high": 9}

## SegFormer localization (with_mask 105)

- mIoU: 0.8314
- mDice: 0.9017
- Forgery IoU: 0.6935
- Forgery Dice: 0.8190
- Pixel Accuracy: 0.9713

## Per dataset Det accuracy

- authentic: 1.0000 (n=15)
- casia: 1.0000 (n=15)
- copymove: 0.8667 (n=15)
- face: 1.0000 (n=15)
- imd2020: 0.8000 (n=15)
- inpainting: 0.6667 (n=15)
- pairs: 0.8333 (n=60)
- splicing: 0.9333 (n=15)

## Runtime

- Mean: 392.3 ms/image
- P50: 208.1 ms
- P95: 1568.6 ms
- Total: 65.0 s

> This is pre-production test data and is not appended to the real-user shadow telemetry log.
