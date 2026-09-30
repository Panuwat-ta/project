# Det Head search loop — result, 2026-09-29

## What was run

12 candidates on the already-computed 64-token Det6 cache
(`v1.0.6-det6-local8x8-audited`). No new precompute, no production change, no
Locked Test access.

Artifacts:

- plan: `Det-Head/search_plan_2026-09-29.json`
- results: `Det-Head/search_runs/2026-09-29/results.json`
- leaderboard: `Det-Head/search_runs/2026-09-29/leaderboard.csv`
- per-candidate logs: `Det-Head/search_runs/2026-09-29/<candidate>/`

## Result: 0 of 12 passed the gate

| candidate | arch | Val acc | Val AUC | camera11 spec | pilot11 acc | testcases acc | gate |
|---|---|---|---|---|---|---|---|
| BASELINE det2b (production) | mlp | 85.93% | 94.05% | **27.27%** | **54.55%** | **86.06%** | production |
| s01 token_stats | token_stats | 82.91% | 92.18% | 18.18% | 27.27% | 84.24% | fail |
| s06 token_stats do0.3 | token_stats | 83.04% | 92.11% | 18.18% | 36.36% | 83.03% | fail |
| s00 control patch_attention 8x8 | patch_attention | 83.31% | 92.44% | 18.18% | 45.45% | 84.24% | fail |
| s09 token_stats hardneg1.5 | token_stats | 82.77% | 91.96% | 18.18% | 36.36% | 84.85% | fail |
| s02 token_stats_coarse | token_stats_coarse | 83.09% | 92.18% | 9.09% | 36.36% | 83.03% | fail |
| s03 spatial_pyramid | spatial_pyramid | 83.91% | 92.73% | 9.09% | 27.27% | 84.24% | fail |
| s04 token_stats_topk k=4 | token_stats_topk | 82.33% | 91.64% | 9.09% | 27.27% | 83.03% | fail |
| s05 token_stats_topk k=8 | token_stats_topk | 82.53% | 91.54% | 9.09% | 18.18% | 80.00% | fail |
| s07 token_stats lr3e-4 | token_stats | 84.02% | 92.96% | 9.09% | 9.09% | 83.64% | fail |
| s08 token_stats seed7 | token_stats | 83.45% | 92.19% | 9.09% | 27.27% | 84.24% | fail |
| s11 spatial_pyramid do0.3 lr3e-4 | spatial_pyramid | 82.96% | 91.99% | 9.09% | 36.36% | 83.03% | fail |
| s10 patch_attention hardneg1.5 | patch_attention | 83.19% | 92.37% | 9.09% | 36.36% | 84.24% | fail |

Every candidate failed all three external gates. The best candidate reached
18.18% camera11 specificity against the production 27.27%.

## Why Val accuracy must not select a candidate

Across these 12 candidates the correlation between Val ranking metrics and
real-camera specificity is essentially zero:

- `pearson r(Val ROC-AUC, camera11 specificity) = -0.037`
- `pearson r(Val AP, camera11 specificity) = -0.037`

s07 has the best Val AUC of the whole search (92.96%) and one of the worst
camera11 results (9.09%). s09 is mid-table on Val and mid-table on camera11.
Ranking by Val would have selected a candidate that is worse in production than
the head that is already deployed.

This is now confirmed on three separate occasions: det3–det6g (6 prior
candidates), the det2b/det5a/det6a full-data comparison, and this 12-candidate
search.

## The hypothesis that was tested and rejected

The 2026-09-29 full-data diagnostic showed the ranking

    det2b  1 global GAP token   camera11 27.27%
    det6a  64 local 8x8 tokens  camera11 18.18%
    det5a  16 local 4x4 tokens  camera11  9.09%

which suggested the Authentic signal is global rather than local, and that a
head reducing local tokens to global statistics should help. Four such heads
were built and tested (`token_stats`, `token_stats_coarse`, `token_stats_topk`,
`spatial_pyramid`), alongside the local-attention control and regularisation
and hard-negative variants.

None of them beat the control on camera11. The global-aggregation hypothesis is
not supported.

## Caveat on protocol

These are screening numbers: 24,999 stratified Train rows, 12 epochs, versus the
95,635-row full protocol used for det2b/det5a/det6a. Screening Val accuracy is
therefore NOT comparable to the baseline Val column and is not evidence of a
regression there. The camera11 / pilot11 / testcases columns ARE comparable,
because every candidate and the baseline were scored by the same
`eval_det_diagnostics.py` on the same image files.

Reproducibility check: re-running `eval_det_diagnostics.py` on the three
existing heads returned exactly the numbers recorded by the earlier ad-hoc
runs (det2b camera11 27.27%, det5a 9.09%, det6a 18.18%, det2b testcases 86.06%,
det5a testcases 86.67%).

## Conclusion and next step

The loop works and is reproducible, and its answer is negative: no head
architecture reachable from the current training set closes the real-camera gap.
The best available Det head remains the production `det2b`.

The blocker is the training data, not the head. The 2026-09-29 audit found the
Authentic Train domain is dominated by low-resolution web-like images
(~0.27 MP median, no camera EXIF) while real camera input is ~12.58 MP. No
architecture over that data can learn the real-camera Authentic distribution.

The next step is the data work already specified in
`Det-Head/dataset_specs/real-camera-authentic-v1.md`: collect verified
direct-camera Authentic images with the protected 11-image holdout excluded, and
re-run this loop afterwards. Re-running the loop on the current data is not
worth further budget.
