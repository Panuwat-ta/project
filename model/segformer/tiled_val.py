"""Tiled validation that matches production inference geometry.

Why this exists
---------------
The training/validation pipeline in the config rescales every image to
512x512 (``Resize(scale=(512, 512), keep_ratio=False)``) and runs a single
forward pass. Production instead feeds overlapping 512x512 tiles at native
resolution and averages the class-1 probability map
(``server/app/services/tiling.py``). The two protocols see different inputs,
so validation can look healthy while the deployed model regresses.

Measured on v1.0.8, same sources, same checkpoint:

    source     validation (squash 512)   local-105 (native tiled)   gap
    casia                 76.52                      75.25      +1.27
    inpainting            79.41                      76.46      +2.96
    face                  98.92                      92.18      +6.74
    splicing              93.36                      81.17     +12.19
    copymove              77.00                      60.91     +16.10
    imd2020               76.94                      47.73     +29.21

Validation is optimistic by 11.41 points on average. (The two sets are also
different datasets, so protocol and sample selection cannot be separated from
this table alone; it shows the blind spot exists, not its sole cause.)

This module ports the production tiling math to PyTorch so a hook can log
production-shaped numbers beside the existing validation metrics. It does not
replace the validation loop, does not touch the locked test, and does not
participate in checkpoint selection.

Fidelity to ``server/app/services/tiling.py``
---------------------------------------------
* Averaging is over softmax probabilities, not logits. mmseg's built-in
  ``slide_inference`` averages logits, which is a different function.
* Edge tiles are zero padded to ``tile_size`` and only the real region is
  accumulated, exactly as production does.
* Single-image fast path (``h <= tile and w <= tile``) resizes the image up to
  ``tile_size`` and the probability map back to the original size. Production
  uses ``cv2.INTER_LANCZOS4`` for the upscale; torch has no Lanczos, so
  ``bicubic`` is the closest available and the residual difference is
  documented here rather than hidden.
* In the tiled branch every patch is already exactly ``tile_size``, so no
  resize happens and the port is exact.
"""

from __future__ import annotations

import json
import logging
import os
import random
import zlib
from typing import Dict, List, Optional, Sequence

import torch
import torch.nn.functional as F
from mmengine.hooks import Hook
from mmengine.logging import print_log
from mmengine.registry import HOOKS
from mmengine.runner import Runner
from mmseg.registry import DATASETS

__all__ = [
    'tiled_forgery_probability',
    'TiledValidationHook',
]


def _as_meta(sample) -> dict:
    """Accept a SegDataSample or a plain dict and return a metainfo dict."""
    meta = getattr(sample, 'metainfo', None)
    if meta is None:
        meta = sample if isinstance(sample, dict) else {}
    return dict(meta)


def _patch_metas(img_metas: Optional[Sequence[dict]], shape: Sequence[int]):
    if img_metas is not None:
        metas = list(img_metas)
    else:
        metas = [{}]
    height, width = int(shape[0]), int(shape[1])
    for meta in metas:
        meta['img_shape'] = (height, width)
        meta['ori_shape'] = (height, width)
        meta['pad_shape'] = (height, width)
        meta.setdefault('batch_input_shape', (3, height, width))
    return metas


def _forgery_probability(model, patch: torch.Tensor, img_metas) -> torch.Tensor:
    """Run one patch through the segmentor and return the class-1 probability.

    ``patch`` is a normalized ``(1, 3, tile, tile)`` tensor. Returns a
    ``(tile, tile)`` probability map, or zeros when the head is not a
    2-class segmentor.
    """
    logits = model.encode_decode(patch, _patch_metas(img_metas, patch.shape[2:]))
    if logits.dim() != 4 or logits.shape[1] != 2:
        return torch.zeros(tuple(patch.shape[2:]), dtype=torch.float32,
                           device=patch.device)
    return logits.float().softmax(dim=1)[0, 1]


