# เตรียมข้อมูลแบบ Clean (Single Pipeline)

แทนที่ `prepare_dataset_*.py` + `prepare_dataset.sh` ตัวเก่าทั้งหมด (ลบแล้ว) ซึ่งมีปัญหา: บีบอัด JPG ซ้ำ, mask หายแล้วเขียนดำหลอก, ไม่มี manifest

## ใช้ยังไง

```bash
# smoke test (30 ไฟล์/แหล่ง ลง /tmp)
/tmp/plotvenv/bin/python prepare_dataset/clean_dataset.py --out /tmp/dataset_smoke --limit 30

# รันจริง (USB -> Pictures, นานเป็นชั่วโมง รันเบื้องหลัง)
nohup /tmp/plotvenv/bin/python prepare_dataset/clean_dataset.py > /tmp/clean_full.log 2>&1 &
```

## ตัวเลือก

| flag | default | หมายถึง |
|---|---|---|
| `--src` | `/run/media/panuwat/USB/data` | โฟลเดอร์ดิบ (อ่านอย่างเดียว ไม่แตะ) |
| `--out` | `/home/panuwat/Pictures/dataset` | ที่เก็บของ clean |
| `--split` | `0.8` | สัดส่วน train |
| `--seed` | `42` | reproduce ได้ |
| `--limit N` | `0` (=ไม่จำกัด) | จำกัดไฟล์/แหล่ง (smoke test) |
| `--min-side` | `64` | ด้านสั้นสุดที่รับ (px) |

## ผลลัพธ์

```
<out>/images/{train,val}/*.png        รูป lossless (ปลอม+จริงปน, แยกด้วย tag)
<out>/annotations/{train,val}/*.png  mask 0/255 ตรงพิกเซลกับรูป
<out>/manifest.json                   รายชื่อไฟล์ทุกไฟล์ + split + แหล่งที่มา
<out>/clean_log.json                  skipped/quarantine/duplicates พร้อมเหตุผล
```

## กติกาสำคัญ

1. **PNG lossless เท่านั้น** — ไม่บีบอัดซ้ำแบบของเก่า
2. **mask มีปัญหา = ทิ้ง + จด log** — ไม่เขียนดำหลอก (ยกเว้น inpaint2 ที่ mask ว่างคือรูปจริง ย้ายเป็น authentic)
3. **แบ่งแบบ stratified ตาม (tag, label)** — val มีครบทุกแหล่ง; inpaint2 คง split เดิมจากต้นทาง
4. **ไฟล์ซ้ำ (sha1) ข้ามแหล่ง = เก็บตัวแรก + จด log**
