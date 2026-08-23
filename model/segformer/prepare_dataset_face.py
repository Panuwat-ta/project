import os
import glob
import json
import cv2
import numpy as np
import random

try:
    from tqdm import tqdm
    USE_TQDM = True
except ImportError:
    USE_TQDM = False
    print("tqdm not found, falling back to print-based progress.")


def process_and_save(file_list, img_out_dir, ann_out_dir):
    total = len(file_list)
    seen_names = {}  # ตรวจสอบชื่อไฟล์ชนกัน

    iterator = tqdm(enumerate(file_list), total=total) if USE_TQDM else enumerate(file_list)

    for i, (img_path, label) in iterator:
        if not USE_TQDM and i % 500 == 0:
            print(f"[{img_out_dir}] Processed {i}/{total}...")

        raw_name = os.path.splitext(os.path.basename(img_path))[0]
        # เพิ่ม prefix เพื่อป้องกันชื่อไฟล์ชนกันระหว่าง Authentic และ Tampered
        if label == 1:
            # ใช้ชื่อโฟลเดอร์ต้นทาง (morphing หรือ swapping) เป็น prefix เพื่อกันชื่อซ้ำข้ามประเภท
            sub_type = os.path.basename(os.path.dirname(os.path.dirname(img_path))).split('_')[0]
            prefix = f'tp_{sub_type}_'
        else:
            prefix = 'au_'
        base_name = prefix + raw_name

        # ตรวจสอบชื่อซ้ำภายใน split เดียวกัน
        if base_name in seen_names:
            print(f"Warning: Duplicate filename detected '{base_name}', "
                  f"skipping {img_path}")
            continue
        seen_names[base_name] = img_path

        out_img_path = os.path.join(img_out_dir, base_name + '.jpg')
        out_ann_path = os.path.join(ann_out_dir, base_name + '.png')

        img = cv2.imread(img_path)
        if img is None:
            print(f"Failed to read image: {img_path}")
            continue

        h, w = img.shape[:2]

        if label == 1:  # Tampered
            # หา folder จาก img_path
            # img_path = .../morphing_img/img/... หรือ .../swapping_img/img/...
            img_dir = os.path.dirname(os.path.dirname(img_path)) # .../morphing_img
            sub_img = os.path.basename(img_dir)
            sub_ann = sub_img.replace('_img', '_annotations')
            base_dir = os.path.dirname(img_dir) # .../defacto-face
            
            # ไฟล์หน้ากากใน defacto-face ไม่มีนามสกุล .tif ต่อท้าย (ชื่อไฟล์เป็น .jpg ตรงๆ เลย)
            donor_path = os.path.join(base_dir, sub_ann, 'donor_mask', raw_name)
            probe_path = os.path.join(base_dir, sub_ann, 'probe_mask', raw_name)

            mask = np.zeros((h, w), dtype=np.uint8)
            found = False

            if os.path.exists(donor_path):
                donor_mask = cv2.imread(donor_path, cv2.IMREAD_GRAYSCALE)
                if donor_mask is not None:
                    if donor_mask.shape != (h, w):
                        donor_mask = cv2.resize(
                            donor_mask, (w, h), interpolation=cv2.INTER_NEAREST
                        )
                    mask = np.bitwise_or(mask, donor_mask)
                    found = True

            if os.path.exists(probe_path):
                probe_mask = cv2.imread(probe_path, cv2.IMREAD_GRAYSCALE)
                if probe_mask is not None:
                    if probe_mask.shape != (h, w):
                        probe_mask = cv2.resize(
                            probe_mask, (w, h), interpolation=cv2.INTER_NEAREST
                        )
                    mask = np.bitwise_or(mask, probe_mask)
                    found = True

            if not found:
                print(f"Warning: No mask found for {raw_name}, "
                      "saving all-zero mask.")

            # Convert: ค่า > 0 ใดๆ (รวม anti-aliasing) กลายเป็น class label 1
            mask = (mask > 0).astype(np.uint8)

        else:  # Authentic
            mask = np.zeros((h, w), dtype=np.uint8)

        cv2.imwrite(out_img_path, img)
        cv2.imwrite(out_ann_path, mask)


