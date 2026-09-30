# SegFormer MiT-B2 Forgery Localization (v12) — fresh-training candidate for v1.0.7.
# Data: clean tree only (PNG lossless, stem-grouped train/val/test).
# Set DATA_ROOT on the training machine before running.
# Run from model/segformer (fresh from MIT-B2 pretrained, NOT from v1.0.6):
# ./train.sh --config configs/segformer_mit-b2-v12.py --no-load
#
# Changes vs v11 (evidence-driven):
# - New sources (added 2026-09-18, already clean-tree PNG): aiforge (AI-made
#   forgeries, 1,962 train, x10) and realtext (text forgeries, 9,706 train,
#   x6). Both join train AND val; test stays frozen at 7 sources so the
#   locked ranking set (2,504 batches) remains comparable with v1.0.0-v1.0.6.
# - CopyPasteForgery: synthesize copy-move inside the 512 crop (targets copymove,
#   local Forgery Dice only 65.86% in v1.0.6; raising repeat x4 proved insufficient).
# - Repeat rebalance: casia 5 -> 4 (highest FPR 5.85%), imd2020 2 -> 3 (weakest,
#   Forgery Dice 42.13%). Everything else unchanged.
# - Schedule 200k -> 250k iters: both v1.0.5 and v1.0.6 peaked within the last
#   5k iters, so the budget was the binding constraint.
# - Seed 42 -> 43 so the run is independent of v1.0.6.
# - Backbone/head LR policy, loss weights, val/test protocol: unchanged from v11.
#
# Abort rule: if validation Forgery Dice does not pass 85% of v1.0.6's level
# (mDice 97.30) by iter 100k, stop and inspect instead of burning GPU.
# Promotion gate for v1.0.7: locked mDice >= 97.29, local imd2020 Forgery Dice
# > 50%, overall FPR <= 1.0%. Evaluate the locked test only once at the end.
# NOTE: CopyPasteForgery lives in ../forgery_aug.py (plain module with normal
# imports). It must not be defined or imported here: any static third-party
# `import` makes mmengine misclassify this file as lazy-import (rejecting
# `_base_`), and class/module objects left in config globals break
# `cfg.pretty_text` at Runner startup (crashed 2026-09-18). This bare
# __import__ expression registers the transform as a side effect without
# binding any name. Requires the segformer dir on PYTHONPATH (train.sh sets it).
__import__('forgery_aug')

DATA_ROOT = '/run/media/panuwat/USB/dataset'

_base_ = [
    '../library/mmsegmentation/configs/segformer/'
    'segformer_mit-b0_8xb2-160k_ade20k-512x512.py'
]

checkpoint = (
    'https://download.openmmlab.com/mmsegmentation/v0.5/'
    'pretrain/segformer/'
    'mit_b2_20220624-66e8bf70.pth'
)

# Only backbone.init_cfg initializes pretrained weights for a fresh run.
# An explicit train.sh --load-from can override this for a separate experiment.
load_from = None
resume = False
randomness = dict(seed=43, diff_rank_seed=False, deterministic=False)


model = dict(
    backbone=dict(
        type='MixVisionTransformer',
        init_cfg=dict(type='Pretrained', checkpoint=checkpoint),
        embed_dims=64,
        num_heads=[1, 2, 5, 8],
        num_layers=[3, 4, 6, 3]
    ),
    decode_head=dict(
        type='SegformerHead',
        in_channels=[64, 128, 320, 512],
        channels=256,
        num_classes=2,
        ignore_index=255,
        loss_decode=[
            dict(
                type='CrossEntropyLoss',
                use_sigmoid=False,
                avg_non_ignore=True,
                loss_weight=1.0,
                class_weight=[1.0, 2.5]
            ),
            dict(
                type='DiceLoss',
                use_sigmoid=False,  # mutually exclusive background/forgery classes
                loss_weight=1.5,
                ignore_index=255
            )
        ]
    )
)

dataset_type = 'BaseSegDataset'

casia_root = DATA_ROOT + '/casia/'
authentic_root = DATA_ROOT + '/authentic/'
defacto_inpaint_root = DATA_ROOT + '/inpainting/'
defacto_copymove_root = DATA_ROOT + '/copymove/'
defacto_splicing_root = DATA_ROOT + '/splicing/'
defacto_face_root = DATA_ROOT + '/face/'
imd2020_root = DATA_ROOT + '/imd2020/'
aiforge_root = DATA_ROOT + '/aiforge/'
realtext_root = DATA_ROOT + '/realtext/'

