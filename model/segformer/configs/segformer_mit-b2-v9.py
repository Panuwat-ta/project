# ============================================================
# SegFormer MiT-B2 - Forgery Localization Training Config (v9)
# Optimized for 8 GB VRAM GPU | Training from Scratch
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

        # ------------------------------------------------------------
        # Loss Function: ถ่วงน้ำหนักคลาส Forgery ป้องกันปัญหาทายแต่ Background
        # ------------------------------------------------------------
        loss_decode=[
            dict(
                type='CrossEntropyLoss',
                use_sigmoid=False,
                loss_weight=1.0,
                class_weight=[1.0, 2.5]  # [0: Background=1.0, 1: Forgery=2.5]
            ),
            dict(
                type='DiceLoss',
                loss_weight=1.5,         # เน้นความคมชัดของขอบรอยต่อ
                ignore_index=255
            )
        ]
    )
)

# ============================================================
# Dataset Settings
# ============================================================

dataset_type = 'BaseSegDataset'

casia_root = '/run/media/panuwat/USB/dataset/dataset_CASIA2.0/'
defacto_inpaint_root = '/run/media/panuwat/USB/dataset/defacto-inpainting/'
defacto_copymove_root = '/run/media/panuwat/USB/dataset/defacto-copymove/'
defacto_splicing_root = '/run/media/panuwat/USB/dataset/defacto-splicing/'
defacto_face_root = '/run/media/panuwat/USB/dataset/defacto-face/'
imd2020_root = '/run/media/panuwat/USB/dataset/IMD2020/'

metainfo = dict(
    classes=('background', 'forgery'),
    palette=[[0, 0, 0], [255, 0, 0]]
)

# ============================================================
# Data Pipeline with Realistic Augmentations
# ============================================================

albu_train_transforms = [
    dict(type='ImageCompression', quality_lower=40, quality_upper=95, p=0.5),
    dict(type='GaussianBlur', blur_limit=(3, 7), p=0.3),
    dict(type='GaussNoise', var_limit=(10.0, 50.0), p=0.3),
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

# ============================================================
# Sub-Datasets Definition
# ============================================================

dataset_casia_train = dict(
    type=dataset_type,
    data_root=casia_root,
    metainfo=metainfo,
    data_prefix=dict(
        img_path='images/train',
        seg_map_path='annotations/train'
    ),
    pipeline=train_pipeline
)

dataset_defacto_inpaint_train = dict(
    type=dataset_type,
    data_root=defacto_inpaint_root,
    metainfo=metainfo,
    data_prefix=dict(
        img_path='images/train',
        seg_map_path='annotations/train'
    ),
    pipeline=train_pipeline
)

dataset_defacto_copymove_train = dict(
    type=dataset_type,
    data_root=defacto_copymove_root,
    metainfo=metainfo,
    data_prefix=dict(
        img_path='images/train',
        seg_map_path='annotations/train'
    ),
    pipeline=train_pipeline
)

dataset_defacto_splicing_train = dict(
    type=dataset_type,
    data_root=defacto_splicing_root,
    metainfo=metainfo,
    data_prefix=dict(
        img_path='images/train',
        seg_map_path='annotations/train'
    ),
    pipeline=train_pipeline
)

dataset_defacto_face_train = dict(
    type=dataset_type,
    data_root=defacto_face_root,
    metainfo=metainfo,
    data_prefix=dict(
        img_path='images/train',
        seg_map_path='annotations/train'
    ),
    pipeline=train_pipeline
)

dataset_imd2020_train = dict(
    type=dataset_type,
    data_root=imd2020_root,
    metainfo=metainfo,
    data_prefix=dict(
        img_path='images/train',
        seg_map_path='annotations/train'
    ),
    pipeline=train_pipeline
)

# Balanced Sampling: สุ่มซ้ำ CASIA 2.0 (5 เท่า) ป้องกันภาพตัดต่อฝีมือมนุษย์ถูกกลืน
dataset_casia_train_oversampled = dict(
    type='RepeatDataset',
    times=5,
    dataset=dataset_casia_train
)

# Validation Datasets
dataset_casia_val = dict(
    type=dataset_type,
    data_root=casia_root,
    metainfo=metainfo,
    data_prefix=dict(
        img_path='images/val',
        seg_map_path='annotations/val'
    ),
    pipeline=test_pipeline
)

dataset_imd2020_val = dict(
    type=dataset_type,
    data_root=imd2020_root,
    metainfo=metainfo,
    data_prefix=dict(
        img_path='images/val',
        seg_map_path='annotations/val'
    ),
    pipeline=test_pipeline
)

# ============================================================
# Dataloaders (Optimized for 8 GB VRAM: Batch Size = 16)
# ============================================================

train_dataloader = dict(
    batch_size=16,          # ขยายเป็น 16 สำหรับการ์ดจอ VRAM 8 GB
    num_workers=8,
    persistent_workers=True,

    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[
            dataset_casia_train_oversampled,
            dataset_defacto_splicing_train,
            dataset_defacto_inpaint_train,
            dataset_defacto_copymove_train,
            dataset_defacto_face_train,
            dataset_imd2020_train
        ]
    )
)

val_dataloader = dict(
    batch_size=16,
    num_workers=8,
    persistent_workers=True,

    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[
            dataset_casia_val,
            dataset_imd2020_val
        ]
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
# Optimizer & Differential Learning Rate (Linear Scaled for Batch 16)
# ============================================================

optim_wrapper = dict(
    type='AmpOptimWrapper',
    optimizer=dict(
        type='AdamW',
        lr=2e-5,            # ปรับเพิ่มเป็น 2e-5 ตาม Linear Scaling Rule สำหรับ Batch Size 16
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

# ============================================================
# Scheduler & Training Iterations (120,000 iters)
# ============================================================

max_iters = 120000

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
    val_interval=2500  # ประเมินผลทุกๆ 2,500 รอบ
)

# ============================================================
# Checkpoint Saving Hook
# ============================================================

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
