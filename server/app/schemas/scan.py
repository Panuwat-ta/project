from pydantic import BaseModel, ConfigDict
from uuid import UUID
from datetime import datetime
from typing import Optional, Any, Dict, List

class ScanCreateRequest(BaseModel):
    pass # Will use Form Data for file upload

class RiskSummary(BaseModel):
    total_risk_score: int
    grade: str # low, medium, high

class ScanResponse(BaseModel):
    id: UUID
    user_id: Optional[int] = None
    image_hash: str
    raw_image_url: str
    heatmap_image_url: Optional[str] = None
    
    # Risk Scores
    text_score: int
    visual_score: int
    source_score: int
    total_risk_score: int
    risk_grade: Optional[str] = None
    
    # Analysis Details
    exif_data: Optional[Dict[str, Any]] = None
    ocr_text: Optional[str] = None
    scam_keywords_found: Optional[List[str]] = None
    reverse_search_results: Optional[Dict[str, Any]] = None
    ai_gen_probability: float
    
    status: str
    created_at: datetime
    completed_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
