from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from app.core.database import Base

class ModelVersion(Base):
    __tablename__ = "model_versions"
    
    id = Column(Integer, primary_key=True)
    version_tag = Column(String(50), nullable=False, unique=True)
    file_path = Column(String(512), nullable=False)
    is_active = Column(Boolean, nullable=False, default=False)
    deployed_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # New Phase 4 Fields
    artifact_checksum = Column(String(256), nullable=True)
    framework_compatibility = Column(String(50), nullable=True, default="onnx")
    a_acc = Column(Float, nullable=True)
    m_iou = Column(Float, nullable=True)
    m_acc = Column(Float, nullable=True)
    m_dice = Column(Float, nullable=True)
    dataset_reference = Column(String(256), nullable=True)
    created_by = Column(Integer, ForeignKey("admins.id"), nullable=True)
    status = Column(String(50), nullable=False, default="inactive") # pending, active, inactive, failed
    deployment_history = Column(JSONB, nullable=True)
