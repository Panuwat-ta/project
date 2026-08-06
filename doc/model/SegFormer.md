# โมเดลวิเคราะห์ความผิดปกติของภาพ (Visual Anomaly Detection Layer) - SegFormer

## ข้อมูลทั่วไป
**SegFormer** เป็นโมเดลสถาปัตยกรรมแบบ Transformer ที่มีประสิทธิภาพสูงในงานแยกส่วนภาพ (Semantic Segmentation) โดยถูกนำมาใช้เป็นโมเดลหลักในการระบุตำแหน่งพิกเซลที่ถูกดัดแปลง

* **โครงสร้างและหลักการทำงาน (Mechanism):**
  * **MiT Encoder (Mix Transformer):** สกัดลักษณะเด่นของรูปภาพ (Feature Extraction) จากหลายสเกลความละเอียด ทำให้พิจารณาบริบทภาพรวมและรายละเอียดระดับพิกเซลไปพร้อมกันได้โดยไม่ต้องใช้ Positional Encoding
  * **All-MLP Decoder:** ถอดรหัสโครงสร้างพิกเซลเพื่อสร้าง Segmentation Mask แบบ Binary (จริง/ปลอม)

## อัลกอริทึมและสมการคณิตศาสตร์ (Mathematical Formulation)

การทำงานของ Mix Transformer (MiT) อาศัยกระบวนการลดรูปของ Self-Attention เพื่อประหยัดหน่วยความจำ โดยสามารถเขียนเป็นสมการได้ดังนี้:

1. **Efficient Self-Attention:**
   ในกรณีที่อินพุตคือ $X \in \mathbb{R}^{H \times W \times C}$ จะถูกแปลงให้แบนราบ (Flatten) เป็น Sequence $N = H \times W$
   โดยกระบวนการ Sequence Reduction จะลดมิติของ Key และ Value ลงด้วยอัตราส่วน $R$ เพื่อลดภาระการคำนวณ:
   $$K' = \text{Reshape}\left(\frac{N}{R}, C \cdot R\right)(K) \cdot W_K$$
   $$V' = \text{Reshape}\left(\frac{N}{R}, C \cdot R\right)(V) \cdot W_V$$
   $$ \text{Attention}(Q, K', V') = \text{Softmax}\left( \frac{Q (K')^T}{\sqrt{d_k}} \right) V' $$
   เมื่อ $Q$ คือ Query, $K'$ และ $V'$ คือ Key และ Value ที่ลดมิติแล้ว, และ $d_k$ คือมิติของ Key

2. **Mix-FFN (Mix Feed-Forward Network):**
   เพื่อหลีกเลี่ยงการใช้ Positional Encoding แบบตายตัว SegFormer ใช้ 3x3 Convolution ใน Feed-Forward Network เพื่อพิจารณาตำแหน่งจากบริบทภาพ:
   $$x_{out} = \text{MLP}(\text{GELU}(\text{Conv}_{3\times3}(\text{MLP}(x_{in})))) + x_{in}$$

## บทบาทในระบบ
* ทำหน้าที่ทำนายความน่าจะเป็นระดับพิกเซลของร่องรอยการปลอมแปลง (Pixel-level Prediction)
* คืนค่าผลลัพธ์เป็น Segmentation Mask ซึ่งจะถูกแปลง (Post-Processing) ให้อยู่ในรูปของ **แผนภูมิความร้อน (Grad-CAM Heatmap)** เพื่อใช้วางซ้อน (Overlay) บนรูปต้นฉบับ แจ้งให้ผู้ใช้งานเห็นพื้นที่ดัดแปลงอย่างชัดเจนผ่านแอปพลิเคชัน
