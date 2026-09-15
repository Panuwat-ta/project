# SegFormer MiT-B2 Forgery Localization (v11) — candidate for fresh pretraining transfer.
# Data: clean tree only (PNG lossless, stem-grouped train/val/test).
# Set DATA_ROOT on the training machine before running.
# Run from model/segformer:
# ./train.sh --config configs/segformer_mit-b2-v11.py --no-load
# These are experiment settings, not a demonstrated improvement over v10.
# Choose settings on validation; evaluate the locked test only after selection.
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
                defacto_face_root, imd2020_root]

# Fixed training-only repeats, based on the current training file counts.
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
    num_workers=8,
    persistent_workers=True,
    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[_train_ds(r) for r in _TRAIN_ROOTS]
    )
)

val_dataloader = dict(
    batch_size=16,
    num_workers=8,
    persistent_workers=True,
    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[_ds(r, 'val', test_pipeline) for r in _TRAIN_ROOTS]
    )
)

# Locked TEST set: judge once at the end, never tune on it.
test_dataloader = dict(
    batch_size=16,
    num_workers=8,
    persistent_workers=True,
    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[_ds(r, 'test', test_pipeline) for r in _TRAIN_ROOTS]
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

max_iters = 200000

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
