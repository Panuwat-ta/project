from pydantic import BaseModel, ConfigDict
from uuid import UUID
from datetime import datetime
from typing import Optional, List

class HistoryItemResponse(BaseModel):
    scan_id: UUID
    thumbnail_url: Optional[str] = None
    risk_score: int
    risk_level: Optional[str] = None
    status: str
    created_at: datetime
    title: Optional[str] = None
    
    model_config = ConfigDict(from_attributes=True)

class HistoryListResponse(BaseModel):
    items: List[HistoryItemResponse]
    total: int
    page: int
    limit: int
