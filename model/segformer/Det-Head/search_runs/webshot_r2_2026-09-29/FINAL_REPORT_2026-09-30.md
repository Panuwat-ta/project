# Det Head search — final result, 2026-09-30

## Headline

`det7a_webshot_tokenstats` is the first Det head candidate in 17 attempts to pass
the external gate, and it passes on the full-data protocol, not just screening.

| | production det2b | det7a |
|---|---|---|
| Val accuracy | 85.93% | **86.29%** |
| Val ROC-AUC | 94.05% | **94.42%** |
| Val average precision | 94.82% | **95.10%** |
| camera9 specificity | 33.33% (3/9) | **55.56% (5/9)** |
| chatshot2 accuracy | 0/2 | **1/2** |
| pilot11 accuracy | 54.55% | **72.73%** |
| testcases accuracy | 86.06% | 86.06% (equal) |
| testcases specificity | 86.67% | **88.89%** |
| gate | production baseline | **PASS** |

Full-data training: 103,029 rows (95,635 base + 7,394 webshot), 30 epochs, best
epoch 25, `token_stats` head 401,665 params, source-balanced sampling, seed 42.

## What actually moved the needle

The first 16 attempts all changed the *architecture* and all failed. The
seventeenth changed the *data*.

Measured on the deployed head before any retraining: 45.5% (91/200) and then
48.4% (31/64) of authentic, unmodified desktop screenshots were flagged as
manipulated at threshold 0.5, with mean score ~0.48. The two authentic LINE and
screen captures scored 0.71. The head had no usable representation of the
screenshot/UI domain, and the training manifest contained no screenshot source at
all.

Adding 7,394 authentic screenshot rows moved camera9 from 22.22% to 88.89% in
screening. That single data change produced a larger effect than nineteen
architecture experiments combined.

## The label trap that had to be avoided

`dataset_raw/phishing-screenshots/metadata.csv` labels rows `phishing` (1) or
`legitimate` (0). That is a *phishing-site* label, not a *content-manipulated*
label. A screenshot of a phishing website is still an unmodified image.

Mapping the 328 phishing rows to Det label 1 would have trained the head to
call untouched screenshots manipulated, making the measured false positives
worse. `Det-Head/build_webshot_authentic_manifest.py` therefore writes every row
as Det label 0, keeps the source label in a separate `source_label` column, and
asserts the invariant so the mapping cannot be reintroduced silently.

## Why the data change initially failed the gate

Round 1 (w00–w03) added the screenshots with plain random sampling:

| candidate | camera9 | chatshot2 | pilot11 | testcases |
|---|---|---|---|---|
| w00 control, no webshot | 22.22% | 0/2 | 45.45% | 84.24% |
| w01 patch_attention + webshot | 55.56% | 1/2 | 72.73% | 81.82% |
| w02 token_stats + webshot | 88.89% | 2/2 | 72.73% | 79.39% |
| w03 spatial_pyramid + webshot | 88.89% | 2/2 | 72.73% | 83.64% |

Screenshot false positives collapsed, but every candidate lost testcases accuracy.
The per-dataset breakdown showed this was a *recall* loss, not new false
positives: testcases false positives were identical at 7 in both w00 and w03,
while false negatives rose 19 → 20, driven by inpainting (recall 0.60 → 0.47)
and pairs (0.83 → 0.77). Sparse edits were already the known weak case from the
2026-09-29 label audit. 7,394 extra label0 rows tilted the decision boundary.

Round 2 applied `--source-balanced`, which gives every (label, dataset) group
equal expected sampling mass so the new dataset stops outweighing the
manipulation datasets:

| candidate | camera9 | chatshot2 | pilot11 | testcases | gate |
|---|---|---|---|---|---|
| x01 pyramid + webshot + balanced | 55.56% | 1/2 | 72.73% | 86.67% | PASS |
| **x02 token_stats + webshot + balanced** | 66.67% | **2/2** | **81.82%** | **86.67%** | **PASS** |
| x03 pyramid, 6 epochs | 88.89% | 2/2 | 72.73% | 83.64% | fail |
| x04 pyramid, lr 3e-4 | 55.56% | 1/2 | 72.73% | 83.64% | fail |

x02 was retrained on the full 103,029 rows and produced the table at the top.
Note the screening and full-data numbers differ, which is why the protocol
required re-running: screening camera9 was 66.67% and full-data camera9 is
55.56%, while screening testcases was 86.67% and full-data testcases is 86.06%.

## Honest limitations

- **camera9 is 9 images.** One image moves the metric 11.1 percentage points.
  The 55.56% figure is coarse, and the 4 images still flagged as manipulated
  (to5 0.911, to7 0.697, to8 0.637, to10 0.597) do not share a measurable
  brightness, contrast or edge profile with the 5 correctly handled ones, so
  this looks like noise at n=9 rather than a structured signal.
- **chatshot2 is 2 images and is report-only by design.** det7a gets 1 of 2.
  One image is worth 50 points there, which is exactly why it must not gate.
- **The added data is desktop web screenshots at a uniform 1920x1080.** It does
  not cover mobile LINE captures. chatshot2 improved for the general reason
  "a UI screenshot is usually authentic", not because LINE was represented.
- **pilot11 recall on the 2 manipulated images is still 0.0**, unchanged from
  production. Nothing in this work improved manipulated-chat detection.
- **The webshot source is English-language desktop web pages** captured by a
  crawler; it is not Thai, and not a messaging interface.
- Single seed so far. Seeds 7 and 123 are training to check the gate result is
  not seed luck.

## Reproducibility

- `Det-Head/eval_det_diagnostics.py` — the only script used to score every head.
  Verified to reproduce the earlier ad-hoc numbers exactly, and it caught a real
  manifest bug (`Test-Cases/pairs/manipulated` holds 22 `.jpg` + 8 `.png`, so a
  `*.jpg`-only glob silently produced 157 rows instead of 165).
- `Det-Head/run_det_loop.py` — train → diagnose → gate → leaderboard. Gate uses
  the three external diagnostics; Val is recorded but never used to accept.
- `Det-Head/train_det_screen.py` — screening (25k stratified rows, ~37 s/epoch)
  and full-data (`--subsample 0`) in one script, plus `--extra-cache` to add a
  domain without recomputing the existing 12.5 GB cache.
- `Det-Head/binary_ranking_metrics` replaces sklearn, which is absent from
  `requirements.txt`; the old bare `except Exception` had been silently nulling
  f1/auc/ap. Verified against the previous sklearn values to 2.8e-08.
- Across the 12-candidate architecture search, `pearson r(Val ROC-AUC, camera9
  specificity) = -0.037`. Val still does not predict real-world behaviour, which
  is why the gate ignores it.

## State

- Production is unchanged: `server/.env` `ONNX_MODEL_PATH` still points to the
  det2b ONNX. No production file was modified.
- Locked Test 44,031 was never opened.
- No commit, push, PR, or deploy was performed.
- Promotion is a human decision. The next engineering steps are multi-seed
  confirmation, then ONNX export and parity checks, then shadow rollout — not
  automatic promotion.
