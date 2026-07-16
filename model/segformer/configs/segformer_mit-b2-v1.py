_base_ = ['../library/mmsegmentation/configs/segformer/segformer_mit-b0_8xb2-160k_ade20k-512x512.py']

checkpoint = 'https://download.openmmlab.com/mmsegmentation/v0.5/pretrain/segformer/mit_b2_20220624-66e8bf70.pth'

# ตั้งค่าโมเดลหลัก (Model Settings)
model = dict(
    backbone=dict(
        init_cfg=dict(type='Pretrained', checkpoint=checkpoint),
        embed_dims=64,
        num_heads=[1, 2, 5, 8],
        num_layers=[3, 4, 6, 3]),
    decode_head=dict(
        in_channels=[64, 128, 320, 512],
        num_classes=2,  # เปลี่ยนเป็น 2 คลาส (0: พื้นหลัง, 1: รอยตัดต่อ)
        ignore_index=255 # ละเว้นสีที่ไม่เกี่ยวข้อง
    )
)

# ตั้งค่าชุดข้อมูล (Dataset Settings)
dataset_type = 'BaseSegDataset' 
data_root = 'data/dataset_CASIA2.0/' 
metainfo = dict(classes=('background', 'forgery'), palette=[[0, 0, 0], [255, 0, 0]])

train_pipeline = [
    dict(type='LoadImageFromFile'),
    dict(type='LoadAnnotations', reduce_zero_label=False),
    dict(type='Resize', scale=(512, 512), keep_ratio=False),
    dict(type='RandomFlip', prob=0.5),
    dict(type='PackSegInputs')
]

test_pipeline = [
    dict(type='LoadImageFromFile'),
    dict(type='Resize', scale=(512, 512), keep_ratio=False),
    dict(type='LoadAnnotations', reduce_zero_label=False),
    dict(type='PackSegInputs')
]

train_dataloader = dict(
    batch_size=2, # สามารถเพิ่มได้ตาม VRAM
    num_workers=2,
    dataset=dict(
        type=dataset_type,
        data_root=data_root,
        metainfo=metainfo,
        data_prefix=dict(img_path='images/train', seg_map_path='annotations/train'),
        pipeline=train_pipeline
    )
)

val_dataloader = dict(
    batch_size=1,
    num_workers=1,
    dataset=dict(
        type=dataset_type,
        data_root=data_root,
        metainfo=metainfo,
        data_prefix=dict(img_path='images/val', seg_map_path='annotations/val'),
        pipeline=test_pipeline
    )
)
test_dataloader = val_dataloader

val_evaluator = dict(type='IoUMetric', iou_metrics=['mIoU'])
test_evaluator = val_evaluator

# ตั้งค่าให้โหลดน้ำหนักความรู้เดิมมาเทรนต่อ (เอา # ออกหากต้องการเทรนต่อจากโมเดลเดิม)
# load_from = './work_dirs/segformer_mit-b2_scam_detection/latest.pth'
# ==========================================
# 7. Model Version
# ==========================================
# Versioning: ใช้ระบบ Tagging หรือ Semantic Versioning เพื่อแยกแยะรุ่นของโมเดล
model_version = 'segformer_v2.0.0'
work_dir = f'./work_dirs/{model_version}'

# Checkpoint: ไฟล์น้ำหนักของโมเดล (Weights)
default_hooks = dict(
    checkpoint=dict(
        type='CheckpointHook', 
        interval=4000,          # เซฟ Checkpoint ทุกๆ 4000 iterations
        save_best='mIoU',       # บันทึกโมเดลที่ดีที่สุดอัตโนมัติตามค่า mIoU
        max_keep_ckpts=5        # เก็บ Checkpoint ย้อนหลังไว้สูงสุด 5 ไฟล์
    )
)

# ตั้งค่าให้ตรงกับ design/training.md
optim_wrapper = dict(
    type='OptimWrapper',
    accumulative_counts=2,  # [เพิ่มใหม่] Gradient Accumulation: 2 (รอบ) * batch_size (2) = เสมือนการใช้ batch_size 4 โดยไม่กินแรมการ์ดจอเพิ่ม
    # Fine-tuning: ปรับ Learning Rate ให้ต่ำลงกว่าปกติ (จากเดิม 0.00006 เหลือ 0.00001)
    optimizer=dict(type='AdamW', lr=0.00001, betas=(0.9, 0.999), weight_decay=0.01),
    paramwise_cfg=dict(
        custom_keys={
            # Freeze Encoder: แช่แข็งน้ำหนัก Backbone (Mit Encoder) ไม่ให้อัปเดต
            'backbone': dict(lr_mult=0.0, decay_mult=0.0), 
            'pos_block': dict(decay_mult=0.0),
            'norm': dict(decay_mult=0.0),
            # ปล่อยให้สอนเฉพาะ Decode Head เท่านั้น (เร่งให้เรียนรู้เร็วขึ้น)
            'head': dict(lr_mult=10.0) 
        }
    )
)
