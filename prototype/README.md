

# ScamGuard Prototype

## Run Locally

**Prerequisites:**  Node.js


1. Install dependencies:
   `npm install`
2. Copy [.env.example](.env.example) to `.env.local`, then set `GEMINI_API_KEY` to your Gemini API key

> **ขอบเขต:** โฟลเดอร์ `prototype/` เป็นต้นแบบทดลองภายในเท่านั้น (throwaway) — **ห้ามใช้ใน Production**. ระบบจริงออกแบบแบบ Cloud-Native และรองรับ On-Premise เป็นทางเลือกตามเอกสารสถาปัตยกรรม; ห้าม commit ไฟล์ `.env.local` หรือคีย์จริงลง repo เด็ดขาด
3. Run the app:
   `npm run dev`
