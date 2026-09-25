#!/usr/bin/env bash
# Locked test-set evaluation for the v1.0.8 best-mIoU checkpoint.
# Requires: USB dataset mounted at /run/media/panuwat/USB/dataset
# Batch 16 = for 8GB GPU (linux-ac). On the 4GB machine use batch 4.
set -euo pipefail
cd "$(dirname "$0")"
./venv/bin/python library/mmsegmentation/tools/test.py \
  configs/segformer_mit-b2-v13.py \
  work_dirs/v1.0.8/best_mIoU_iter_207500.pth \
  --work-dir work_dirs/v1.0.8/test_eval \
  --cfg-options test_dataloader.batch_size=16
