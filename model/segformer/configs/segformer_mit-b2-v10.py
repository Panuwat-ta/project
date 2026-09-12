# SegFormer MiT-B2 Forgery Localization (v10) — 8GB VRAM, ImageNet-pretrained backbone.
# Data: clean tree only (PNG lossless, stem-grouped train/val/test).
# Set DATA_ROOT on the training machine before running.
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
                loss_weight=1.0,
                class_weight=[1.0, 2.5]
            ),
            dict(
                type='DiceLoss',
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
    dict(type='ImageCompression', quality_range=(40, 95), p=0.5),
    dict(type='GaussianBlur', blur_limit=(3, 7), p=0.3),
    dict(type='GaussNoise', std_range=(0.01, 0.03), p=0.3),
    dict(type='ColorJitter', brightness=0.2, contrast=0.2, saturation=0.2, hue=0.1, p=0.5),
]

train_pipeline = [
    dict(type='LoadImageFromFile'),
    dict(type='LoadAnnotations', reduce_zero_label=False),
    dict(type='RandomResize', scale=(512, 512), ratio_range=(0.5, 2.0)),
    dict(type='RandomCrop', crop_size=(512, 512)),
    dict(type='RandomFlip', prob=0.5),
    dict(type='Albu', transforms=albu_train_transforms),
    dict(type='PhotoMetricDistortion'),
    dict(type='PackSegInputs')
]

test_pipeline = [
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

dataset_casia_train = _ds(casia_root, 'train', train_pipeline)
dataset_casia_train_oversampled = dict(
    type='RepeatDataset',
    times=5,
    dataset=dataset_casia_train
)

train_dataloader = dict(
    # batch 16 OOMs on 8GB (proven 2026-09-10): 8 + accumulate 2 = effective 16.
    batch_size=8,
    num_workers=8,
    persistent_workers=True,
    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[dataset_casia_train_oversampled] +
                 [_ds(r, 'train', train_pipeline) for r in _TRAIN_ROOTS[1:]]
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
    type='AmpOptimWrapper',
    accumulative_counts=2,
    optimizer=dict(
        type='AdamW',
        lr=2e-5,
        betas=(0.9, 0.999),
        weight_decay=0.01
    ),
    paramwise_cfg=dict(
        custom_keys={
            'backbone': dict(lr_mult=0.1, decay_mult=1.0),
            'decode_head': dict(lr_mult=10.0)
        }
    )
)

max_iters = 200000

param_scheduler = [
    dict(
        type='LinearLR',
        start_factor=1e-6,
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
    val_interval=2500
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
