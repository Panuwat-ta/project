# SegFormer MiT-B2 Forgery Localization (v13) — candidate for v1.0.8.
# Evidence-driven follow-up to v11/v12. Goal: retain v12 gains on CopyMove,
# IMD2020 and Inpainting while recovering CASIA/generalization and lowering FPR.
# Run fresh from MIT-B2 pretrained (do NOT warm-start from v1.0.7):
# ./train.sh --config configs/segformer_mit-b2-v13.py --no-load
#
# Changes vs v12:
# - Restore CASIA repeat 4 -> 5: v1.0.7 lost 11.35 points CASIA Forgery Dice.
# - Restrict CopyPasteForgery to copymove/imd2020/inpainting only. v12 applied it
#   to every forged source; this correlated with better synthetic-sensitive domains
#   but worse CASIA/Face and higher false positives.
# - Lower CopyPasteForgery p 0.30 -> 0.20 to reduce synthetic-distribution bias.
# - Reduce aiforge repeat 10 -> 6 and realtext 6 -> 4 so the new domains remain
#   represented with less influence on the original seven-source mixture.
# - Validate all nine sources, but pool mIoU/mDice over the seven core sources.
#   Report new-domain metrics separately; they do not steer save_best selection.
# - Keep best core mIoU AND best equal-source core Forgery Dice checkpoints.
#   Inspect validation FPR/per-source tradeoffs before final checkpoint selection.
# - Keep v11 loss, optimizer, LR and crop policy; retain the v12 250k budget.
# - Use seed 42, matching v11, to remove an unnecessary changed setting.
#   This does not guarantee identical RNG streams across different data mixtures.
#
# Selection rule: choose checkpoint on validation only. Run the locked common test
# once after selection. Promotion target: at least v1.0.6 production robustness
# (local mDice >= 90.17), locked mDice >= 97.29, IMD2020 Forgery Dice > 50%,
# and overall local FPR <= 1.0%. These are post-training checks, not automatic
# training gates. Local regression feedback is not an untouched holdout.
# No config-only comparison can establish optimal hyperparameters; gains need
# validation and a fresh independent holdout before claiming generalization.
#
# CopyPasteForgery lives in ../forgery_aug.py. Keep the bare __import__ side-effect
# registration pattern; train.sh places the segformer directory on PYTHONPATH.
__import__('forgery_aug')
__import__('forgery_metrics')

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
randomness = dict(seed=42, diff_rank_seed=False, deterministic=False)


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
    dict(type='CopyPasteForgery', p=0.2, min_size=32, max_size=160),
    dict(type='Albu', transforms=albu_train_transforms),
    dict(type='PackSegInputs')
]

# Restrict synthesis to the three domains that improved in v12 and plausibly
# benefit from copy/move-style local compositing. CASIA, Face, Splicing,
# AIForge and RealText use the plain forged pipeline to avoid teaching a
# synthetic boundary cue across every domain. Authentic is always background-pure.
_COPYPASTE_SOURCES = frozenset({'copymove', 'imd2020', 'inpainting'})

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

# Frozen core evaluation sources. The official ranking set
# (scamguard-locked-multisource-test-v1, 2,504 batches) contains only the 7
# original sources. Keep test frozen and pool validation checkpoint metrics
# over those same core sources. AIForge/RealText validation is reported separately
# on every validation pass, so new-domain regressions remain visible.
_TEST_FROZEN_ROOTS = [casia_root, authentic_root, defacto_splicing_root,
                      defacto_inpaint_root, defacto_copymove_root,
                      defacto_face_root, imd2020_root]

# Fixed training-only repeats; counts below are historical v12 inventory,
# not a fresh count of the currently unmounted training dataset.
# Effective entries: CASIA 44,565; authentic 85,130; splicing 76,500;
# inpainting 53,748; copymove 52,424; face 57,308; IMD2020 79,497;
# aiforge 11,772 (1,962 x6); realtext 38,824 (9,706 x4).
# Repeats change sampling frequency, not the number of unique training images.
# v13 restores CASIA exposure and reduces new-domain oversampling after the v12
# local regression/FPR increase while preserving extra IMD2020 emphasis.
train_repeat_factors = dict(
    casia=5, authentic=1, splicing=1, inpainting=3,
    copymove=4, face=1, imd2020=3, aiforge=6, realtext=4
)


def _train_ds(root):
    name = root.rstrip('/').rsplit('/', 1)[-1]
    if name == 'authentic':
        pipeline = authentic_train_pipeline
    elif name in _COPYPASTE_SOURCES:
        pipeline = train_pipeline
    else:
        pipeline = plain_train_pipeline
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
    num_workers=4,
    persistent_workers=True,
    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[_ds(r, 'test', test_pipeline) for r in _TEST_FROZEN_ROOTS]
    )
)

val_evaluator = dict(
    type='SourceAwareIoUMetric',
    iou_metrics=['mIoU', 'mDice'],
    source_roots={r.rstrip('/').rsplit('/', 1)[-1]: r for r in _TRAIN_ROOTS},
    core_sources=[r.rstrip('/').rsplit('/', 1)[-1] for r in _TEST_FROZEN_ROOTS]
)

# Keep the official locked-test evaluator identical to v11/v12.
test_evaluator = dict(type='IoUMetric', iou_metrics=['mIoU', 'mDice'])

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
        save_best=['mIoU', 'core_macro_forgery_dice'],
        rule='greater',
        max_keep_ckpts=5
    )
)
