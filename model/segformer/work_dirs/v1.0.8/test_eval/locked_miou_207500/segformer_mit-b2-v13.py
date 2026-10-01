DATA_ROOT = '/run/media/panuwat/USB/dataset'
_COPYPASTE_SOURCES = frozenset({'copymove', 'imd2020', 'inpainting'})
_TEST_FROZEN_ROOTS = [
    '/run/media/panuwat/USB/dataset/casia/',
    '/run/media/panuwat/USB/dataset/authentic/',
    '/run/media/panuwat/USB/dataset/splicing/',
    '/run/media/panuwat/USB/dataset/inpainting/',
    '/run/media/panuwat/USB/dataset/copymove/',
    '/run/media/panuwat/USB/dataset/face/',
    '/run/media/panuwat/USB/dataset/imd2020/',
]
_TRAIN_ROOTS = [
    '/run/media/panuwat/USB/dataset/casia/',
    '/run/media/panuwat/USB/dataset/authentic/',
    '/run/media/panuwat/USB/dataset/splicing/',
    '/run/media/panuwat/USB/dataset/inpainting/',
    '/run/media/panuwat/USB/dataset/copymove/',
    '/run/media/panuwat/USB/dataset/face/',
    '/run/media/panuwat/USB/dataset/imd2020/',
    '/run/media/panuwat/USB/dataset/aiforge/',
    '/run/media/panuwat/USB/dataset/realtext/',
]
aiforge_root = '/run/media/panuwat/USB/dataset/aiforge/'
albu_train_transforms = [
    dict(p=0.3, quality_range=(
        60,
        95,
    ), type='ImageCompression'),
    dict(blur_limit=(
        3,
        3,
    ), p=0.1, type='GaussianBlur'),
    dict(p=0.1, std_range=(
        0.005,
        0.015,
    ), type='GaussNoise'),
    dict(
        brightness=0.1,
        contrast=0.1,
        hue=0.03,
        p=0.3,
        saturation=0.1,
        type='ColorJitter'),
]
authentic_root = '/run/media/panuwat/USB/dataset/authentic/'
authentic_train_pipeline = [
    dict(type='LoadImageFromFile'),
    dict(reduce_zero_label=False, type='LoadAnnotations'),
    dict(
        keep_ratio=False,
        ratio_range=(
            1.0,
            2.0,
        ),
        scale=(
            512,
            512,
        ),
        type='RandomResize'),
    dict(cat_max_ratio=1.0, crop_size=(
        512,
        512,
    ), type='RandomCrop'),
    dict(prob=0.5, type='RandomFlip'),
    dict(
        transforms=[
            dict(p=0.3, quality_range=(
                60,
                95,
            ), type='ImageCompression'),
            dict(blur_limit=(
                3,
                3,
            ), p=0.1, type='GaussianBlur'),
            dict(p=0.1, std_range=(
                0.005,
                0.015,
            ), type='GaussNoise'),
            dict(
                brightness=0.1,
                contrast=0.1,
                hue=0.03,
                p=0.3,
                saturation=0.1,
                type='ColorJitter'),
        ],
        type='Albu'),
    dict(type='PackSegInputs'),
]
casia_root = '/run/media/panuwat/USB/dataset/casia/'
checkpoint = 'https://download.openmmlab.com/mmsegmentation/v0.5/pretrain/segformer/mit_b2_20220624-66e8bf70.pth'
crop_size = (
    512,
    512,
)
data_preprocessor = dict(
    bgr_to_rgb=True,
    mean=[
        123.675,
        116.28,
        103.53,
    ],
    pad_val=0,
    seg_pad_val=255,
    size=(
        512,
        512,
    ),
    std=[
        58.395,
        57.12,
        57.375,
    ],
    type='SegDataPreProcessor')
