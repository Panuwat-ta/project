# อัลกอริทึมและสถาปัตยกรรมใน MMSegmentation (Algorithms & Architectures)

**MMSegmentation** เป็นไลบรารีโอเพนซอร์ส (Open-source) บน PyTorch สำหรับงาน Semantic Segmentation ที่รวบรวมอัลกอริทึมและโมเดลที่ทันสมัย (State-of-the-Art) ไว้อย่างครบถ้วน โดยออกแบบโครงสร้างโมเดลให้มีความยืดหยุ่นสูงแบบโมดูลาร์ (Modular Design) ทำให้สามารถปรับเปลี่ยนหรือผสมผสานอัลกอริทึมย่อยๆ ได้ง่าย

---

## 1. แนวคิดแบบ Modular (Modular Decomposition)
MMSegmentation ไม่ได้มองอัลกอริทึมเป็นก้อนเดียว แต่แยกส่วนประกอบออกเป็นชิ้นๆ ดังนี้:

- **Backbone (สกัดลักษณะเด่น):** อัลกอริทึมแกนหลักสำหรับดึง Feature Maps จากรูปภาพ เช่น ResNet, MobileNet, Swin Transformer หรือ Mix Vision Transformer (MiT)
- **Neck (ตัวเชื่อมและรวบรวม Feature):** อัลกอริทึมที่ใช้รวมข้อมูลจาก Backbone หลายๆ ระดับเข้าด้วยกัน เช่น FPN (Feature Pyramid Network)
- **Decode Head (ตัวถอดรหัสและทำนายผล):** อัลกอริทึมส่วนท้ายที่แปลง Feature Map ให้เป็นภาพ Mask การทำนาย (Prediction Mask) เช่น SegformerHead, UPerHead
- **Auxiliary Head:** ส่วนทำนายผลเสริม (ใช้เฉพาะตอน Train) เพื่อช่วยให้ Backbone สกัดฟีเจอร์ได้แม่นยำขึ้น โดยใช้หลักการ Auxiliary Loss

---

## 2. กลุ่มอัลกอริทึม (Algorithms) ที่มีใน MMSegmentation

MMSegmentation รวบรวมสถาปัตยกรรมที่หลากหลาย โดยแบ่งเป็น 2 กลุ่มหลักๆ ตามเทคโนโลยีพื้นฐาน ได้แก่ **CNN-based** และ **Transformer-based**

### 2.1 กลุ่มโครงข่ายประสาทเทียมแบบคอนโวลูชัน (CNN-based Algorithms)
เป็นอัลกอริทึมยุคคลาสสิกถึงยุคกลางที่ใช้การประมวลผลด้วยฟิลเตอร์ (Convolutional Filter)
- **FCN (Fully Convolutional Networks):** ต้นกำเนิดของ Semantic Segmentation เปลี่ยนชั้น Fully Connected ให้เป็น Convolutional ทั้งหมดเพื่อรองรับรูปภาพทุกขนาด
- **PSPNet (Pyramid Scene Parsing Network):** ใช้อัลกอริทึม *Pyramid Pooling Module (PPM)* เพื่อรวบรวมข้อมูลบริบทรอบข้าง (Global Context) ในหลายๆ สเกลพร้อมกัน
- **DeepLab Series (V3, V3+):** ใช้อัลกอริทึม *Atrous Spatial Pyramid Pooling (ASPP)* หรือ Dilated Convolution เพื่อเพิ่มขอบเขตการมองเห็น (Receptive Field) โดยไม่ต้องลดความละเอียดภาพ
- **U-Net:** อัลกอริทึมยอดนิยมสำหรับภาพทางการแพทย์ มีโครงสร้างรูปตัว U (Encoder-Decoder) พร้อม Skip Connections เพื่อรักษาความละเอียดของขอบภาพ
- **HRNet (High-Resolution Network):** รักษา Feature Map ให้มีความละเอียดสูง (High Resolution) ตลอดทั้งโครงข่าย แทนที่จะลดขนาดแล้วค่อยขยายกลับแบบโมเดลอื่นๆ ทำให้ขอบเขตภาพ (Boundary) คมชัด

### 2.2 กลุ่มทรานส์ฟอร์เมอร์ (Transformer-based Algorithms)
เป็นอัลกอริทึมยุคใหม่ที่ใช้เทคโนโลยี *Self-Attention* (แบบเดียวกับ ChatGPT) มาใช้กับรูปภาพ ทำให้โมเดลเข้าใจความสัมพันธ์ของวัตถุระยะไกลในรูปภาพ (Long-range Dependency) ได้ดีมาก
- **SegFormer:** *(อัลกอริทึมที่เราใช้ในโปรเจคนี้)* ใช้ *Mix Vision Transformer (MiT)* เป็น Backbone โดยไม่ต้องอาศัย Positional Encoding แบบตายตัว และใช้ MLP ธรรมดาๆ เป็น Decoder ทำให้โมเดลเร็ว เบา และทนทานต่อภาพที่ถูกรบกวนได้ดีเยี่ยม
- **SETR (SEgmentation TRansformer):** อัลกอริทึมแรกๆ ที่นำ Vision Transformer (ViT) มาใช้กับ Segmentation แบบเพียวๆ โดยถือว่ารูปภาพเป็นชุดของ "คำ (Patches)" เรียงต่อกัน
- **Swin Transformer / UPerNet:** ใช้ *Shifted Window Attention* เพื่อลดภาระการคำนวณของ Transformer จากระดับกำลังสอง (Quadratic) ให้เหลือแค่เชิงเส้น (Linear) ทำให้ประมวลผลภาพขนาดใหญ่ได้เร็วขึ้นมาก
- **Mask2Former:** อัลกอริทึมขั้นสูงที่เปลี่ยนกระบวนทัศน์จากการทำนายผล "รายพิกเซล (Per-pixel classification)" ไปเป็นการทำนายแบบ "หาหน้ากาก (Mask Classification)" ทำหน้าที่ได้ทั้ง Semantic, Instance และ Panoptic Segmentation ในตัวเดียว

