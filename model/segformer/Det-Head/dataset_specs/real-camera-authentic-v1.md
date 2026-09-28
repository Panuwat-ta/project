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

## Collection coverage
Prefer non-sensitive scenes/objects. Cover indoor/outdoor, daylight/low-light, screens/electronics, fine textures, plants, buildings, documents, motion, zoom, portrait/landscape, and flat/simple scenes.
## Target size and split
- Minimum useful pilot: 500 new images; preferred initial version: 1,000+.
- Multiple devices/capture sessions are preferred to avoid learning one phone's pipeline.
- Split by device/session, not random near-duplicate frames.
- Suggested first version: 80% Train, 10% camera-Val, 10% fresh camera-Test.
- The current 11-image holdout remains separate from all three splits.

## Model protocol
1. Validate provenance and duplicate hashes.
2. Create a versioned manifest; never overwrite source files.
3. Precompute Det5 local tokens only for approved Train/camera-Val images.
4. Train patch_attention from scratch with fixed seeds.
5. Select architecture/hyperparameters using normal Val + camera-Val only.
6. Run current camera11/pilot/Test-Cases only as development diagnostics.
7. Open Locked Test 44,031 only after the candidate passes the gates.

Current evidence: existing Authentic Train is dominated by low-resolution web-like images (~0.27 MP median), while fresh camera11 is ~12.58 MP median.