data_root = 'data/ade/ADEChallengeData2016'
dataset_type = 'BaseSegDataset'
defacto_copymove_root = '/run/media/panuwat/USB/dataset/copymove/'
defacto_face_root = '/run/media/panuwat/USB/dataset/face/'
defacto_inpaint_root = '/run/media/panuwat/USB/dataset/inpainting/'
defacto_splicing_root = '/run/media/panuwat/USB/dataset/splicing/'
default_hooks = dict(
    checkpoint=dict(
        by_epoch=False,
        interval=2500,
        max_keep_ckpts=5,
        rule='greater',
        save_best=[
            'mIoU',
            'core_macro_forgery_dice',
        ],
        type='CheckpointHook'),
    logger=dict(interval=50, log_metric_by_epoch=False, type='LoggerHook'),
    param_scheduler=dict(type='ParamSchedulerHook'),
    sampler_seed=dict(type='DistSamplerSeedHook'),
    timer=dict(type='IterTimerHook'),
    visualization=dict(type='SegVisualizationHook'))
default_scope = 'mmseg'
env_cfg = dict(
    cudnn_benchmark=True,
    dist_cfg=dict(backend='nccl'),
    mp_cfg=dict(mp_start_method='fork', opencv_num_threads=0))
imd2020_root = '/run/media/panuwat/USB/dataset/imd2020/'
img_ratios = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
]
launcher = 'none'
load_from = 'work_dirs/v1.0.8/best_mIoU_iter_207500.pth'
log_level = 'INFO'
log_processor = dict(by_epoch=False)
max_iters = 250000
metainfo = dict(
    classes=(
        'background',
        'forgery',
    ),
    palette=[
        [
            0,
            0,
            0,
        ],
        [
            255,
            0,
            0,
        ],
    ])
model = dict(
    backbone=dict(
        attn_drop_rate=0.0,
        drop_path_rate=0.1,
        drop_rate=0.0,
        embed_dims=64,
        in_channels=3,
        init_cfg=dict(
            checkpoint=
            'https://download.openmmlab.com/mmsegmentation/v0.5/pretrain/segformer/mit_b2_20220624-66e8bf70.pth',
            type='Pretrained'),
        mlp_ratio=4,
        num_heads=[
            1,
            2,
            5,
            8,
        ],
        num_layers=[
            3,
            4,
            6,
            3,
        ],
        num_stages=4,
        out_indices=(
            0,
            1,
            2,
            3,
        ),
        patch_sizes=[
            7,
            3,
            3,
            3,
        ],
        qkv_bias=True,
        sr_ratios=[
            8,
            4,
            2,
            1,
        ],
        type='MixVisionTransformer'),
    data_preprocessor=dict(
        bgr_to_rgb=True,
        mean=[
            123.675,
            116.28,
            103.53,
        ],
        pad_val=0,
        seg_pad_val=255,
        size=(
            512,
            512,
        ),
        std=[
            58.395,
            57.12,
            57.375,
        ],
        type='SegDataPreProcessor'),
    decode_head=dict(
        align_corners=False,
        channels=256,
        dropout_ratio=0.1,
        ignore_index=255,
        in_channels=[
            64,
            128,
            320,
            512,
        ],
        in_index=[
            0,
            1,
            2,
            3,
        ],
        loss_decode=[
            dict(
                avg_non_ignore=True,
                class_weight=[
                    1.0,
                    2.5,
                ],
                loss_weight=1.0,
                type='CrossEntropyLoss',
                use_sigmoid=False),
            dict(
                ignore_index=255,
                loss_weight=1.5,
                type='DiceLoss',
                use_sigmoid=False),
        ],
        norm_cfg=dict(requires_grad=True, type='SyncBN'),
        num_classes=2,
        type='SegformerHead'),
    pretrained=None,
    test_cfg=dict(mode='whole'),
    train_cfg=dict(),
    type='EncoderDecoder')
norm_cfg = dict(requires_grad=True, type='SyncBN')
optim_wrapper = dict(
    accumulative_counts=2,
    clip_grad=dict(max_norm=1.0, norm_type=2),
    optimizer=dict(
        betas=(
            0.9,
            0.999,
        ), lr=1e-05, type='AdamW', weight_decay=0.01),
    paramwise_cfg=dict(
        bias_decay_mult=0.0,
        custom_keys=dict({
            'decode_head':
            dict(lr_mult=10.0),
            'decode_head.conv_seg.bias':
            dict(decay_mult=0.0, lr_mult=10.0),
            'decode_head.convs.0.bn':
            dict(decay_mult=0.0, lr_mult=10.0),
            'decode_head.convs.1.bn':
            dict(decay_mult=0.0, lr_mult=10.0),
            'decode_head.convs.2.bn':
            dict(decay_mult=0.0, lr_mult=10.0),
            'decode_head.convs.3.bn':
            dict(decay_mult=0.0, lr_mult=10.0),
            'decode_head.fusion_conv.bn':
            dict(decay_mult=0.0, lr_mult=10.0)
        }),
        norm_decay_mult=0.0),
    type='AmpOptimWrapper')
