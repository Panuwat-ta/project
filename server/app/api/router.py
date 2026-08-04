from fastapi import APIRouter
from app.api.v1 import auth, scan

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(scan.router, prefix="/scan", tags=["Scan & Analysis"])
# api_router.include_router(report.router, prefix="/report", tags=["Scam Reports"])
# api_router.include_router(admin.router, prefix="/admin", tags=["Admin"])
