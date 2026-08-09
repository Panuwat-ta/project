from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from app.core.database import Base

class AuditLog(Base):
    __tablename__ = "audit_log"
    
    id = Column(Integer, primary_key=True)
    admin_id = Column(Integer, ForeignKey("admins.id", ondelete="SET NULL"), nullable=True, index=True)
    action = Column(String(100), nullable=False, index=True)
    
    # Structured Audit Log fields
    entity_type = Column(String(50), nullable=True, index=True)  # 'report', 'user', 'model', 'system'
    entity_id = Column(String(255), nullable=True)
    before_state = Column(JSONB, nullable=True)
    after_state = Column(JSONB, nullable=True)
    reason = Column(Text, nullable=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    request_id = Column(String(100), nullable=True)
    
    # Kept for backward compatibility and general messages
    details = Column(Text, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