optimizer = dict(lr=0.01, momentum=0.9, type='SGD', weight_decay=0.0005)
param_scheduler = [
    dict(
        begin=0, by_epoch=False, end=3000, start_factor=0.01, type='LinearLR'),
    dict(
        begin=3000,
        by_epoch=False,
        end=250000,
        eta_min=1e-06,
        power=1.0,
        type='PolyLR'),
]
plain_train_pipeline = [
    dict(type='LoadImageFromFile'),
    dict(reduce_zero_label=False, type='LoadAnnotations'),
    dict(
        keep_ratio=False,
        ratio_range=(
            1.0,
            2.0,
        ),
        scale=(
            512,
            512,
        ),
        type='RandomResize'),
    dict(cat_max_ratio=0.99, crop_size=(
        512,
        512,
    ), type='RandomCrop'),
    dict(prob=0.5, type='RandomFlip'),
    dict(
        transforms=[
            dict(p=0.3, quality_range=(
                60,
                95,
            ), type='ImageCompression'),
            dict(blur_limit=(
                3,
                3,
            ), p=0.1, type='GaussianBlur'),
            dict(p=0.1, std_range=(
                0.005,
                0.015,
            ), type='GaussNoise'),
            dict(
                brightness=0.1,
                contrast=0.1,
                hue=0.03,
                p=0.3,
                saturation=0.1,
                type='ColorJitter'),
        ],
        type='Albu'),
    dict(type='PackSegInputs'),
]
randomness = dict(deterministic=False, diff_rank_seed=False, seed=42)
realtext_root = '/run/media/panuwat/USB/dataset/realtext/'
resume = False
test_cfg = dict(type='TestLoop')
test_dataloader = dict(
    batch_size=16,
    dataset=dict(
        datasets=[
            dict(
                data_prefix=dict(
                    img_path='images/test', seg_map_path='annotations/test'),
                data_root='/run/media/panuwat/USB/dataset/casia/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/test', seg_map_path='annotations/test'),
                data_root='/run/media/panuwat/USB/dataset/authentic/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/test', seg_map_path='annotations/test'),
                data_root='/run/media/panuwat/USB/dataset/splicing/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/test', seg_map_path='annotations/test'),
                data_root='/run/media/panuwat/USB/dataset/inpainting/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/test', seg_map_path='annotations/test'),
                data_root='/run/media/panuwat/USB/dataset/copymove/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/test', seg_map_path='annotations/test'),
                data_root='/run/media/panuwat/USB/dataset/face/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/test', seg_map_path='annotations/test'),
                data_root='/run/media/panuwat/USB/dataset/imd2020/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
        ],
        type='ConcatDataset'),
    num_workers=4,
    persistent_workers=True,
    sampler=dict(shuffle=False, type='DefaultSampler'))
test_evaluator = dict(
    iou_metrics=[
        'mIoU',
        'mDice',
    ], type='IoUMetric')
test_pipeline = [
    dict(type='LoadImageFromFile'),
    dict(keep_ratio=False, scale=(
        512,
        512,
    ), type='Resize'),
    dict(reduce_zero_label=False, type='LoadAnnotations'),
    dict(type='PackSegInputs'),
]
train_cfg = dict(
    dynamic_intervals=[
        (
            150000,
            2500,
        ),
    ],
    max_iters=250000,
    type='IterBasedTrainLoop',
    val_interval=5000)
