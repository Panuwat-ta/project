# รายละเอียดโมเดลปัญญาประดิษฐ์ (AI Models Specification)
## โครงงาน: แอปตรวจสอบรูปภาพตัดต่อที่ถูกนำมาหลอกลวง (Scam Image Detection)

เอกสารฉบับนี้อธิบายรายละเอียดทางเทคนิคของโมเดลปัญญาประดิษฐ์ (AI Models) ที่ใช้ในระบบ เพื่อตอบสนองความต้องการด้านความแม่นยำในการวิเคราะห์ข้อความแฝง และการตรวจหาร่องรอยดัดแปลงภาพ (Forgery Detection) โดยปรับลดความซับซ้อนของโครงสร้างและมุ่งเน้นไปที่โมเดลที่มีประสิทธิภาพสูงสุดตามสถาปัตยกรรมล่าสุด

---

## 1. แผนภาพการทำงานร่วมกันของโมเดล (Model Pipeline Architecture)

ระบบวิเคราะห์และประมวลผลถูกแบ่งเป็น 2 เลเยอร์หลัก ดังนี้:

```mermaid
flowchart TD
    %% Styling
    classDef modelFill fill:#dae8fc,stroke:#6c8ebf,color:black,font-weight:bold
    classDef inputFill fill:#fff2cc,stroke:#d6b656,color:black,font-weight:bold
    classDef outputFill fill:#d5e8d4,stroke:#82b366,color:black,font-weight:bold

    Input["รูปภาพนำเข้า (Input Image)"]
    
    subgraph Textual["Layer 1: Textual Analysis (วิเคราะห์ข้อความ)"]
        OCR["Surya-OCR<br>(Text & Layout Detection)"]
        NLP["Scam Keyword Matching<br>(Regex/NLP Classifier)"]
    end

    subgraph Visual["Layer 2: Visual Anomaly Detection (วิเคราะห์ร่องรอยตัดต่อ)"]
        SegFormer["SegFormer<br>(Transformer Segmentation)"]
        HeatmapGen["Post-Processing<br>(Mask to Grad-CAM Heatmap)"]
    end

    Input --> OCR
    Input --> SegFormer

    OCR -->|"สกัดข้อความ (Thai/Eng)"| NLP
    SegFormer -->|"วิเคราะห์และทำนายระดับพิกเซล"| HeatmapGen

    NLP -->|"คะแนนความเสี่ยงด้านข้อความ"| Final["ประเมินระดับความเสี่ยงรวม<br>(Weighted Risk Score)"]
    HeatmapGen -->|"แผนภูมิความร้อนจุดดัดแปลง"| Final

    class Input inputFill
    class OCR modelFill
    class SegFormer modelFill
    class Final outputFill
```

---

## 2. โมเดลในชั้นวิเคราะห์ข้อความ (Textual Analysis Layer)

เพื่อดึงข้อความจากรูปภาพ (เช่น สลิปโอนเงินปลอม, หน้าจอแชตหลอกลวง, สื่อโฆษณาชวนเชื่อ) มาตรวจสอบคำศัพท์อันตราย (Scam Keywords) เช่น "กู้เงินด่วน", "โอนเงินรับปันผล"

### Surya-OCR (Native PyTorch)
**Surya-OCR** เป็นโมเดลสำหรับอ่านตัวอักษรและวิเคราะห์โครงสร้างเอกสารสมัยใหม่ (Modern OCR) ขับเคลื่อนด้วย VLM (Vision-Language Model) เพื่อลดข้อผิดพลาดที่มักเกิดใน OCR ยุคเก่า โดยในโปรเจกต์นี้เลือกใช้ในรูปแบบ **Native PyTorch (v0.5.0)** เพื่อให้มีความเสถียรสูงสุดและทำงานร่วมกับ Backend Python (FastAPI) ได้โดยตรง โดยไม่จำเป็นต้องพึ่งพาเซิร์ฟเวอร์แยก

* **สามารถดูรายละเอียดเชิงลึกของสถาปัตยกรรม คุณสมบัติหลัก และสมการคณิตศาสตร์ได้ที่:**
  * [เอกสารรายละเอียดโมเดล Surya-OCR](./Surya-OCR.md)

---

## 3. โมเดลในชั้นวิเคราะห์ความผิดปกติของภาพ (Visual Anomaly Detection Layer)

สำหรับการวิเคราะห์ร่องรอยการตัดต่อ ดัดแปลง แก้ไข หรือปลอมแปลงตัวเลขบนสลิปในระดับพิกเซล

### SegFormer (Semantic Segmentation using Transformers)
**SegFormer** เป็นโมเดลสถาปัตยกรรมแบบ Transformer ที่เบาแต่มีประสิทธิภาพสูงมากในงานแยกส่วนภาพ (Semantic Segmentation) โดยถูกนำมาใช้เป็นโมเดลหลักแต่เพียงตัวเดียวในการระบุตำแหน่งพิกเซลที่ผิดปกติ (ทำงานผ่าน ONNX Runtime ใน Worker Process แยกต่างหาก) เพื่อลดความซับซ้อนของระบบและเพิ่มความเร็วในการประมวลผล

