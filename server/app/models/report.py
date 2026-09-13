from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.core.database import Base

class ScamReport(Base):
    __tablename__ = "scam_reports"
    __table_args__ = (
        CheckConstraint(
            "category IN ('romance_scam', 'online_shopping', 'fake_slip', 'investment', "
            "'identity_theft', 'ai_deepfake', 'other')",
            name="ck_scam_reports_category",
        ),
        CheckConstraint(
            "status IN ('pending', 'reviewing', 'approved', 'rejected')",
            name="ck_scam_reports_status",
        ),
    )
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    scan_id = Column(UUID(as_uuid=True), ForeignKey("scans.id", ondelete="SET NULL"), nullable=True, index=True)
    category = Column(String(50), nullable=False, default="other", index=True)
    reason = Column(Text, nullable=False)
    platform = Column(String(50), nullable=True)
    reference_url = Column(String(512), nullable=True)
    allow_research_use = Column(Boolean, nullable=False, default=False)
    status = Column(String(20), nullable=False, default="pending", index=True)  # pending, reviewing, approved, rejected
    admin_note = Column(Text, nullable=True)
    moderated_by = Column(Integer, ForeignKey("admins.id", ondelete="SET NULL"), nullable=True, index=True)
    moderated_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    version = Column(Integer, default=1, nullable=False)