train_dataloader = dict(
    batch_size=8,
    dataset=dict(
        datasets=[
            dict(
                dataset=dict(
                    data_prefix=dict(
                        img_path='images/train',
                        seg_map_path='annotations/train'),
                    data_root='/run/media/panuwat/USB/dataset/casia/',
                    img_suffix='.png',
                    metainfo=dict(
                        classes=(
                            'background',
                            'forgery',
                        ),
                        palette=[
                            [
                                0,
                                0,
                                0,
                            ],
                            [
                                255,
                                0,
                                0,
                            ],
                        ]),
                    pipeline=[
                        dict(type='LoadImageFromFile'),
                        dict(reduce_zero_label=False, type='LoadAnnotations'),
                        dict(
                            keep_ratio=False,
                            ratio_range=(
                                1.0,
                                2.0,
                            ),
                            scale=(
                                512,
                                512,
                            ),
                            type='RandomResize'),
                        dict(
                            cat_max_ratio=0.99,
                            crop_size=(
                                512,
                                512,
                            ),
                            type='RandomCrop'),
                        dict(prob=0.5, type='RandomFlip'),
                        dict(
                            transforms=[
                                dict(
                                    p=0.3,
                                    quality_range=(
                                        60,
                                        95,
                                    ),
                                    type='ImageCompression'),
                                dict(
                                    blur_limit=(
                                        3,
                                        3,
                                    ),
                                    p=0.1,
                                    type='GaussianBlur'),
                                dict(
                                    p=0.1,
                                    std_range=(
                                        0.005,
                                        0.015,
                                    ),
                                    type='GaussNoise'),
                                dict(
                                    brightness=0.1,
                                    contrast=0.1,
                                    hue=0.03,
                                    p=0.3,
                                    saturation=0.1,
                                    type='ColorJitter'),
                            ],
                            type='Albu'),
                        dict(type='PackSegInputs'),
                    ],
                    type='BaseSegDataset'),
                times=5,
                type='RepeatDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/train', seg_map_path='annotations/train'),
                data_root='/run/media/panuwat/USB/dataset/authentic/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(
                        keep_ratio=False,
                        ratio_range=(
                            1.0,
                            2.0,
                        ),
                        scale=(
                            512,
                            512,
                        ),
                        type='RandomResize'),
                    dict(
                        cat_max_ratio=1.0,
                        crop_size=(
                            512,
                            512,
                        ),
                        type='RandomCrop'),
                    dict(prob=0.5, type='RandomFlip'),
                    dict(
                        transforms=[
                            dict(
                                p=0.3,
                                quality_range=(
                                    60,
                                    95,
                                ),
                                type='ImageCompression'),
                            dict(
                                blur_limit=(
                                    3,
                                    3,
                                ),
                                p=0.1,
                                type='GaussianBlur'),
                            dict(
                                p=0.1,
                                std_range=(
                                    0.005,
                                    0.015,
                                ),
                                type='GaussNoise'),
                            dict(
                                brightness=0.1,
                                contrast=0.1,
                                hue=0.03,
                                p=0.3,
                                saturation=0.1,
                                type='ColorJitter'),
                        ],
                        type='Albu'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/train', seg_map_path='annotations/train'),
                data_root='/run/media/panuwat/USB/dataset/splicing/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(
                        keep_ratio=False,
                        ratio_range=(
                            1.0,
                            2.0,
                        ),
                        scale=(
                            512,
                            512,
                        ),
                        type='RandomResize'),
                    dict(
                        cat_max_ratio=0.99,
                        crop_size=(
                            512,
                            512,
                        ),
                        type='RandomCrop'),
                    dict(prob=0.5, type='RandomFlip'),
                    dict(
                        transforms=[
                            dict(
                                p=0.3,
                                quality_range=(
                                    60,
                                    95,
                                ),
                                type='ImageCompression'),
                            dict(
                                blur_limit=(
                                    3,
                                    3,
                                ),
                                p=0.1,
                                type='GaussianBlur'),
                            dict(
                                p=0.1,
                                std_range=(
                                    0.005,
                                    0.015,
                                ),
                                type='GaussNoise'),
                            dict(
                                brightness=0.1,
                                contrast=0.1,
                                hue=0.03,
                                p=0.3,
                                saturation=0.1,
                                type='ColorJitter'),
                        ],
                        type='Albu'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                dataset=dict(
                    data_prefix=dict(
                        img_path='images/train',
                        seg_map_path='annotations/train'),
                    data_root='/run/media/panuwat/USB/dataset/inpainting/',
                    img_suffix='.png',
                    metainfo=dict(
                        classes=(
                            'background',
                            'forgery',
                        ),
                        palette=[
                            [
                                0,
                                0,
                                0,
                            ],
                            [
                                255,
                                0,
                                0,
                            ],
                        ]),
                    pipeline=[
                        dict(type='LoadImageFromFile'),
                        dict(reduce_zero_label=False, type='LoadAnnotations'),
                        dict(
                            keep_ratio=False,
                            ratio_range=(
                                1.0,
                                2.0,
                            ),
                            scale=(
                                512,
                                512,
                            ),
                            type='RandomResize'),
                        dict(
                            cat_max_ratio=0.99,
                            crop_size=(
                                512,
                                512,
                            ),
                            type='RandomCrop'),
                        dict(prob=0.5, type='RandomFlip'),
                        dict(
                            max_size=160,
                            min_size=32,
                            p=0.2,
                            type='CopyPasteForgery'),
                        dict(
                            transforms=[
                                dict(
                                    p=0.3,
                                    quality_range=(
                                        60,
                                        95,
                                    ),
                                    type='ImageCompression'),
                                dict(
                                    blur_limit=(
                                        3,
                                        3,
                                    ),
                                    p=0.1,
                                    type='GaussianBlur'),
                                dict(
                                    p=0.1,
                                    std_range=(
                                        0.005,
                                        0.015,
                                    ),
                                    type='GaussNoise'),
                                dict(
                                    brightness=0.1,
                                    contrast=0.1,
                                    hue=0.03,
                                    p=0.3,
                                    saturation=0.1,
                                    type='ColorJitter'),
                            ],
                            type='Albu'),
                        dict(type='PackSegInputs'),
                    ],
                    type='BaseSegDataset'),
                times=3,
                type='RepeatDataset'),
            dict(
                dataset=dict(
                    data_prefix=dict(
                        img_path='images/train',
                        seg_map_path='annotations/train'),
                    data_root='/run/media/panuwat/USB/dataset/copymove/',
                    img_suffix='.png',
                    metainfo=dict(
                        classes=(
                            'background',
                            'forgery',
                        ),
                        palette=[
                            [
                                0,
                                0,
                                0,
                            ],
                            [
                                255,
                                0,
                                0,
                            ],
                        ]),
                    pipeline=[
                        dict(type='LoadImageFromFile'),
                        dict(reduce_zero_label=False, type='LoadAnnotations'),
                        dict(
                            keep_ratio=False,
                            ratio_range=(
                                1.0,
                                2.0,
                            ),
                            scale=(
                                512,
                                512,
                            ),
                            type='RandomResize'),
                        dict(
                            cat_max_ratio=0.99,
                            crop_size=(
                                512,
                                512,
                            ),
                            type='RandomCrop'),
                        dict(prob=0.5, type='RandomFlip'),
                        dict(
                            max_size=160,
                            min_size=32,
                            p=0.2,
                            type='CopyPasteForgery'),
                        dict(
                            transforms=[
                                dict(
                                    p=0.3,
                                    quality_range=(
                                        60,
                                        95,
                                    ),
                                    type='ImageCompression'),
                                dict(
                                    blur_limit=(
                                        3,
                                        3,
                                    ),
                                    p=0.1,
                                    type='GaussianBlur'),
                                dict(
                                    p=0.1,
                                    std_range=(
                                        0.005,
                                        0.015,
                                    ),
                                    type='GaussNoise'),
                                dict(
                                    brightness=0.1,
                                    contrast=0.1,
                                    hue=0.03,
                                    p=0.3,
                                    saturation=0.1,
                                    type='ColorJitter'),
                            ],
                            type='Albu'),
                        dict(type='PackSegInputs'),
                    ],
                    type='BaseSegDataset'),
                times=4,
                type='RepeatDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/train', seg_map_path='annotations/train'),
                data_root='/run/media/panuwat/USB/dataset/face/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(
                        keep_ratio=False,
                        ratio_range=(
                            1.0,
                            2.0,
                        ),
                        scale=(
                            512,
                            512,
                        ),
                        type='RandomResize'),
                    dict(
                        cat_max_ratio=0.99,
                        crop_size=(
                            512,
                            512,
                        ),
                        type='RandomCrop'),
                    dict(prob=0.5, type='RandomFlip'),
                    dict(
                        transforms=[
                            dict(
                                p=0.3,
                                quality_range=(
                                    60,
                                    95,
                                ),
                                type='ImageCompression'),
                            dict(
                                blur_limit=(
                                    3,
                                    3,
                                ),
                                p=0.1,
                                type='GaussianBlur'),
                            dict(
                                p=0.1,
                                std_range=(
                                    0.005,
                                    0.015,
                                ),
                                type='GaussNoise'),
                            dict(
                                brightness=0.1,
                                contrast=0.1,
                                hue=0.03,
                                p=0.3,
                                saturation=0.1,
                                type='ColorJitter'),
                        ],
                        type='Albu'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                dataset=dict(
                    data_prefix=dict(
                        img_path='images/train',
                        seg_map_path='annotations/train'),
                    data_root='/run/media/panuwat/USB/dataset/imd2020/',
                    img_suffix='.png',
                    metainfo=dict(
                        classes=(
                            'background',
                            'forgery',
                        ),
                        palette=[
                            [
                                0,
                                0,
                                0,
                            ],
                            [
                                255,
                                0,
                                0,
                            ],
                        ]),
                    pipeline=[
                        dict(type='LoadImageFromFile'),
                        dict(reduce_zero_label=False, type='LoadAnnotations'),
                        dict(
                            keep_ratio=False,
                            ratio_range=(
                                1.0,
                                2.0,
                            ),
                            scale=(
                                512,
                                512,
                            ),
                            type='RandomResize'),
                        dict(
                            cat_max_ratio=0.99,
                            crop_size=(
                                512,
                                512,
                            ),
                            type='RandomCrop'),
                        dict(prob=0.5, type='RandomFlip'),
                        dict(
                            max_size=160,
                            min_size=32,
                            p=0.2,
                            type='CopyPasteForgery'),
                        dict(
                            transforms=[
                                dict(
                                    p=0.3,
                                    quality_range=(
                                        60,
                                        95,
                                    ),
                                    type='ImageCompression'),
                                dict(
                                    blur_limit=(
                                        3,
                                        3,
                                    ),
                                    p=0.1,
                                    type='GaussianBlur'),
                                dict(
                                    p=0.1,
                                    std_range=(
                                        0.005,
                                        0.015,
                                    ),
                                    type='GaussNoise'),
                                dict(
                                    brightness=0.1,
                                    contrast=0.1,
                                    hue=0.03,
                                    p=0.3,
                                    saturation=0.1,
                                    type='ColorJitter'),
                            ],
                            type='Albu'),
                        dict(type='PackSegInputs'),
                    ],
                    type='BaseSegDataset'),
                times=3,
                type='RepeatDataset'),
            dict(
                dataset=dict(
                    data_prefix=dict(
                        img_path='images/train',
                        seg_map_path='annotations/train'),
                    data_root='/run/media/panuwat/USB/dataset/aiforge/',
                    img_suffix='.png',
                    metainfo=dict(
                        classes=(
                            'background',
                            'forgery',
                        ),
                        palette=[
                            [
                                0,
                                0,
                                0,
                            ],
                            [
                                255,
                                0,
                                0,
                            ],
                        ]),
                    pipeline=[
                        dict(type='LoadImageFromFile'),
                        dict(reduce_zero_label=False, type='LoadAnnotations'),
                        dict(
                            keep_ratio=False,
                            ratio_range=(
                                1.0,
                                2.0,
                            ),
                            scale=(
                                512,
                                512,
                            ),
                            type='RandomResize'),
                        dict(
                            cat_max_ratio=0.99,
                            crop_size=(
                                512,
                                512,
                            ),
                            type='RandomCrop'),
                        dict(prob=0.5, type='RandomFlip'),
                        dict(
                            transforms=[
                                dict(
                                    p=0.3,
                                    quality_range=(
                                        60,
                                        95,
                                    ),
                                    type='ImageCompression'),
                                dict(
                                    blur_limit=(
                                        3,
                                        3,
                                    ),
                                    p=0.1,
                                    type='GaussianBlur'),
                                dict(
                                    p=0.1,
                                    std_range=(
                                        0.005,
                                        0.015,
                                    ),
                                    type='GaussNoise'),
                                dict(
                                    brightness=0.1,
                                    contrast=0.1,
                                    hue=0.03,
                                    p=0.3,
                                    saturation=0.1,
                                    type='ColorJitter'),
                            ],
                            type='Albu'),
                        dict(type='PackSegInputs'),
                    ],
                    type='BaseSegDataset'),
                times=6,
                type='RepeatDataset'),
            dict(
                dataset=dict(
                    data_prefix=dict(
                        img_path='images/train',
                        seg_map_path='annotations/train'),
                    data_root='/run/media/panuwat/USB/dataset/realtext/',
                    img_suffix='.png',
                    metainfo=dict(
                        classes=(
                            'background',
                            'forgery',
                        ),
                        palette=[
                            [
                                0,
                                0,
                                0,
                            ],
                            [
                                255,
                                0,
                                0,
                            ],
                        ]),
                    pipeline=[
                        dict(type='LoadImageFromFile'),
                        dict(reduce_zero_label=False, type='LoadAnnotations'),
                        dict(
                            keep_ratio=False,
                            ratio_range=(
                                1.0,
                                2.0,
                            ),
                            scale=(
                                512,
                                512,
                            ),
                            type='RandomResize'),
                        dict(
                            cat_max_ratio=0.99,
                            crop_size=(
                                512,
                                512,
                            ),
                            type='RandomCrop'),
                        dict(prob=0.5, type='RandomFlip'),
                        dict(
                            transforms=[
                                dict(
                                    p=0.3,
                                    quality_range=(
                                        60,
                                        95,
                                    ),
                                    type='ImageCompression'),
                                dict(
                                    blur_limit=(
                                        3,
                                        3,
                                    ),
                                    p=0.1,
                                    type='GaussianBlur'),
                                dict(
                                    p=0.1,
                                    std_range=(
                                        0.005,
                                        0.015,
                                    ),
                                    type='GaussNoise'),
                                dict(
                                    brightness=0.1,
                                    contrast=0.1,
                                    hue=0.03,
                                    p=0.3,
                                    saturation=0.1,
                                    type='ColorJitter'),
                            ],
                            type='Albu'),
                        dict(type='PackSegInputs'),
                    ],
                    type='BaseSegDataset'),
                times=4,
                type='RepeatDataset'),
        ],
        type='ConcatDataset'),
    num_workers=4,
    persistent_workers=True,
    sampler=dict(shuffle=True, type='InfiniteSampler'))
