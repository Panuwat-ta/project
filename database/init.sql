-- สคริปต์เริ่มต้นสำหรับฐานข้อมูล scamguard_db
-- ฐานข้อมูลและ Role ถูกสร้างอัตโนมัติจาก Environment Variables POSTGRES_DB, POSTGRES_USER อยู่แล้ว
-- เราจะใช้ Alembic ในการสร้างตารางแทน ดังนั้นไฟล์นี้จึงเว้นว่างไว้สำหรับ Custom Initialization ในอนาคต (เช่น การติดตั้ง Extension)

-- ใช้งาน UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
