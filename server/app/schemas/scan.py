from pydantic import BaseModel, ConfigDict, model_validator
from uuid import UUID
from datetime import datetime
from typing import Optional, Any, Dict, List, Literal

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
    source_score: Optional[int] = None
    source_status: Literal["unavailable", "not_checked", "checked_no_match", "matches_found", "error"] = "unavailable"
    total_risk_score: int
    risk_grade: Optional[str] = None
    
    # Analysis Details
    exif_data: Optional[Dict[str, Any]] = None
    ocr_text: Optional[str] = None
    scam_keywords_found: Optional[List[str]] = None
    reverse_search_results: Optional[Dict[str, Any]] = None
    ai_gen_probability: float
    xai_explanation: Optional[str] = None
    
    status: str
    progress: int = 0
    created_at: datetime
    completed_at: Optional[datetime] = None

    @model_validator(mode="after")
    def hide_unavailable_source_score(self):
        if self.source_status not in {"checked_no_match", "matches_found"}:
            self.source_score = None
        return self

    model_config = ConfigDict(from_attributes=True)
