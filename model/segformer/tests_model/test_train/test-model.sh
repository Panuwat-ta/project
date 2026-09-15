#!/usr/bin/env bash
# Test-set eval (locked test/ 40k) for v1.0.5 best checkpoint.
# Requires: USB dataset mounted at /run/media/panuwat/USB/dataset
# Run from: /home/panuwat/project/model/segformer
# Batch 16 = for 8GB GPU (linux-ac). On the 4GB machine use batch 4.
set -euo pipefail
cd "$(dirname "$0")/.."
./venv/bin/python library/mmsegmentation/tools/test.py \
  configs/segformer_mit-b2-v10.py \
  work_dirs/v1.0.5/best_mIoU_iter_197500.pth \
  --work-dir work_dirs/v1.0.5/test_eval \
  --cfg-options test_dataloader.batch_size=16
