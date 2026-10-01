# Det5-A audited review — 2026-09-29

- Train: 95,635 audited rows; 135 PSBattles source-original semantics-risk rows excluded.
- Val: 11,972 unchanged.
- Best Val accuracy: 86.385% at epoch 16.
- Val @0.5: F1 86.17%, AUC 94.36%, AP 95.03%, specificity 87.94%, recall 84.83%, macro dataset accuracy 87.09%.
- Dedicated Authentic Val accuracy/specificity fell to 87.17%.
- Fresh camera Authentic 11: 1/11 correct (specificity 9.09%).
- Pilot11: 3/11 correct.
- Val threshold ~0.63 restores det2-b-level Authentic specificity, but external diagnostic scores remain strongly shifted; regression is not calibration-only.
- Decision: reject before locked Test 44,031. Keep production det2-b unchanged.
- Next: keep the 135 rows semantically `uncertain`, but test fractional weak-negative loss weights rather than full exclusion or full trusted-label training.
