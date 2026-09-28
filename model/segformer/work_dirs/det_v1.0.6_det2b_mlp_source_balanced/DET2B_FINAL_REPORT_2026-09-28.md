# Det Head v2-b Final Evaluation

## Candidate

- SegFormer backbone: v1.0.6 (frozen)
- Det Head: MLP 1024→256→64→1, GELU, dropout 0.2
- Sampling: sqrt source-balanced within label
- Threshold: 0.5 (not tuned on test)
- Checkpoint SHA-256: `72c6f5513130a72fab99061fa4123ebfcc7136be6cc9b3d56a06e54ef16cc799`

## Leakage audit and clean split

- Audited 151,815 Train/Val/Test rows.
- Exact byte hash found 1 cross-split conflicting-label group.
- Decoded-pixel audit found 41 cross-split duplicate groups total.
- 40 groups were same-label duplicates, mainly PSBattles ↔ IMD2020.
- 1 group was conflicting-label Authentic ↔ CopyMove and was quarantined from both train/val sides.
- Policy for same-label duplicates: keep priority Test > Val > Train; remove lower-priority duplicate from training/validation only.
- Clean counts: Train 95,770; Val 11,972; Test 44,031. Test set was not modified.

## Validation selection

| Model | Val Accuracy | Val F1 | Val ROC-AUC | Val AP | Macro dataset Acc |
|---|---:|---:|---:|---:|---:|
| det1 linear | 79.18% | 78.72% | — | — | 76.19% |
| det2-a MLP | 84.99% | 84.58% | 93.54% | 94.36% | 84.28% |
| det2-b MLP + source-balanced | **85.93%** | **85.37%** | **94.05%** | **94.82%** | **85.37%** |

## Final test: det1 vs det2-b

| Metric | det1 | det2-b | Delta |
|---|---:|---:|---:|
| Accuracy | 85.35% | **89.79%** | +4.44 pp |
| F1 | 88.48% | **92.22%** | +3.74 pp |
| Precision | 94.68% | **95.41%** | +0.72 pp |
| Recall | 83.04% | **89.23%** | +6.19 pp |
| Specificity | 90.20% | **90.97%** | +0.77 pp |
| ROC-AUC | 93.66% | **96.46%** | +2.80 pp |
| Average Precision | 97.05% | **98.45%** | +1.40 pp |
| Macro dataset Accuracy | 77.56% | **85.47%** | +7.90 pp |

Confusion matrix for det2-b:

- TP: 26,625
- TN: 12,912
- FP: 1,282
- FN: 3,212

## Per-dataset final test

| Dataset | det1 Acc | det2-b Acc | Delta |
|---|---:|---:|---:|
| aiforge | 76.18% | **99.84%** | +23.65 pp |
| authentic | 93.93% | **91.49%** | -2.44 pp |
| casia | 90.11% | **90.74%** | +0.63 pp |
| copymove | 55.43% | **61.40%** | +5.97 pp |
| face | 99.88% | **99.85%** | -0.02 pp |
| imd2020 | 95.41% | **94.63%** | -0.78 pp |
| inpainting | 53.93% | **71.21%** | +17.28 pp |
| psbattles | 73.81% | **79.37%** | +5.56 pp |
| realtext | 57.04% | **74.96%** | +17.92 pp |
| splicing | 79.91% | **91.18%** | +11.27 pp |

## Status

- `det2-b` is the selected Det Head candidate based on clean Validation metrics before Final Test.
- Final Test confirms improved generalization versus det1.
- Do not tune threshold or architecture further using this Test set.
- Not yet integrated into the production server. Next gate is export/integration plus regression testing that segmentation output remains unchanged.

## Export / Server integration gate

- Exported dynamic ONNX with outputs `logits` and `det_logit`.
- Actual ONNX opset: 18. Current PyTorch exporter cannot down-convert `Resize` to opset 17, so exporter default was updated to 18.
- Artifact pair must stay together: `.onnx` + `.onnx.data`.
- PyTorch base segmentation vs DetSegWrapper: exact match, max abs diff `0.0`.
- PyTorch vs ONNX @512: segmentation max abs diff <= `1.36e-5`, det logit abs diff <= `8.11e-6`.
- Dynamic @640: segmentation max abs diff <= `1.57e-5`, det logit abs diff <= `1.44e-6`.
- Server production-style environment successfully loads `CUDAExecutionProvider`.
- Real worker smoke: CASIA authentic `det_score≈0.149`; AIForge manipulated `det_score≈0.979`; heatmap/results returned normally.
- Server ONNX/tiling unit regression: `11 passed`.
- Server has Track-B-compatible output handling already; `det_score` is returned but not yet fused into the total risk score.

### Artifact hashes

- `det_head.pth` SHA-256: `72c6f5513130a72fab99061fa4123ebfcc7136be6cc9b3d56a06e54ef16cc799`
- `segformer_v1_0_6_det2b_dynamic.onnx` SHA-256: `ddd1195c6bf955fca187661c16530ef3da4dd3e2d9d0f7cdac631ef388344fa3`
- `segformer_v1_0_6_det2b_dynamic.onnx.data` SHA-256: `90f318f6d7af0be878cc7f1d370c39f38d630d5456dfd624697d5af72c168b5a`

Deployment metadata is also stored in `deployment_manifest.json`.

## Shadow-mode server wiring

- `InferenceService.predict()` now forwards `det_score` from the ONNX worker into the internal inference result.
- Scan cache stores the whole inference dict, so `det_score` is retained in Redis shadow cache automatically.
- `scan_service` still calls `calculate_risk_score(text_score, visual_score, source_score)` exactly as before; Det Head does not alter the user-facing risk score.
- No DB migration or public API field was added.
- Focused server regression suite: `19 passed`.
- The running server has **not** been promoted/restarted and `ONNX_MODEL_PATH` has not been changed by this work.
