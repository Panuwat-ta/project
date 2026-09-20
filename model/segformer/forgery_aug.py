"""Custom training augmentations for ScamGuard SegFormer configs.

Kept as a plain module (instead of inside the config file) for two reasons:
1. mmengine misclassifies any static third-party ``import`` in a config as a
   lazy-import config, which rejects the classic ``_base_`` list style.
2. Class/module objects left in config globals break ``cfg.pretty_text``
   (yapf) at Runner startup, aborting training before iter 0.

Configs pull this in with a bare ``__import__('forgery_aug')`` expression
(side effect = registry import; no name is bound), and ``train.sh`` puts
this directory on ``PYTHONPATH``.
"""

import random

import cv2
import numpy as np
from mmcv.transforms import BaseTransform
from mmseg.registry import TRANSFORMS


@TRANSFORMS.register_module()
class CopyPasteForgery(BaseTransform):
    """Synthesize copy-move forgery inside the training crop.

    Copies a random background patch and pastes it at a displaced
    background location, labeling the pasted area as forgery (1) in
    ``gt_seg_map``. Attempts touching existing forgery (source or
    destination) are skipped, so every synthetic sample unambiguously means
    "background copied elsewhere = new forgery". Half of the pastes use
    feathered edges (Gaussian-blurred alpha blending, following the DF2023
    synthesis protocol) so the model also sees concealed boundaries; the
    rest stay hard-edged. Photometric laundering of the pasted patch is
    left to the downstream Albu step.
    """

    def __init__(self, p=0.3, min_size=32, max_size=160, max_attempts=10,
                 feather_prob=0.5):
        self.p = p
        self.min_size = min_size
        self.max_size = max_size
        self.max_attempts = max_attempts
        self.feather_prob = feather_prob

    def _paste(self, img, seg, sy, sx, dy, dx, s):
        patch = img[sy:sy + s, sx:sx + s].copy()
        if random.random() < self.feather_prob:
            h, w = seg.shape[:2]
            alpha = np.zeros((h, w), dtype=np.float32)
            alpha[dy:dy + s, dx:dx + s] = 1.0
            k = max(3, (s // 16) * 2 + 1)  # odd kernel scaled to patch size
            alpha = cv2.GaussianBlur(alpha, (k, k), 0)
            canvas = img.astype(np.float32)
            # Start from canvas (not zeros): blurred alpha bleeds outside the
            # destination, and blending bleed area with black would bake a
            # dark halo ring that the model could learn as a forgery cue.
            pasted = canvas.copy()
            pasted[dy:dy + s, dx:dx + s] = patch.astype(np.float32)
            a3 = alpha[..., None]
            img[:] = (a3 * pasted + (1.0 - a3) * canvas).astype(np.uint8)
            seg[dy:dy + s, dx:dx + s] = (
                alpha[dy:dy + s, dx:dx + s] > 0.5).astype(seg.dtype)
        else:
            img[dy:dy + s, dx:dx + s] = patch
            seg[dy:dy + s, dx:dx + s] = 1

    def transform(self, results):
        if random.random() >= self.p:
            return results
        img = results['img']
        seg = results['gt_seg_map']
        h, w = seg.shape[:2]
        max_s = min(self.max_size, h, w)
        if max_s < self.min_size:
            return results
        for _ in range(self.max_attempts):
            s = random.randint(self.min_size, max_s)
            sy = random.randint(0, h - s)
            sx = random.randint(0, w - s)
            dy = random.randint(0, h - s)
            dx = random.randint(0, w - s)
            if abs(dy - sy) < s and abs(dx - sx) < s:
                continue  # require a visibly displaced duplicate
            if seg[sy:sy + s, sx:sx + s].any():
                continue  # source must be background: copy background only
            if seg[dy:dy + s, dx:dx + s].any():
                continue  # keep destination background-pure
            self._paste(img, seg, sy, sx, dy, dx, s)
            break
        results['img'] = img
        results['gt_seg_map'] = seg
        return results
