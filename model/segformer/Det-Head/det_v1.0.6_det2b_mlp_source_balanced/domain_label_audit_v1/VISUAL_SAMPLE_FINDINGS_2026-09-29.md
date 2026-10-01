# Visual Audit Sample Findings — 2026-09-29

Reviewed contact sheets are derived from the 225-row stratified Train-only audit sample.
These observations do not change labels.

## label0 / authentic
Many high Det2-b score examples visually appear to be ordinary photographic scenes (sports, buildings, vehicles, events, objects).
This supports treating at least part of the high-score label-0 queue as genuine hard negatives rather than automatic label errors.
Provenance still requires explicit verification before assigning `verified_label`.

## label0 / PSBattles
The source/original side contains highly heterogeneous content, including ordinary photos and stylized/surreal-looking source imagery.
Being the original member of a PSBattles pair is not equivalent to verified camera-pristine provenance.
Keep these rows at high semantics-risk until reviewed with source URL/pair context.

## label1 / sparse-mask datasets
Splicing samples with low Det2-b scores frequently have forged areas below 0.5% of the image in the reviewed sheet.
At thumbnail scale the changed region is often not visually identifiable.
This is consistent with the measured mask-area distribution and supports local/MIL feature modeling.