train_pipeline = [
    dict(type='LoadImageFromFile'),
    dict(reduce_zero_label=False, type='LoadAnnotations'),
    dict(
        keep_ratio=False,
        ratio_range=(
            1.0,
            2.0,
        ),
        scale=(
            512,
            512,
        ),
        type='RandomResize'),
    dict(cat_max_ratio=0.99, crop_size=(
        512,
        512,
    ), type='RandomCrop'),
    dict(prob=0.5, type='RandomFlip'),
    dict(max_size=160, min_size=32, p=0.2, type='CopyPasteForgery'),
    dict(
        transforms=[
            dict(p=0.3, quality_range=(
                60,
                95,
            ), type='ImageCompression'),
            dict(blur_limit=(
                3,
                3,
            ), p=0.1, type='GaussianBlur'),
            dict(p=0.1, std_range=(
                0.005,
                0.015,
            ), type='GaussNoise'),
            dict(
                brightness=0.1,
                contrast=0.1,
                hue=0.03,
                p=0.3,
                saturation=0.1,
                type='ColorJitter'),
        ],
        type='Albu'),
    dict(type='PackSegInputs'),
]
train_repeat_factors = dict(
    aiforge=6,
    authentic=1,
    casia=5,
    copymove=4,
    face=1,
    imd2020=3,
    inpainting=3,
    realtext=4,
    splicing=1)
