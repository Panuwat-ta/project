# SegFormer MiT-B2 Forgery Localization (v14) — candidate for v1.0.9.
# Run fresh from MIT-B2 pretrained (do NOT warm-start from an older version):
# ./train.sh --config configs/segformer_mit-b2-v14.py --no-load
#
# REQUIRES a training machine with all NINE dataset sources mounted, including
# aiforge/realtext images/val. They are validation-only here, but
# SourceAwareIoUMetric raises on any source_roots entry that produced no
# result, and the dataset build raises FileNotFoundError on a missing folder.
# That fail-loud behaviour is intentional. v12 and v13 had the same
# requirement. If the extra sources are unavailable, run with the
# monitoring-only block removed from _EVAL_ROOTS and source_roots.
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
# WHY aiforge/realtext ARE NOT IN TRAINING -- read the unit, not the count
# -----------------------------------------------------------------------
# A previous draft of this file justified that choice as "they displace CASIA
# in the sampling mix". That reasoning is wrong. The training signal is
# foreground pixel mass, not image count, because foreground share per image
# differs by more than an order of magnitude across sources.
#
# Mean foreground percentage, measured on 120 random train masks per source:
#   casia 18.90   face 21.19   splicing 2.48   imd2020 1.43   copymove 1.67
#   inpainting 1.16   aiforge 0.98   realtext 1.08   authentic 0.00
#
#   recipe                  image-count share   FOREGROUND MASS share
#   v11 / v1.0.6                     0.00%                 0.00%
#   v12 / v1.0.7                    15.03%                 3.40%
#   v13 / v1.0.8                    10.12%                 2.09%
#   this config + aiforge/realtext x1 2.53%                 0.49%
#
# So the damage is not proportional to how much data was added. 2.09% of the
# foreground mass cost 5.63 points of Forgery Dice. The plausible cause is a
# modality shift, not a volume effect: realtext is vankey/RealText-V2, scanned
# multi-script text documents (th, ar, en, zh, ms, id) and 89.6% of its pixels
# are near-white, against 1.6-4.4% for the core sources, which are natural
# photographs (casia is computer graphics, imd2020 is inpainting).
# CopyPasteForgery is an equally plausible cause. This is a HYPOTHESIS, not a
# finding: v12 changed data, CopyPaste, repeat factors, budget and the
# validation set at the same time, so the confound cannot be separated from
# the runs that exist.
#
# Accepted cost of training on zero of them: the core seven contain no forged
# text document at all, and no Thai text forgery (realtext holds only 1,456
# Thai images of 9,706). aiforge is Scam-AI/AIForge-Doc-v2, AI-forged
# documents, which matches the AI-generated scope in AGENTS.md. Both are
# invisible to every evaluation used for ranking: the locked common test and
# the local 105 set contain neither. They stay in validation as
# monitoring-only so the cost is measured rather than assumed.
#
# CHANGES vs v11 (every other v11 setting is preserved)
# ---------------------------------------------------
# 1. aiforge and realtext are NOT in the training mixture. See above.
# 2. CopyPasteForgery is NOT used. p=0.30 (v12) and p=0.20 (v13) were only
#    ever tested together with the new-domain shift, so no run has measured it
#    on its own.
# 3. imd2020 repeat 2 -> 3. IMD2020 is the weakest core source (42.13% Dice in
#    v1.0.6) and is the one recorded promotion target that v1.0.6 failed.
#    v12 (x3) and v13 (x3) both improved it, to 49.62 and 47.73, but both also
#    changed the data mixture, so repeat 3 alone is still unproven. Effect on
#    the balance: CASIA 10.5% -> 9.9% of images, IMD2020 12.5% -> 17.7%.
# 4. Budget 200k -> 250k iterations. Both 200k runs peaked inside the last 3% of
#    their budget (v1.0.5 best at 197,500; v1.0.6 best at 195,000), which is the
#    signature of an under-trained run rather than an overfitted one. 250k
#    matches v12/v13. This is the one budget increase not yet tested on the v11
#    recipe, so it is a hypothesis, not a measured gain.
# 5. Validation uses SourceAwareIoUMetric so per-source Forgery Dice and FPR are
#    logged. In forgery_metrics.py the pooled mIoU/mDice are computed over
#    core_sources only, so 'mIoU' stays comparable to v1.0.6 even though the
#    validation set is larger. Verified: super().compute_metrics(core).
# 6. aiforge and realtext stay in validation as MONITORING-ONLY sources. They
#    cannot steer save_best (see point 5).
# 7. Keep both best_mIoU and best_core_macro_forgery_dice checkpoints so the
#    checkpoint choice can be made from validation evidence, never from the
#    locked test.
# 8. num_workers 8 -> 4 on every dataloader. Workers from the training loader are
#    still alive during validation, and 8+8 was the OOM risk on 4GB GPUs.
# 9. seed 42, same as v11, so this is not a needless extra variable.
# 10. TiledValidationHook adds a second, production-shaped pass at native
#     resolution. See the section below.
#
# DELIBERATELY UNCHANGED FROM v11
# -------------------------------
# Loss (CE class_weight [1.0, 2.5] + softmax Dice 1.5), AdamW lr 1e-5 with
# decode_head lr_mult 10, zero decay on norm/bias, clip_grad 1.0, accumulate 2,
# LinearLR warmup 0->3000 then PolyLR, RandomResize ratio (1.0, 2.0) keep_ratio
# False, RandomCrop cat_max_ratio 0.99 with the authentic exception, the light
# Albu set, and the whole-image 512 validation protocol. These produced the
# v1.0.6 numbers and there is no measured reason to move them.
#
# THE VALIDATION BLIND SPOT, AND WHAT THE HOOK DOES ABOUT IT
# ---------------------------------------------------------
# Validation rescales each image to 512x512 and runs one forward pass, but
# production (server/app/services/tiling.py) runs overlapping 512x512 tiles at
# NATIVE resolution with overlap 64 and averages the probability maps. For
# v1.0.8, same checkpoint, same sources, two protocols:
#
#   source    validation (squash 512)   local-105 (native tiled)    gap
#   casia               76.52                      75.25           +1.27
#   inpainting          79.41                      76.46           +2.96
#   face                98.92                      92.18           +6.74
#   splicing            93.36                      81.17          +12.19
#   copymove            77.00                      60.91          +16.10
#   imd2020             76.94                      47.73          +29.21
#
# Validation is optimistic by 11.41 points on average. The two sets are also
# different datasets, so protocol and sample selection cannot be separated from
# that table alone; it shows the blind spot exists, not its sole cause.
#
# TiledValidationHook closes it as a measurement, not as a replacement. It runs
# a second pass over a fixed, seeded subsample at native resolution using the
# same tiling math as production, and writes tiled_<source>_forgery_dice and
# tiled_<source>_fpr into the validation metrics. Those keys appear in the
# Iter(val) line and in vis_data/*.json. They are a monitoring signal and are
# NOT save_best keys: checkpoint selection keeps using the regular evaluator.
#
# Two implementation details that are easy to get wrong:
#   - The hook must run before RuntimeInfoHook (priority VERY_HIGH = 10), which
#     is the component that pushes validation metrics into the message hub that
#     the LoggerHook reads. tiled_val.py sets priority = 'HIGHEST' for this
#     reason. At the default NORMAL the keys would be added after publishing
#     and would silently never reach the log.
#   - mmseg's built-in slide_inference averages LOGITS; production averages
#     softmax PROBABILITIES. tiled_val.py implements the production version.
#     Verified numerically against server/app/services/tiling.py: max absolute
#     difference 5.96e-08 (float32 epsilon) over 512x512, 640x480, 700x900,
#     1368x2000, 480x640 and 300x700 inputs, on both axes.
#
# Cost, measured: the configured subsample is imd2020 1,500 + aiforge 200 +
# realtext 200 = 14,123 forward passes, counted on the real images (6.2, 6.6
# and 17.8 tiles per image respectively). At the 30.7 tiles/s measured for
# batch 1 on an RTX 3050 that is about 7.7 minutes per trigger, so ten triggers
# over 250k iterations cost roughly 1.3 hours. Batch 1 is forced by mmseg's
# SegDataPreProcessor, which asserts a uniform size within a batch; the native
# validation set has 3,000+ distinct sizes, so batching by size is not possible
# without code changes. Batching tiles would gain little anyway: at 512x512 this
# model reaches 30.7 tiles/s at batch 1 and 35.5 at batch 4.
# The throughput figure was measured on a 4GB laptop GPU, not on the training
# machine, and that machine has other processes resident during a run. Treat
# 7.7 minutes as an order-of-magnitude estimate and re-measure on the first
# real trigger; adjust interval_iters if it turns out materially slower.
#
# VRAM: this pass runs from after_val_epoch, so the training graph, gradients
# and AdamW state are all still resident. tiled_val.py frees cached blocks
# before starting, but peak usage is still training peak (6,299 MB measured for
# this recipe) plus one 512 tile. On the training card that should fit; on a
# smaller card it will not. The hook is deliberately fail-soft: a source that
# raises is skipped with a WARNING, recorded as {"error": ...} in
# tiled_val_log.jsonl, and the run continues. Verified by a real-Runner smoke
# test on a 4GB card where every source OOM'd and training still exited 0.
# A monitoring feature must not be able to destroy a multi-hour run.
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
#   A. v15 = this config + aiforge x1 + realtext x1, no CopyPasteForgery.
#      Adds 0.49% of foreground mass. If the core seven hold or improve, the
#      damage in v12/v13 came from CopyPasteForgery and the AI-generated and
#      text-document coverage is close to free. If they regress, the modality
#      shift is real and the decision becomes whether to ship a separate
#      document detector. Either way this isolates ONE variable, which neither
#      v12 nor v13 did.
#   B. CopyPasteForgery alone on the v14 mixture, p <= 0.2.
#   C. Per-source class weighting. class_weight [1.0, 2.5] and
#      cat_max_ratio 0.99 were tuned on sources with ~2% foreground. Median
#      foreground is below 1% for casia (0.00%), realtext (0.24%), inpainting
#      (0.39%), splicing (0.40%), aiforge (0.68%) and copymove (0.88%), so the
#      crop rule is already ineffective for most sources and only face and
#      imd2020 satisfy it. Untested.
#
# tiled_val.py and forgery_metrics.py must sit next to this config's project
# root; train.sh puts the segformer directory on PYTHONPATH. Keep the bare
# __import__ side-effect registration pattern.
__import__('tiled_val')
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

