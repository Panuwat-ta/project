---
title: "Use Case Diagram"
category: requirements
tags: [requirements, use-case, diagram, canonical]
sources: [Document/srs/05_Software_Requirement_Specification.md, Document/Software Architecture/Use-Case-Diagram.md]
updated: 2026-09-16
---

# Use Case Diagram

Use cases ผูกกับ canonical FR IDs จาก SRS โดยตรง

```mermaid
flowchart LR
    classDef actorFill fill:#fff2cc,stroke:#d6b656,color:black
    classDef ucFill fill:#dae8fc,stroke:#6c8ebf,color:black
    classDef extFill fill:#f5f5f5,stroke:#666666,color:black

    User("General User<br>[Actor]")
    Admin("Admin<br>[Actor]")

    subgraph SystemBoundary [Scam Image Detection System]
        direction TB
        UCAUTH("Authentication<br>FR-AUTH-01..04")
        UCSCAN("Select, crop, upload, poll<br>FR-SCAN-01..03")
        UCANALYZE("Textual / Visual / Source / Risk<br>FR-ANALYSIS-01..04")
        UCXAI("View result & Heatmap<br>FR-XAI-01")
        UCHISTORY("History & scam report<br>FR-HISTORY-01..02")
        UCPDPA("Consent management<br>FR-PDPA-01")
        UCADMIN("Dashboard, moderation, model, audit<br>FR-ADMIN-01..04")
    end

    GoogleVision("Google Vision API<br>[optional source analysis]")

    User --> UCAUTH
    User --> UCSCAN
    User --> UCXAI
    User --> UCHISTORY
    User --> UCPDPA
    Admin --> UCADMIN

    UCSCAN -. " <<include>> " .-> UCANALYZE
    UCXAI -. " <<include>> " .-> UCANALYZE
    UCANALYZE --> GoogleVision

    class User,Admin actorFill
    class UCAUTH,UCSCAN,UCANALYZE,UCXAI,UCHISTORY,UCPDPA,UCADMIN ucFill
    class GoogleVision extFill
```

## คำอธิบาย Use Cases

| Use case | Actor | Canonical requirements | พฤติกรรมปัจจุบัน |
| :--- | :--- | :--- | :--- |
| Authentication | General User | FR-AUTH-01..04 | Email/Password + JWT; consent ส่งใน register body; code v1 ไม่มี OAuth |
| Select, crop, upload | General User | FR-SCAN-01..02 | Gallery, crop, `POST /api/v1/scan/` |
| Wait for result | General User | FR-SCAN-03 | Mobile poll `GET /api/v1/scan/{scan_id}` ทุก 3 วินาที; ไม่มี Mobile WebSocket client |
| Analyze image | System | FR-ANALYSIS-01..04 | Textual, Visual และ Source ร่วมคำนวณ; EXIF แสดงผลเท่านั้น |
| View explainable result | General User | FR-XAI-01 | Risk badge เขียว/amber/แดง, Breakdown 3 มิติ และ Heatmap |
| History & report | General User | FR-HISTORY-01..02 | ดู/ลบประวัติและส่ง Scam Report |
| Consent | General User | FR-PDPA-01 | บันทึก `system_consent`/`research_consent` ใน `consent_logs` |
| Admin operations | Admin | FR-ADMIN-01..04 | บัญชี `admins` แยกจาก `users`; Dashboard, Report Queue, Model, Audit |

## ประเด็นสำคัญ

- แผนภาพนี้ไม่ออก requirement IDs ใหม่
- FCM และ Social Login ไม่อยู่ใน implemented v1 use cases
- Admin authentication และ Mobile authentication ใช้คนละตาราง/คนละ session flow

## หน้าที่เกี่ยวข้อง

- [[requirements/functional-requirements]]
- [[requirements/traceability-matrix]]
- [[requirements/srs]]
- [[entities/actors]]
- [[architecture/mobile-app]]
- [[architecture/backend-api]]
