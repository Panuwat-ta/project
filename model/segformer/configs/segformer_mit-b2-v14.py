# SegFormer MiT-B2 Forgery Localization (v14) — candidate for v1.0.9.
# Run fresh from MIT-B2 pretrained (do NOT warm-start from an older version):
# ./train.sh --config configs/segformer_mit-b2-v14.py --no-load
#
# WHY THIS CONFIG EXISTS
# ----------------------
# v11 / model v1.0.6 is the best measured recipe so far on the production-style
# evaluation protocol. Measured on the local 105-image ONNX set (tiling 512,
# overlap 64, threshold 0.5) and on the locked common test (2504 batches):
#
#   version  config  local mIoU  local Forgery Dice  local FPR  locked mDice
#   v1.0.5   v10       75.96          71.89            0.54        95.25
#   v1.0.6   v11       83.14          81.90            0.83        97.29   <- best
#   v1.0.7   v12       81.13          79.34            1.08        97.36
#   v1.0.8   v13       78.72          76.27            1.86        97.38
#
# v12 and v13 raised the locked mDice slightly while losing 2.0 then 2.4 points
# of local mIoU and 2.6 then 5.6 points of Forgery Dice, and nearly doubling the
# pixel false-positive rate. Both changes are reverted here.
#
# CHANGES vs v11 (every other v11 setting is byte-identical in intent)
# ------------------------------------------------------------------
# 1. Revert the two v12/v13 training-data changes that were measured to hurt:
#    - aiforge and realtext are NOT in the training mixture.
#    - CopyPasteForgery is NOT used. Its effect is confounded: p=0.30 (v12) and
#      p=0.20 (v13) were only ever tested together with the new-domain shift, so
#      no run has ever measured CopyPasteForgery on its own. It stays out until
#      it is isolated in a single-variable arm.
# 2. Budget 200k -> 250k iterations. Both 200k runs peaked inside the last 3% of
#    their budget (v1.0.5 best at 197,500; v1.0.6 best at 195,000), which is the
#    signature of an under-trained run rather than an overfitted one. 250k
#    matches v12/v13. This is the one budget increase not yet tested on the v11
#    recipe, so it is a hypothesis, not a measured gain.
# 3. Validation uses SourceAwareIoUMetric so per-source Forgery Dice and FPR are
#    logged. In forgery_metrics.py the pooled mIoU/mDice are computed over
#    core_sources only, so 'mIoU' stays comparable to v1.0.6 even though the
#    validation set is larger. Verified: super().compute_metrics(core).
# 4. aiforge and realtext stay in validation as MONITORING-ONLY sources. They
#    are never trained on, so this measures the real cost of excluding them
#    instead of assuming it. They cannot steer save_best (see point 3).
# 5. Keep both best_mIoU and best_core_macro_forgery_dice checkpoints so the
#    checkpoint choice can be made from validation evidence, never from the
#    locked test.
# 6. num_workers 8 -> 4 on every dataloader. Workers from the training loader are
#    still alive during validation, and 8+8 was the OOM risk on 4GB GPUs.
# 7. seed 42, same as v11, so this is not a needless extra variable.
#
# DELIBERATELY UNCHANGED FROM v11
# -------------------------------
# Loss (CE class_weight [1.0, 2.5] + softmax Dice 1.5), AdamW lr 1e-5 with
# decode_head lr_mult 10, zero decay on norm/bias, clip_grad 1.0, accumulate 2,
# LinearLR warmup 0->3000 then PolyLR, RandomResize ratio (1.0, 2.0) keep_ratio
# False, RandomCrop cat_max_ratio 0.99 with the authentic exception, the light
# Albu set, the core-7 repeat factors, and the whole-image 512 validation
# protocol. These produced the v1.0.6 numbers and there is no measured reason to
# move them.
#
# KNOWN LIMITATION THAT A CONFIG CANNOT FIX (read before trusting validation)
# ------------------------------------------------------------------------
# Validation rescales each image to 512x512 and runs one forward pass, but
# production (server/app/services/tiling.py) runs overlapping 512x512 tiles at
# NATIVE resolution with overlap 64, averaging the probability maps. Validation
# therefore sees a squashed forgery while production sees it at full scale. This
# mismatch is the most likely reason the whole-image validation mIoU stayed flat
# (v1.0.5 91.15 -> v1.0.8 94.83) while the tiled Forgery Dice moved 71.89 ->
# 90.17 -> 76.27 across the same versions. Closing this needs sliding-window
# validation at native resolution, which requires a data preprocessor and
# evaluator change plus variable-size batching. That is a code change and is NOT
# attempted here; until it exists, judge candidates on the tiled local set.
#
# SELECTION AND PROMOTION RULES
# -----------------------------
# Choose the final checkpoint on validation only, then run the locked common test
# once. Promotion targets, checked after training (not automatic training gates):
#   local mDice >= 90.17%   (v1.0.6)
#   local Forgery Dice >= 81.90%   (v1.0.6)
#   local overall FPR <= 1.0%
#   IMD2020 local Forgery Dice > 50%   (v1.0.6 reached only 42.13%)
#   locked mDice >= 97.29%   (v1.0.6)
# The local 105 images were already used to design v13, so they are a regression
# set and not an untouched holdout. A fresh holdout is required before claiming
# generalization on new scam images.
#
# NEXT SINGLE-VARIABLE ARMS (do not bundle these into v14)
#   A. imd2020 repeat 2 -> 3: IMD2020 is the weakest core source (42.13% Dice).
#      v12 (x3) and v13 (x3) both improved it to 49.62 and 47.73, but both also
#      added the new domains, so repeat 3 alone is still unproven.
#   B. CopyPasteForgery alone on the v14 mixture, p <= 0.2.
#   C. aiforge/realtext in training at a repeat low enough to stay under ~5% of
#      the effective sample mass.
#
# forgery_metrics.py must sit next to this config's project root; train.sh puts
# the segformer directory on PYTHONPATH. Keep the bare __import__ side-effect
# registration pattern.
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
    dict(type='Albu', transforms=albu_train_transforms),
    dict(type='PackSegInputs')
]

