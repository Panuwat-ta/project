albu_train_transforms = [
    dict(p=0.5, quality_lower=40, quality_upper=90, type='ImageCompression'),
    dict(blur_limit=(
        3,
        7,
    ), p=0.3, type='GaussianBlur'),
    dict(p=0.3, type='GaussNoise', var_limit=(
        10.0,
        50.0,
    )),
    dict(
        brightness=0.2,
        contrast=0.2,
        hue=0.1,
        p=0.5,
        saturation=0.2,
        type='ColorJitter'),
]
casia_root = '/run/media/panuwat/USB/dataset/dataset_CASIA2.0/'
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
dataset_casia_train = dict(
    data_prefix=dict(
        img_path='images/train', seg_map_path='annotations/train'),
    data_root='/run/media/panuwat/USB/dataset/dataset_CASIA2.0/',
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
            ratio_range=(
                0.5,
                2.0,
            ), scale=(
                512,
                512,
            ), type='RandomResize'),
        dict(crop_size=(
            512,
            512,
        ), type='RandomCrop'),
        dict(prob=0.5, type='RandomFlip'),
        dict(
            transforms=[
                dict(
                    p=0.5,
                    quality_lower=40,
                    quality_upper=90,
                    type='ImageCompression'),
                dict(blur_limit=(
                    3,
                    7,
                ), p=0.3, type='GaussianBlur'),
                dict(p=0.3, type='GaussNoise', var_limit=(
                    10.0,
                    50.0,
                )),
                dict(
                    brightness=0.2,
                    contrast=0.2,
                    hue=0.1,
                    p=0.5,
                    saturation=0.2,
                    type='ColorJitter'),
            ],
            type='Albu'),
        dict(type='PhotoMetricDistortion'),
        dict(type='PackSegInputs'),
    ],
    type='BaseSegDataset')
dataset_casia_val = dict(
    data_prefix=dict(img_path='images/val', seg_map_path='annotations/val'),
    data_root='/run/media/panuwat/USB/dataset/dataset_CASIA2.0/',
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
    type='BaseSegDataset')
dataset_defacto_copymove_train = dict(
    data_prefix=dict(
        img_path='images/train', seg_map_path='annotations/train'),
    data_root='/run/media/panuwat/USB/dataset/defacto-copymove/',
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
            ratio_range=(
                0.5,
                2.0,
            ), scale=(
                512,
                512,
            ), type='RandomResize'),
        dict(crop_size=(
            512,
            512,
        ), type='RandomCrop'),
        dict(prob=0.5, type='RandomFlip'),
        dict(
            transforms=[
                dict(
                    p=0.5,
                    quality_lower=40,
                    quality_upper=90,
                    type='ImageCompression'),
                dict(blur_limit=(
                    3,
                    7,
                ), p=0.3, type='GaussianBlur'),
                dict(p=0.3, type='GaussNoise', var_limit=(
                    10.0,
                    50.0,
                )),
                dict(
                    brightness=0.2,
                    contrast=0.2,
                    hue=0.1,
                    p=0.5,
                    saturation=0.2,
                    type='ColorJitter'),
            ],
            type='Albu'),
        dict(type='PhotoMetricDistortion'),
        dict(type='PackSegInputs'),
    ],
    type='BaseSegDataset')
dataset_defacto_copymove_val = dict(
    data_prefix=dict(img_path='images/val', seg_map_path='annotations/val'),
    data_root='/run/media/panuwat/USB/dataset/defacto-copymove/',
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
    type='BaseSegDataset')
dataset_defacto_face_train = dict(
    data_prefix=dict(
        img_path='images/train', seg_map_path='annotations/train'),
    data_root='/run/media/panuwat/USB/dataset/defacto-face/',
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
            ratio_range=(
                0.5,
                2.0,
            ), scale=(
                512,
                512,
            ), type='RandomResize'),
        dict(crop_size=(
            512,
            512,
        ), type='RandomCrop'),
        dict(prob=0.5, type='RandomFlip'),
        dict(
            transforms=[
                dict(
                    p=0.5,
                    quality_lower=40,
                    quality_upper=90,
                    type='ImageCompression'),
                dict(blur_limit=(
                    3,
                    7,
                ), p=0.3, type='GaussianBlur'),
                dict(p=0.3, type='GaussNoise', var_limit=(
                    10.0,
                    50.0,
                )),
                dict(
                    brightness=0.2,
                    contrast=0.2,
                    hue=0.1,
                    p=0.5,
                    saturation=0.2,
                    type='ColorJitter'),
            ],
            type='Albu'),
        dict(type='PhotoMetricDistortion'),
        dict(type='PackSegInputs'),
    ],
    type='BaseSegDataset')
