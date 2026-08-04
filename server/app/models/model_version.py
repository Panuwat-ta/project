from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func
from app.core.database import Base

class ModelVersion(Base):
    __tablename__ = "model_versions"
    
    id = Column(Integer, primary_key=True)
    version_tag = Column(String(50), nullable=False, unique=True)
    file_path = Column(String(512), nullable=False)
    is_active = Column(Boolean, nullable=False, default=False)
    deployed_at = Column(DateTime(timezone=True), server_default=func.now())
