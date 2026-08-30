from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base

class AdminSession(Base):
    """Session ที่ออก refresh token ให้ admin เพื่อให้เพิกถอนได้จริง (token rotation)"""
    __tablename__ = "admin_sessions"

    id = Column(String(64), primary_key=True)  # session id (uuid4 hex)
    admin_id = Column(Integer, ForeignKey("admins.id", ondelete="CASCADE"), nullable=False, index=True)
    refresh_hash = Column(String(64), nullable=False, unique=True, index=True)  # sha256 ของ refresh token
    expires_at = Column(DateTime(timezone=True), nullable=False)
    revoked_at = Column(DateTime(timezone=True), nullable=True, index=True)
    replaced_by = Column(String(64), nullable=True)  # id ของ session ใหม่ (rotation)
    user_agent = Column(String(255), nullable=True)
    ip_address = Column(String(64), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_used_at = Column(DateTime(timezone=True), nullable=True)