dataset_defacto_face_val = dict(
    data_prefix=dict(img_path='images/val', seg_map_path='annotations/val'),
    data_root='/run/media/panuwat/USB/dataset/defacto-face/',
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
    type='BaseSegDataset')
dataset_defacto_inpaint_train = dict(
    data_prefix=dict(
        img_path='images/train', seg_map_path='annotations/train'),
    data_root='/run/media/panuwat/USB/dataset/defacto-inpainting/',
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
            ratio_range=(
                0.5,
                2.0,
            ), scale=(
                512,
                512,
            ), type='RandomResize'),
        dict(crop_size=(
            512,
            512,
        ), type='RandomCrop'),
        dict(prob=0.5, type='RandomFlip'),
        dict(
            transforms=[
                dict(
                    p=0.5,
                    quality_lower=40,
                    quality_upper=90,
                    type='ImageCompression'),
                dict(blur_limit=(
                    3,
                    7,
                ), p=0.3, type='GaussianBlur'),
                dict(p=0.3, type='GaussNoise', var_limit=(
                    10.0,
                    50.0,
                )),
                dict(
                    brightness=0.2,
                    contrast=0.2,
                    hue=0.1,
                    p=0.5,
                    saturation=0.2,
                    type='ColorJitter'),
            ],
            type='Albu'),
        dict(type='PhotoMetricDistortion'),
        dict(type='PackSegInputs'),
    ],
    type='BaseSegDataset')
dataset_defacto_inpaint_val = dict(
    data_prefix=dict(img_path='images/val', seg_map_path='annotations/val'),
    data_root='/run/media/panuwat/USB/dataset/defacto-inpainting/',
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
    type='BaseSegDataset')
dataset_defacto_splicing_train = dict(
    data_prefix=dict(
        img_path='images/train', seg_map_path='annotations/train'),
    data_root='/run/media/panuwat/USB/dataset/defacto-splicing/',
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
            ratio_range=(
                0.5,
                2.0,
            ), scale=(
                512,
                512,
            ), type='RandomResize'),
        dict(crop_size=(
            512,
            512,
        ), type='RandomCrop'),
        dict(prob=0.5, type='RandomFlip'),
        dict(
            transforms=[
                dict(
                    p=0.5,
                    quality_lower=40,
                    quality_upper=90,
                    type='ImageCompression'),
                dict(blur_limit=(
                    3,
                    7,
                ), p=0.3, type='GaussianBlur'),
                dict(p=0.3, type='GaussNoise', var_limit=(
                    10.0,
                    50.0,
                )),
                dict(
                    brightness=0.2,
                    contrast=0.2,
                    hue=0.1,
                    p=0.5,
                    saturation=0.2,
                    type='ColorJitter'),
            ],
            type='Albu'),
        dict(type='PhotoMetricDistortion'),
        dict(type='PackSegInputs'),
    ],
    type='BaseSegDataset')
dataset_defacto_splicing_val = dict(
    data_prefix=dict(img_path='images/val', seg_map_path='annotations/val'),
    data_root='/run/media/panuwat/USB/dataset/defacto-splicing/',
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
    type='BaseSegDataset')
dataset_imd2020_train = dict(
    data_prefix=dict(
        img_path='images/train', seg_map_path='annotations/train'),
    data_root='/run/media/panuwat/USB/dataset/IMD2020/',
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
            ratio_range=(
                0.5,
                2.0,
            ), scale=(
                512,
                512,
            ), type='RandomResize'),
        dict(crop_size=(
            512,
            512,
        ), type='RandomCrop'),
        dict(prob=0.5, type='RandomFlip'),
        dict(
            transforms=[
                dict(
                    p=0.5,
                    quality_lower=40,
                    quality_upper=90,
                    type='ImageCompression'),
                dict(blur_limit=(
                    3,
                    7,
                ), p=0.3, type='GaussianBlur'),
                dict(p=0.3, type='GaussNoise', var_limit=(
                    10.0,
                    50.0,
                )),
                dict(
                    brightness=0.2,
                    contrast=0.2,
                    hue=0.1,
                    p=0.5,
                    saturation=0.2,
                    type='ColorJitter'),
            ],
            type='Albu'),
        dict(type='PhotoMetricDistortion'),
        dict(type='PackSegInputs'),
    ],
    type='BaseSegDataset')
