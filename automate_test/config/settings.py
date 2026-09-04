"""Central settings for automate_test — โหลดจาก .env + environments.yaml"""
import os
from pathlib import Path
import yaml
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")
# fallback โหลดจาก server/.env ด้วยถ้ามี
load_dotenv(ROOT.parent / "server" / ".env", override=False)

ENV_FILE = ROOT / "config" / "environments.yaml"

def _load_yaml():
    if ENV_FILE.exists():
        with open(ENV_FILE, "r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    return {}

_yaml = _load_yaml()
_env = os.getenv("ENV", "local")
_env_cfg = _yaml.get("environments", {}).get(_env, {})

BASE_URL = os.getenv("BASE_URL", _env_cfg.get("base_url", _yaml.get("base_url", "http://localhost:8000"))).rstrip("/")
API_PREFIX = os.getenv("API_PREFIX", _yaml.get("api_prefix", "/api/v1"))
TEST_USER_EMAIL = os.getenv("TEST_USER_EMAIL", "automate_test_user@example.com")
TEST_USER_PASSWORD = os.getenv("TEST_USER_PASSWORD", "Test1234!@#")
TEST_ADMIN_EMAIL = os.getenv("TEST_ADMIN_EMAIL", "admin@scamguard.local")
TEST_ADMIN_PASSWORD = os.getenv("TEST_ADMIN_PASSWORD", "Admin1234!@#")
TIMEOUT = int(os.getenv("TIMEOUT", str(_yaml.get("defaults", {}).get("timeout", 30))))

# ถ้า BASE_URL ว่าง = รันแบบ in-process ASGI (ไม่ต้องเปิด server)
USE_ASGI = not bool(BASE_URL)

API_BASE = f"{BASE_URL}{API_PREFIX}" if BASE_URL else API_PREFIX
