# ER Diagram for ScamGuard (9 ตาราง)

```mermaid
erDiagram
    users {
        int id PK
        string email
        string hashed_password
        string full_name
        string role "user, researcher, admin"
        boolean is_active
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
        string image_hash "SHA-256 String(64)"
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
        text xai_explanation
        string status
        int progress
        datetime created_at
        datetime completed_at
    }

    scam_reports {
        int id PK
        int user_id FK
        uuid scan_id FK
        string category
        text reason
        string platform
        string reference_url
        boolean allow_research_use
        string status "pending, reviewing, approved, rejected"
        text admin_note
        int moderated_by FK
        datetime moderated_at
        datetime created_at
        int version
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
        string version_tag "unique"
        string file_path
        boolean is_active
        datetime deployed_at
        string artifact_checksum
        string framework_compatibility "onnx"
        float a_acc
        float m_iou
        float m_acc
        float m_dice
        string dataset_reference
        int created_by FK
        string status
        jsonb deployment_history
    }

    admin_sessions {
        string id PK
        int admin_id FK
        string refresh_hash
        datetime expires_at
        datetime revoked_at
        string replaced_by
        string user_agent
        string ip_address
        datetime created_at
        datetime last_used_at
    }

    audit_log {
        int id PK
        int admin_id FK
        string action
        string entity_type
        string entity_id
        jsonb before_state
        jsonb after_state
        text reason
        string ip_address
        text user_agent
        string request_id
        text details
        datetime created_at
    }

    export_jobs {
        uuid id PK
        int admin_id FK
        string status
        float progress
        int total_rows
        bigint file_size_bytes
        string error_message
        string file_path
        jsonb manifest
        jsonb filter_config
        datetime expires_at
        datetime created_at
        datetime completed_at
    }

    %% Relationships
    users ||--o{ scans : "performs"
    users ||--o{ scam_reports : "submits"
    users ||--o{ consent_logs : "records"
    admins ||--o{ scam_reports : "moderates"
    admins ||--o{ audit_log : "performs"
    admins ||--o{ admin_sessions : "has"
    admins ||--o{ model_versions : "deploys"
    admins ||--o{ export_jobs : "creates"
    scans ||--o{ scam_reports : "is reported in"
```

## รายละเอียดแต่ละตาราง
- **users**: เก็บข้อมูลบัญชีผู้ใช้ (role: user/researcher/admin)
- **admins**: เก็บข้อมูลบัญชีผู้ดูแลระบบแยกตาราง
- **scans**: เก็บข้อมูลสรุปของการสแกนรูปภาพ พร้อมคะแนนความเสี่ยง
- **scam_reports**: การรายงานภาพว่าเป็น Scam โดยผู้ใช้ และแอดมินใช้พิจารณา
- **consent_logs**: ใช้เก็บประวัติการยินยอมเพื่อทำ PDPA Compliance
- **model_versions**: ข้อมูลโมเดล AI ที่ Deploy แต่ละเวอร์ชัน (metrics a_acc/m_iou/m_acc/m_dice)
- **admin_sessions**: session/refresh-token ของ admin
- **audit_log**: บันทึกกิจกรรมสำคัญที่กระทำโดย Admin (Append-only)
- **export_jobs**: งาน export dataset ของ admin
