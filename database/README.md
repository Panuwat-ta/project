# ScamGuard Database Setup

ส่วนนี้เป็นระบบฐานข้อมูลสำหรับโปรเจกต์ **Scam Image Detection** (แอปตรวจสอบรูปภาพตัดต่อที่ถูกนำมาหลอกลวง) โดยประกอบไปด้วยบริการต่างๆ ที่รันผ่านคอนเทนเนอร์เพื่อความสะดวกในการตั้งค่าและใช้งาน

## บริการที่รัน (Services)

ระบบประกอบไปด้วย 3 บริการหลัก:
1. **PostgreSQL** (Port `5432`): ฐานข้อมูลหลักสำหรับเก็บข้อมูลแอปพลิเคชัน
2. **Redis** (Port `6379`): ใช้สำหรับ Caching และการทำงานพื้นหลัง (Background tasks/Queue)
3. **pgAdmin** (Port `5050`): เครื่องมือจัดการฐานข้อมูล PostgreSQL ผ่านหน้าเว็บ (Web GUI)

## ข้อมูลการเข้าสู่ระบบ (Default Credentials)

**PostgreSQL:**
- **User:** `scamguard` (หรือตามไฟล์ `.env`)
- **Password:** `password` (หรือตามไฟล์ `.env`)
- **Database:** `scamguard_db` (หรือตามไฟล์ `.env`)

**pgAdmin:**
- **URL:** `http://localhost:5050`
- **Email:** `admin@scamguard.com`
- **Password:** `admin123`

---

## วิธีการรัน (How to run)

> [!NOTE]
> โปรเจกต์นี้ทำงานบนระบบจัดการคอนเทนเนอร์ด้วย **Podman** ดังนั้นคำสั่งต่างๆ จะใช้ `podman compose` เป็นหลัก (หรือใช้ `docker compose` หากมีการทำ alias ไว้)

### 1. เริ่มต้นระบบ (Start Services)
รันคำสั่งนี้ภายในโฟลเดอร์ `database` เพื่อดาวน์โหลด Image และเริ่มต้นคอนเทนเนอร์ทั้งหมดแบบ Background (Detached mode):
```bash
podman compose up -d
```

### 2. สร้างโครงสร้างฐานข้อมูล (Run Migrations)
หากเป็นการรันระบบครั้งแรก (หรือมีการอัปเดต Schema) จำเป็นต้องสร้างตารางต่างๆ ในฐานข้อมูลด้วย Alembic โดยรันคำสั่งเหล่านี้:
```bash
cd ../server
source venv/bin/activate
alembic upgrade head
```

### 3. ตรวจสอบสถานะ (Check Status)
ดูรายการคอนเทนเนอร์ที่กำลังทำงานอยู่:
```bash
podman ps
```
หรือ
```bash
podman compose ps
```

### 4. ดู Log การทำงาน (View Logs)
หากต้องการดู Log ของคอนเทนเนอร์ทั้งหมด:
```bash
podman compose logs -f
```
(กด `Ctrl + C` เพื่อออกจากหน้า Log)

### 5. ปิดระบบ (Stop Services)
หากต้องการปิดคอนเทนเนอร์ทั้งหมด (ข้อมูลจะไม่หายเพราะถูก mount ไว้ใน volume):
```bash
podman compose down
```

---

## การจัดการข้อมูล (Volumes & Networks)
- ระบบมีการตั้งค่า Network เป็น `scamguard_net` เพื่อให้คอนเทนเนอร์คุยกันเองได้
- ข้อมูลของ PostgreSQL และ Redis จะถูกเก็บถาวรใน Volumes (`postgres_data` และ `redis_data`) ทำให้ข้อมูลไม่สูญหายเมื่อปิดคอนเทนเนอร์