metainfo = dict(
    classes=('background', 'forgery'),
    palette=[[0, 0, 0], [255, 0, 0]]
)

albu_train_transforms = [
    # Keep corruption examples while reducing destruction of small forensic cues.
    dict(type='ImageCompression', quality_range=(60, 95), p=0.3),
    dict(type='GaussianBlur', blur_limit=(3, 3), p=0.1),
    dict(type='GaussNoise', std_range=(0.005, 0.015), p=0.1),
    dict(type='ColorJitter', brightness=0.1, contrast=0.1,
         saturation=0.1, hue=0.03, p=0.3),
]

train_pipeline = [
    dict(type='LoadImageFromFile'),
    dict(type='LoadAnnotations', reduce_zero_label=False),
    # Avoid shrinking to 256px before cropping. Retain v10's square resize policy.
    dict(type='RandomResize', scale=(512, 512), ratio_range=(1.0, 2.0),
         keep_ratio=False),
    # Retry up to 10 crops to find both classes with >=~1% minority pixels.
    # This is best-effort: very small/full-image forgeries can still fail the rule.
    dict(type='RandomCrop', crop_size=(512, 512), cat_max_ratio=0.99),
    dict(type='RandomFlip', prob=0.5),
    # Copy-move synthesis only on forged sources; authentic stays background-pure.
    dict(type='CopyPasteForgery', p=0.3, min_size=32, max_size=160),
    dict(type='Albu', transforms=albu_train_transforms),
    dict(type='PackSegInputs')
]

# CopyPasteForgery scope: synthesis applies to every forged source, not just
# copymove. Rationale: it is a general augmentation (ObjectFormer/DF2023
# synthesize broadly during pretraining), masks stay exact so there is no
# label noise, and per-source regressions are caught by Test-Case
# per_category + FPR monitoring after training. To restrict synthesis to
# specific sources (ablation), list them here, e.g.
# frozenset({'face', 'realtext', 'aiforge', 'splicing', 'inpainting'}).
# 'authentic' never gets synthesis (always uses authentic_train_pipeline).
_NO_COPYPASTE_SOURCES = frozenset()

# Authentic images deliberately contain no forgery; do not retry mixed-class crops
# and do not synthesize forgery into them.
authentic_train_pipeline = [
    dict(step, cat_max_ratio=1.0) if step['type'] == 'RandomCrop' else dict(step)
    for step in train_pipeline if step['type'] != 'CopyPasteForgery'
]

plain_train_pipeline = [
    dict(step) for step in train_pipeline
    if step['type'] != 'CopyPasteForgery'
]

test_pipeline = [
    # Same whole-image protocol as v10 for comparable validation/common-test logs.
    # Production tiled ONNX validation must be measured separately, on val data.
    dict(type='LoadImageFromFile'),
    dict(type='Resize', scale=(512, 512), keep_ratio=False),
    dict(type='LoadAnnotations', reduce_zero_label=False),
    dict(type='PackSegInputs')
]


def _ds(root, split, pipeline):
    # img_suffix must be .png: mmseg defaults to .jpg which finds 0 files here.
    return dict(
        type=dataset_type,
        img_suffix='.png',
        data_root=root,
        metainfo=metainfo,
        data_prefix=dict(
            img_path=f'images/{split}',
            seg_map_path=f'annotations/{split}'
        ),
        pipeline=pipeline
    )


_TRAIN_ROOTS = [casia_root, authentic_root, defacto_splicing_root,
                defacto_inpaint_root, defacto_copymove_root,
                defacto_face_root, imd2020_root,
                aiforge_root, realtext_root]

# Frozen locked-test sources. The official ranking set
# (scamguard-locked-multisource-test-v1, 2,504 batches) contains only the 7
# original sources, so test_dataloader stays frozen to keep v1.0.7 comparable
# with v1.0.0-v1.0.6. New sources join train AND val (val guides checkpoint
# selection and measures new-domain fit). If official numbers on the new
# domains are needed later, create locked-test-v2 as separate work.
_TEST_FROZEN_ROOTS = [casia_root, authentic_root, defacto_splicing_root,
                      defacto_inpaint_root, defacto_copymove_root,
                      defacto_face_root, imd2020_root]

