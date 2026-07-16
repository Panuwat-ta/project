import os
import torch
import numpy as np
import cv2
from mmseg.apis import init_model, inference_model

def run_inference(image_path, config_file, checkpoint_file, device='cuda:0'):
    """
    ฟังก์ชันสำหรับรันโมเดล SegFormer เพื่อตรวจหาการตัดต่อรูปภาพ
    """
    print(f"กำลังโหลดโมเดลจากคอนฟิก: {config_file}")
    
    # 1. โหลดโมเดลจาก Config และ Checkpoint
    # หากรันบน CPU ให้เปลี่ยน device='cpu'
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
        
        output_path = "result_heatmap.jpg"
        cv2.imwrite(output_path, overlay_image)
        print(f"บันทึกผลลัพธ์ภาพ Heatmap สำเร็จที่: {output_path}")
    else:
        print("ไม่พบไฟล์รูปภาพต้นฉบับ")

if __name__ == '__main__':
    # กำหนดพาธของไฟล์คอนฟิก (อ้างอิงไปที่โฟลเดอร์ configs ของเราเอง)
    CONFIG_PATH = "configs/segformer_mit-b2.py"
    
    # ไฟล์น้ำหนักโมเดล (ต้องผ่านการเทรนมาก่อนถึงจะมี)
    CHECKPOINT_PATH = "work_dirs/segformer_mit-b2/latest.pth" 
    
    # ภาพทดสอบ
    IMAGE_PATH = "test_scam.jpg"
    
    if not os.path.exists(CONFIG_PATH):
        print(f"ไม่พบไฟล์คอนฟิก: {CONFIG_PATH}")
    elif not os.path.exists(CHECKPOINT_PATH):
        print(f"ไม่พบไฟล์ Checkpoint: {CHECKPOINT_PATH} (รันเทรนโมเดลก่อน)")
    else:
        run_inference(IMAGE_PATH, CONFIG_PATH, CHECKPOINT_PATH, device='cpu')
