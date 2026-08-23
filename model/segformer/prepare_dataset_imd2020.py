import os
import glob
import json
import cv2
import numpy as np
import random
import argparse

try:
    from tqdm import tqdm
    USE_TQDM = True
except ImportError:
    USE_TQDM = False
    print("tqdm not found, falling back to print-based progress.")


def get_imd2020_files(imd_dir):
    tp_files = []
    
    # 1. Original IMD2020
    # Directory: imd_dir/IMD2020/<id>/
    # Files: <tp_name>.jpg, <tp_name>_mask.png
    base_imd2020 = os.path.join(imd_dir, 'IMD2020')
    if os.path.exists(base_imd2020):
        mask_files = glob.glob(os.path.join(base_imd2020, '*', '*_mask.png'))
        for mask_path in mask_files:
            img_path = mask_path.replace('_mask.png', '.jpg')
            if os.path.exists(img_path):
                tp_files.append((img_path, mask_path, 'orig'))

    # 2. Generative Inpainting
    # Directories: imd_dir/IMD2020_Generative_Image_Inpainting_yu2018_01 to 07
    # Mask dir: imd_dir/IMD2020_Generative_Image_Inpainting_yu2018_mask
    mask_dir = os.path.join(imd_dir, 'IMD2020_Generative_Image_Inpainting_yu2018_mask')
    if os.path.exists(mask_dir):
        for i in range(1, 8):
            img_dir = os.path.join(imd_dir, f'IMD2020_Generative_Image_Inpainting_yu2018_0{i}')
            if not os.path.exists(img_dir): continue
            img_files = glob.glob(os.path.join(img_dir, '*.jpg'))
            for img_path in img_files:
                base_name = os.path.basename(img_path).replace('.jpg', '_mask.jpg')
                mask_path = os.path.join(mask_dir, base_name)
                if os.path.exists(mask_path):
                    tp_files.append((img_path, mask_path, f'inpaint_0{i}'))

    return tp_files


def process_and_save(file_list, img_out_dir, ann_out_dir):
    total = len(file_list)
    seen_names = {}  # ตรวจสอบชื่อไฟล์ชนกัน

    iterator = tqdm(enumerate(file_list), total=total) if USE_TQDM else enumerate(file_list)

    for i, item in iterator:
        if not USE_TQDM and i % 500 == 0:
            print(f"[{img_out_dir}] Processed {i}/{total}...")

        if len(item) == 3: # Tampered
            img_path, mask_path, sub_type = item
            label = 1
        else: # Authentic
            img_path, label = item

        raw_name = os.path.splitext(os.path.basename(img_path))[0]
        
        if label == 1:
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
            mask = cv2.imread(mask_path, cv2.IMREAD_GRAYSCALE)
            if mask is None:
                print(f"Warning: Failed to read mask {mask_path}, saving all-zero mask.")
                mask = np.zeros((h, w), dtype=np.uint8)
            else:
                if mask.shape != (h, w):
                    mask = cv2.resize(mask, (w, h), interpolation=cv2.INTER_NEAREST)
        else:  # Authentic
            mask = np.zeros((h, w), dtype=np.uint8)

        # แปลงเป็น Binary mask (1=forgery, 0=background)
        mask = np.where(mask > 127, 1, 0).astype(np.uint8)

        # Save ภาพและ Annotation
        cv2.imwrite(out_img_path, img)
        cv2.imwrite(out_ann_path, mask)


def main():
    parser = argparse.ArgumentParser(description="Prepare IMD2020 Dataset")
    parser.add_argument("--imd-dir", required=True, help="Path to IMD2020 folder")
    parser.add_argument("--au-dir", required=True, help="Path to Authentic folder")
    parser.add_argument("--out-dir", required=True, help="Path to output folder")
    parser.add_argument("--split-ratio", type=float, default=0.8, help="Train split ratio")
    args = parser.parse_args()

    print("Gathering Tampered images...")
    tp_items = get_imd2020_files(args.imd_dir)
    
    print("Gathering Authentic images...")
    au_files = glob.glob(os.path.join(args.au_dir, '**', '*.jpg'), recursive=True) + \
               glob.glob(os.path.join(args.au_dir, '**', '*.png'), recursive=True) + \
               glob.glob(os.path.join(args.au_dir, '*.jpg')) + \
               glob.glob(os.path.join(args.au_dir, '*.png'))
    # เอารายชื่อไฟล์ที่ไม่ซ้ำกัน
    au_files = list(set(au_files))
    au_items = [(f, 0) for f in au_files]

    print(f"Found {len(au_items)} Authentic and {len(tp_items)} Tampered images.")

    # จัดการ Class Imbalance ด้วยการ Undersample คลาสที่เยอะกว่า
    if len(au_items) > len(tp_items):
        random.seed(42)
        au_items = random.sample(au_items, len(tp_items))
        print(f"Undersampled Authentic to {len(tp_items)} images.")
    elif len(tp_items) > len(au_items):
        random.seed(42)
        tp_items = random.sample(tp_items, len(au_items))
        print(f"Undersampled Tampered to {len(au_items)} images.")

    # นำสองคลาสมารวมกันและสลับลำดับ
    all_items = tp_items + au_items
    random.seed(42)
    random.shuffle(all_items)

    # Train/Val Split
    split_idx = int(len(all_items) * args.split_ratio)
    train_list = all_items[:split_idx]
    val_list = all_items[split_idx:]

    print(f"Train: {len(train_list)} | Val: {len(val_list)}")

    # สร้าง Folder ปลายทาง
    os.makedirs(os.path.join(args.out_dir, 'images', 'train'), exist_ok=True)
    os.makedirs(os.path.join(args.out_dir, 'images', 'val'), exist_ok=True)
    os.makedirs(os.path.join(args.out_dir, 'annotations', 'train'), exist_ok=True)
    os.makedirs(os.path.join(args.out_dir, 'annotations', 'val'), exist_ok=True)

    # บันทึกข้อมูลการ split ไว้เช็คทีหลัง
    with open(os.path.join(args.out_dir, 'split.json'), 'w') as f:
        json.dump({
            "train": len(train_list),
            "val": len(val_list)
        }, f, indent=4)

    print("Processing Train set...")
    process_and_save(train_list, 
                     os.path.join(args.out_dir, 'images', 'train'),
                     os.path.join(args.out_dir, 'annotations', 'train'))

    print("Processing Val set...")
    process_and_save(val_list, 
                     os.path.join(args.out_dir, 'images', 'val'),
                     os.path.join(args.out_dir, 'annotations', 'val'))

    print("Done! Dataset is ready for SegFormer training.")


if __name__ == '__main__':
    main()
