# โมเดลวิเคราะห์ข้อความ (Textual Analysis Layer) - Surya OCR

## ข้อมูลทั่วไป
**Surya-OCR** เป็นโมเดลสำหรับอ่านตัวอักษรและวิเคราะห์โครงสร้างเอกสารระดับสูง โดยในโปรเจกต์นี้เลือกใช้เวอร์ชัน **0.5.0 (Native PyTorch)** แทนการใช้งานผ่าน llama.cpp เพื่อเสถียรภาพสูงสุดและการปรับจูนประสิทธิภาพด้วยไลบรารี PyTorch (CUDA) โดยตรง โมเดลหลักที่ใช้คือ `vikp/surya_det3` สำหรับตรวจจับกล่องข้อความ และ `vikp/surya_rec2` สำหรับอ่านข้อความ

* **คุณสมบัติหลัก (Key Features):**
  * **Multi-lingual Support:** รองรับการอ่านมากกว่า 90 ภาษา รวมทั้งภาษาไทยและอังกฤษ
  * **Native PyTorch Inference:** ทำงานผ่าน Native PyTorch โดยไม่ต้องพึ่งพาเซิร์ฟเวอร์แยกหรือ Docker Container
  * **Layout Detection:** วิเคราะห์บรรทัดและฟิลด์ของสลิปโอนเงินได้แม่นยำ
  * **Robust to Noise:** ทนทานต่อภาพที่ความละเอียดต่ำหรือภาพถูกบีบอัดผ่านแอปแชต

## อัลกอริทึมและสมการคณิตศาสตร์ (Mathematical Formulation)

Surya-OCR อาศัยสถาปัตยกรรมระดับ Vision-Language Model โดยแบ่งการทำงานเป็นส่วนของการเข้ารหัสภาพ (Vision Encoder) และการถอดรหัสข้อความ (Text Decoder):

1. **Vision Encoder (Feature Extraction):**
   ภาพอินพุต $I$ จะถูกแปลงเป็น Sequence ของ Vision Tokens $F_v$ ผ่านเครือข่าย Transformer/CNN:
   $$ F_v = \text{Encoder}_{\text{vision}}(I) $$

2. **Text Decoder (Autoregressive Text Generation):**
   การทำนายข้อความ $Y = (y_1, y_2, \dots, y_T)$ อาศัยความน่าจะเป็นแบบมีเงื่อนไข (Conditional Probability) ในการทำนายตัวอักษรถัดไป:
   $$ P(Y | I) = \prod_{t=1}^T P(y_t | y_{<t}, F_v) $$
   ฟังก์ชันเป้าหมาย (Objective Function) เพื่อลดค่าข้อผิดพลาดระหว่างการเทรนคือ Cross-Entropy Loss ($L_{CE}$):
   $$ L_{CE} = - \sum_{t=1}^T \log P(y_t | y_{<t}, F_v) $$

3. **Layout Detection (Bounding Box Regression):**
   เพื่อกำหนดขอบเขต (Bounding Box) ของตัวอักษร โมเดลใช้ฟังก์ชัน Smooth L1 Loss ในการเทียบพิกัด $(x, y, w, h)$:
   $$ L_{loc}(b, \hat{b}) = \sum_{i \in \{x,y,w,h\}} \text{smooth}_{L_1}(b_i - \hat{b}_i) $$
   เมื่อ $\text{smooth}_{L_1}(x)$ ถูกนิยามเป็น:
   $$ \text{smooth}_{L_1}(x) = \begin{cases} 0.5 x^2 & \text{if } |x| < 1 \\ |x| - 0.5 & \text{otherwise} \end{cases} $$

## บทบาทในระบบ
* ทำการแปลงรูปภาพอินพุตออกมาเป็นสตริงข้อความ (Text Recognition) พร้อมระบุขอบเขตและรูปแบบ (Layout) ของเอกสาร
* ส่งข้อมูลสตริงที่สกัดได้ให้ส่วน Backend กรองหาข้อความหลอกลวง (Scam Keyword Matching) เพื่อนำไปคิดคะแนนความเสี่ยงต่อไป