---

## 3. อัลกอริทึมสำหรับฟังก์ชันย่อยอื่นๆ (Loss & Data Augmentation)

นอกเหนือจากตัวโมเดลแล้ว MMSegmentation ยังเตรียมอัลกอริทึมสนับสนุนอื่นๆ อีกมากมาย:

### อัลกอริทึมการคำนวณความผิดพลาด (Loss Functions)
- **Cross Entropy Loss:** อัลกอริทึมพื้นฐานที่แม่นยำสูงสำหรับการแยกแยะคลาส
- **Dice Loss:** อัลกอริทึมที่ออกแบบมาสำหรับชุดข้อมูลที่ไม่สมดุลกันสุดๆ (Imbalanced Data) เช่น รอยตัดต่อที่เล็กมากๆ ในภาพใหญ่
- **Focal Loss:** ช่วยให้โมเดลหันไปโฟกัสการเรียนรู้พิกเซลที่มัน "ทายผิดบ่อยๆ" หรือทายยากๆ มากขึ้น

### อัลกอริทึมการปรับเปลี่ยนรูปภาพ (Data Augmentation)
- **Photometric Distortion:** อัลกอริทึมสุ่มปรับแสง สี ความสว่าง คอนทราสต์
- **Geometric Transformations:** สุ่มย่อขยาย บิด หมุน (Random Crop, Random Resize, Flip)
- **Albumentations Integration:** รองรับการดึงชุดคำสั่งล้ำๆ (เช่น Gaussian Noise, Image Compression) มาช่วยให้โมเดลรับมือกับภาพดัดแปลงได้เก่งขึ้น

---

## 4. สมการคณิตศาสตร์ที่สำคัญ (Core Mathematical Equations)

เพื่อความเข้าใจเชิงลึก นี่คือสมการคณิตศาสตร์ที่อยู่เบื้องหลังอัลกอริทึมสำคัญๆ ใน MMSegmentation

### 4.1 สมการ Self-Attention (กลไกหลักของกลุ่ม Transformer)
กลไก Attention จะคำนวณความสัมพันธ์ระหว่างทุกๆ พิกเซลในภาพ เพื่อสร้าง Global Context:
$$ \text{Attention}(Q, K, V) = \text{softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right)V $$
- $Q$ (Query), $K$ (Key), $V$ (Value): เมทริกซ์ที่ได้จากการแปลง Feature Map
- $d_k$: มิติของ Key (ใช้หารเพื่อป้องกันค่า Dot Product ใหญ่เกินไปจน Gradient หาย)
- **ความหมาย:** พิกเซลใดๆ จะดึงข้อมูลจากพิกเซลอื่นมาผสมกันตาม "น้ำหนักความสัมพันธ์" (Softmax)

### 4.2 สมการ Cross Entropy Loss
ใช้สำหรับวัดความผิดพลาดของการแบ่งคลาสแบบมาตรฐาน:
$$ \mathcal{L}_{CE} = - \sum_{c=1}^{C} y_c \log(\hat{y}_c) $$
- $y_c$: ความจริง (Ground Truth) เป็น 1 ถ้าตรงกับคลาส $c$ นอกนั้นเป็น 0
- $\hat{y}_c$: ความน่าจะเป็นที่โมเดลทำนายได้ในคลาส $c$
- **ความหมาย:** ยิ่งโมเดลทำนายคลาสที่ถูกต้องด้วยความมั่นใจต่ำ ค่า Loss ก็จะยิ่งพุ่งสูงขึ้น

### 4.3 สมการ Dice Loss
แก้ปัญหา Class Imbalance (เช่น รอยตัดต่อมีพื้นที่แค่ 1% ของภาพ):
$$ \mathcal{L}_{Dice} = 1 - \frac{2 \sum_{i} y_i \hat{y}_i}{\sum_{i} y_i + \sum_{i} \hat{y}_i} $$
- $y_i$: ค่าความจริงของพิกเซล $i$
- $\hat{y}_i$: ค่าที่ทำนายได้ของพิกเซล $i$
- **ความหมาย:** วัดจาก "พื้นที่ทับซ้อน (Intersection)" หารด้วย "พื้นที่รวมทั้งหมด" ยิ่งทับซ้อนกันมาก Loss ยิ่งเข้าใกล้ 0

### 4.4 สมการ Focal Loss
ปรับปรุงมาจาก Cross Entropy เพื่อเน้นเรียนรู้พิกเซลที่ทายยากๆ (Hard Examples):
$$ \mathcal{L}_{Focal} = - \sum_{c=1}^{C} \alpha_c (1 - \hat{y}_c)^\gamma y_c \log(\hat{y}_c) $$
- $(1 - \hat{y}_c)^\gamma$: Term ลดน้ำหนัก (Modulating Factor)
- $\gamma$ (Gamma): ตัวปรับโฟกัส (มักตั้งค่าเป็น 2)
- **ความหมาย:** ถ้าพิกเซลไหนโมเดลทายถูกแบบมั่นใจชัวร์ๆ (เช่น $\hat{y}_c \approx 1$) ค่า Modulating Factor จะลดทอน Loss จนเหลือใกล้ 0 บังคับให้โมเดลไปสนใจพิกเซลที่ทายผิดบ่อยๆ แทน