dataset_imd2020_val = dict(
    data_prefix=dict(img_path='images/val', seg_map_path='annotations/val'),
    data_root='/run/media/panuwat/USB/dataset/IMD2020/',
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
    type='BaseSegDataset')
dataset_type = 'BaseSegDataset'
defacto_copymove_root = '/run/media/panuwat/USB/dataset/defacto-copymove/'
defacto_face_root = '/run/media/panuwat/USB/dataset/defacto-face/'
defacto_inpaint_root = '/run/media/panuwat/USB/dataset/defacto-inpainting/'
defacto_splicing_root = '/run/media/panuwat/USB/dataset/defacto-splicing/'
default_hooks = dict(
    checkpoint=dict(
        by_epoch=False,
        interval=5000,
        max_keep_ckpts=5,
        rule='greater',
        save_best='mIoU',
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
imd2020_root = '/run/media/panuwat/USB/dataset/IMD2020/'
img_ratios = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
]
launcher = 'none'
load_from = None
log_level = 'INFO'
log_processor = dict(by_epoch=False)
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
            dict(loss_weight=1.0, type='CrossEntropyLoss', use_sigmoid=False),
            dict(ignore_index=255, loss_weight=1.0, type='DiceLoss'),
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
    optimizer=dict(
        betas=(
            0.9,
            0.999,
        ), lr=1e-05, type='AdamW', weight_decay=0.01),
    paramwise_cfg=dict(
        custom_keys=dict(
            backbone=dict(decay_mult=1.0, lr_mult=0.1),
            decode_head=dict(lr_mult=10.0),
            head=dict(lr_mult=10.0),
            norm=dict(decay_mult=0.0),
            pos_block=dict(decay_mult=0.0))),
    type='AmpOptimWrapper')
