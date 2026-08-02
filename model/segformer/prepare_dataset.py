import os
import glob
import cv2
import numpy as np
import shutil
import random

def main():
    base_dir = '/home/panuwat/project/model/segformer/data/dataset_CASIA2.0'
    casia_dir = os.path.join(base_dir, 'CASIA2.0_revised')
    
    au_dir = os.path.join(casia_dir, 'Au')
    tp_dir = os.path.join(casia_dir, 'Tp')
    gt_dir = os.path.join(casia_dir, 'CASIA2.0_Groundtruth')
    
    out_img_train = os.path.join(base_dir, 'images', 'train')
    out_img_val = os.path.join(base_dir, 'images', 'val')
    out_ann_train = os.path.join(base_dir, 'annotations', 'train')
    out_ann_val = os.path.join(base_dir, 'annotations', 'val')
    
    # Create directories
    for d in [out_img_train, out_img_val, out_ann_train, out_ann_val]:
        os.makedirs(d, exist_ok=True)
        
    # Get all file paths
    au_files = glob.glob(os.path.join(au_dir, '*.*'))
    tp_files = glob.glob(os.path.join(tp_dir, '*.*'))
    
    print(f"Found {len(au_files)} Authentic images and {len(tp_files)} Tampered images.")
    
    # Assign labels: 0 for Au, 1 for Tp
    all_files = [(f, 0) for f in au_files] + [(f, 1) for f in tp_files]
    
    # Split train and val (80/20) using random
    random.seed(42)
    au_files_labeled = [(f, 0) for f in au_files]
    tp_files_labeled = [(f, 1) for f in tp_files]
    
    random.shuffle(au_files_labeled)
    random.shuffle(tp_files_labeled)
    
    au_train_idx = int(len(au_files_labeled) * 0.8)
    tp_train_idx = int(len(tp_files_labeled) * 0.8)
    
    train_files = au_files_labeled[:au_train_idx] + tp_files_labeled[:tp_train_idx]
    val_files = au_files_labeled[au_train_idx:] + tp_files_labeled[tp_train_idx:]
    
    random.shuffle(train_files)
    random.shuffle(val_files)
    
    print(f"Train size: {len(train_files)}, Val size: {len(val_files)}")
    
    def process_and_save(file_list, img_out_dir, ann_out_dir):
        total = len(file_list)
        for i, (img_path, label) in enumerate(file_list):
            if i % 500 == 0:
                print(f"[{img_out_dir}] Processed {i}/{total}...")
            base_name = os.path.splitext(os.path.basename(img_path))[0]
            
            # Use original filename but with .jpg extension for images
            out_img_path = os.path.join(img_out_dir, base_name + '.jpg')
            # Annotation MUST end with .png
            out_ann_path = os.path.join(ann_out_dir, base_name + '.png')
            
            img = cv2.imread(img_path)
            if img is None:
                print(f"Failed to read image: {img_path}")
                continue
            
            h, w = img.shape[:2]
            
            if label == 1: # Tp
                # Find ground truth mask
                mask_path = os.path.join(gt_dir, base_name + '_gt.png')
                if not os.path.exists(mask_path):
                    # Try finding it with .tif or other extensions if _gt.png doesn't exist
                    # but usually it's _gt.png
                    print(f"Warning: Mask not found for {base_name}")
                    mask = np.zeros((h, w), dtype=np.uint8)
                else:
                    mask = cv2.imread(mask_path, cv2.IMREAD_GRAYSCALE)
                    if mask is None:
                        mask = np.zeros((h, w), dtype=np.uint8)
                    else:
                        # Convert 255 to 1 (all values > 0 become 1)
                        mask = (mask > 0).astype(np.uint8)
            else: # Au
                # Create black mask
                mask = np.zeros((h, w), dtype=np.uint8)
            
            # Save image as JPG
            cv2.imwrite(out_img_path, img)
            # Save mask as PNG
            cv2.imwrite(out_ann_path, mask)

    print("Processing Train set...")
    process_and_save(train_files, out_img_train, out_ann_train)
    
    print("Processing Val set...")
    process_and_save(val_files, out_img_val, out_ann_val)
    
    print("Done! Dataset is ready for SegFormer training.")

if __name__ == '__main__':
    main()
