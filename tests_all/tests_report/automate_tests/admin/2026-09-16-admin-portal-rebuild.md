## 2026-09-16 - ScamGuard Admin Portal (rebuild ใหม่, React 19 + Vite 8)

- Target: `admin-portal/src` ทั้งหมด (api-client, formatters, queue-sort, report flows, auth routing, dashboard smoke)
- Command: `npm run test:run` (vitest run, jsdom + MSW)
- Result: PASS
- Summary: Total: 24 | Passed: 24 | Failed: 0 | Skipped: 0 | Duration: ~4s

### 1. รายการที่ผ่าน (Passed Tests) และพฤติกรรมที่ผ่าน (How it Passed)

- **api-client > login ส่ง form-urlencoded และเก็บ token ใน memory เท่านั้น**:
  - พฤติกรรมที่ผ่าน: MSW ตรวจ Content-Type เป็น `application/x-www-form-urlencoded` และ body มี username/password ครบ; หลัง login `tokenStore.get()` ได้ token แต่ `localStorage`/`sessionStorage` ว่างเปล่า (ยืนยันว่าไม่ persist token)
- **api-client > แนบ Authorization หลัง login**:
  - พฤติกรรมที่ผ่าน: request ถัดไปส่ง header `Authorization: Bearer valid-token` และได้โปรไฟล์กลับมา (Expected == Actual)
- **api-client > 401 พร้อมกันหลาย request ทำ refresh เพียงครั้งเดียวแล้ว retry สำเร็จ**:
  - พฤติกรรมที่ผ่าน: ยิง 2 requests พร้อมกันด้วย token หมดอายุ; refresh ถูกเรียก 1 ครั้ง (counter == 1) และทั้งสอง request retry สำเร็จได้ข้อมูลเดียวกัน
- **api-client > refresh ล้มเหลว (401) ล้าง auth state และเรียก unauthorized handler**:
  - พฤติกรรมที่ผ่าน: token ถูกล้างเป็น null และ handler ถูกเรียก 1 ครั้ง (logout flow)
- **api-client > abort request โยน AbortedRequestError**:
  - พฤติกรรมที่ผ่าน: AbortController ทำให้ promise reject เป็น AbortedRequestError (caller ใช้แยกแยะเพื่อไม่สร้าง toast)
- **api-client > response ผิดรูปถูก Zod reject + 422 map field errors**:
  - พฤติกรรมที่ผ่าน: response ผิด schema กลายเป็น ApiError ข้อความ "รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง"; 422 แปลง `detail[].loc/msg` เป็น `{admin_note: 'field required'}`
- **formatters (5 เคส)**:
  - พฤติกรรมที่ผ่าน: `formatNumber` ใช้ th-TH และ em dash เมื่อ null; `riskLevelForScore` ตรงขอบเขต 39/40/69/70; `normalizeRiskDistribution` รวม key แบบ case-insensitive (`HIGH`+`Critical` → high: 5); `formatWaitingTime` แสดง นาที/ชม.; `formatFileSize`/`formatMetric` คืนค่าถูก (0.87654 → "0.88", null → em dash/null)
- **sortQueue (2 เคส)**:
  - พฤติกรรมที่ผ่าน: ลำดับ [92 เก่า, 92 ใหม่, 58, 41, ไม่มี scan] ถูกต้อง และไม่ mutate array ต้นฉบับ
- **report flows (5 เคส)**:
  - พฤติกรรมที่ผ่าน: รับเคสส่ง `{version}` แล้วได้ status reviewing; body ไม่มี version โดน backend 400; 409 กลายเป็น ApiError ให้ caller refetch (ไม่มี retry อัตโนมัติ); Zod บังคับ audit note/reason (สตริงว่างไม่ผ่าน)
- **auth routing (3 เคส)**:
  - พฤติกรรมที่ผ่าน: ยังไม่ login เข้า protected route เห็น skeleton ระหว่าง bootstrap แล้วไป `/login` โดยไม่ render เนื้อหา; login สำเร็จกลับ route เดิม (เห็น secret-content); ฟอร์มว่างแสดง validation error และไม่ยิง request (calls == 0)
- **dashboard smoke (2 เคส)**:
  - พฤติกรรมที่ผ่าน: render ด้วย fixtures รูป backend จริงแล้วเจอ header/KPI/signal map/คิว/rail ครบ; คิวว่างแสดง empty state "ยังไม่มีรายงานรอตรวจ"

### 2. รายการที่ไม่ผ่าน (Failed Tests) และสาเหตุที่ไม่ผ่าน (How & Why it Failed)

- ไม่มีข้อผิดพลาด (0 Failed)

### หมายเหตุการตรวจสอบเพิ่มเติม (นอก vitest)

- `npm run lint`: 0 errors (มี react-refresh warnings 6 จุด ไม่มีผล runtime)
- `npm run build`: ผ่าน, chunk ใหญ่สุด 304 kB (ไม่เกินเกณฑ์ 500 kB)
- Backend จริง: login 200 ทุก endpoint 200 และ Zod schemas 10 ตัว validate ผ่านทั้งหมด
- Impeccable detector: ไม่พบปัญหา (`[]`)
