import os
import argparse
import torch
import numpy as np
import cv2
from mmseg.apis import init_model, inference_model

def run_inference(image_path, config_file, checkpoint_file, output_path, device='cuda:0'):
    """
    ฟังก์ชันสำหรับรันโมเดล SegFormer เพื่อตรวจหาการตัดต่อรูปภาพ
    """
    print(f"กำลังโหลดโมเดลจากคอนฟิก: {config_file}")
    
    # 1. โหลดโมเดลจาก Config และ Checkpoint
    model = init_model(config_file, checkpoint_file, device=device)
    
    print(f"กำลังวิเคราะห์ภาพ: {image_path}")
    # 2. ป้อนภาพเข้าโมเดล
    result = inference_model(model, image_path)
    
    # 3. ดึงผลลัพธ์การคาดการณ์ (Segmentation Mask)
    # result.pred_sem_seg.data จะเป็น Tensor ที่เก็บ class index ของแต่ละพิกเซล
    pred_mask = result.pred_sem_seg.data[0].cpu().numpy()
    
    # สมมติว่า Class 1 คือ "รอยตัดต่อ" (ดัดแปลงข้อมูล)
    # เราจะสร้าง Heatmap สีแดงเฉพาะจุดที่เป็น Class 1
    forgery_mask = (pred_mask == 1).astype(np.uint8) * 255
    
    # 4. สร้างภาพ Heatmap นำไปซ้อนทับภาพต้นฉบับ
    original_image = cv2.imread(image_path)
    if original_image is not None:
        # ปรับขนาดหน้ากากให้ตรงกับภาพดั้งเดิม (เผื่อโมเดลย่อส่วนภาพ)
        forgery_mask_resized = cv2.resize(forgery_mask, (original_image.shape[1], original_image.shape[0]), interpolation=cv2.INTER_NEAREST)
        
        # สร้างภาพสีแดง (B,G,R)
        red_heatmap = np.zeros_like(original_image)
        red_heatmap[:, :, 2] = forgery_mask_resized # ใส่สีแดง
        
        # ผสมภาพต้นฉบับกับสีแดง (ความโปร่งใส 0.5)
        alpha = 0.5
        overlay_image = cv2.addWeighted(original_image, 1.0, red_heatmap, alpha, 0)
        
        cv2.imwrite(output_path, overlay_image)
        print(f"บันทึกผลลัพธ์ภาพ Heatmap สำเร็จที่: {output_path}")
    else:
        print(f"ข้อผิดพลาด: ไม่สามารถอ่านไฟล์รูปภาพต้นฉบับได้ ({image_path})")

def main():
    parser = argparse.ArgumentParser(description="สคริปต์สำหรับรันโมเดล SegFormer เพื่อตรวจหาสลิปปลอม")
    parser.add_argument("--config", type=str, default="configs/segformer_mit-b2-v1.py",
                        help="พาธของไฟล์คอนฟิก (default: configs/segformer_mit-b2-v1.py)")
    parser.add_argument("--checkpoint", type=str, default="work_dirs/segformer_v2.0.0/latest.pth",
                        help="พาธของไฟล์โมเดล .pth (default: work_dirs/segformer_v2.0.0/latest.pth)")
    parser.add_argument("--image", type=str, default="test_scam.jpg",
                        help="ภาพที่ต้องการตรวจสอบ (default: test_scam.jpg)")
    parser.add_argument("--output", type=str, default="result_heatmap.jpg",
                        help="พาธสำหรับบันทึกภาพผลลัพธ์ (default: result_heatmap.jpg)")
    
    # เช็คว่ามี GPU (CUDA) ให้ใช้หรือไม่
    default_device = 'cuda:0' if torch.cuda.is_available() else 'cpu'
    parser.add_argument("--device", type=str, default=default_device,
                        help=f"อุปกรณ์ที่ใช้รัน เช่น 'cuda:0' หรือ 'cpu' (default: {default_device})")

    args = parser.parse_args()

    if not os.path.exists(args.config):
        print(f"ไม่พบไฟล์คอนฟิก: {args.config}")
        return
    if not os.path.exists(args.checkpoint):
        print(f"ไม่พบไฟล์ Checkpoint: {args.checkpoint} (คุณต้องรันเทรนโมเดลก่อน)")
        return
    if not os.path.exists(args.image):
        print(f"ไม่พบไฟล์รูปภาพ: {args.image}")
        return

    run_inference(args.image, args.config, args.checkpoint, args.output, device=args.device)

if __name__ == '__main__':
    main()
