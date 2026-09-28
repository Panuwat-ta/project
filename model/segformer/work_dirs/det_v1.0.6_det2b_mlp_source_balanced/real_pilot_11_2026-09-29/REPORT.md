# Real-user pilot — 11 scans (2026-09-29)

Ground truth supplied by user:
- Original1–Original9 = Authentic (9)
- Manipulated1–Manipulated2 = Manipulated (2)

## Det Head v2-b @ threshold 0.5

- TP=0, TN=6, FP=3, FN=2
- Accuracy = 54.55%
- Recall = 0.00%
- Specificity = 66.67%
- The two manipulated pilot images were both missed.

## SegFormer max-pixel image decision @ threshold 0.5

- TP=0, TN=0, FP=9, FN=2
- Accuracy = 0.00%
- All 9 originals were flagged high by max-pixel score.
- Both manipulated images were scored low.

This is a small pilot and must not be used to tune thresholds. It is sufficient to block risk-score fusion until the domain-shift/error causes are understood.
## Per-image results

| Image | GT | Det score | Det | Seg max | Visual | Seg |
|---|---|---:|---|---:|---:|---|
| Original1 | O | 0.5616 | FP | 0.9910 | 99 | FP |
| Original2 | O | 0.4844 | TN | 0.9751 | 98 | FP |
| Original3 | O | 0.9134 | FP | 0.9993 | 100 | FP |
| Original4 | O | 0.4941 | TN | 0.8931 | 89 | FP |
| Original5 | O | 0.4277 | TN | 0.9690 | 97 | FP |
| Original6 | O | 0.4049 | TN | 0.9603 | 96 | FP |
| Original7 | O | 0.8017 | FP | 0.8723 | 87 | FP |
| Original8 | O | 0.1892 | TN | 0.9924 | 99 | FP |
| Original9 | O | 0.1905 | TN | 0.9022 | 90 | FP |
| Manipulated1 | M | 0.2914 | FN | 0.1152 | 12 | FN |
| Manipulated2 | M | 0.0027 | FN | 0.1105 | 11 | FN |

## Runtime

- CUDA: 11/11
- Worker timeout: 0/11
- ONNX latency p50: 4.573 s
- ONNX latency p95: 5.201 s
- Seg/Det disagreement: 6/11

Next action: inspect the 5 Det Head errors and SegFormer heatmaps against the actual pilot images before changing threshold, training data, or fusion policy.

## Internet-sourced manipulated samples

- `Manipulated1` corresponds to `/home/panuwat/project/server/tests/test2.png` (500x375).
- `Manipulated2` corresponds to `/home/panuwat/project/server/tests/test1.png` (500x456).
- Both were downloaded from the internet and used by the user as manipulated/composite pilot examples.
- Visual inspection shows obvious composite/photomontage content, but original edit provenance and source masks are unavailable.
- Mobile upload re-encoded both images slightly; evidence dimensions match and pixel differences remain small.
- These two samples are valid for this pilot's semantic manipulated label, but should not be treated as forensic pixel-mask ground truth.
