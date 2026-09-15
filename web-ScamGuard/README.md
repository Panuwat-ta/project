# ScamGuard Documentation Website

เว็บไซต์เอกสารแบบ static ที่สร้างจาก Markdown ทั้งหมดใน `../wiki` โดยไม่แก้ไฟล์ต้นฉบับ เปิดใช้งานผ่าน `file://` ได้และไม่ต้องเชื่อมต่ออินเทอร์เน็ต

## เปิดเว็บไซต์

ดับเบิลคลิก `../index.html` หรือ `index.html` ในโฟลเดอร์นี้ด้วยเว็บเบราว์เซอร์ หน้าเอกสารและระบบค้นหาทำงานจากไฟล์ภายในเครื่องทั้งหมด

## อัปเดตจาก Wiki

ต้องติดตั้ง Node.js ก่อน จากนั้นรัน:

```bash
npm --prefix web-ScamGuard install
npm --prefix web-ScamGuard run build
npm --prefix web-ScamGuard test
npm --prefix web-ScamGuard run check
```

ตัวสร้างจะค้นหา `wiki/**/*.md` แบบ recursive ดังนั้นหน้า Markdown ใหม่จะถูกเพิ่มในหมวดเอกสารอัตโนมัติจากค่า `category` ใน frontmatter หรือชื่อโฟลเดอร์

ผลการสร้างและรายการลิงก์ที่หาเป้าหมายไม่ได้อยู่ใน `build-report.json` การตรวจจะไม่สร้างปลายทางปลอมให้ลิงก์ที่ไม่สมบูรณ์

## โครงสร้าง

- `scripts/` ตัวสร้างเว็บไซต์และตัวตรวจผลลัพธ์
- `src/` CSS และ JavaScript ต้นฉบับ
- `tests/` unit tests ของตัวแปลง
- `pages/`, `assets/`, `sources/` และ `index.html` เป็นผลลัพธ์จากคำสั่ง build

Mermaid ถูกแปลงเป็น SVG ในขั้นตอน build โดยใช้ Chrome ที่ `/usr/bin/google-chrome` และไฟล์ต้นฉบับ Wiki ถูกคัดลอกไว้ใต้ `sources/wiki/` เพื่อใช้อ้างอิงแบบออฟไลน์
