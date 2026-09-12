from typing import Optional, List, Literal
from pydantic import BaseModel, UUID4, Field
from datetime import datetime

# Canonical report categories (มติ DOC-08) — ตรงกับ GET /reports/categories
ReportCategory = Literal[
    "romance_scam",
    "online_shopping",
    "fake_slip",
    "investment",
    "identity_theft",
    "ai_deepfake",
    "other",
]

class ReportCreateRequest(BaseModel):
    scan_id: UUID4
    category: ReportCategory
    description: str = Field(..., min_length=10)
    platform: Optional[str] = None
    reference_url: Optional[str] = None
    allow_research_use: bool = False

class ReportResponse(BaseModel):
    id: int
    scan_id: UUID4
    category: str
    description: str
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}

class ReportSubmitResponse(BaseModel):
    id: int
    scan_id: UUID4
    category: str
    status: str
    message: str
    created_at: datetime

class CategoryItem(BaseModel):
    key: str
    label_th: str
    label_en: str

class CategoryListResponse(BaseModel):
    categories: List[CategoryItem]

class ReportListResponse(BaseModel):
    items: List[ReportResponse]
    total: int
    page: int
    limit: int
