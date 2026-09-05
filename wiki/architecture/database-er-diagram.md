---
title: "Entity Relationship Diagram (ER Diagram)"
category: architecture
tags: [architecture, database, er, postgresql]
sources: [database/ER_Diagram.md]
updated: 2026-09-06
---

# ER Diagram for ScamGuard

แผนผังแสดงความสัมพันธ์ของฐานข้อมูลหลัก (PostgreSQL) ที่ออกแบบไว้สำหรับระบบ Scam Image Detection

```mermaid
erDiagram
    users {
        int id PK
        string email
        string hashed_password
        string full_name
        string role "user, researcher"
        boolean is_active
        boolean consent_analysis
        boolean consent_research
        datetime consent_revoked_at
        datetime created_at
        datetime updated_at
    }

    admins {
        int id PK
        string email
        string hashed_password
        string full_name
        boolean is_active
        boolean is_superadmin
        datetime created_at
        datetime updated_at
    }

    scans {
        uuid id PK
        int user_id FK
        string image_hash
        string title
        string raw_image_url
        string heatmap_image_url
        int text_score
        int visual_score
        int source_score
        int total_risk_score
        jsonb exif_data
        text ocr_text
        jsonb scam_keywords_found
        jsonb reverse_search_results
        float ai_gen_probability
        string status
        int progress
        datetime created_at
        datetime completed_at
    }
    
    scan_results {
        int id PK
        uuid scan_id FK
        string mask_url
        string heatmap_url
        jsonb keywords
        jsonb source_urls
    }

    scam_reports {
        int id PK
        int user_id FK
        uuid scan_id FK
        text reason
        string status "pending, approved, rejected"
        int moderated_by FK
        datetime moderated_at
        datetime created_at
    }

    consent_logs {
        int id PK
        int user_id FK
        boolean system_consent
        boolean research_consent
        string ip_address
        text user_agent
        datetime created_at
    }

    model_versions {
        int id PK
        string version_tag
        string file_path
        boolean is_active
        datetime deployed_at
    }
    
    audit_log {
        int id PK
        int admin_id FK
        string action
        text details
        datetime created_at
    }

    %% Relationships
    users ||--o{ scans : "performs"
    users ||--o{ scam_reports : "submits"
    users ||--o{ consent_logs : "records"
    admins ||--o{ scam_reports : "moderates"
    admins ||--o{ audit_log : "performs"
    
    scans ||--o| scan_results : "has details"
    scans ||--o{ scam_reports : "is reported in"
```

## รายละเอียดแต่ละตาราง

- **users**: เก็บข้อมูลบัญชีผู้ใช้ทั่วไปและนักวิจัย พร้อมสถานะความยินยอม (Consent) และสิทธิ์การใช้งาน
- **admins**: เก็บข้อมูลบัญชีผู้ดูแลระบบ (Admin และ Super Admin) แยกออกจากผู้ใช้ทั่วไปเพื่อความปลอดภัย
- **scans**: เก็บข้อมูลสรุปของการสแกนรูปภาพ พร้อมคะแนนความเสี่ยง สถานะการประมวลผล (`progress`) และหัวข้อภาพ (`title`)
- **scan_results**: (ทางเลือก) เก็บข้อมูลรายละเอียดเพิ่มเติมในกรณีที่มีหลาย Layer ลึกๆ
- **scam_reports**: การรายงานภาพว่าเป็น Scam โดยผู้ใช้ สำหรับให้แอดมินใช้ตรวจสอบและอนุมัติเข้าชุดข้อมูล
- **consent_logs**: ใช้เก็บประวัติการยินยอมเพื่อทำ PDPA Compliance แบบตรวจสอบย้อนหลังได้ (Immutable)
- **model_versions**: ข้อมูลโมเดล AI ที่ Deploy แต่ละเวอร์ชัน พร้อมค่าเมตริกและการควบคุมการ Rollback
- **audit_log**: บันทึกกิจกรรมสำคัญที่กระทำโดย Admin (Append-only) เพื่อความโปร่งใสและตรวจสอบความปลอดภัย

---

## หน้าที่เกี่ยวข้อง

- [[architecture/database-schema|สคีมาฐานข้อมูล (Database Schema)]]
- [[architecture/database-migrations|การจัดการการย้ายฐานข้อมูล (Database Migrations)]]
- [[architecture/admin-portal|สถาปัตยกรรม Admin Portal]]
- [[architecture/backend-api|Backend API]]