# Fixed training-only repeats, based on the current training file counts.
# Effective entries: CASIA 35,652; authentic 85,130; splicing 76,500;
# inpainting 53,748; copymove 52,424; face 57,308; IMD2020 79,497;
# aiforge 19,620 (1,962 x10, capped to avoid overfitting the tiny set);
# realtext 58,236 (9,706 x6, text forgeries directly relevant to ScamGuard).
# Repeats change sampling frequency, not the number of unique training images.
# v12 changes vs v11: casia 5 -> 4 (highest FPR), imd2020 2 -> 3 (weakest),
# + aiforge/realtext.
train_repeat_factors = dict(
    casia=4, authentic=1, splicing=1, inpainting=3,
    copymove=4, face=1, imd2020=3, aiforge=10, realtext=6
)


def _train_ds(root):
    name = root.rstrip('/').rsplit('/', 1)[-1]
    if name == 'authentic':
        pipeline = authentic_train_pipeline
    elif name in _NO_COPYPASTE_SOURCES:
        pipeline = plain_train_pipeline
    else:
        pipeline = train_pipeline
    dataset = _ds(root, 'train', pipeline)
    repeats = train_repeat_factors[name]
    if repeats == 1:
        return dataset
    return dict(type='RepeatDataset', times=repeats, dataset=dataset)

train_dataloader = dict(
    # batch 16 OOMs on 8GB (proven 2026-09-10): 8 + accumulate 2 = effective 16.
    batch_size=8,
    # 4 workers (not 8): 2026-09-18 OOM killed a data worker on the 15GB
    # desktop during val, when 8 train + 8 val workers coexisted with desktop
    # apps. data_time was ~0.01s, so loading is far from the bottleneck.
    num_workers=4,
    persistent_workers=True,
    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[_train_ds(r) for r in _TRAIN_ROOTS]
    )
)

val_dataloader = dict(
    batch_size=16,
    num_workers=4,  # see OOM note on train_dataloader (workers coexist during val)
    persistent_workers=True,
    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[_ds(r, 'val', test_pipeline) for r in _TRAIN_ROOTS]
    )
)

# Locked TEST set: judge once at the end, never tune on it.
# Frozen at the 7 original sources (see _TEST_FROZEN_ROOTS above).
test_dataloader = dict(
    batch_size=16,
    num_workers=8,
    persistent_workers=True,
    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[_ds(r, 'test', test_pipeline) for r in _TEST_FROZEN_ROOTS]
    )
)

val_evaluator = dict(
    type='IoUMetric',
    iou_metrics=['mIoU', 'mDice']
)

test_evaluator = val_evaluator

optim_wrapper = dict(
    # Clear inherited custom_keys so no broad backbone rule shadows norm policy.
    _delete_=True,
    type='AmpOptimWrapper',
    accumulative_counts=2,
    clip_grad=dict(max_norm=1.0, norm_type=2),
    optimizer=dict(
        type='AdamW',
        lr=1e-5,  # backbone base LR; head LR is 1e-4 before scheduler
        betas=(0.9, 0.999),
        weight_decay=0.01
    ),
    paramwise_cfg=dict(
        norm_decay_mult=0.0,
        bias_decay_mult=0.0,
        custom_keys={
            'decode_head': dict(lr_mult=10.0),
            # custom_keys override norm_decay_mult: use longer explicit head BN
            # keys so both the head LR and zero normalization decay are applied.
            **{f'decode_head.convs.{i}.bn': dict(lr_mult=10.0, decay_mult=0.0)
               for i in range(4)},
            'decode_head.fusion_conv.bn': dict(lr_mult=10.0, decay_mult=0.0),
            'decode_head.conv_seg.bias': dict(lr_mult=10.0, decay_mult=0.0),
        }
    )
)

max_iters = 250000

param_scheduler = [
    dict(
        type='LinearLR',
        start_factor=0.01,
        begin=0,
        end=3000,
        by_epoch=False
    ),
    dict(
        type='PolyLR',
        eta_min=1e-6,
        power=1.0,
        begin=3000,
        end=max_iters,
        by_epoch=False
    )
]

train_cfg = dict(
    type='IterBasedTrainLoop',
    max_iters=max_iters,
    val_interval=5000,
    dynamic_intervals=[(150000, 2500)]
)

default_hooks = dict(
    checkpoint=dict(
        type='CheckpointHook',
        by_epoch=False,
        interval=2500,
        save_best='mIoU',
        rule='greater',
        max_keep_ckpts=5
    )
)