optimizer = dict(lr=0.01, momentum=0.9, type='SGD', weight_decay=0.0005)
param_scheduler = [
    dict(
        begin=0, by_epoch=False, end=5000, start_factor=1e-06,
        type='LinearLR'),
    dict(
        begin=5000,
        by_epoch=False,
        end=500000,
        eta_min=1e-06,
        power=1.0,
        type='PolyLR'),
]
resume = False
test_cfg = dict(type='TestLoop')
test_dataloader = dict(
    batch_size=8,
    dataset=dict(
        datasets=[
            dict(
                data_prefix=dict(
                    img_path='images/val', seg_map_path='annotations/val'),
                data_root='/run/media/panuwat/USB/dataset/dataset_CASIA2.0/',
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
                data_root='/run/media/panuwat/USB/dataset/defacto-inpainting/',
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
                data_root='/run/media/panuwat/USB/dataset/defacto-copymove/',
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
                data_root='/run/media/panuwat/USB/dataset/defacto-splicing/',
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
                data_root='/run/media/panuwat/USB/dataset/defacto-face/',
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
                data_root='/run/media/panuwat/USB/dataset/IMD2020/',
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
    num_workers=8,
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
    max_iters=500000, type='IterBasedTrainLoop', val_interval=5000)
train_dataloader = dict(
    batch_size=8,
    dataset=dict(
        datasets=[
            dict(
                data_prefix=dict(
                    img_path='images/train', seg_map_path='annotations/train'),
                data_root='/run/media/panuwat/USB/dataset/dataset_CASIA2.0/',
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
                        ratio_range=(
                            0.5,
                            2.0,
                        ),
                        scale=(
                            512,
                            512,
                        ),
                        type='RandomResize'),
                    dict(crop_size=(
                        512,
                        512,
                    ), type='RandomCrop'),
                    dict(prob=0.5, type='RandomFlip'),
                    dict(
                        transforms=[
                            dict(
                                p=0.5,
                                quality_lower=40,
                                quality_upper=90,
                                type='ImageCompression'),
                            dict(
                                blur_limit=(
                                    3,
                                    7,
                                ),
                                p=0.3,
                                type='GaussianBlur'),
                            dict(
                                p=0.3,
                                type='GaussNoise',
                                var_limit=(
                                    10.0,
                                    50.0,
                                )),
                            dict(
                                brightness=0.2,
                                contrast=0.2,
                                hue=0.1,
                                p=0.5,
                                saturation=0.2,
                                type='ColorJitter'),
                        ],
                        type='Albu'),
                    dict(type='PhotoMetricDistortion'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/train', seg_map_path='annotations/train'),
                data_root='/run/media/panuwat/USB/dataset/defacto-inpainting/',
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
                        ratio_range=(
                            0.5,
                            2.0,
                        ),
                        scale=(
                            512,
                            512,
                        ),
                        type='RandomResize'),
                    dict(crop_size=(
                        512,
                        512,
                    ), type='RandomCrop'),
                    dict(prob=0.5, type='RandomFlip'),
                    dict(
                        transforms=[
                            dict(
                                p=0.5,
                                quality_lower=40,
                                quality_upper=90,
                                type='ImageCompression'),
                            dict(
                                blur_limit=(
                                    3,
                                    7,
                                ),
                                p=0.3,
                                type='GaussianBlur'),
                            dict(
                                p=0.3,
                                type='GaussNoise',
                                var_limit=(
                                    10.0,
                                    50.0,
                                )),
                            dict(
                                brightness=0.2,
                                contrast=0.2,
                                hue=0.1,
                                p=0.5,
                                saturation=0.2,
                                type='ColorJitter'),
                        ],
                        type='Albu'),
                    dict(type='PhotoMetricDistortion'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/train', seg_map_path='annotations/train'),
                data_root='/run/media/panuwat/USB/dataset/defacto-copymove/',
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
                        ratio_range=(
                            0.5,
                            2.0,
                        ),
                        scale=(
                            512,
                            512,
                        ),
                        type='RandomResize'),
                    dict(crop_size=(
                        512,
                        512,
                    ), type='RandomCrop'),
                    dict(prob=0.5, type='RandomFlip'),
                    dict(
                        transforms=[
                            dict(
                                p=0.5,
                                quality_lower=40,
                                quality_upper=90,
                                type='ImageCompression'),
                            dict(
                                blur_limit=(
                                    3,
                                    7,
                                ),
                                p=0.3,
                                type='GaussianBlur'),
                            dict(
                                p=0.3,
                                type='GaussNoise',
                                var_limit=(
                                    10.0,
                                    50.0,
                                )),
                            dict(
                                brightness=0.2,
                                contrast=0.2,
                                hue=0.1,
                                p=0.5,
                                saturation=0.2,
                                type='ColorJitter'),
                        ],
                        type='Albu'),
                    dict(type='PhotoMetricDistortion'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/train', seg_map_path='annotations/train'),
                data_root='/run/media/panuwat/USB/dataset/defacto-splicing/',
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
                        ratio_range=(
                            0.5,
                            2.0,
                        ),
                        scale=(
                            512,
                            512,
                        ),
                        type='RandomResize'),
                    dict(crop_size=(
                        512,
                        512,
                    ), type='RandomCrop'),
                    dict(prob=0.5, type='RandomFlip'),
                    dict(
                        transforms=[
                            dict(
                                p=0.5,
                                quality_lower=40,
                                quality_upper=90,
                                type='ImageCompression'),
                            dict(
                                blur_limit=(
                                    3,
                                    7,
                                ),
                                p=0.3,
                                type='GaussianBlur'),
                            dict(
                                p=0.3,
                                type='GaussNoise',
                                var_limit=(
                                    10.0,
                                    50.0,
                                )),
                            dict(
                                brightness=0.2,
                                contrast=0.2,
                                hue=0.1,
                                p=0.5,
                                saturation=0.2,
                                type='ColorJitter'),
                        ],
                        type='Albu'),
                    dict(type='PhotoMetricDistortion'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/train', seg_map_path='annotations/train'),
                data_root='/run/media/panuwat/USB/dataset/defacto-face/',
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
                        ratio_range=(
                            0.5,
                            2.0,
                        ),
                        scale=(
                            512,
                            512,
                        ),
                        type='RandomResize'),
                    dict(crop_size=(
                        512,
                        512,
                    ), type='RandomCrop'),
                    dict(prob=0.5, type='RandomFlip'),
                    dict(
                        transforms=[
                            dict(
                                p=0.5,
                                quality_lower=40,
                                quality_upper=90,
                                type='ImageCompression'),
                            dict(
                                blur_limit=(
                                    3,
                                    7,
                                ),
                                p=0.3,
                                type='GaussianBlur'),
                            dict(
                                p=0.3,
                                type='GaussNoise',
                                var_limit=(
                                    10.0,
                                    50.0,
                                )),
                            dict(
                                brightness=0.2,
                                contrast=0.2,
                                hue=0.1,
                                p=0.5,
                                saturation=0.2,
                                type='ColorJitter'),
                        ],
                        type='Albu'),
                    dict(type='PhotoMetricDistortion'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
            dict(
                data_prefix=dict(
                    img_path='images/train', seg_map_path='annotations/train'),
                data_root='/run/media/panuwat/USB/dataset/IMD2020/',
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
                        ratio_range=(
                            0.5,
                            2.0,
                        ),
                        scale=(
                            512,
                            512,
                        ),
                        type='RandomResize'),
                    dict(crop_size=(
                        512,
                        512,
                    ), type='RandomCrop'),
                    dict(prob=0.5, type='RandomFlip'),
                    dict(
                        transforms=[
                            dict(
                                p=0.5,
                                quality_lower=40,
                                quality_upper=90,
                                type='ImageCompression'),
                            dict(
                                blur_limit=(
                                    3,
                                    7,
                                ),
                                p=0.3,
                                type='GaussianBlur'),
                            dict(
                                p=0.3,
                                type='GaussNoise',
                                var_limit=(
                                    10.0,
                                    50.0,
                                )),
                            dict(
                                brightness=0.2,
                                contrast=0.2,
                                hue=0.1,
                                p=0.5,
                                saturation=0.2,
                                type='ColorJitter'),
                        ],
                        type='Albu'),
                    dict(type='PhotoMetricDistortion'),
                    dict(type='PackSegInputs'),
                ],
                type='BaseSegDataset'),
        ],
        type='ConcatDataset'),
    num_workers=8,
    persistent_workers=True,
    sampler=dict(shuffle=True, type='InfiniteSampler'))
train_pipeline = [
    dict(type='LoadImageFromFile'),
    dict(reduce_zero_label=False, type='LoadAnnotations'),
    dict(ratio_range=(
        0.5,
        2.0,
    ), scale=(
        512,
        512,
    ), type='RandomResize'),
    dict(crop_size=(
        512,
        512,
    ), type='RandomCrop'),
    dict(prob=0.5, type='RandomFlip'),
    dict(
        transforms=[
            dict(
                p=0.5,
                quality_lower=40,
                quality_upper=90,
                type='ImageCompression'),
            dict(blur_limit=(
                3,
                7,
            ), p=0.3, type='GaussianBlur'),
            dict(p=0.3, type='GaussNoise', var_limit=(
                10.0,
                50.0,
            )),
            dict(
                brightness=0.2,
                contrast=0.2,
                hue=0.1,
                p=0.5,
                saturation=0.2,
                type='ColorJitter'),
        ],
        type='Albu'),
    dict(type='PhotoMetricDistortion'),
    dict(type='PackSegInputs'),
]
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
    batch_size=8,
    dataset=dict(
        datasets=[
            dict(
                data_prefix=dict(
                    img_path='images/val', seg_map_path='annotations/val'),
                data_root='/run/media/panuwat/USB/dataset/dataset_CASIA2.0/',
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
                data_root='/run/media/panuwat/USB/dataset/defacto-inpainting/',
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
                data_root='/run/media/panuwat/USB/dataset/defacto-copymove/',
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
                data_root='/run/media/panuwat/USB/dataset/defacto-splicing/',
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
                data_root='/run/media/panuwat/USB/dataset/defacto-face/',
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
                data_root='/run/media/panuwat/USB/dataset/IMD2020/',
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
    num_workers=8,
    persistent_workers=True,
    sampler=dict(shuffle=False, type='DefaultSampler'))
val_evaluator = dict(
    iou_metrics=[
        'mIoU',
        'mDice',
    ], type='IoUMetric')
vis_backends = [
    dict(type='LocalVisBackend'),
]
visualizer = dict(
    name='visualizer',
    type='SegLocalVisualizer',
    vis_backends=[
        dict(type='LocalVisBackend'),
    ])
work_dir = '/home/panuwat/project/model/segformer/work_dirs/v1.0.4'
