# Mobile App: Scam Image Detection


## 👤 User Flow (การทำงานฝั่งผู้ใช้)
```mermaid
graph TD
    %% Nodes Definition
    Start([เริ่มใช้งาน])
    Home[หน้าแรก<br/>แสดงประวัติรูป]
    ImportMethod{วิธีการนำเข้าไฟล์}
    Camera[ถ่ายรูป]
    Gallery[เลือกรูปจาก Gallery]
    Edit[ปรับแต่ง / Crop รูป]
    Preview[แสดง Preview รูปภาพ]
    CheckBtn[/กดปุ่มตรวจสอบ/]
    Analyzing{ระบบกำลังวิเคราะห์...}
    
    Result[หน้าผลลัพธ์<br/>Risk Score + Evidence]
    Error[แจ้งเตือนข้อผิดพลาด]
    
    Action{Action}
    AutoSave[(Auto-Save ลง DB)]
    Share[แชร์ผลลัพธ์]
    
    Options{ทางเลือก}
    End([จบการทำงาน])

    %% Flow Connections
    Start --> Home
    Home -- "เลือกเมนู" --> ImportMethod
    
    ImportMethod -- "กล้อง" --> Camera
    ImportMethod -- "อัลบั้ม" --> Gallery
    
    Camera --> Edit
    Gallery --> Edit
    Edit --> Preview
    Preview --> CheckBtn
    CheckBtn --> Analyzing
    
    %% Analysis Result Paths
    Analyzing -- "สำเร็จ" --> Result
    Analyzing -- "ล้มเหลว" --> Error
    
    %% Success Flow
    Result --> AutoSave
    Result --> Action
    Action -- "แชร์" --> Share
    Action -- "ไม่แชร์" --> End
    Share --> End
    
    %% Error Flow
    Error --> Options
    Options -- "นำเข้ารูปใหม่" --> ImportMethod
    Options -- "ยกเลิก" --> End

    %% Styling with Black Text (color:#000)
    classDef allText color:#000;
    class Start,Home,ImportMethod,Camera,Gallery,Edit,Preview,CheckBtn,Analyzing,Result,Error,Action,AutoSave,Share,Options,End allText;

    style Start fill:#0050ef,stroke:#001DBC
    style End fill:#0050ef,stroke:#001DBC
    
    style Home fill:#d5e8d4,stroke:#82b366
    style Camera fill:#d5e8d4,stroke:#82b366
    style Gallery fill:#d5e8d4,stroke:#82b366
    style Edit fill:#d5e8d4,stroke:#82b366
    style Preview fill:#d5e8d4,stroke:#82b366
    style Result fill:#d5e8d4,stroke:#82b366
    style Error fill:#d5e8d4,stroke:#82b366
    style Share fill:#d5e8d4,stroke:#82b366
    
    style ImportMethod fill:#fff2cc,stroke:#d6b656
    style Analyzing fill:#fff2cc,stroke:#d6b656
    style Action fill:#fff2cc,stroke:#d6b656
    style Options fill:#fff2cc,stroke:#d6b656
    
    style CheckBtn fill:#e1d5e7,stroke:#9673a6
    style AutoSave fill:#dae8fc,stroke:#6c8ebf
```
### 1. User Flow (กระบวนการฝั่งผู้ใช้)

* **การนำเข้าข้อมูล:** ผู้ใช้สามารถเลือกได้ว่าจะ "ถ่ายรูปใหม่" หรือ "เลือกจากอัลบั้ม" จากนั้นระบบจะมีขั้นตอนให้ปรับแต่งรูปภาพ (Crop/Edit) ก่อนส่งตรวจ เพื่อให้ได้ส่วนที่ต้องการวิเคราะห์จริงๆ
* **การประมวลผล:** เมื่อกดปุ่มตรวจสอบ ระบบจะเข้าสู่สถานะวิเคราะห์ หากเกิดข้อผิดพลาด (เช่น เน็ตหลุด หรือไฟล์เสีย) ระบบจะมีทางเลือกให้ผู้ใช้ลองใหม่หรือยกเลิก
* **ผลลัพธ์และการจัดเก็บ:** เมื่อวิเคราะห์สำเร็จ ผู้ใช้จะเห็นคะแนนความเสี่ยง (Risk Score) และหลักฐานประกอบ (Evidence) โดยระบบจะทำการบันทึกข้อมูลให้อัตโนมัติ (Auto-Save) และเปิดโอกาสให้ผู้ใช้เลือกแชร์ข้อมูลนั้นเพื่อเตือนภัยผู้อื่นได้

---





