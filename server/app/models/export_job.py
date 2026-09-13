import uuid
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float, BigInteger, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from app.core.database import Base

class ExportJob(Base):
    __tablename__ = "export_jobs"
    __table_args__ = (
        CheckConstraint(
            "status IN ('queued', 'running', 'succeeded', 'failed', 'canceled', 'expired')",
            name="ck_export_jobs_status",
        ),
    )
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    admin_id = Column(Integer, ForeignKey("admins.id", ondelete="SET NULL"), nullable=True, index=True)
    status = Column(String(50), nullable=False, default="queued") # queued, running, succeeded, failed, canceled, expired
    progress = Column(Float, nullable=False, default=0.0)
    total_rows = Column(Integer, nullable=True)
    file_size_bytes = Column(BigInteger, nullable=True)
    error_message = Column(String, nullable=True)
    file_path = Column(String(512), nullable=True)
    manifest = Column(JSONB, nullable=True)
    filter_config = Column(JSONB, nullable=False)
    
    expires_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)