def main():
    import argparse

    parser = argparse.ArgumentParser(description='Prepare face dataset for SegFormer')
    parser.add_argument('--face-dir', required=True, help='Base directory for defacto-face')
    parser.add_argument('--au-dir', required=True, help='Authentic image directory')
    parser.add_argument('--out-dir', required=True, help='Output base directory')
    args = parser.parse_args()

    out_img_train = os.path.join(args.out_dir, 'images', 'train')
    out_img_val = os.path.join(args.out_dir, 'images', 'val')
    out_ann_train = os.path.join(args.out_dir, 'annotations', 'train')
    out_ann_val = os.path.join(args.out_dir, 'annotations', 'val')

    for d in [out_img_train, out_img_val, out_ann_train, out_ann_val]:
        os.makedirs(d, exist_ok=True)

    # Guard: ตรวจสอบโฟลเดอร์ก่อน glob
    if not os.path.isdir(args.face_dir):
        raise FileNotFoundError(f"Face directory not found: {args.face_dir}")
    if not os.path.isdir(args.au_dir):
        raise FileNotFoundError(f"Authentic image directory not found: {args.au_dir}")

    au_files = sorted(glob.glob(os.path.join(args.au_dir, '*.*')))
    
    tp_files = []
    for sub in ['morphing_img', 'swapping_img']:
        tp_dir = os.path.join(args.face_dir, sub, 'img')
        if os.path.isdir(tp_dir):
            tp_files.extend(sorted(glob.glob(os.path.join(tp_dir, '*.*'))))

    if len(tp_files) == 0:
        raise ValueError(f"No tampered images found in: {args.face_dir}")

    print(f"Found {len(au_files)} Authentic and {len(tp_files)} Tampered images.")

    # Split train/val (80/20)
    random.seed(42)
    au_files_labeled = [(f, 0) for f in au_files]
    tp_files_labeled = [(f, 1) for f in tp_files]

    random.shuffle(au_files_labeled)
    random.shuffle(tp_files_labeled)

    # Undersampling: จำกัด Authentic ให้เท่ากับ Tampered (1:1) เพื่อป้องกัน class imbalance
    if len(au_files_labeled) > len(tp_files_labeled):
        au_files_labeled = au_files_labeled[:len(tp_files_labeled)]
        print(f"Undersampled Authentic to {len(au_files_labeled)} images.")

    au_train_idx = int(len(au_files_labeled) * 0.8)
    tp_train_idx = int(len(tp_files_labeled) * 0.8)

    train_files = au_files_labeled[:au_train_idx] + tp_files_labeled[:tp_train_idx]
    val_files = au_files_labeled[au_train_idx:] + tp_files_labeled[tp_train_idx:]

    random.shuffle(train_files)
    random.shuffle(val_files)

    print(f"Train: {len(train_files)} | Val: {len(val_files)}")

    # บันทึก split list เพื่อให้ reproducible และ debug ได้ง่าย
    split_record = {
        'train': [{'path': p, 'label': l} for p, l in train_files],
        'val':   [{'path': p, 'label': l} for p, l in val_files],
    }
    split_path = os.path.join(args.out_dir, 'split.json')
    with open(split_path, 'w') as f:
        json.dump(split_record, f, indent=2)
    print(f"Saved split list to {split_path}")

    print("Processing Train set...")
    process_and_save(
        train_files, out_img_train, out_ann_train
    )

    print("Processing Val set...")
    process_and_save(
        val_files, out_img_val, out_ann_val
    )

    print("Done! Dataset is ready for SegFormer training.")


if __name__ == '__main__':
    main()