## ⚙️ System Logic (การทำงานฝั่งระบบ)
```mermaid
graph TD
    %% Nodes Definition
    Start([รับไฟล์รูปภาพ])
    Validate{ตรวจสอบไฟล์<br/>Valid Image?}
    Reject[คืนค่า Error]
    
    Preprocess[Preprocessing<br/>- Resize<br/>- Normalize]
    
    CacheCheck{เคยตรวจรูปนี้ไหม?<br/>Redis Hash}
    RetCache[ดึงผลเก่าจาก DB]
    
    %% Parallel Tasks Section
    Fork1[ ] 
    style Fork1 fill:#000,stroke:#000,height:2px
    
    Task1[<b>Task 1: Metadata</b><br/>ดึงค่า EXIF/GPS]
    Task2[<b>Task 2: Forgery</b><br/>เช็คการตัดต่อ ELA]
    Task3[<b>Task 3: OCR</b><br/>อ่านข้อความในภาพ]
    Task4[<b>Task 4: Source</b><br/>ตรวจสอบแหล่งที่มา]
    
    Join1[ ]
    style Join1 fill:#000,stroke:#000,height:2px
    
    %% Post-Parallel Logic
    Timeout[<b>Partial Failure</b><br/>Timeout < 10 s]
    
    KeywordCheck{เจอ Keyword<br/>อันตรายสูง?}
    Task5[<b>Task 5: AI-Gen</b><br/>เช็คว่าเป็นภาพ AI]
    
    Calc[<b>คำนวณคะแนนความเสี่ยง</b><br/>Weighted Risk Score]
    GenDesc[สร้างคำอธิบายผลลัพธ์]
    SaveDB[(บันทึกลง<br/>Database)]
    End([ส่ง JSON กลับ Client])

    %% Flow Connections
    Start --> Validate
    Validate -- "ไม่ใช่รูป/เสีย" --> Reject
    Validate -- "ถูกต้อง" --> Preprocess
    
    Preprocess --> CacheCheck
    CacheCheck -- "Hit (เคยตรวจ)" --> RetCache
    RetCache --> End
    
    CacheCheck -- "Miss (ไม่เคย)" --> Fork1
    
    Fork1 --> Task1
    Fork1 --> Task2
    Fork1 --> Task3
    Fork1 --> Task4
    
    Task1 --> Join1
    Task2 --> Join1
    Task3 --> Join1
    Task4 --> Join1
    
    Join1 --> Timeout
    Timeout --> KeywordCheck
    
    KeywordCheck -- "เจอความเสี่ยงที่แน่ชัด" --> Calc
    KeywordCheck -- "ไม่พบ" --> Task5
    Task5 --> Calc
    
    Calc --> GenDesc
    GenDesc --> SaveDB
    SaveDB --> End

    %% Styling with Black Text and Draw.io Colors
    classDef allText color:#000;
    class Start,Validate,Reject,Preprocess,CacheCheck,RetCache,Task1,Task2,Task3,Task4,Timeout,KeywordCheck,Task5,Calc,GenDesc,SaveDB,End allText;

    style Start fill:#0050ef,stroke:#001DBC
    style End fill:#0050ef,stroke:#001DBC
    
    style Validate fill:#fff2cc,stroke:#d6b656
    style CacheCheck fill:#fff2cc,stroke:#d6b656
    style KeywordCheck fill:#fff2cc,stroke:#d6b656
    
    style Reject fill:#d5e8d4,stroke:#82b366
    style Calc fill:#d5e8d4,stroke:#82b366
    style Timeout fill:#d5e8d4,stroke:#82b366
    style GenDesc fill:#d5e8d4,stroke:#82b366
    
    style Preprocess fill:#dae8fc,stroke:#6c8ebf
    style RetCache fill:#dae8fc,stroke:#6c8ebf
    style SaveDB fill:#dae8fc,stroke:#6c8ebf
    
    style Task1 fill:#f5f5f5,stroke:#666
    style Task2 fill:#f5f5f5,stroke:#666
    style Task3 fill:#f5f5f5,stroke:#666
    style Task4 fill:#f5f5f5,stroke:#666
    style Task5 fill:#f5f5f5,stroke:#666
```
### 2. System Logic (กระบวนการฝั่งระบบ/หลังบ้าน)

* **Validation & Preprocessing:** ก่อนจะเริ่มวิเคราะห์ ระบบจะเช็คความถูกต้องของไฟล์และปรับขนาด (Resize/Normalize) เพื่อให้โมเดล AI ทำงานได้แม่นยำที่สุด
* **Optimization (Cache Strategy):** มีการใช้ **Redis Hash** เพื่อตรวจสอบว่ารูปนี้เคยมีคนส่งตรวจหรือยัง หาก "เคยแล้ว" ระบบจะดึงผลเก่าจาก DB มาตอบทันที ช่วยประหยัดทรัพยากรเครื่องเซิร์ฟเวอร์
* **Parallel Processing (การทำงานขนาน):** หากเป็นรูปใหม่ ระบบจะแยกการทำงานออกเป็น 4 งานหลักพร้อมกัน (Task 1-4) เพื่อความรวดเร็ว:
* **Metadata:** เช็คค่า EXIF/GPS ว่ารูปถ่ายที่ไหน เมื่อไหร่ (ป้องกันการแอบอ้างสถานที่)
* **Forgery (ELA):** เช็คการตัดต่อระดับพิกเซล (Error Level Analysis) เช่น การแก้ตัวเลขบนสลิปโอนเงิน
* **OCR:** อ่านข้อความในภาพเพื่อหา Keyword อันตราย (เช่น ชื่อบัญชีม้า หรือข้อความเชิญชวนหลอกลวง)
* **Source:** ตรวจสอบแหล่งที่มาของภาพ


* **Decision Logic:** ระบบมีจุดตัดสินใจ (Keyword Check) หากพบความเสี่ยงที่ชัดเจนมาก จะข้ามไปคำนวณคะแนนเลย แต่ถ้ายังไม่ชัดเจน จะส่งไปเช็คต่อที่ **AI-Gen Task** เพื่อดูว่าเป็นภาพที่สร้างจาก AI หรือไม่
* **Final Output:** จบด้วยการคำนวณคะแนนแบบถ่วงน้ำหนัก (Weighted Risk Score) สร้างคำอธิบาย บันทึก และส่งกลับไปแสดงผลที่หน้าแอปในรูปแบบ JSON



---

### [Diagram ](https://drive.google.com/file/d/1I2ksLvZp0x3iNYt57_46cqnTDfPgWvzR/view?usp=sharing)