tta_model = dict(type='SegTTAModel')
tta_pipeline = [
    dict(backend_args=None, type='LoadImageFromFile'),
    dict(
        transforms=[
            [
                dict(keep_ratio=True, scale_factor=0.5, type='Resize'),
                dict(keep_ratio=True, scale_factor=0.75, type='Resize'),
                dict(keep_ratio=True, scale_factor=1.0, type='Resize'),
                dict(keep_ratio=True, scale_factor=1.25, type='Resize'),
                dict(keep_ratio=True, scale_factor=1.5, type='Resize'),
                dict(keep_ratio=True, scale_factor=1.75, type='Resize'),
            ],
            [
                dict(direction='horizontal', prob=0.0, type='RandomFlip'),
                dict(direction='horizontal', prob=1.0, type='RandomFlip'),
            ],
            [
                dict(type='LoadAnnotations'),
            ],
            [
                dict(type='PackSegInputs'),
            ],
        ],
        type='TestTimeAug'),
]
val_cfg = dict(type='ValLoop')
val_dataloader = dict(
    batch_size=16,
    dataset=dict(
        datasets=[
            dict(
                data_prefix=dict(
                    img_path='images/val', seg_map_path='annotations/val'),
                data_root='/run/media/panuwat/USB/dataset/casia/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/val', seg_map_path='annotations/val'),
                data_root='/run/media/panuwat/USB/dataset/authentic/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/val', seg_map_path='annotations/val'),
                data_root='/run/media/panuwat/USB/dataset/splicing/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/val', seg_map_path='annotations/val'),
                data_root='/run/media/panuwat/USB/dataset/inpainting/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/val', seg_map_path='annotations/val'),
                data_root='/run/media/panuwat/USB/dataset/copymove/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/val', seg_map_path='annotations/val'),
                data_root='/run/media/panuwat/USB/dataset/face/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/val', seg_map_path='annotations/val'),
                data_root='/run/media/panuwat/USB/dataset/imd2020/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/val', seg_map_path='annotations/val'),
                data_root='/run/media/panuwat/USB/dataset/aiforge/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/val', seg_map_path='annotations/val'),
                data_root='/run/media/panuwat/USB/dataset/realtext/',
                img_suffix='.png',
                metainfo=dict(
                    classes=(
                        'background',
                        'forgery',
                    ),
                    palette=[
                        [
                            0,
                            0,
                            0,
                        ],
                        [
                            255,
                            0,
                            0,
                        ],
                    ]),
                pipeline=[
                    dict(type='LoadImageFromFile'),
                    dict(keep_ratio=False, scale=(
                        512,
                        512,
                    ), type='Resize'),
                    dict(reduce_zero_label=False, type='LoadAnnotations'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
        ],
        type='ConcatDataset'),
    num_workers=4,
    persistent_workers=True,
    sampler=dict(shuffle=False, type='DefaultSampler'))
val_evaluator = dict(
    core_sources=[
        'casia',
        'authentic',
        'splicing',
        'inpainting',
        'copymove',
        'face',
        'imd2020',
    ],
    iou_metrics=[
        'mIoU',
        'mDice',
    ],
    source_roots=dict(
        aiforge='/run/media/panuwat/USB/dataset/aiforge/',
        authentic='/run/media/panuwat/USB/dataset/authentic/',
        casia='/run/media/panuwat/USB/dataset/casia/',
        copymove='/run/media/panuwat/USB/dataset/copymove/',
        face='/run/media/panuwat/USB/dataset/face/',
        imd2020='/run/media/panuwat/USB/dataset/imd2020/',
        inpainting='/run/media/panuwat/USB/dataset/inpainting/',
        realtext='/run/media/panuwat/USB/dataset/realtext/',
        splicing='/run/media/panuwat/USB/dataset/splicing/'),
    type='SourceAwareIoUMetric')
vis_backends = [
    dict(type='LocalVisBackend'),
]
visualizer = dict(
    name='visualizer',
    type='SegLocalVisualizer',
    vis_backends=[
        dict(type='LocalVisBackend'),
    ])
work_dir = 'work_dirs/v1.0.8/test_eval/locked_miou_207500'
