"""CPU checks; fixtures are synthetic and do not measure model quality."""
import copy
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np
import torch
from mmcv.transforms import Compose
from mmengine.config import Config
from mmengine.hooks import CheckpointHook
from mmengine.structures import PixelData
from mmseg.evaluation.metrics import IoUMetric
from mmseg.registry import METRICS, MODELS
from mmseg.structures import SegDataSample
from mmseg.utils import register_all_modules

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from forgery_metrics import SourceAwareIoUMetric

META = dict(classes=('background', 'forgery'))


def sample(source, pred, gt):
    return dict(img_path=f'/fixture/{source}/images/val/a.png',
                pred_sem_seg=dict(data=torch.tensor(pred).reshape(1, 2, -1)),
                gt_sem_seg=dict(data=torch.tensor(gt).reshape(1, 2, -1)))


def metric():
    m = SourceAwareIoUMetric(
        source_roots={s: f'/fixture/{s}' for s in ['casia', 'imd2020', 'authentic', 'new']},
        core_sources=['casia', 'imd2020', 'authentic'],
        iou_metrics=['mIoU', 'mDice'])
    m.dataset_meta = META
    return m


def fixtures():
    return [sample('casia', [1, 1, 0, 0], [1, 0, 1, 0]),
            sample('imd2020', [1, 0, 0, 0], [1, 0, 0, 0]),
            sample('authentic', [1, 0, 0, 0], [0, 0, 0, 0]),
            sample('new', [0, 0, 0, 0], [1, 1, 1, 1])]


class SourceMetricTests(unittest.TestCase):
    def test_hand_calculated_confusion_and_core_matches_official_metric(self):
        m = metric(); data = fixtures(); m.process({}, data)
        result = m.compute_metrics(m.results)
        self.assertAlmostEqual(result['casia_forgery_dice'], 50)
        self.assertAlmostEqual(result['casia_fpr'], 50)
        self.assertAlmostEqual(result['authentic_fpr'], 25)
        self.assertAlmostEqual(result['core_fpr'], 200 / 9)
        self.assertAlmostEqual(result['core_macro_forgery_dice'], 75)
        reference = IoUMetric(iou_metrics=['mIoU', 'mDice'])
        reference.dataset_meta = META; reference.process({}, data[:3])
        for key, value in reference.compute_metrics(reference.results).items():
            self.assertAlmostEqual(result[key], value)

    def test_new_domain_size_cannot_change_core_checkpoint_scores(self):
        m = metric(); m.process({}, fixtures()); before = m.compute_metrics(m.results)
        m.process({}, [sample('new', [1, 1, 1, 1], [1, 1, 1, 1])] * 20)
        after = m.compute_metrics(m.results)
        for key in ['mIoU', 'mDice', 'core_macro_forgery_dice', 'core_fpr']:
            self.assertEqual(before[key], after[key])
        self.assertGreater(after['new_forgery_dice'], before['new_forgery_dice'])

    def test_macro_weights_sources_equally_not_by_image_count(self):
        m = metric(); m.process({}, fixtures() + [fixtures()[0]] * 9)
        r = m.compute_metrics(m.results)
        self.assertAlmostEqual(r['core_macro_forgery_dice'], 75)

    def test_ignore_pixels_and_perfect_authentic_are_not_forgery_score(self):
        m = metric(); data = fixtures()
        data[0] = sample('casia', [1, 1, 0, 0], [1, 255, 0, 0])
        data[2] = sample('authentic', [0, 0, 0, 0], [0, 0, 0, 0])
        m.process({}, data); r = m.compute_metrics(m.results)
        self.assertEqual(r['casia_forgery_dice'], 100)
        self.assertEqual(r['casia_fpr'], 0)
        self.assertEqual(r['authentic_fpr'], 0)
        self.assertTrue(np.isnan(r['authentic_forgery_dice']))
        self.assertEqual(r['core_macro_forgery_dice'], 100)

    def test_missing_or_unknown_sources_fail_loudly(self):
        m = metric(); m.process({}, fixtures()[:3])
        with self.assertRaisesRegex(ValueError, 'Missing validation sources'):
            m.compute_metrics(m.results)
        with self.assertRaisesRegex(ValueError, 'Unknown validation source'):
            m.process({}, [sample('casia-other', [0]*4, [0]*4)])

    def test_ambiguous_roots_rejected(self):
        with self.assertRaisesRegex(ValueError, 'overlap'):
            SourceAwareIoUMetric(source_roots={'casia': '/fixture', 'authentic': '/fixture/a'},
                                 core_sources=['casia', 'authentic'])

    def test_evaluate_clears_results_and_retains_source_identity(self):
        m = metric(); m.process({}, list(reversed(fixtures())))
        r = m.evaluate(4)
        self.assertEqual(r['core_macro_forgery_dice'], 75)
        self.assertEqual(m.results, [])


class ConfigIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        register_all_modules(init_default_scope=True)
        cls.cfg = Config.fromfile(str(ROOT/'configs/segformer_mit-b2-v13.py'))

    def test_config_dump_roundtrip_evaluator_and_checkpoint_hook(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)/'resolved.py'
            self.cfg.dump(str(path)); resolved = Config.fromfile(str(path))
        evaluator = METRICS.build(resolved.val_evaluator)
        self.assertIsInstance(evaluator, SourceAwareIoUMetric)
        self.assertEqual(len(evaluator.source_roots), 9)
        self.assertEqual(len(evaluator.core_sources), 7)
        self.assertEqual(resolved.test_evaluator.type, 'IoUMetric')
        hook = CheckpointHook(**{k: v for k, v in resolved.default_hooks.checkpoint.items() if k != 'type'})
        self.assertEqual(hook.key_indicators, ['mIoU', 'core_macro_forgery_dice'])
        # Both indicators must be present in the actual metric output.
        m = metric(); m.process({}, fixtures()); r = m.compute_metrics(m.results)
        self.assertTrue(set(hook.key_indicators) <= r.keys())

    def test_runtime_augmentation_keeps_authentic_background_and_binary_masks(self):
        for wrapper in self.cfg.train_dataloader.dataset.datasets:
            d = wrapper.get('dataset', wrapper)
            name = Path(d.data_root).name
            transforms = [copy.deepcopy(x) for x in d.pipeline
                          if x.type not in ['LoadImageFromFile', 'LoadAnnotations']]
            has_copy = any(x.type == 'CopyPasteForgery' for x in transforms)
            self.assertEqual(has_copy, name in ['copymove', 'imd2020', 'inpainting'])
            # Force the optional operation to execute in this fixture test.
            for x in transforms:
                if x.type == 'CopyPasteForgery':
                    x.p = 1.0
            image = np.random.default_rng(42).integers(0, 256, (512, 512, 3), dtype=np.uint8)
            mask = np.zeros((512, 512), dtype=np.uint8)
            if name != 'authentic': mask[128:384, 128:384] = 1
            result = Compose(transforms)(dict(img=image, gt_seg_map=mask,
                img_shape=image.shape[:2], ori_shape=image.shape[:2], seg_fields=['gt_seg_map']))
            labels = set(result['data_samples'].gt_sem_seg.data.unique().tolist())
            self.assertTrue(labels <= {0, 1})
            if name == 'authentic': self.assertEqual(labels, {0})
            self.assertEqual(tuple(result['inputs'].shape), (3, 512, 512))

    def test_cpu_forward_backward_and_real_optimizer_groups(self):
        from mmengine.optim import build_optim_wrapper
        torch.set_num_threads(2)
        model_cfg = copy.deepcopy(self.cfg.model)
        model_cfg.backbone.init_cfg = None  # no download in a compatibility test
        model_cfg.decode_head.norm_cfg = dict(type='BN', requires_grad=True)
        model = MODELS.build(model_cfg)
        optim_cfg = copy.deepcopy(self.cfg.optim_wrapper)
        optim_cfg.type = 'OptimWrapper'  # CUDA AMP is deliberately not tested here
        optim = build_optim_wrapper(model, optim_cfg)
        group_for = {id(p): group for group in optim.optimizer.param_groups for p in group['params']}
        for name, parameter in model.named_parameters():
            group = group_for[id(parameter)]
            self.assertAlmostEqual(group['lr'], 1e-4 if name.startswith('decode_head.') else 1e-5)
            if name.endswith('.bias') or '.bn.' in name or '.norm' in name or '.ln' in name:
                self.assertEqual(group['weight_decay'], 0)
        samples = [SegDataSample(gt_sem_seg=PixelData(data=torch.randint(0, 2, (1, 64, 64)))) for _ in range(2)]
        losses = model(torch.randn(2, 3, 64, 64), samples, mode='loss')
        total = sum(value for key, value in losses.items() if 'loss' in key)
        self.assertTrue(torch.isfinite(total).item())
        total.backward()
        for part in [model.backbone, model.decode_head]:
            gradients = [p.grad for p in part.parameters() if p.grad is not None]
            self.assertTrue(gradients)
            self.assertTrue(all(torch.isfinite(g).all().item() for g in gradients))


if __name__ == '__main__':
    unittest.main()
