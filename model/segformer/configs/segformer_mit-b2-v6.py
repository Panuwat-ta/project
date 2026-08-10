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

# เก็บชุดข้อมูลแยกโฟลเดอร์ไว้ แล้วรวมเฉพาะตอน train
casia_root = 'dataset/dataset_CASIA2.0/'
defacto_inpaint_root = 'dataset/defacto-inpainting/'
defacto_copymove_root = 'dataset/defacto-copymove/'

metainfo = dict(
    classes=('background', 'forgery'),
    palette=[[0, 0, 0], [255, 0, 0]]
)

# ============================================================
# Data Pipeline
# ============================================================

albu_train_transforms = [
    dict(type='ImageCompression', quality_lower=40, quality_upper=90, p=0.5),
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
# Dataloader
# ============================================================

# ทุกชุดต้องใช้ค่า mask เดียวกัน: background=0, forgery=1
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

# Validation ใช้ pipeline ที่ไม่มี augmentation และรวมคะแนนจากทั้งสามชุด
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

dataset_defacto_inpaint_val = dict(
    type=dataset_type,
    data_root=defacto_inpaint_root,
    metainfo=metainfo,
    data_prefix=dict(
        img_path='images/val',
        seg_map_path='annotations/val'
    ),
    pipeline=test_pipeline
)

dataset_defacto_copymove_val = dict(
    type=dataset_type,
    data_root=defacto_copymove_root,
    metainfo=metainfo,
    data_prefix=dict(
        img_path='images/val',
        seg_map_path='annotations/val'
    ),
    pipeline=test_pipeline
)

train_dataloader = dict(
    batch_size=8,
    num_workers=4,
    persistent_workers=True,

    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[dataset_casia_train, dataset_defacto_inpaint_train, dataset_defacto_copymove_train]
    )
)

val_dataloader = dict(
    batch_size=8,
    num_workers=4,
    persistent_workers=True,

    dataset=dict(
        _delete_=True,
        type='ConcatDataset',
        datasets=[dataset_casia_val, dataset_defacto_inpaint_val, dataset_defacto_copymove_val]
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
        eta_min=1e-6,  # ไม่ให้ lr ตกเป็น 0 สนิท
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
# work_dir และ load_from ถูกส่งผ่าน train.sh --work-dir และ --load-from
# เพื่อให้ config ไม่ผูกกับ path ใด path หนึ่ง
# ============================================================

default_hooks = dict(
    checkpoint=dict(
        type='CheckpointHook',
        interval=4000,
        save_best='mIoU',
        rule='greater',
        max_keep_ckpts=5
    )
)
