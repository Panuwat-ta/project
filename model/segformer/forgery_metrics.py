"""Validation metrics that keep the core benchmark separate from new sources."""

from pathlib import Path

import numpy as np
import torch
from mmseg.evaluation.metrics import IoUMetric
from mmseg.registry import METRICS


@METRICS.register_module()
class SourceAwareIoUMetric(IoUMetric):
    """Pool core sources exactly as IoUMetric; also report each source.

    All values use percentages. FPR is FP / (FP + TN) over pixels, not
    an image-level false alarm rate. Macro Dice weights each forged core
    source equally; authentic is monitored using FPR instead of Dice.
    Results contain the source name so distributed collection preserves it.
    """

    def __init__(self, source_roots, core_sources, authentic_source='authentic',
                 **kwargs):
        super().__init__(**kwargs)
        if self.format_only or self.output_dir is not None:
            raise ValueError('SourceAwareIoUMetric is for scored validation only')
        self.source_roots = {
            name: Path(root).resolve() for name, root in source_roots.items()
        }
        self.core_sources = tuple(core_sources)
        self.authentic_source = authentic_source
        if (len(set(self.core_sources)) != len(self.core_sources)
                or not set(self.core_sources) <= self.source_roots.keys()
                or authentic_source not in self.core_sources
                or len(self.core_sources) < 2):
            raise ValueError('Core sources must be unique, known, and include authentic')
        roots = list(self.source_roots.values())
        if any(a == b or a in b.parents or b in a.parents
               for i, a in enumerate(roots) for b in roots[i + 1:]):
            raise ValueError('Source roots must not overlap')

    def process(self, data_batch, data_samples):
        if tuple(self.dataset_meta['classes']) != ('background', 'forgery'):
            raise ValueError('Expected background=0 and forgery=1')
        for sample in data_samples:
            path = Path(sample['img_path']).resolve()
            matches = [name for name, root in self.source_roots.items()
                       if root in path.parents]
            if len(matches) != 1:
                raise ValueError(f'Unknown validation source: {path}')
            pred = sample['pred_sem_seg']['data'].squeeze()
            label = sample['gt_sem_seg']['data'].squeeze().to(pred)
            histograms = self.intersect_and_union(
                pred, label, 2, self.ignore_index)
            self.results.append((matches[0], tuple(h.double() for h in histograms)))

    @staticmethod
    def _scores(results):
        intersect, union, predicted, labelled = (
            torch.stack(items).sum(0) for items in zip(*results))
        tp = intersect[1].item()
        fp = predicted[1].item() - tp
        fn = labelled[1].item() - tp
        negatives = labelled[0].item()
        return {
            'forgery_dice': 100 * 2 * tp / (2 * tp + fp + fn)
            if 2 * tp + fp + fn else float('nan'),
            'fpr': 100 * fp / negatives if negatives else float('nan'),
        }

    def compute_metrics(self, results):
        grouped = {name: [] for name in self.source_roots}
        for name, histograms in results:
            grouped[name].append(histograms)
        missing = [name for name, items in grouped.items() if not items]
        if missing:
            raise ValueError(f'Missing validation sources: {missing}')
        core = [histograms for name, histograms in results
                if name in self.core_sources]
        metrics = super().compute_metrics(core)
        metrics.update({f'core_{key}': value
                        for key, value in self._scores(core).items()})
        for name, items in grouped.items():
            metrics.update({f'{name}_{key}': value
                            for key, value in self._scores(items).items()})
        forged_dice = [metrics[f'{name}_forgery_dice']
                       for name in self.core_sources
                       if name != self.authentic_source]
        if not np.isfinite(forged_dice).all():
            raise ValueError('Every forged core source must have a defined Dice')
        metrics['core_macro_forgery_dice'] = float(np.mean(forged_dice))
        return metrics
