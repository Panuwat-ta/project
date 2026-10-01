# Label Audit Findings — 2026-09-29

## Scope
- Train-only conflict queue: 3,080 images
- No label was changed automatically
- Pilot 11, real-camera 11, Val, Test-Cases and locked Test are not audit training inputs

## Provenance coverage
- Source provenance resolved: 3,080 / 3,080
- Main9 rows with `original_src`: 2,309
- PSBattles rows with source URL and pair group: 771
- PSBattles Authentic high-risk rows in conflict queue: 135

## Mask-area finding
For manipulated conflict rows with pixel masks, 1,718 / 1,718 masks were found.
- forged area <0.1%: 228
- forged area 0.1–1%: 1,141
- forged area 1–5%: 258
- forged area 5–20%: 40
- forged area >=20%: 51

Therefore 1,369 / 1,718 (79.69%) have <1% manipulated area.
## Interpretation
- A low image-level Det score does not prove a manipulated label is wrong.
- CopyMove, Inpainting, Splicing and RealText conflict rows are dominated by sparse edits.
- Global pooling can dilute these local forensic signals.
- This is direct evidence for testing Det5 local/MIL heads before any backbone fine-tune.

## Dataset-label semantics risk
- PSBattles `authentic` means the source/original member of an edit pair.
- It must not automatically be interpreted as verified camera-pristine provenance.
- Other label-0 datasets remain `dataset-authentic` until provenance is manually verified.

## Review policy
Use `audit_review_queue_v4.csv` and set one of:
- `keep`
- `relabel`
- `exclude`
- `uncertain`

Only reviewer-supported `verified_label` may change a future training manifest.
The original dataset label must remain preserved for traceability.