# Fixed training-only repeats. Core seven only; aiforge and realtext are
# validation-only in this config.
# Effective entries: CASIA 44,565; authentic 85,130; splicing 76,500;
# inpainting 53,748; copymove 52,424; face 57,308; IMD2020 79,497.
# Total 449,172. Image-count share: CASIA 9.9%, IMD2020 17.7%.
# Repeats change sampling frequency, not the number of unique training images.
train_repeat_factors = dict(
    casia=5, authentic=1, splicing=1, inpainting=3,
    copymove=4, face=1, imd2020=3
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

# Second, production-shaped measurement pass. Monitoring only: the keys it adds
# (tiled_<source>_forgery_dice, tiled_<source>_fpr) are not save_best keys.
# Tiling geometry matches server/app/services/tiling.py: tile 512, overlap 64,
# decision threshold 0.5 on the averaged probability map.
# imd2020 is sampled hardest because it is both the weakest core source and the
# one validation squashes hardest (1.73x linear downscale, 6.06 tiles per image).
# aiforge and realtext are sampled lightly because this config never trains on
# them; these numbers quantify the accepted blind spot rather than track a
# regression. Tiled dice of ~55 was the best recorded for those sources
# (v1.0.8, which did train on them), so that is the reference point.
custom_hooks = [
    dict(
        type='TiledValidationHook',
        sources=[
            dict(name='imd2020', data_root=DATA_ROOT + '/imd2020/', split='val'),
            dict(name='aiforge', data_root=DATA_ROOT + '/aiforge/', split='val'),
            dict(name='realtext', data_root=DATA_ROOT + '/realtext/', split='val'),
        ],
        subsample=dict(imd2020=1500, aiforge=200, realtext=200),
        interval_iters=25000,
        tile_size=512,
        overlap=64,
        threshold=0.5,
        num_workers=2,
        seed=20260929,
    )
]
