# โมเดลวิเคราะห์ข้อความ (Textual Analysis Layer) - Surya OCR 2

## ข้อมูลทั่วไป
**Surya-OCR 2** เป็นโมเดลสำหรับอ่านตัวอักษรและวิเคราะห์โครงสร้างเอกสารสมัยใหม่ (Modern OCR) ขับเคลื่อนด้วย VLM (Vision-Language Model) โดยในโปรเจกต์นี้เลือกใช้รูปแบบ **GGUF Format** (`datalab-to/surya-ocr-2-gguf`) เพื่อลดการใช้ทรัพยากรและทำงานบน Local Server (CPU/GPU) ได้อย่างมีประสิทธิภาพผ่าน `llama.cpp`

* **คุณสมบัติหลัก (Key Features):**
  * **Multi-lingual Support:** รองรับการอ่านมากกว่า 90 ภาษา รวมทั้งภาษาไทยและอังกฤษ
  * **GGUF Optimized:** แปลงน้ำหนักโมเดลเพื่อประหยัดหน่วยความจำ
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
