from sqlalchemy import Column, Integer, Boolean, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base

class ConsentLog(Base):
    __tablename__ = "consent_logs"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    system_consent = Column(Boolean, nullable=False, default=True)
    research_consent = Column(Boolean, nullable=False, default=False)
    ip_address = Column(String(45))
    user_agent = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
