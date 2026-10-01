"""CPU checks for tiled_val and config v14.

Synthetic fixtures and a stub segmentor. Nothing here measures model quality;
these tests check that the tiled hook reproduces the production tiling math and
that it is wired into mmengine in a way that actually reaches the log.
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest
import unittest.mock
from pathlib import Path

import numpy as np
import torch
from mmengine.config import Config
from mmengine.registry import HOOKS, init_default_scope
from mmengine.runner.priority import Priority, get_priority
from mmseg.utils import register_all_modules

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tiled_val import (  # noqa: E402
    TiledValidationHook,
    _confusion,
    _dice_and_fpr,
    tiled_forgery_probability,
)

TILE, OVERLAP = 512, 64
DATA_ROOT = '/run/media/panuwat/USB/dataset'
SERVER_TILING = Path('/home/panuwat/project/server/app/services/tiling.py')


# --------------------------------------------------------------------------
# stubs
# --------------------------------------------------------------------------
def _ramp_logits(axis, height, width):
    if axis == 'x':
        base = torch.arange(width, dtype=torch.float32) / max(width - 1, 1)
        out = base.view(1, 1, 1, width).expand(1, 2, height, width)
    else:
        base = torch.arange(height, dtype=torch.float32) / max(height - 1, 1)
        out = base.view(1, 1, height, 1).expand(1, 2, height, width)
    out = out.clone()
    out[:, 0] = 0.0
    return out


class RampModel:
    """Segmentor stub: position ramp, independent of content.

    Lets the parity test compare crop placement without depending on resize
    kernels, which are no-ops on the already-tile-sized tiled path.
    """

    def __init__(self, axis='x'):
        self.axis = axis

    def encode_decode(self, inputs, batch_img_metas):
        return _ramp_logits(self.axis, inputs.shape[2], inputs.shape[3])


class ConstantModel:
    def __init__(self, value):
        self.value = value

    def encode_decode(self, inputs, batch_img_metas):
        logits = torch.zeros(inputs.shape[0], 2, inputs.shape[2], inputs.shape[3])
        logits[:, 1] = float(torch.logit(torch.tensor(self.value)))
        return logits


class SingleChannelModel:
    def encode_decode(self, inputs, batch_img_metas):
        return torch.zeros(inputs.shape[0], 1, inputs.shape[2], inputs.shape[3])


def _fake_session(axis):
    class Session:
        def run(self, _outputs, feeds):
            tensor = feeds[list(feeds)[0]]
            return [_ramp_logits(axis, tensor.shape[2], tensor.shape[3]).numpy()]

    return Session()


# --------------------------------------------------------------------------
# production parity
# --------------------------------------------------------------------------
@unittest.skipUnless(SERVER_TILING.exists(),
                     'server/app/services/tiling.py not available')
class ProductionParityTests(unittest.TestCase):
    """tiled_val must match the code production actually runs."""

    def _compare(self, height, width, axis):
        sys.path.insert(0, str(SERVER_TILING.parent))
        from PIL import Image
        from tiling import tile_inference

        rng = np.random.default_rng(7)
        image = Image.fromarray(rng.integers(0, 256, (height, width, 3), dtype=np.uint8))
        production = tile_inference(_fake_session(axis), 'input', image, TILE,
                                    OVERLAP, strict=True)
        ours = tiled_forgery_probability(RampModel(axis), torch.rand(1, 3, height, width),
                                         tile_size=TILE, overlap=OVERLAP).numpy()
        return float(np.abs(production.astype(np.float64)
                            - ours.astype(np.float64)).max())

    def test_parity_exact_across_sizes_and_axes(self):
        worst = 0.0
        for height, width in [(512, 512), (640, 480), (480, 640), (700, 900),
                              (300, 700), (1368, 2000)]:
            for axis in ('x', 'y'):
                worst = max(worst, self._compare(height, width, axis))
        # float32 epsilon; anything larger means the tiling geometry drifted.
        self.assertLess(worst, 1e-6, f'max abs diff {worst}')

    def test_parity_holds_for_nonzero_and_large_overlap(self):
        """overlap 0, the production 64, and a heavy overlap.

        Deliberately avoids overlap close to tile_size: stride = 512 - overlap
        would become 1 and the tile loop would run millions of iterations,
        which is a degenerate setting for production too, not a behaviour worth
        spending test time on.
        """
        for overlap in (0, 64, 256):
            sys.path.insert(0, str(SERVER_TILING.parent))
            from PIL import Image
            from tiling import tile_inference
            rng = np.random.default_rng(11)
            image = Image.fromarray(rng.integers(0, 256, (700, 900, 3), dtype=np.uint8))
            production = tile_inference(_fake_session('x'), 'input', image, TILE,
                                        overlap, strict=True)
            ours = tiled_forgery_probability(RampModel('x'), torch.rand(1, 3, 700, 900),
                                             tile_size=TILE, overlap=overlap).numpy()
            self.assertLess(float(np.abs(production - ours).max()), 1e-6,
                            f'overlap {overlap}')


# --------------------------------------------------------------------------
# tiling behaviour
# --------------------------------------------------------------------------
class TilingBehaviourTests(unittest.TestCase):

    def test_constant_model_stays_constant_everywhere(self):
        """acc/weight normalisation and edge padding must not leak artefacts."""
        for height, width in [(400, 500), (640, 480), (700, 900), (2000, 1368)]:
            out = tiled_forgery_probability(ConstantModel(0.7),
                                             torch.rand(1, 3, height, width),
                                             tile_size=TILE, overlap=OVERLAP)
            self.assertEqual(tuple(out.shape), (height, width))
            self.assertTrue(torch.allclose(out, torch.full_like(out, 0.7), atol=1e-5),
                            f'{height}x{width} not flat: {out.min()}..{out.max()}')

    def test_single_image_fast_path_returns_original_size(self):
        """h<=tile and w<=tile takes the single-pass branch and resizes back."""
        out = tiled_forgery_probability(ConstantModel(0.3), torch.rand(1, 3, 300, 700),
                                        tile_size=TILE, overlap=OVERLAP)
        self.assertEqual(tuple(out.shape), (300, 700))

    def test_non_binary_head_degrades_to_zeros(self):
        out = tiled_forgery_probability(SingleChannelModel(), torch.rand(1, 3, 640, 480),
                                        tile_size=TILE, overlap=OVERLAP)
        self.assertEqual(tuple(out.shape), (640, 480))
        self.assertTrue(bool((out == 0).all()))

    def test_rejects_invalid_tile_arguments(self):
        image = torch.rand(1, 3, 640, 480)
        with self.assertRaises(ValueError):
            tiled_forgery_probability(ConstantModel(0.5), image, tile_size=0)
        with self.assertRaises(ValueError):
            tiled_forgery_probability(ConstantModel(0.5), image, tile_size=512, overlap=512)
        with self.assertRaises(ValueError):
            tiled_forgery_probability(ConstantModel(0.5), image, tile_size=512, overlap=-1)

    def test_output_is_probability_bounded(self):
        out = tiled_forgery_probability(RampModel('x'), torch.rand(1, 3, 700, 900),
                                        tile_size=TILE, overlap=OVERLAP)
        self.assertGreaterEqual(float(out.min()), 0.0)
        self.assertLessEqual(float(out.max()), 1.0)


# --------------------------------------------------------------------------
# metric arithmetic
# --------------------------------------------------------------------------
class MetricArithmeticTests(unittest.TestCase):

    def test_confusion_and_dice_by_hand(self):
        pred = torch.tensor([1, 1, 0, 0, 1, 0], dtype=torch.uint8)
        true = torch.tensor([1, 0, 1, 0, 0, 0], dtype=torch.uint8)
        counts = _confusion(pred, true)
        self.assertEqual(counts, {'tp': 1, 'fp': 2, 'fn': 1, 'tn': 2})
        scores = _dice_and_fpr(counts)
        self.assertAlmostEqual(scores['forgery_dice'], 100 * 2 / 5)
        self.assertAlmostEqual(scores['fpr'], 100 * 2 / 4)

    def test_empty_ground_truth_is_nan_and_total_miss_is_zero(self):
        """A source with no forgery must not read as a perfect 0% Dice.

        A foreground-free source is undefined, not zero: the 1,084 authentic
        realtext images would otherwise be scored as a total miss and pulled
        the macro down for a reason that has nothing to do with the model.
        """
        perfect_negative = _dice_and_fpr({'tp': 0, 'fp': 0, 'fn': 0, 'tn': 100})
        self.assertTrue(np.isnan(perfect_negative['forgery_dice']))
        self.assertAlmostEqual(perfect_negative['fpr'], 0.0)
        # foreground exists and every pixel is missed: a real, well defined zero
        total_miss = _dice_and_fpr({'tp': 0, 'fp': 0, 'fn': 50, 'tn': 50})
        self.assertAlmostEqual(total_miss['forgery_dice'], 0.0)


# --------------------------------------------------------------------------
# hook wiring
# --------------------------------------------------------------------------
class _StubRunner:
    def __init__(self, iteration, max_iters, model, work_dir):
        self.iter = iteration
        self.max_iters = max_iters
        self.model = model
        self.work_dir = work_dir


class _StubLoader:
    def __init__(self, batches):
        self._batches = batches

    def __iter__(self):
        return iter(self._batches)


class _StubPreprocessor:
    def __call__(self, batch, training=False):
        return batch


class _HookModel:
    """Model stub carrying just what _run_source touches."""

    def __init__(self, value=0.8, training=True):
        self._inner = ConstantModel(value)
        self.data_preprocessor = _StubPreprocessor()
        self.training = training

    def encode_decode(self, inputs, metas):
        return self._inner.encode_decode(inputs, metas)

    def eval(self):
        self.training = False
        return self

    def train(self, mode=True):
        self.training = mode
        return self


class _StubSample:
    def __init__(self, img_path, target):
        self.img_path = img_path
        self.gt_sem_seg = type('S', (), {'data': target})()


def _segformer_stub():
    """Real SegFormer with random weights: exercises the real data preprocessor.

    Pretrained init is disabled so the test needs no network access and stays
    deterministic; only preprocessing behaviour matters here, not accuracy.
    """
    from mmengine.config import Config
    from mmseg.registry import MODELS
    config = Config.fromfile(str(ROOT / 'configs/segformer_mit-b2-v14.py'))
    config.model.backbone.init_cfg = None
    return MODELS.build(config.model)


def _preprocessor_model(value=0.8):
    """Real SegFormer with a constant-output head.

    Keeps the REAL data preprocessor (that is the point of the test) and only
    replaces encode_decode, so no forward pass and no network access is needed.
    """
    model = _segformer_stub()
    constant = ConstantModel(value)
    model.encode_decode = constant.encode_decode
    model.eval()
    return model


class HookWiringTests(unittest.TestCase):

    def _hook(self, **kwargs):
        options = dict(
            sources=[dict(name='fake', data_root='/nonexistent/', split='val')],
            interval_iters=100,
            num_workers=0,
        )
        options.update(kwargs)
        return TiledValidationHook(**options)

    def test_priority_precedes_runtime_info_hook(self):
        """Guards the silent failure: RuntimeInfoHook publishes metrics.

        If this hook ran after RuntimeInfoHook, its keys would be added to the
        metrics dict after the message hub was updated and would never appear in
        the Iter(val) line or the vis_data json, with no error raised.
        """
        self.assertLess(get_priority(TiledValidationHook.priority),
                        get_priority('VERY_HIGH'))
        self.assertIn('after_val_epoch', TiledValidationHook.stages)
        self.assertEqual(get_priority(TiledValidationHook.priority), Priority.HIGHEST.value)

    def test_is_registered_for_config_building(self):
        register_all_modules()
        init_default_scope('mmseg')
        self.assertIs(HOOKS.get('TiledValidationHook'), TiledValidationHook)

    def test_does_not_run_off_interval(self):
        hook = self._hook()
        hook._dataloaders = {}
        model = _HookModel()
        metrics = {'mIoU': 90.0}
        with tempfile.TemporaryDirectory() as work_dir:
            runner = _StubRunner(50, 250000, model, work_dir)
            hook.after_val_epoch(runner, metrics)
            self.assertEqual(os.listdir(work_dir), [],
                             'an off-interval call must not write anything')
        self.assertEqual(metrics, {'mIoU': 90.0})

    def test_does_not_run_at_iteration_zero(self):
        hook = self._hook()
        hook._dataloaders = {}
        metrics = {'mIoU': 90.0}
        with tempfile.TemporaryDirectory() as work_dir:
            hook.after_val_epoch(_StubRunner(0, 250000, _HookModel(), work_dir), metrics)
        self.assertEqual(metrics, {'mIoU': 90.0})

    def test_runs_on_interval_and_injects_keys(self):
        hook = self._hook()
        target = torch.zeros(600, 800, dtype=torch.uint8)
        target[100:200, 100:200] = 1
        batch = dict(
            inputs=[torch.rand(1, 3, 600, 800)],
            data_samples=[_StubSample('/fake/images/val/a.png', target)],
        )
        hook._dataloaders = {'fake': _StubLoader([batch])}
        model = _HookModel(value=0.9)
        metrics = {'mIoU': 90.0}
        with tempfile.TemporaryDirectory() as work_dir:
            hook.after_val_epoch(_StubRunner(100, 250000, model, work_dir), metrics)
            self.assertTrue(os.path.exists(os.path.join(work_dir, 'tiled_val_log.jsonl')))
            record = json.loads(
                open(os.path.join(work_dir, 'tiled_val_log.jsonl')).readline())
        self.assertIn('tiled_fake_forgery_dice', metrics)
        self.assertIn('tiled_fake_fpr', metrics)
        self.assertEqual(metrics['mIoU'], 90.0)
        self.assertEqual(record['iteration'], 100)
        self.assertEqual(record['tile_size'], TILE)
        self.assertEqual(record['sources']['fake']['sampled_filenames'], ['a.png'])

    def test_runs_on_final_iteration_even_off_interval(self):
        hook = self._hook(interval_iters=25000)
        target = torch.zeros(600, 800, dtype=torch.uint8)
        batch = dict(inputs=[torch.rand(1, 3, 600, 800)],
                     data_samples=[_StubSample('/fake/images/val/a.png', target)])
        hook._dataloaders = {'fake': _StubLoader([batch])}
        metrics = {}
        with tempfile.TemporaryDirectory() as work_dir:
            hook.after_val_epoch(_StubRunner(250000, 250000, _HookModel(), work_dir), metrics)
        self.assertIn('tiled_fake_forgery_dice', metrics)

    def test_restores_training_mode(self):
        hook = self._hook()
        target = torch.zeros(600, 800, dtype=torch.uint8)
        batch = dict(inputs=[torch.rand(1, 3, 600, 800)],
                     data_samples=[_StubSample('/fake/images/val/a.png', target)])
        hook._dataloaders = {'fake': _StubLoader([batch])}
        model = _HookModel(training=True)
        with tempfile.TemporaryDirectory() as work_dir:
            hook.after_val_epoch(_StubRunner(100, 250000, model, work_dir), {})
        self.assertTrue(model.training, 'hook must hand training mode back')

    def test_sampled_filenames_logged_only_once(self):
        hook = self._hook()
        target = torch.zeros(600, 800, dtype=torch.uint8)
        batch = dict(inputs=[torch.rand(1, 3, 600, 800)],
                     data_samples=[_StubSample('/fake/images/val/a.png', target)])
        hook._dataloaders = {'fake': _StubLoader([batch])}
        with tempfile.TemporaryDirectory() as work_dir:
            hook.after_val_epoch(_StubRunner(100, 250000, _HookModel(), work_dir), {})
            hook.after_val_epoch(_StubRunner(200, 250000, _HookModel(), work_dir), {})
            lines = open(os.path.join(work_dir, 'tiled_val_log.jsonl')).readlines()
        self.assertEqual(len(lines), 2)
        self.assertIn('sampled_filenames', lines[0])
        self.assertNotIn('sampled_filenames', lines[1])

    def test_source_failure_does_not_kill_training_run(self):
        """A monitoring pass must never take down a multi-hour training run.

        Found by the real-Runner smoke test: the tiled forward pass starts while
        the training graph and AdamW state are still resident, so on a memory
        constrained card it can OOM. Losing the metric is acceptable; losing the
        run is not.
        """
        target = torch.zeros(600, 800, dtype=torch.uint8)
        good = dict(inputs=[torch.rand(1, 3, 600, 800)],
                    data_samples=[_StubSample('/fake/images/val/a.png', target)])

        class ExplodingModel(_HookModel):
            def encode_decode(self, inputs, metas):
                raise torch.OutOfMemoryError('CUDA out of memory. Tried to allocate 20 MiB')

        hook = self._hook()
        # The tiled pass feeds 512x512 crops, so discriminate on pixel content
        # rather than image size: the broken source is all ones, the healthy one
        # all zeros.
        broken_batch = dict(inputs=[torch.ones(1, 3, 600, 800)],
                            data_samples=[_StubSample('/fake/images/val/broken.png',
                                                     torch.zeros(600, 800, dtype=torch.uint8))])
        healthy_batch = dict(inputs=[torch.zeros(1, 3, 640, 480)],
                             data_samples=[_StubSample('/fake/images/val/ok.png',
                                                      torch.zeros(640, 480, dtype=torch.uint8))])
        broken_loader = _StubLoader([broken_batch])
        healthy_loader = _StubLoader([healthy_batch])
        hook._dataloaders = {'broken': broken_loader, 'healthy': healthy_loader}

        class HalfBrokenModel(_HookModel):
            """OOMs on the all-ones source, works on the all-zeros one."""

            def encode_decode(self, inputs, metas):
                if float(inputs.mean()) > 0.9:
                    raise torch.OutOfMemoryError('CUDA out of memory. Tried 20 MiB')
                return self._inner.encode_decode(inputs, metas)

        metrics = {'mIoU': 90.0}
        with tempfile.TemporaryDirectory() as work_dir:
            hook.after_val_epoch(_StubRunner(100, 250000, HalfBrokenModel(), work_dir), metrics)
            with open(os.path.join(work_dir, 'tiled_val_log.jsonl'),
                      encoding='utf-8') as handle:
                record = json.loads(handle.readline())
        self.assertIn('error', record['sources']['broken'])
        self.assertIn('CUDA out of memory', record['sources']['broken']['error'])
        self.assertIn('tiled_healthy_forgery_dice', metrics,
                      'a failing source must not suppress the others')
        self.assertEqual(metrics['mIoU'], 90.0)
        self.assertNotIn('tiled_broken_forgery_dice', metrics,
                         'a skipped source must not publish a partial number')

    def test_rejects_bad_construction(self):
        with self.assertRaises(ValueError):
            self._hook(sources=[])
        with self.assertRaises(ValueError):
            self._hook(interval_iters=0)
        with self.assertRaises(ValueError):
            TiledValidationHook(sources=[dict(name='x')])
        with self.assertRaises(ValueError):
            TiledValidationHook(sources=[dict(name='x', data_root='/n/')],
                                subsample=dict(x=0))

    def test_missing_source_root_raises_instead_of_scoring_nothing(self):
        hook = self._hook()
        with self.assertRaises(FileNotFoundError):
            hook._sample_indices('fake', 'val', '/definitely/not/here/')

    def test_per_source_seed_is_stable_across_processes(self):
        """hash() on str is salted per process; that would break reproducibility."""
        names = ('imd2020', 'aiforge', 'realtext')
        expected = [TiledValidationHook._source_seed(20260929, n) for n in names]
        script = (
            "import sys; sys.path.insert(0, %r);"
            "from tiled_val import TiledValidationHook as T;"
            "print([T._source_seed(20260929, n) for n in %r])" % (str(ROOT), names)
        )
        result = subprocess.run([sys.executable, '-c', script], capture_output=True,
                                text=True, env={'PYTHONHASHSEED': '424242', 'PATH': '/usr/bin'})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(eval(result.stdout.strip()), expected)


# --------------------------------------------------------------------------
# config v14
# --------------------------------------------------------------------------
@unittest.skipUnless((ROOT / 'configs/segformer_mit-b2-v14.py').exists(), 'v14 config missing')
class ConfigV14Tests(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        register_all_modules()
        init_default_scope('mmseg')
        sys.path.insert(0, str(ROOT))
        cls.config = Config.fromfile(str(ROOT / 'configs/segformer_mit-b2-v14.py'))

    @staticmethod
    def _names(dataset):
        found = []

        def walk(node):
            if node.get('type') == 'RepeatDataset':
                walk(node['dataset'])
            elif node.get('type') == 'ConcatDataset':
                for item in node['datasets']:
                    walk(item)
            else:
                found.append(node['data_root'].rstrip('/').rsplit('/', 1)[-1])

        walk(dataset)
        return sorted(found)

    def test_config_loads_and_pretty_prints(self):
        self.assertGreater(len(self.config.pretty_text), 1000)

    def test_split_composition(self):
        core = ['authentic', 'casia', 'copymove', 'face', 'imd2020', 'inpainting', 'splicing']
        self.assertEqual(self._names(self.config.train_dataloader['dataset']), core)
        self.assertEqual(self._names(self.config.test_dataloader['dataset']), core)
        self.assertEqual(self._names(self.config.val_dataloader['dataset']),
                         sorted(core + ['aiforge', 'realtext']))

    def test_new_domains_absent_from_training(self):
        self.assertNotIn('aiforge', self._names(self.config.train_dataloader['dataset']))
        self.assertNotIn('realtext', self._names(self.config.train_dataloader['dataset']))

    def test_repeat_factors_cover_every_training_root(self):
        names = set(self._names(self.config.train_dataloader['dataset']))
        self.assertTrue(names <= set(self.config.train_repeat_factors))
        self.assertEqual(self.config.train_repeat_factors['imd2020'], 3)
        self.assertEqual(self.config.train_repeat_factors['casia'], 5)

    def test_evaluator_pools_core_only(self):
        evaluator = self.config.val_evaluator
        self.assertEqual(evaluator['type'], 'SourceAwareIoUMetric')
        self.assertEqual(len(evaluator['core_sources']), 7)
        self.assertEqual(len(evaluator['source_roots']), 9)
        self.assertIn('authentic', evaluator['core_sources'])

    def test_no_copypaste_in_training_pipeline(self):
        self.assertNotIn('CopyPasteForgery',
                         [step['type'] for step in self.config.train_pipeline])

    def test_budget_and_scheduler_end_together(self):
        self.assertEqual(self.config.train_cfg.max_iters, 250000)
        self.assertEqual(self.config.param_scheduler[-1]['end'], 250000)

    def test_checkpoint_keeps_two_core_candidates(self):
        self.assertEqual(self.config.default_hooks.checkpoint['save_best'],
                         ['mIoU', 'core_macro_forgery_dice'])

    def test_workers_reduced_on_every_loader(self):
        for split in ('train', 'val', 'test'):
            self.assertEqual(self.config[split + '_dataloader']['num_workers'], 4)

    def test_tiled_hook_is_wired(self):
        self.assertEqual(len(self.config.custom_hooks), 1)
        hook = self.config.custom_hooks[0]
        self.assertEqual(hook['type'], 'TiledValidationHook')
        self.assertEqual(hook['tile_size'], 512)
        self.assertEqual(hook['overlap'], 64)
        self.assertEqual(hook['threshold'], 0.5)
        self.assertEqual([s['name'] for s in hook['sources']],
                         ['imd2020', 'aiforge', 'realtext'])
        self.assertEqual(HOOKS.get('TiledValidationHook'), TiledValidationHook)

    def test_tiled_metrics_cannot_become_save_best_keys(self):
        keys = set(self.config.default_hooks.checkpoint['save_best'])
        self.assertNotIn('tiled_imd2020_forgery_dice', keys)
        self.assertNotIn('tiled_imd2020_fpr', keys)

    def test_everything_resolves_in_the_registry(self):
        from mmengine.registry import OPTIM_WRAPPERS
        from mmseg.registry import DATASETS, METRICS, MODELS
        self.assertIsNotNone(MODELS.get(self.config.model['type']))
        self.assertIsNotNone(OPTIM_WRAPPERS.get(self.config.optim_wrapper['type']))
        self.assertIsNotNone(METRICS.get(self.config.val_evaluator['type']))
        for dataset in self.config.train_dataloader['dataset']['datasets']:
            self.assertIsNotNone(DATASETS.get(dataset['type']))

    def test_seed_matches_v11(self):
        v11 = Config.fromfile(str(ROOT / 'configs/segformer_mit-b2-v11.py'))
        self.assertEqual(self.config.randomness['seed'], v11.randomness['seed'])


# --------------------------------------------------------------------------
# real data, only when the training machine is available
# --------------------------------------------------------------------------
@unittest.skipUnless(Path(DATA_ROOT, 'imd2020', 'images', 'val').is_dir(),
                     'training dataset not mounted')
class RealDataSmokeTests(unittest.TestCase):

    def test_dataloader_subsamples_deterministically_and_keeps_native_size(self):
        hook = TiledValidationHook(
            sources=[dict(name='imd2020', data_root=DATA_ROOT + '/imd2020/', split='val')],
            subsample=dict(imd2020=12),
            interval_iters=100,
            num_workers=0,
        )
        # The image tensor lives in batch['inputs']; SegDataSample carries only
        # the mask and metainfo, so the two must be zipped.
        def collect():
            return [(batch['inputs'][0], batch['data_samples'][0])
                    for batch in hook._dataloader(hook.sources[0])]

        loader = hook._dataloader(hook.sources[0])
        self.assertEqual(len(loader.dataset), 12)
        first = collect()
        second = collect()
        self.assertEqual([s.img_path for _, s in first], [s.img_path for _, s in second],
                         'subsample must be reproducible')
        self.assertEqual(len(set(s.img_path for _, s in first)), 12, 'no duplicates')
        for image, sample in first:
            height, width = image.shape[1:]
            # mmseg keeps a leading channel dim on PixelData; the hook squeezes
            # it, so compare against the squeezed shape.
            mask = sample.gt_sem_seg.data
            if mask.dim() == 3:
                mask = mask.squeeze(0)
            self.assertEqual(tuple(mask.shape), (height, width),
                             'mask must stay at native resolution')
            self.assertNotEqual((height, width), (512, 512),
                                'val pipeline must not squash to 512')

    def test_tiled_probability_matches_native_shape_on_real_image(self):
        hook = TiledValidationHook(
            sources=[dict(name='imd2020', data_root=DATA_ROOT + '/imd2020/', split='val')],
            subsample=dict(imd2020=1),
            num_workers=0,
        )
        batch = next(iter(hook._dataloader(hook.sources[0])))
        # Exercise the real preprocessor: it returns a stacked (1, C, H, W)
        # tensor on the test branch, and tiled_forgery_probability needs the
        # batch dimension present.
        model = _segformer_stub()
        data = model.data_preprocessor(batch, training=False)
        image = data['inputs'][0:1]
        self.assertEqual(image.dim(), 4)
        out = tiled_forgery_probability(ConstantModel(0.42), image,
                                        tile_size=TILE, overlap=OVERLAP)
        self.assertEqual(tuple(out.shape), tuple(image.shape[2:]))
        self.assertTrue(torch.allclose(out, torch.full_like(out, 0.42), atol=1e-5))

    def test_hook_scores_real_image_end_to_end(self):
        """Full hook path with the real preprocessor and real native resolution.

        Regression guard: the preprocessor returns a stacked tensor, and
        iterating it yields 3-dim slices. A hook that passed those straight to
        the tiling function would raise IndexError on the first image.
        """
        hook = TiledValidationHook(
            sources=[dict(name='imd2020', data_root=DATA_ROOT + '/imd2020/', split='val')],
            subsample=dict(imd2020=3),
            interval_iters=1,
            num_workers=0,
        )
        hook._dataloaders = {'imd2020': hook._dataloader(hook.sources[0])}
        metrics = {}
        with tempfile.TemporaryDirectory() as work_dir:
            hook.after_val_epoch(_StubRunner(1, 250000, _preprocessor_model(), work_dir),
                                 metrics)
            with open(os.path.join(work_dir, 'tiled_val_log.jsonl'),
                      encoding='utf-8') as handle:
                record = json.loads(handle.readline())
        self.assertIn('tiled_imd2020_forgery_dice', metrics)
        self.assertIn('tiled_imd2020_fpr', metrics)
        self.assertEqual(record['sources']['imd2020']['images'], 3)
        self.assertEqual(len(record['sources']['imd2020']['sampled_filenames']), 3)

    def test_real_imd2020_sample_is_actually_larger_than_one_tile(self):
        """Guard the premise: a real imd2020 image must exercise the tiled path."""
        hook = TiledValidationHook(
            sources=[dict(name='imd2020', data_root=DATA_ROOT + '/imd2020/', split='val')],
            subsample=dict(imd2020=8),
            num_workers=0,
        )
        shapes = [tuple(b['inputs'][0].shape[1:])
                  for b in hook._dataloader(hook.sources[0])]
        self.assertTrue(any(h > TILE or w > TILE for h, w in shapes),
                        f'no sample exceeded one tile: {shapes}')


if __name__ == '__main__':
    unittest.main(verbosity=2)
