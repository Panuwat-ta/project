# แผนการทดสอบอัตโนมัติ: การทดสอบประสิทธิภาพและอัตราการรองรับ (Performance & Load Automation Test Plan)

- **System / Component**: ScamGuard Infrastructure & API Gateway
- **Framework**: Locust (Python-based Distributed Load Testing Framework)
- **Execution Script**: `tests_all/automate_tests/run.sh perf`
- **Document Version**: 1.0.0
- **Status**: Approved

---

## 1. วัตถุประสงค์และเป้าหมายตัวชี้วัด (Objectives & Target KPIs)

การทดสอบประสิทธิภาพอัตโนมัติมีวัตถุประสงค์เพื่อประเมินขีดความสามารถของระบบในการรองรับปริมาณคำขอพร้อมกัน (Concurrency), ค้นหาจุดคอขวด (Bottlenecks) ของระบบประมวลผล AI และแคช, และยืนยันว่าระบบตอบสนองได้ตามเกณฑ์ Non-Functional Requirements ที่ระบุไว้

| ตัวชี้วัด (Metric) | เกณฑ์ที่ยอมรับได้ (Target KPI) | วิธีการวัด |
|---|---|---|
| **Cache Hit Latency** | Median <= 1.5s, 95th Percentile (p95) <= 3.0s | Locust Task: Repeat Image Scan Upload |
| **Full Inference Latency** | 90th Percentile (p90) <= 15.0s | Locust Task: Unique High-Res Image Upload |
| **Error Rate** | 0.0% ที่โหลดปกติ (<= 50 CCU) | สัดส่วน HTTP Non-2xx Responses |
| **System Throughput** | >= 30 คำขอต่อวินาที (RPS) สำหรับงานผสม | Locust Aggregate Statistics |
| **Worker Resource Limit** | RAM <= 80%, GPU Memory ไม่เกิด OOM Crash | ระบบติดตามสถานะ Resource Monitor |

---

## 2. การออกแบบรูปแบบการโหลด (Load Profile & Test Scenarios)

### 2.1 โครงสร้างการทำงานของ Locustfile (`locustfile.py`)
- **ScamGuardUser Class**:
  - `wait_time`: สุ่มช่วงเวลาระหว่าง 1 ถึง 3 วินาที เพื่อจำลองพฤติกรรมมนุษย์จริง
  - Task 1 (Weight 3): ตรวจสอบสถานะความพร้อมผ่าน `GET /health`
  - Task 2 (Weight 1): อัปโหลดรูปภาพทดสอบผ่าน `POST /api/v1/scan/upload` โดยสร้างภาพใน Memory ผ่าน PIL

### 2.2 สถานการณ์การทดสอบโหลด (Load Scenarios)
1. **Baseline Load (Smoke Test)**:
   - จำนวนผู้ใช้เสมือน: 10 Virtual Users
   - Spawn Rate: 2 ผู้ใช้/วินาที
   - ระยะเวลา: 2 นาที
   - วัตถุประสงค์: ตรวจสอบความพร้อมของไพป์ไลน์ว่าไม่มีข้อผิดพลาดเบื้องต้น
2. **Stress Load (Peak Traffic)**:
   - จำนวนผู้ใช้เสมือน: 50 - 100 Virtual Users
   - Spawn Rate: 5 ผู้ใช้/วินาที
   - ระยะเวลา: 10 นาที
   - วัตถุประสงค์: ตรวจสอบพฤติกรรมเมื่อมีคำขอส่งเข้ามาอย่างหนาแน่นและทดสอบขีดจำกัดของ Redis Cache
3. **Endurance / Soak Test**:
   - จำนวนผู้ใช้เสมือน: 30 Virtual Users คงที่
   - ระยะเวลา: 1 ชั่วโมง
   - วัตถุประสงค์: ตรวจสอบ Memory Leak ของกระบวนการ Tiling และความเสถียรของ Database Connection Pool

---

## 3. ขั้นตอนการสั่งรันและรายงานผล (Execution & Reporting)

### 3.1 การสั่งรันผ่าน Headless CLI (สำหรับ CI/CD หรือ Automated Run)
```bash
cd /home/panuwat/project/tests_all/automate_tests

# สั่งรันผ่าน run.sh
./run.sh perf

# หรือสั่งรันด้วยคำสั่ง Locust โดยตรง
locust -f tests/performance/locustfile.py \
  --headless \
  --users 50 \
  --spawn-rate 5 \
  --run-time 3m \
  --host http://localhost:8000 \
  --html reports/locust_report.html \
  --csv reports/locust_stats
```

### 3.2 การรันแบบ Web UI Console (สำหรับการวิเคราะห์แบบ Real-time)
```bash
locust -f tests/performance/locustfile.py --host http://localhost:8000
# เปิดเบราว์เซอร์ที่ http://localhost:8089 เพื่อควบคุมและดูกราฟ Real-time
```

---

## 4. การจัดการความเสี่ยงและจุดที่ต้องเฝ้าระวัง (Risk Monitoring)
- **GPU Memory Saturation**: การส่งงานประมวลผลขนาดใหญ่เข้าโมเดล SegFormer พร้อมกันอาจทำให้เกิด Out-Of-Memory (OOM) ดังนั้นระบบต้องมีคิวจัดการ (Task Queue) และจำกัด Concurrency ของ Subprocess
- **Connection Pool Exhaustion**: ในระหว่างการยิงโหลดสูง ต้องเฝ้าสังเกตค่า `max_connections` ของ PostgreSQL และ Redis ไม่ให้เกินขีดจำกัด