# Authentic images deliberately contain no forgery; do not retry mixed-class crops.
authentic_train_pipeline = [
    dict(step, cat_max_ratio=1.0) if step['type'] == 'RandomCrop' else dict(step)
    for step in train_pipeline
]

test_pipeline = [
    # Unchanged from v10/v11 on purpose: identical protocol keeps the validation
    # and locked-test logs directly comparable to v1.0.5 - v1.0.8.
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


# The seven sources that v1.0.6 was trained and measured on. Training, locked
# test and checkpoint selection all stay inside this set.
_CORE_ROOTS = [casia_root, authentic_root, defacto_splicing_root,
               defacto_inpaint_root, defacto_copymove_root,
               defacto_face_root, imd2020_root]

# Never trained on. Present in validation only so the cost of excluding these
# domains is measured every run instead of assumed. Excluded from save_best.
_MONITOR_ONLY_ROOTS = [aiforge_root, realtext_root]

# SourceAwareIoUMetric needs a root for every image it will score, and raises on
# an unclassified path, so source_roots must be the union and val must load all.
_EVAL_ROOTS = _CORE_ROOTS + _MONITOR_ONLY_ROOTS

# Fixed training-only repeats, unchanged from v11.
# Effective entries: CASIA 44,565; authentic 85,130; splicing 76,500;
# inpainting 53,748; copymove 52,424; face 57,308; IMD2020 52,998.
# Repeats change sampling frequency, not the number of unique training images.
train_repeat_factors = dict(
    casia=5, authentic=1, splicing=1, inpainting=3,
    copymove=4, face=1, imd2020=2
)


def _train_ds(root):
    name = root.rstrip('/').rsplit('/', 1)[-1]
    pipeline = authentic_train_pipeline if name == 'authentic' else train_pipeline
    dataset = _ds(root, 'train', pipeline)
    repeats = train_repeat_factors[name]
    if repeats == 1:
        return dataset
    return dict(type='RepeatDataset', times=repeats, dataset=dataset)


train_dataloader = dict(
    # batch 16 OOMs on 8GB (proven 2026-09-10): 8 + accumulate 2 = effective 16.
    batch_size=8,
    # 4, not 8: training workers stay alive during validation and 8+8 was the
    # RAM pressure point on 4GB GPUs (same fix as v13).
    num_workers=4,
    persistent_workers=True,
    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[_train_ds(r) for r in _CORE_ROOTS]
    )
)

val_dataloader = dict(
    batch_size=16,
    num_workers=4,
    persistent_workers=True,
    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[_ds(r, 'val', test_pipeline) for r in _EVAL_ROOTS]
    )
)

# Locked TEST set: judge once at the end, never tune on it.
# Frozen at the same seven sources as v10-v13 so the logs stay comparable.
test_dataloader = dict(
    batch_size=16,
    num_workers=4,
    persistent_workers=True,
    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[_ds(r, 'test', test_pipeline) for r in _CORE_ROOTS]
    )
)

val_evaluator = dict(
    type='SourceAwareIoUMetric',
    iou_metrics=['mIoU', 'mDice'],
    source_roots={r.rstrip('/').rsplit('/', 1)[-1]: r for r in _EVAL_ROOTS},
    # Pooled mIoU/mDice are computed over these seven only, so 'mIoU' remains
    # comparable with v1.0.6 even though validation now loads nine sources.
    core_sources=[r.rstrip('/').rsplit('/', 1)[-1] for r in _CORE_ROOTS]
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
    # Denser validation over the final quarter, where the 200k runs peaked.
    dynamic_intervals=[(200000, 2500)]
)

default_hooks = dict(
    checkpoint=dict(
        type='CheckpointHook',
        by_epoch=False,
        interval=2500,
        # Two candidates, both decided on core-7 validation. core_macro
        # weights each forged source equally, so it cannot be dominated by the
        # largest source the way pooled mIoU can.
        save_best=['mIoU', 'core_macro_forgery_dice'],
        rule='greater',
        max_keep_ckpts=5
    )
)
