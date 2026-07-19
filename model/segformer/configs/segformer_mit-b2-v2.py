# ============================================================
# SegFormer MiT-B2 - Forgery Localization Training Config
# ============================================================

_base_ = [
    '../library/mmsegmentation/configs/segformer/'
    'segformer_mit-b0_8xb2-160k_ade20k-512x512.py'
]

# ============================================================
# Model Settings
# ============================================================

checkpoint = (
    'https://download.openmmlab.com/mmsegmentation/v0.5/'
    'pretrain/segformer/'
    'mit_b2_20220624-66e8bf70.pth'
)

model = dict(
    backbone=dict(
        type='MixVisionTransformer',
        init_cfg=dict(
            type='Pretrained',
            checkpoint=checkpoint
        ),
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
                loss_weight=1.0
            ),
            dict(
                type='DiceLoss',
                loss_weight=1.0,
                ignore_index=255
            )
        ]
    )
)

# ============================================================
# Dataset Settings
# ============================================================

dataset_type = 'BaseSegDataset'

data_root = 'data/dataset_CASIA2.0/'

metainfo = dict(
    classes=('background', 'forgery'),
    palette=[[0, 0, 0], [255, 0, 0]]
)

# ============================================================
# Data Pipeline
# ============================================================

train_pipeline = [
    dict(type='LoadImageFromFile'),
    dict(type='LoadAnnotations', reduce_zero_label=False),
    dict(type='RandomResize', scale=(512, 512), ratio_range=(0.5, 2.0)),
    dict(type='RandomCrop', crop_size=(512, 512)),
    dict(type='RandomFlip', prob=0.5),
    dict(type='PhotoMetricDistortion'),
    dict(type='PackSegInputs')
]

test_pipeline = [
    dict(type='LoadImageFromFile'),
    dict(type='Resize', scale=(512, 512), keep_ratio=False),
    dict(type='LoadAnnotations', reduce_zero_label=False),
    dict(type='PackSegInputs')
]

# ============================================================
# Dataloader
# ============================================================

train_dataloader = dict(
    batch_size=8,
    num_workers=4,
    persistent_workers=True,

    dataset=dict(
        type=dataset_type,
        data_root=data_root,
        metainfo=metainfo,

        data_prefix=dict(
            img_path='images/train',
            seg_map_path='annotations/train'
        ),

        pipeline=train_pipeline
    )
)

val_dataloader = dict(
    batch_size=4,
    num_workers=4,
    persistent_workers=True,

    dataset=dict(
        type=dataset_type,
        data_root=data_root,
        metainfo=metainfo,

        data_prefix=dict(
            img_path='images/val',
            seg_map_path='annotations/val'
        ),

        pipeline=test_pipeline
    )
)

test_dataloader = val_dataloader

# ============================================================
# Evaluation Metrics
# ============================================================

val_evaluator = dict(
    type='IoUMetric',
    iou_metrics=['mIoU', 'mDice']
)

test_evaluator = val_evaluator

# ============================================================
# Fine-tuning / Incremental Learning
# ============================================================

# ใช้เมื่อ train ต่อจากโมเดลเดิม (เอาคอมเมนต์ออกแล้วแก้ไข path เมื่อต้องการใช้)
# load_from = './work_dirs/'

# ============================================================
# Optimizer
# ============================================================

optim_wrapper = dict(
    type='AmpOptimWrapper',
    
    # หากรันแล้วเจอ Error CUDA Out of Memory ให้ปรับ train_dataloader batch_size=4 
    # และเปิดใช้งาน accumulative_counts=2 ด้านล่างนี้แทน
    # accumulative_counts=2, 
    
    optimizer=dict(
        type='AdamW',
        lr=1e-5,
        betas=(0.9, 0.999),
        weight_decay=0.01
    ),

    paramwise_cfg=dict(
        custom_keys={
            # Backbone เรียนช้า ป้องกันลืม feature เดิม
            'backbone': dict(lr_mult=0.1, decay_mult=1.0),
            # Decoder เรียนเร็ว
            'decode_head': dict(lr_mult=10.0)
        }
    )
)

# ============================================================
# Scheduler
# ============================================================

param_scheduler = [
    dict(
        type='LinearLR',
        start_factor=1e-6,
        begin=0,
        end=1500,
        by_epoch=False
    ),
    dict(
        type='PolyLR',
        eta_min=0,
        power=1.0,
        begin=1500,
        end=160000,
        by_epoch=False
    )
]

# ============================================================
# Training Runtime
# ============================================================

train_cfg = dict(
    type='IterBasedTrainLoop',
    max_iters=160000,
    val_interval=4000
)

# ============================================================
# Checkpoint
# ============================================================

import os
import re

work_dir_base = './work_dirs'
major = 1
minor = 0
patch = 0

if os.path.exists(work_dir_base):
    existing_dirs = os.listdir(work_dir_base)
    versions = []
    for d in existing_dirs:
        match = re.match(r'^v(\d+)\.(\d+)\.(\d+)$', d)
        if match:
            versions.append((int(match.group(1)), int(match.group(2)), int(match.group(3))))
    
    if versions:
        max_major, max_minor, max_patch = max(versions)
        major, minor, patch = max_major, max_minor, max_patch + 1
        
        if patch >= 10:
            patch = 0
            minor += 1

model_version = f"v{major}.{minor}.{patch}"
work_dir = f'{work_dir_base}/{model_version}'

default_hooks = dict(
    checkpoint=dict(
        type='CheckpointHook',
        interval=4000,
        save_best='mIoU',
        rule='greater',
        max_keep_ckpts=5
    )
)
