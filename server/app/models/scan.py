from sqlalchemy import Column, String, Integer, Float, Text, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
import uuid
from app.core.database import Base

class Scan(Base):
    __tablename__ = "scans"
    __table_args__ = (
        CheckConstraint(
            "status IN ('pending', 'uploading', 'queued', 'processing_source', "
            "'processing_visual', 'processing_text', 'completed', 'failed')",
            name="ck_scans_status",
        ),
        CheckConstraint("text_score BETWEEN 0 AND 100", name="ck_scans_text_score"),
        CheckConstraint("visual_score BETWEEN 0 AND 100", name="ck_scans_visual_score"),
        CheckConstraint("source_score BETWEEN 0 AND 100", name="ck_scans_source_score"),
        CheckConstraint("total_risk_score BETWEEN 0 AND 100", name="ck_scans_total_risk_score"),
        CheckConstraint("progress BETWEEN 0 AND 100", name="ck_scans_progress"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    image_hash = Column(String(64), nullable=False, index=True)  # SHA-256
    raw_image_url = Column(String(512), nullable=False)
    heatmap_image_url = Column(String(512))
    title = Column(String(255), nullable=True)

    # Risk Scores (0-100)
    text_score = Column(Integer, nullable=False, default=0)
    visual_score = Column(Integer, nullable=False, default=0)
    source_score = Column(Integer, nullable=False, default=0)
    total_risk_score = Column(Integer, nullable=False, default=0)

    # Analysis Details
    exif_data = Column(JSONB)
    ocr_text = Column(Text)
    scam_keywords_found = Column(JSONB)
    reverse_search_results = Column(JSONB)
    ai_gen_probability = Column(Float, default=0.0)
    xai_explanation = Column(Text, nullable=True)

    status = Column(String(20), nullable=False, default="pending")
    progress = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    completed_at = Column(DateTime(timezone=True))