def tiled_forgery_probability(
    model,
    image: torch.Tensor,
    *,
    tile_size: int = 512,
    overlap: int = 64,
    img_metas: Optional[Sequence[dict]] = None,
) -> torch.Tensor:
    """Native-resolution forgery probability map.

    Mirrors ``server/app/services/tiling.py::tile_inference`` on an
    already-normalized tensor. ``image`` is ``(1, 3, H, W)``; the result is
    ``(H, W)`` class-1 probability, averaged over overlapping tiles.
    """
    if tile_size <= 0:
        raise ValueError('tile_size must be positive')
    if overlap < 0 or overlap >= tile_size:
        raise ValueError('overlap must be in the range [0, tile_size)')

    channels, height, width = int(image.shape[1]), int(image.shape[2]), int(image.shape[3])

    if height <= tile_size and width <= tile_size:
        resized = F.interpolate(
            image,
            size=(tile_size, tile_size),
            mode='bicubic',
            align_corners=False,
        ).clamp(0, 1)
        prob = _forgery_probability(model, resized, img_metas)
        return F.interpolate(
            prob[None, None],
            size=(height, width),
            mode='bilinear',
            align_corners=False,
        )[0, 0]

    stride = tile_size - overlap
    accumulator = torch.zeros((height, width), dtype=torch.float64, device=image.device)
    weight = torch.zeros((height, width), dtype=torch.float64, device=image.device)

    for y0 in range(0, height, stride):
        for x0 in range(0, width, stride):
            y1 = min(y0 + tile_size, height)
            x1 = min(x0 + tile_size, width)
            tile_h, tile_w = y1 - y0, x1 - x0

            patch = torch.zeros(
                (channels, tile_size, tile_size),
                dtype=image.dtype,
                device=image.device,
            )
            patch[:, :tile_h, :tile_w] = image[0, :, y0:y1, x0:x1]

            prob = _forgery_probability(model, patch[None], img_metas)
            accumulator[y0:y1, x0:x1] += prob[:tile_h, :tile_w].double()
            weight[y0:y1, x0:x1] += 1.0

    return (accumulator / weight.clamp_min(1e-8)).float()


def _confusion(prediction: torch.Tensor, target: torch.Tensor) -> Dict[str, int]:
    pred = prediction.reshape(-1) > 0
    true = target.reshape(-1) > 0
    return {
        'tp': int(torch.count_nonzero(pred & true)),
        'fp': int(torch.count_nonzero(pred & ~true)),
        'fn': int(torch.count_nonzero(~pred & true)),
        'tn': int(torch.count_nonzero(~pred & ~true)),
    }


def _dice_and_fpr(counts: Dict[str, int]) -> Dict[str, float]:
    tp, fp, fn, tn = counts['tp'], counts['fp'], counts['fn'], counts['tn']
    denominator = 2 * tp + fp + fn
    return {
        'forgery_dice': 100.0 * 2 * tp / denominator if denominator else float('nan'),
        'fpr': 100.0 * fp / (fp + tn) if (fp + tn) else float('nan'),
    }


