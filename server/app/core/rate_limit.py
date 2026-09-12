from slowapi import Limiter
from slowapi.util import get_remote_address
from app.core.config import settings

# Tiered rate limits ต่อนาที แยกตาม role (มติ DOC-02, 2026-09-11)
# ตรงกับ 04 RC-NFR-08 / 05 SRS / Appendix B §9.2:
# Guest (public) 10/min, Authenticated user 60/min, Admin 300/min,
# POST /scan 5/min (ต้นทุนสูง), login/refresh 5/min (กัน brute-force)
GUEST_LIMIT = f"{settings.RATE_LIMIT_GUEST_PER_MINUTE}/minute"
USER_LIMIT = f"{settings.RATE_LIMIT_USER_PER_MINUTE}/minute"
ADMIN_LIMIT = f"{settings.RATE_LIMIT_ADMIN_PER_MINUTE}/minute"
SCAN_CREATE_LIMIT = f"{settings.RATE_LIMIT_SCAN_CREATE_PER_MINUTE}/minute"
LOGIN_LIMIT = "5/minute"

limiter = Limiter(key_func=get_remote_address, default_limits=[GUEST_LIMIT])
