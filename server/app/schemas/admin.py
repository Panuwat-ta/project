from typing import Optional, List, Dict, Any
from pydantic import BaseModel, UUID4
from datetime import datetime

# Dashboard Schemas
class DashboardOverview(BaseModel):
    total_users: int
    active_users_today: int
    total_scans: int
    scans_today: int
    scans_this_week: int
    scans_this_month: int

class DashboardReports(BaseModel):
    total: int
    pending: int
    reviewing: int
    approved: int
    rejected: int

class DashboardModelStatus(BaseModel):
    active_version: Optional[str]
    deployed_at: Optional[datetime]
    total_versions: int

class TrendItem(BaseModel):
    date: str
    count: int

class DashboardResponse(BaseModel):
    overview: DashboardOverview
    risk_distribution: Dict[str, int]
    reports: DashboardReports
    category_breakdown: Dict[str, int]
    model: DashboardModelStatus
    scan_trend: List[TrendItem]

# User Management
class UserAdminResponse(BaseModel):
    id: int
    email: str
    full_name: Optional[str]
    role: str
    is_active: bool
    total_scans: int = 0
    total_reports: int = 0
    created_at: datetime
    updated_at: datetime

class UserAdminListResponse(BaseModel):
    items: List[UserAdminResponse]
    total: int
    page: int
    limit: int

class UserStats(BaseModel):
    total_scans: int
    scans_this_month: int
    total_reports_submitted: int
    reports_approved: int
    reports_rejected: int
    reports_pending: int

class UserAdminDetailResponse(UserAdminResponse):
    stats: UserStats
    recent_scans: List[Dict[str, Any]]

class UserUpdateRequest(BaseModel):
    role: Optional[str] = None
    is_active: Optional[bool] = None

# Report Management
class ReportUser(BaseModel):
    id: int
    email: str
    full_name: Optional[str]
    total_reports_submitted: Optional[int] = None

class ReportScanBrief(BaseModel):
    id: UUID4
    thumbnail_url: Optional[str] = None
    total_risk_score: int
    risk_grade: str

class AdminReportListItem(BaseModel):
    id: int
    user: Optional[ReportUser]
    scan: Optional[ReportScanBrief]
    category: str
    description: str
    platform: Optional[str]
    reference_url: Optional[str]
    allow_research_use: bool
    status: str
    admin_note: Optional[str]
    moderated_by: Optional[int]
    moderated_at: Optional[datetime]
    created_at: datetime

class AdminReportListResponse(BaseModel):
    items: List[AdminReportListItem]
    total: int
    page: int
    limit: int

class AdminReportDetailResponse(AdminReportListItem):
    # Overriding scan to include full details
    scan: Optional[Dict[str, Any]]

class ReportDecisionRequest(BaseModel):
    status: str
    admin_note: Optional[str] = None

# Model Management
class ModelVersionResponse(BaseModel):
    id: int
    version_tag: str
    file_path: str
    is_active: bool
    deployed_at: Optional[datetime]

class ModelVersionListResponse(BaseModel):
    items: List[ModelVersionResponse]
    total: int

# Export
class ExportRequest(BaseModel):
    categories: Optional[List[str]] = None
    from_date: Optional[str] = None
    to_date: Optional[str] = None
    include_metadata: bool = True
    format: str = "zip"

# Audit Logs
class AuditLogResponse(BaseModel):
    id: int
    admin_id: Optional[int]
    action: str
    details: Optional[str]
    created_at: datetime

class AuditLogListResponse(BaseModel):
    items: List[AuditLogResponse]
    total: int
    page: int
    limit: int