@HOOKS.register_module()
class TiledValidationHook(Hook):
    """Log production-shaped forgery metrics beside the normal validation log.

    The hook runs its own pass over a fixed, deterministically sampled subset
    of native-resolution validation images, using the same tiling geometry as
    ``server/app/services/tiling.py``. Results are written into the validation
    metrics dict so they appear in the ``Iter(val)`` line and in the
    ``vis_data`` json, under a ``tiled_`` prefix.

    These numbers are a monitoring signal only. Checkpoint selection keeps
    using ``save_best`` keys from the regular validation evaluator.

    Args:
        sources: list of ``dict(name=str, data_root=str, split=str)``. The
            ``data_root`` is the dataset folder that contains
            ``images/<split>`` and ``annotations/<split>``.
        subsample: number of images to draw per source. Use a fixed ``seed``
            so the sample is reproducible and auditable.
        interval_iters: run only when ``runner.iter`` is a positive multiple of
            this value, or on the final iteration.
        tile_size: production tile size.
        overlap: production tile overlap.
        threshold: production decision threshold on the probability map.
        num_workers: dataloader workers for this pass.
        log_path: jsonl file, relative to the runner work_dir, that records
            every trigger including the sampled filenames on the first run.
    """

    # Must run before RuntimeInfoHook (VERY_HIGH = 10). RuntimeInfoHook is the
    # component that pushes validation metrics into the message hub, and the
    # message hub is what the LoggerHook reads to build the Iter(val) line.
    # With a lower priority value this hook runs first, so keys it adds are
    # still present when RuntimeInfoHook publishes them. With the default
    # NORMAL (50) the keys would be added after publishing and would silently
    # never reach the log or the vis_data json.
    priority = 'HIGHEST'
    stages = ('after_val_epoch',)

    def __init__(
        self,
        sources: Sequence[dict],
        subsample: Optional[Dict[str, int]] = None,
        *,
        interval_iters: int = 25000,
        tile_size: int = 512,
        overlap: int = 64,
        threshold: float = 0.5,
        num_workers: int = 2,
        seed: int = 20260929,
        log_path: str = 'tiled_val_log.jsonl',
        max_images_per_source: Optional[int] = None,
    ) -> None:
        if not sources:
            raise ValueError('sources must not be empty')
        if interval_iters <= 0:
            raise ValueError('interval_iters must be positive')
        for source in sources:
            missing = {'name', 'data_root'} - set(source)
            if missing:
                raise ValueError(f'source is missing keys: {sorted(missing)}')
        self.sources = [dict(source) for source in sources]
        self.subsample = dict(subsample or {})
        for name, limit in self.subsample.items():
            if limit <= 0:
                raise ValueError(f'subsample for {name} must be positive, got {limit}')
        unknown = set(self.subsample) - {source['name'] for source in self.sources}
        if unknown:
            raise ValueError(f'subsample names not in sources: {sorted(unknown)}')
        self.interval_iters = interval_iters
        self.tile_size = tile_size
        self.overlap = overlap
        self.threshold = threshold
        self.num_workers = num_workers
        self.seed = seed
        self.log_path = log_path
        self.max_images_per_source = max_images_per_source
        self._dataloaders: Optional[Dict[str, object]] = None
        self._sample_logged = False

    # -- sampling -----------------------------------------------------------
    @staticmethod
    def _source_seed(seed: int, name: str) -> int:
        """Stable per-source seed.

        ``hash()`` on str is salted per process unless PYTHONHASHSEED is set,
        so it cannot be used for a sample that has to be reproducible across
        runs. crc32 is stable and process independent.
        """
        return seed + zlib.crc32(name.encode('utf-8')) % 100000

    def _sample_indices(self, name: str, split: str, data_root: str) -> Optional[List[int]]:
        limit = self.subsample.get(name)
        if limit is None:
            limit = self.max_images_per_source
        image_dir = os.path.join(data_root, 'images', split)
        if not os.path.isdir(image_dir):
            raise FileNotFoundError(f'No images directory for {name}: {image_dir}')
        total = len([f for f in os.listdir(image_dir) if f.lower().endswith('.png')])
        if limit is None or limit >= total:
            return None
        if limit <= 0:
            raise ValueError(f'subsample for {name} must be positive')
        return sorted(
            random.Random(self._source_seed(self.seed, name)).sample(range(total), limit))

    def _dataloader(self, source: dict):
        name = source['name']
        split = source.get('split', 'val')
        data_root = source['data_root'].rstrip('/')
        dataset = DATASETS.build(
            dict(
                type='BaseSegDataset',
                img_suffix='.png',
                data_root=data_root,
                metainfo=dict(
                    classes=('background', 'forgery'),
                    palette=[[0, 0, 0], [255, 0, 0]],
                ),
                data_prefix=dict(
                    img_path=f'images/{split}',
                    seg_map_path=f'annotations/{split}',
                ),
                # Native resolution on purpose: no Resize, so the tiles this
                # pass produces match the tiles production will produce.
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(type='LoadAnnotations', reduce_zero_label=False),
                    dict(type='PackSegInputs'),
                ],
                indices=self._sample_indices(name, split, data_root),
            )
        )
        return Runner.build_dataloader(
            {
                'batch_size': 1,
                'num_workers': self.num_workers,
                'persistent_workers': False,
                'sampler': dict(type='DefaultSampler', shuffle=False),
                'dataset': dataset,
            }
        )

    def _ensure_dataloaders(self, runner) -> Dict[str, object]:
        if self._dataloaders is None:
            self._dataloaders = {source['name']: self._dataloader(source) for source in self.sources}
        return self._dataloaders

    # -- scoring ------------------------------------------------------------
    def _run_source(self, model, loader) -> Dict[str, object]:
        totals = {'tp': 0, 'fp': 0, 'fn': 0, 'tn': 0}
        filenames: List[str] = []
        preprocessor = model.data_preprocessor
        for batch in loader:
            data = preprocessor(batch, training=False)
            # SegDataPreProcessor returns a STACKED tensor on the test branch,
            # not a list. Iterating that tensor yields (C, H, W) per sample,
            # which would break the (1, C, H, W) contract of the tiling
            # function, so slice the batch dimension back off explicitly.
            stacked = data['inputs']
            if isinstance(stacked, torch.Tensor):
                images = [stacked[i:i + 1] for i in range(stacked.shape[0])]
            else:
                images = list(stacked)
            for inputs, samples in zip(images, data['data_samples']):
                # mmseg's slide_inference receives metainfo DICTS, not
                # SegDataSample objects (see EncoderDecoder.predict, which does
                # [d.metainfo for d in data_samples]). Passing the object here
                # would fail in _patch_metas on item assignment.
                probability = tiled_forgery_probability(
                    model,
                    inputs,
                    tile_size=self.tile_size,
                    overlap=self.overlap,
                    img_metas=[_as_meta(samples)],
                )
                target = samples.gt_sem_seg.data
                if target.dim() == 3:
                    target = target.squeeze(0)
                if probability.shape != target.shape:
                    probability = F.interpolate(
                        probability[None, None],
                        size=target.shape,
                        mode='nearest',
                    )[0, 0]
                counts = _confusion(probability > self.threshold, target)
                for key in totals:
                    totals[key] += counts[key]
                filenames.append(os.path.basename(samples.img_path))
        scores: Dict[str, object] = dict(_dice_and_fpr(totals))
        scores['images'] = len(filenames)
        scores['filenames'] = filenames
        return scores

    def _write_log(self, runner, record: dict) -> None:
        work_dir = getattr(runner, 'work_dir', None)
        if not work_dir:
            return
        path = os.path.join(work_dir, self.log_path)
        os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
        with open(path, 'a', encoding='utf-8') as handle:
            handle.write(json.dumps(record, ensure_ascii=False) + '\n')

    def after_val_epoch(self, runner, metrics: Optional[Dict[str, float]] = None) -> None:
        iteration = int(runner.iter)
        final = int(getattr(runner, 'max_iters', 0) or 0)
        due = (iteration > 0 and iteration % self.interval_iters == 0) or (
            final and iteration == final)
        if not due:
            return

        model = runner.model
        if hasattr(model, 'module'):
            model = model.module
        was_training = model.training
        model.eval()

        # The training graph, gradients and AdamW state are all still resident
        # when validation finishes, so the tiled pass starts from a high
        # watermark. Free the blocks the val loop cached before adding more.
        if torch.cuda.is_available():
            torch.cuda.empty_cache()

        loaders = self._ensure_dataloaders(runner)
        record: Dict[str, object] = {
            'iteration': iteration,
            'tile_size': self.tile_size,
            'overlap': self.overlap,
            'threshold': self.threshold,
            'sources': {},
        }
        sources_record: Dict[str, Dict[str, object]] = {}
        try:
            for name, loader in loaders.items():
                try:
                    scores = self._run_source(model, loader)
                except Exception as error:  # noqa: BLE001
                    # This is a monitoring pass. Losing it must never take down
                    # a multi-hour training run, and a partially reported source
                    # is worse than a missing one, so skip the source, record
                    # why, and carry on. The failure is written to the jsonl and
                    # logged at WARNING level, so it is loud, not silent.
                    message = f'{type(error).__name__}: {error}'
                    print_log(f'TiledValidationHook skipped {name} at iter {iteration}: '
                              f'{message}', logger='current', level=logging.WARNING)
                    sources_record[name] = {'error': message}
                    if torch.cuda.is_available():
                        torch.cuda.empty_cache()
                    continue
                filenames = scores.pop('filenames')
                dice = float(scores['forgery_dice'])  # type: ignore[arg-type]
                fpr = float(scores['fpr'])  # type: ignore[arg-type]
                if metrics is not None:
                    metrics[f'tiled_{name}_forgery_dice'] = dice
                    metrics[f'tiled_{name}_fpr'] = fpr
                entry: Dict[str, object] = {
                    'forgery_dice': dice,
                    'fpr': fpr,
                    'images': scores['images'],
                }
                if not self._sample_logged:
                    entry['sampled_filenames'] = filenames
                sources_record[name] = entry
        finally:
            if was_training:
                model.train()
            self._sample_logged = True
            record['sources'] = sources_record
            self._write_log(runner, record)
