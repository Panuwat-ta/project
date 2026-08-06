from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.core.database import Base

class ScamReport(Base):
    __tablename__ = "scam_reports"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    scan_id = Column(UUID(as_uuid=True), ForeignKey("scans.id", ondelete="SET NULL"), nullable=True)
    category = Column(String(50), nullable=False, default="other")
    reason = Column(Text, nullable=False)
    platform = Column(String(50), nullable=True)
    reference_url = Column(String(512), nullable=True)
    allow_research_use = Column(Boolean, nullable=False, default=False)
    status = Column(String(20), nullable=False, default="pending")  # pending, reviewing, approved, rejected
    admin_note = Column(Text, nullable=True)
    moderated_by = Column(Integer, ForeignKey("admins.id"), nullable=True)
    moderated_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
