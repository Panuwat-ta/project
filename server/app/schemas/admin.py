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
    a_acc: Optional[float] = None
    m_iou: Optional[float] = None
    m_acc: Optional[float] = None
    m_dice: Optional[float] = None

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

# System Health
class HealthStatus(BaseModel):
    database: str
    storage: str
    models: str
    queue: str
    last_check: datetime
    
# Global Search
class SearchResultItem(BaseModel):
    id: str
    type: str # 'user', 'report', 'scan'
    title: str
    subtitle: Optional[str] = None
    url: str

class GlobalSearchResponse(BaseModel):
    items: List[SearchResultItem]
    total: int

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
    recent_reports: List[Dict[str, Any]]
    ban_reason: Optional[str] = None

class UserUpdateRequest(BaseModel):
    is_active: bool
    reason: str

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
    version: int

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
    version: int
    admin_note: Optional[str] = None

# Model Management
class ModelVersionResponse(BaseModel):
    id: int
    version_tag: str
    file_path: str
    is_active: bool
    deployed_at: Optional[datetime]
    artifact_checksum: Optional[str]
    framework_compatibility: Optional[str]
    a_acc: Optional[float]
    m_iou: Optional[float]
    m_acc: Optional[float]
    m_dice: Optional[float]
    dataset_reference: Optional[str]
    created_by: Optional[int]
    status: str
    deployment_history: Optional[Any]

class ModelDeployRequest(BaseModel):
    reason: str

class ModelDryRunResponse(BaseModel):
    success: bool
    message: str
    details: Optional[Dict[str, Any]]

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

class ExportJobResponse(BaseModel):
    id: UUID4
    status: str
    progress: float
    total_rows: Optional[int]
    file_size_bytes: Optional[int]
    error_message: Optional[str]
    created_at: datetime
    completed_at: Optional[datetime]
    expires_at: Optional[datetime]

class ExportJobListResponse(BaseModel):
    items: List[ExportJobResponse]
    total: int
    page: int
    limit: int

# Audit Logs
class AuditLogResponse(BaseModel):
    id: int
    admin_id: Optional[int]
    action: str
    entity_type: Optional[str]
    entity_id: Optional[str]
    before_state: Optional[Dict[str, Any]]
    after_state: Optional[Dict[str, Any]]
    reason: Optional[str]
    ip_address: Optional[str]
    user_agent: Optional[str]
    request_id: Optional[str]
    details: Optional[str]
    created_at: datetime

class AuditLogListResponse(BaseModel):
    items: List[AuditLogResponse]
    total: int
    page: int
    limit: int

# Admin Profile & Sessions
class AdminProfileResponse(BaseModel):
    id: int
    email: str
    full_name: Optional[str]
    role: str
    is_superadmin: bool

class AdminProfileUpdateRequest(BaseModel):
    full_name: Optional[str] = None
    current_password: Optional[str] = None
    new_password: Optional[str] = None

class AdminSessionResponse(BaseModel):
    id: str
    is_current: bool = False
    user_agent: Optional[str]
    ip_address: Optional[str]
    created_at: Optional[datetime]
    last_used_at: Optional[datetime]
    expires_at: Optional[datetime]
    revoked_at: Optional[datetime]

class AdminSessionListResponse(BaseModel):
    items: List[AdminSessionResponse]
    total: int
