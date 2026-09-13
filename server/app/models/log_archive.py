from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from app.core.database import Base


class AuditLogArchive(Base):
    """สำเนา audit_log ที่หมดอายุ retention (1 ปี) — schema เดียวกัน + archived_at, ไม่มี trigger."""
    __tablename__ = "audit_log_archive"

    id = Column(Integer, primary_key=True)
    admin_id = Column(Integer, nullable=True, index=True)
    action = Column(String(100), nullable=False, index=True)
    entity_type = Column(String(50), nullable=True, index=True)
    entity_id = Column(String(255), nullable=True)
    before_state = Column(JSONB, nullable=True)
    after_state = Column(JSONB, nullable=True)
    reason = Column(Text, nullable=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    request_id = Column(String(100), nullable=True)
    details = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), index=True)
    archived_at = Column(DateTime(timezone=True), server_default=func.now())


class ConsentLogArchive(Base):
    """สำเนา consent_logs ที่หมดอายุ retention (1 ปี) — หลักฐาน PDPA แบบ offline."""
    __tablename__ = "consent_logs_archive"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, nullable=True, index=True)
    system_consent = Column(Boolean, nullable=False)
    research_consent = Column(Boolean, nullable=False)
    ip_address = Column(String(45))
    user_agent = Column(Text)
    created_at = Column(DateTime(timezone=True))
    archived_at = Column(DateTime(timezone=True), server_default=func.now())