* **สามารถดูรายละเอียดเชิงลึกของสถาปัตยกรรม โครงสร้าง และสมการคณิตศาสตร์ได้ที่:**
  * [เอกสารรายละเอียดโมเดล SegFormer](./SegFormer.md)

---

## 4. อัลกอริทึมการประเมินความเสี่ยงรวม (Weighted Risk Score Algorithm)

คะแนนความเสี่ยงโดยรวม (Total Risk Score) คำนวณจากการถ่วงน้ำหนักความสำคัญของผลลัพธ์ทั้ง 3 ชั้น ได้แก่ ข้อความ (Textual), ภาพ (Visual) และแหล่งที่มา (Source) ตามสูตรเดียวกับ `server/app/utils/risk_calculator.py`:

$$ S_{total} = (S_{textual} \times 0.25) + (S_{visual} \times 0.45) + (S_{source} \times 0.30) $$

โดยที่:
* $S_{total}$ คือคะแนนความเสี่ยงรวม มีค่าตั้งแต่ 0 ถึง 100
* $S_{textual}$ คือคะแนนความเสี่ยงด้านข้อความหลอกลวง (ประเมินจากระดับความรุนแรงของ Scam Keyword) — น้ำหนัก 25%
* $S_{visual}$ คือคะแนนความเสี่ยงจากการถูกดัดแปลงภาพ (คำนวณจากค่าเฉลี่ยหรือพื้นที่พิกเซลความร้อนของ SegFormer) — น้ำหนัก 45%
* $S_{source}$ คือคะแนนความเสี่ยงจากแหล่งที่มาของภาพ (Reverse Image Search) — น้ำหนัก 30%

เกณฑ์การตัดสินระดับความเสี่ยง (Risk Grade):

$$
\text{Risk Grade} = 
\begin{cases} 
\text{Safe (ปลอดภัย)} & \text{if } S_{total} < 20 \\
\text{Low (เสี่ยงต่ำ)} & \text{if } 20 \le S_{total} \le 39 \\
\text{Medium (น่าสงสัย)} & \text{if } 40 \le S_{total} \le 69 \\
\text{High (อันตราย)} & \text{if } S_{total} \ge 70 
\end{cases}
$$

* **ช่วงปลอดภัย (0 -- 19):** คะแนนตกอยู่ในช่วงที่ทุกชั้นการวิเคราะห์ (ภาพ ข้อความ และแหล่งที่มา) ไม่มีลักษณะเข้าข่ายการหลอกลวง ถือว่าเชื่อถือได้ในระดับสูง
* **ช่วงเสี่ยงต่ำ (20 -- 39):** มีสัญญาณอ่อนบางจุดที่ตรวจพบ แต่ยังไม่ถึงระดับที่ควรกังวล ผู้ใช้งานควรทราบแต่ไม่จำเป็นต้องดำเนินการใดเป็นพิเศษ
* **ช่วงน่าสงสัย (40 -- 69):** มีบางชั้นตรวจพบความผิดปกติ แต่ไม่ชัดเจนทุกชั้น หรือพบหลักฐานแบบอ่อนๆ ผู้ใช้งานควรพิจารณาประกอบกับวิจารณญาณส่วนตัว
* **ช่วงอันตราย (70 -- 100):** ผลวิเคราะห์ส่วนใหญ่ชี้ไปในทิศทางเดียวกันว่าภาพถูกปรับแต่งหรือมีข้อความหลอกลวงที่ชัดเจน ให้ถือว่าภาพนี้มีความเสี่ยงสูงที่จะเป็นสแกม (กรณี $S_{visual} \ge 80$ ระบบจะขึ้นเป็น High ทันที)

---

## 5. ประสิทธิภาพและเป้าหมายตัวชี้วัด (Target Metrics)

เพื่อให้แอปพลิเคชันทำงานได้อย่างมีประสิทธิภาพในการใช้งานจริง (Production):
* **ความแม่นยำรวมของ AI (F1-Score / Accuracy):** ตั้งเป้าหมายที่ความแม่นยำ $\ge 85\%$ สำหรับการตรวจจับจุดที่ถูกตัดต่อ
* **เวลาเฉลี่ยในการประมวลผล (Inference Latency):** $< 5$ วินาทีต่อภาพ (โดยรวมการทำงานผ่าน ONNX Runtime บนฝั่ง AI Inference Service แล้ว)

---

## 5. การอ้างอิง (References & Related Documents)

เอกสารฉบับนี้อธิบายถึงคุณลักษณะของตัวโมเดลเท่านั้น สำหรับรายละเอียดอื่นๆ สามารถดูเพิ่มเติมได้ที่:
* **กลยุทธ์การฝึกสอนโมเดล:** ดูรายละเอียดเชิงลึกเกี่ยวกับ Incremental Learning, การ Freeze Backbone, และการอัปเดตโมเดลได้ที่ [training.md](./training.md)
* **สถาปัตยกรรมระดับซอฟต์แวร์:** การจัดการไฟล์โมเดล, เวอร์ชัน และ ONNX Export ในระดับระบบ ให้ดูที่เอกสาร [Model Design (Design Folder)](../../design/model.md) และ [Training Design (Design Folder)](../../design/training.md)
