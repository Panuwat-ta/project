# real-camera-authentic-v1

Purpose: add a high-confidence Authentic domain that matches real smartphone/camera inputs.

## Ground-truth rule
- Authentic means a direct camera photo with no content manipulation.
- Keep the original camera file when possible; do not use screenshots, downloaded web images, edited exports, or AI-generated images.
- Metadata/EXIF is supporting provenance only; it is not used as a model input.
- Uncertain files are excluded rather than relabeled.

## Holdout protection
The existing 11 files under `/home/panuwat/Pictures/Test-Cases/image-Authentic` are diagnostic holdout and MUST NOT enter Train or camera-Val.
Byte SHA-256 and decoded-pixel hashes must be checked before ingestion.

The folder name is misleading: it is not one domain. On 2026-09-29 the user
confirmed that `to1` is a LINE chat capture and `to11` is a screen capture.
Both carry zero EXIF tags, while the other 9 files carry 12 each including GPS.
Those 9 are the real-camera set (`camera9`); the 2 chat/screen captures are
scored separately as `chatshot2` and are specified in
`dataset_specs/chat-screenshot-v1.md`. `Det-Head/eval_det_diagnostics.py`
verifies the EXIF evidence against the declared provenance at load time, so a
re-saved or mislabelled file cannot silently change domain.

## Collection coverage
Prefer non-sensitive scenes/objects. Cover indoor/outdoor, daylight/low-light, screens/electronics, fine textures, plants, buildings, documents, motion, zoom, portrait/landscape, and flat/simple scenes.
## Target size and split
- Minimum useful pilot: 500 new images; preferred initial version: 1,000+.
- Multiple devices/capture sessions are preferred to avoid learning one phone's pipeline.
- Split by device/session, not random near-duplicate frames.
- Suggested first version: 80% Train, 10% camera-Val, 10% fresh camera-Test.
- The current 11-image holdout remains separate from all three splits.

## Ingested v1 (2026-09-30)
Built by `build_real_camera_authentic_manifest.py` from 157 camera photos staged
in `incoming/`. Audit output: `manifests/incoming_audit.csv`.

- 157 audited, 157 accepted, 0 excluded, `holdout_overlap=0`,
  `duplicate_incoming=0`.
- Sessions come from EXIF `DateTimeOriginal`: 37 day-level sessions, assigned
  whole to one split, never per frame. Result: Train 125 (20 sessions),
  camera-Val 16 (9), camera-Test 16 (8) = 79.6 / 10.2 / 10.2 percent.
- EXIF is intact on all 157 (Make `realme`, Model `realme GT Neo2 5G`),
  which fixes the provenance gap noted for the 9 `camera9` files below.
- Median 15.93 MP, versus ~0.274 MP median for existing Authentic Train.
- Layout: `<split>/authentic/to<N>_auth.jpg`, byte-identical copies of the
  staged files. Manifests: `manifests/manifest.csv` plus one CSV per split,
  and top-level `manifests/det-train-v5-camera.csv`,
  `det-camera-val-v1.csv`, `det-camera-test-v1.csv`.
- Every row is Det label 0; the builder asserts this.

### Known gaps in v1
- **Single device.** All 157 come from one phone, so this version can still
  teach one capture pipeline. The multi-device preference above is unmet.
- **157 < 500.** Below the minimum useful pilot, so this is a pilot, not v1.
- camera-Test here is a development split. It is not the Locked Test 44,031.
- `incoming/` and the staged copy under
  `/home/panuwat/Pictures/Det-Head/image-Authentic` both remain on disk. The
  `image-Authentic` folder also holds byte-identical copies of the 11
  protected holdout files, so it must never be used as a glob source for
  ingestion; `incoming/` is the only sanctioned input directory.

## Model protocol
1. Validate provenance and duplicate hashes.
2. Create a versioned manifest; never overwrite source files.
3. Precompute Det local tokens only for approved Train/camera-Val images.
4. Train patch_attention from scratch with fixed seeds.
5. Select architecture/hyperparameters using normal Val + camera-Val only.
6. Run current camera9/chatshot2/pilot/Test-Cases only as development diagnostics.
7. Open Locked Test 44,031 only after the candidate passes the gates.

## Current evidence
- Existing Authentic Train is dominated by low-resolution web-like images
  (~0.274 MP median over a 1,000-row sample, 0% with camera EXIF), while the
  9 real-camera images are 12.58 MP median.
- 2026-09-29: a 12-candidate search over the frozen backbone produced 0 passes.
  Every head is worst on real-camera Authentic, and Val accuracy does not
  predict it (`pearson r = -0.037`). See
  `Det-Head/search_runs/2026-09-29/REPORT.md`.
- EXIF `Make`/`Model` on the 9 camera files is the literal string `"--"`, so
  the captures were re-saved with metadata stripped. Future collection should
  preserve EXIF so provenance can be verified automatically.