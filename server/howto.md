# แนวทางการเริ่มต้นพัฒนา Backend Server (How to Start)
## โครงงาน: แอปตรวจสอบรูปภาพตัดต่อที่ถูกนำมาหลอกลวง (Scam Image Detection)

เอกสารฉบับนี้เป็นคู่มือปฏิบัติการสำหรับทีมพัฒนา อธิบายขั้นตอนการเริ่มต้นสร้าง Backend Server จากศูนย์ โดยอ้างอิงจากเอกสารออกแบบที่จัดทำไว้แล้ว

### เอกสารออกแบบที่ต้องอ่านก่อนเริ่ม
- [design/server.md](../design/server.md) - สถาปัตยกรรม Backend, Database Schema, API Specs
- [design/architecture.md](../design/architecture.md) - สถาปัตยกรรมระบบรวม, Risk Scoring Pipeline
- [design/model.md](../design/model.md) - AI Model Design (SegFormer)
- [design/training.md](../design/training.md) - Training Workflow, ONNX Export
- [doc/server/server.md](../doc/server/server.md) - เอกสารสรุปภาพรวม Server

---

## สารบัญ

1. [โครงสร้างโฟลเดอร์ที่ต้องสร้าง](#1-โครงสร้างโฟลเดอร์ที่ต้องสร้าง)
2. [ลำดับขั้นตอนการพัฒนา (Roadmap)](#2-ลำดับขั้นตอนการพัฒนา-roadmap)
3. [Phase 1 - Foundation: ฐานรากของ Server](#3-phase-1---foundation-ฐานรากของ-server)
4. [Phase 2 - Auth: ระบบยืนยันตัวตน](#4-phase-2---auth-ระบบยืนยันตัวตน)
5. [Phase 3 - Scan: ท่อประมวลผลภาพ](#5-phase-3---scan-ท่อประมวลผลภาพ)
6. [Phase 4 - AI Inference: เชื่อมต่อโมเดล](#6-phase-4---ai-inference-เชื่อมต่อโมเดล)
7. [Phase 5 - Report & Admin](#7-phase-5---report--admin)
8. [Phase 6 - Cache, Storage & Polish](#8-phase-6---cache-storage--polish)
9. [Dependencies ทั้งหมด](#9-dependencies-ทั้งหมด)
10. [API Endpoints สรุปรวม](#10-api-endpoints-สรุปรวม)
11. [Database Schema สรุปรวม](#11-database-schema-สรุปรวม)
12. [Environment Variables](#12-environment-variables)
13. [คำสั่งเริ่มต้นใช้งาน](#13-คำสั่งเริ่มต้นใช้งาน)

---

## 1. โครงสร้างโฟลเดอร์ที่ต้องสร้าง

อ้างอิงจาก `design/server.md` Section 2.1:

```
server/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI Initialization + Lifespan
│   │
│   ├── core/                   # การตั้งค่าหลัก, ระบบความปลอดภัย, DB Connection
│   │   ├── __init__.py
│   │   ├── config.py           # Pydantic Settings - อ่านค่าจาก .env
│   │   ├── security.py         # Password Hashing (bcrypt) + JWT Token
│   │   └── database.py         # SQLAlchemy AsyncEngine + AsyncSession
│   │
│   ├── models/                 # SQLAlchemy ORM Models (ตาราง DB)
│   │   ├── __init__.py
│   │   ├── user.py             # users table
│   │   ├── scan.py             # scans table
│   │   ├── consent.py          # consent_logs table
│   │   └── report.py           # scam_reports table
│   │
│   ├── schemas/                # Pydantic Schemas (Request/Response Validation)
│   │   ├── __init__.py
│   │   ├── auth.py             # RegisterRequest, LoginRequest, TokenResponse
│   │   ├── scan.py             # ScanResponse, RiskSummary, LayerDetail
│   │   └── report.py           # ReportCreateRequest, ReportResponse
│   │
│   ├── repositories/           # Data Access Layer (Queries)
│   │   ├── __init__.py
│   │   ├── user_repo.py        # CRUD operations สำหรับ users
│   │   └── scan_repo.py        # CRUD operations สำหรับ scans + reports
│   │
│   ├── services/               # Business Logic Layer
│   │   ├── __init__.py
│   │   ├── auth_service.py     # Register, Login, Token Verification
│   │   ├── scan_service.py     # Multi-layer Analysis Orchestrator
│   │   ├── ocr_service.py      # Surya-OCR + Scam Keywords Detection
│   │   ├── exif_service.py     # EXIF Metadata Extraction
│   │   ├── inference_service.py # เชื่อมต่อ AI Inference (ONNX Runtime)
│   │   └── storage_service.py  # Cloud Storage Upload/Download + Presigned URL
│   │
│   ├── api/                    # Routing Layer (Controllers)
│   │   ├── __init__.py
│   │   ├── router.py           # รวม Router ทั้งหมดไว้ที่นี่
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── auth.py         # POST /register, POST /login
│   │       ├── scan.py         # POST /scan, GET /scan/{id}
│   │       ├── report.py       # POST /report
│   │       └── admin.py        # POST /admin/train, POST /admin/model
│   │
│   └── utils/                  # Utility Functions
│       ├── __init__.py
│       ├── hashing.py          # SHA-256 Image Hash
│       └── risk_calculator.py  # Weighted Risk Score Calculator
│
├── migrations/                 # Alembic Database Migrations
│   ├── env.py
│   ├── alembic.ini
│   └── versions/               # Migration Scripts ที่ auto-generate
│
├── tests/                      # Unit Tests + Integration Tests
│   ├── __init__.py
│   ├── test_auth.py
│   ├── test_scan.py
│   └── conftest.py             # Fixtures (TestClient, TestDB)
│
├── .env                        # Environment Variables (ห้าม commit)
├── .env.example                # ตัวอย่าง .env สำหรับทีมงาน
├── .gitignore
├── requirements.txt            # Python Dependencies
├── Dockerfile                  # Docker Image สำหรับ Deploy
├── docker-compose.yml          # Docker Compose (API + PostgreSQL + Redis)
└── howto.md                    # เอกสารนี้
```

---

## 2. ลำดับขั้นตอนการพัฒนา (Roadmap)

แบ่งการพัฒนาออกเป็น 6 Phase ตามลำดับ ควรทำให้เสร็จทีละ Phase:

| Phase | ชื่อ | เป้าหมาย | ระยะเวลาประมาณ |
|:---:|---|---|:---:|
| 1 | Foundation | สร้างโครงสร้าง, ตั้งค่า DB, รัน Server ได้ | 1-2 วัน |
| 2 | Auth | ระบบ Register / Login / JWT | 2-3 วัน |
| 3 | Scan | รับรูปภาพ, EXIF, OCR, Risk Score (Mock AI) | 3-4 วัน |
| 4 | AI Inference | เชื่อม ONNX Model จริง, สร้าง Heatmap | 3-5 วัน |
| 5 | Report & Admin | ระบบรายงานสแกม, Admin Endpoints | 2-3 วัน |
| 6 | Cache, Storage & Polish | Redis Cache, Cloud Storage, Rate Limit, Tests | 3-4 วัน |

---

## 3. Phase 1 - Foundation: ฐานรากของ Server

### 3.1 สร้างโครงสร้างโฟลเดอร์

```bash
cd /home/panuwat/project/server
mkdir -p app/{core,models,schemas,repositories,services,api/v1,utils}
mkdir -p migrations/versions tests

touch app/__init__.py app/main.py
touch app/core/{__init__,config,security,database}.py
touch app/models/{__init__,user,scan,consent,report}.py
touch app/schemas/{__init__,auth,scan,report}.py
touch app/repositories/{__init__,user_repo,scan_repo}.py
touch app/services/{__init__,auth_service,scan_service,ocr_service,exif_service,inference_service,storage_service}.py
touch app/api/{__init__,router}.py
touch app/api/v1/{__init__,auth,scan,report,admin}.py
touch app/utils/{__init__,hashing,risk_calculator}.py
touch tests/{__init__,conftest,test_auth,test_scan}.py
```

### 3.2 สร้างไฟล์ `app/core/config.py`

ใช้ `pydantic-settings` อ่านค่า Environment Variables:

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # App
    APP_NAME: str = "ScamGuard API"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = True

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://scamguard:password@localhost:5432/scamguard_db"

    # JWT
    JWT_SECRET_KEY: str = "change-this-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Storage
    STORAGE_BACKEND: str = "local"  # "local" สำหรับ dev, "gcs" สำหรับ production
    LOCAL_UPLOAD_DIR: str = "./uploads"

    # AI Inference
    ONNX_MODEL_PATH: str = "../model/segformer/work_dirs/latest.onnx"

    # Rate Limit
    RATE_LIMIT_PER_HOUR: int = 60

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
```

### 3.3 สร้างไฟล์ `app/core/database.py`

ใช้ SQLAlchemy AsyncEngine:

```python
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

engine = create_async_engine(settings.DATABASE_URL, echo=settings.DEBUG)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

class Base(DeclarativeBase):
    pass

async def get_db() -> AsyncSession:
    async with async_session() as session:
        yield session
```

### 3.4 สร้างไฟล์ `app/main.py`

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.core.config import settings
from app.api.router import api_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: สร้างตาราง DB, โหลด Model, etc.
    print(f"[Startup] {settings.APP_NAME} v{settings.APP_VERSION}")
    yield
    # Shutdown: ปิด connections
    print("[Shutdown] Cleaning up...")

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan,
)

app.include_router(api_router, prefix="/api/v1")

@app.get("/health")
async def health_check():
    return {"status": "ok", "version": settings.APP_VERSION}
```

### 3.5 สร้างไฟล์ `app/api/router.py`

```python
from fastapi import APIRouter
from app.api.v1 import auth, scan, report, admin

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(scan.router, prefix="/scan", tags=["Scan & Analysis"])
api_router.include_router(report.router, prefix="/report", tags=["Scam Reports"])
api_router.include_router(admin.router, prefix="/admin", tags=["Admin"])
```

### 3.6 ทดสอบรัน

```bash
# ติดตั้ง dependencies เบื้องต้น
pip install fastapi uvicorn pydantic-settings

# รัน server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

เปิด http://localhost:8000/docs จะเห็น Swagger UI อัตโนมัติ
เปิด http://localhost:8000/health จะได้ `{"status": "ok"}`

---

## 4. Phase 2 - Auth: ระบบยืนยันตัวตน

### 4.1 ORM Model - `app/models/user.py`

อ้างอิงจาก `design/server.md` Section 4.1:

```python
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100))
    role = Column(String(20), nullable=False, default="user")  # user, researcher, admin
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
```

### 4.2 Security - `app/core/security.py`

```python
from datetime import datetime, timedelta, timezone
from passlib.context import CryptContext
from jose import jwt, JWTError
from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)

def decode_access_token(token: str) -> dict | None:
    try:
        return jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
    except JWTError:
        return None
```

### 4.3 Pydantic Schemas - `app/schemas/auth.py`

อ้างอิง Request/Response จาก `design/server.md` Section 5.1:

```python
from pydantic import BaseModel, EmailStr

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    system_consent: bool = True
    research_consent: bool = False

class LoginRequest(BaseModel):
    username: str  # email
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict

class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    role: str
    message: str = "User registered successfully"
```

### 4.4 API Route - `app/api/v1/auth.py`

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse, UserResponse
# ... import service functions

router = APIRouter()

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    # 1. ตรวจสอบว่า email ซ้ำหรือไม่
    # 2. สร้าง User ใหม่ + hash password
    # 3. บันทึก consent_logs
    # 4. return UserResponse
    ...

@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    # 1. ค้นหา user จาก email
    # 2. ตรวจสอบ password
    # 3. สร้าง JWT Token
    # 4. return TokenResponse
    ...
```

---

## 5. Phase 3 - Scan: ท่อประมวลผลภาพ

### 5.1 ORM Model - `app/models/scan.py`

อ้างอิงจาก `design/server.md` Section 4.2:

```python
from sqlalchemy import Column, String, Integer, Float, Text, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
import uuid
from app.core.database import Base

class Scan(Base):
    __tablename__ = "scans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    image_hash = Column(String(64), nullable=False, index=True)  # SHA-256
    raw_image_url = Column(String(512), nullable=False)
    heatmap_image_url = Column(String(512))

    # Risk Scores (0-100)
    text_score = Column(Integer, nullable=False, default=0)
    visual_score = Column(Integer, nullable=False, default=0)
    source_score = Column(Integer, nullable=False, default=0)
    total_risk_score = Column(Integer, nullable=False, default=0)

    # Analysis Details
    exif_data = Column(JSONB)
    ocr_text = Column(Text)
    scam_keywords_found = Column(JSONB)
    reverse_search_results = Column(JSONB)
    ai_gen_probability = Column(Float, default=0.0)

    status = Column(String(20), nullable=False, default="pending")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True))
```

### 5.2 Risk Calculator - `app/utils/risk_calculator.py`

อ้างอิงจาก `design/architecture.md` Section 5.1:

```python
def calculate_risk_score(text_score: int, visual_score: int, source_score: int) -> dict:
    """
    สูตร: Risk Score = (S_text * 0.25) + (S_visual * 0.45) + (S_source * 0.30)

    Risk Grades:
      0-39  = low    (สีเขียว)
      40-69 = medium (สีเหลือง)
      70-100 = high  (สีแดง)
    """
    total = round((text_score * 0.25) + (visual_score * 0.45) + (source_score * 0.30))
    total = max(0, min(100, total))

    if total >= 70:
        grade = "high"
    elif total >= 40:
        grade = "medium"
    else:
        grade = "low"

    return {
        "total_risk_score": total,
        "grade": grade,
    }
```

### 5.3 Scan Service - `app/services/scan_service.py`

ขั้นตอนการทำงานหลัก (อ้างอิงจาก `design/architecture.md` Section 5, Multi-layer Pipeline):

```python
async def analyze_image(file_bytes: bytes, user_id: int, db) -> dict:
    """
    Multi-layer Analysis Pipeline:
    1. Validate file type + size (max 10MB, JPG/PNG only)
    2. คำนวณ SHA-256 Hash
    3. ตรวจ Redis Cache (Cache Hit -> return ผลเดิม)
    4. Task 1: EXIF Metadata Extraction
    5. Task 2: OCR + Scam Keywords Analysis
    6. Task 3: Visual Forgery Detection (ส่งไป AI Inference)
    7. Task 4: Reverse Image Search (optional)
    8. Task 5: AI-Generated Image Detection
    9. รวม Weighted Risk Score
    10. บันทึกลง PostgreSQL + เขียน Redis Cache
    11. return ผลลัพธ์ JSON
    """
    pass
```

### 5.4 API Route - `app/api/v1/scan.py`

อ้างอิง Request/Response จาก `design/server.md` Section 5.2:

```python
from fastapi import APIRouter, UploadFile, File, Depends

router = APIRouter()

@router.post("/")
async def create_scan(file: UploadFile = File(...), ...):
    """
    POST /api/v1/scan
    Request: Multipart/Form-Data (file: binary JPG/PNG)
    Response: JSON ตาม design/server.md Section 5.2.1
    """
    # 1. Validate file type + size
    # 2. อ่าน bytes
    # 3. เรียก scan_service.analyze_image()
    # 4. return ScanResponse
    ...

@router.get("/{scan_id}")
async def get_scan(scan_id: str, ...):
    """
    GET /api/v1/scan/{id}
    Response: JSON เดียวกับ POST /scan
    """
    ...
```

---

## 6. Phase 4 - AI Inference: เชื่อมต่อโมเดล

### 6.1 ONNX Runtime Service - `app/services/inference_service.py`

เชื่อมต่อกับโมเดล SegFormer ที่ Export เป็น ONNX แล้ว (อ้างอิง `design/model.md` + `design/training.md` Section 13):

```python
import onnxruntime as ort
import numpy as np
from PIL import Image

class InferenceService:
    def __init__(self, model_path: str):
        self.session = ort.InferenceSession(model_path)

    def predict(self, image_bytes: bytes) -> dict:
        """
        Input:  ภาพ RGB -> Tensor [1, 3, 512, 512]
        Output: Probability Map (Heatmap) + Segmentation Mask + Risk Score
        """
        # 1. Decode image from bytes
        # 2. Resize to 512x512
        # 3. Normalize (mean, std)
        # 4. Run forward pass
        # 5. Post-process: Mask, Heatmap, Score
        ...

    def generate_heatmap(self, prob_map: np.ndarray, original_image) -> bytes:
        """
        แปลง Probability Map เป็นภาพ Heatmap (สีแดง=เสี่ยง, สีน้ำเงิน=ปลอดภัย)
        ซ้อนทับ (Overlay) กับภาพต้นฉบับ
        """
        ...
```

### 6.2 การเตรียมไฟล์ ONNX

ก่อนใช้งานจริง ต้อง Export โมเดลจาก PyTorch Checkpoint:

```bash
# ใน environment ที่มี mmsegmentation
cd /home/panuwat/project/model/segformer

# Export checkpoint เป็น ONNX (ดูเพิ่มเติมใน model/segformer/README.md)
python -m mmseg.tools.pytorch2onnx \
    configs/segformer_mit-b2-v1.py \
    work_dirs/latest.pth \
    --output-file work_dirs/latest.onnx \
    --input-img data/test_sample.jpg \
    --shape 512 512
```

---

## 7. Phase 5 - Report & Admin

### 7.1 ORM Models

**consent_logs** (อ้างอิง `design/server.md` Section 4.3):

```python
class ConsentLog(Base):
    __tablename__ = "consent_logs"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    system_consent = Column(Boolean, nullable=False, default=True)
    research_consent = Column(Boolean, nullable=False, default=False)
    ip_address = Column(String(45))
    user_agent = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
```

**scam_reports** (อ้างอิง `design/server.md` Section 4.4):

```python
class ScamReport(Base):
    __tablename__ = "scam_reports"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    scan_id = Column(UUID(as_uuid=True), ForeignKey("scans.id", ondelete="SET NULL"))
    reason = Column(Text, nullable=False)
    status = Column(String(20), nullable=False, default="pending")  # pending, approved, rejected
    moderated_by = Column(Integer, ForeignKey("users.id"))
    moderated_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
```

### 7.2 API Routes

```python
# app/api/v1/report.py
@router.post("/")
async def create_report(body: ReportCreateRequest, ...):
    """POST /api/v1/report - ผู้ใช้รายงานภาพหลอกลวง"""
    ...

# app/api/v1/admin.py
@router.post("/train")
async def trigger_training(...):
    """POST /api/v1/admin/train - Admin สั่ง Incremental Training"""
    ...

@router.post("/model")
async def update_model(...):
    """POST /api/v1/admin/model - Admin อัปโหลด ONNX Model ใหม่ (Hot Reload)"""
    ...
```

---

## 8. Phase 6 - Cache, Storage & Polish

### 8.1 Redis Cache (อ้างอิง `design/server.md` Section 2.2.5)

```python
import redis.asyncio as redis

# Key pattern: scan:hash:{image_sha256}
# TTL: 7 วัน (604800 วินาที)

async def check_cache(image_hash: str) -> dict | None:
    cached = await redis_client.get(f"scan:hash:{image_hash}")
    if cached:
        return json.loads(cached)  # Cache Hit
    return None  # Cache Miss

async def set_cache(image_hash: str, result: dict):
    await redis_client.setex(
        f"scan:hash:{image_hash}",
        604800,  # 7 days
        json.dumps(result)
    )
```

### 8.2 Cloud Storage (Presigned URLs)

อ้างอิง `design/server.md` Section 2.2.2:

```
โครงสร้างไฟล์บน Storage:
  raw-images/{user_id}/{scan_id}.jpg        <- ภาพต้นฉบับ
  heatmap-images/{user_id}/{scan_id}_heatmap.jpg  <- ภาพ Heatmap

Presigned URL มีอายุ 15 นาที (เพื่อ PDPA Compliance)
```

สำหรับ Development ให้ใช้ Local File Storage ก่อน แล้วเปลี่ยนเป็น Cloud (GCS/S3) ตอน Deploy

### 8.3 Rate Limiting (อ้างอิง `design/server.md` Section 6)

- ผู้ใช้ทั่วไป: สแกนได้สูงสุด **60 ครั้ง/ชั่วโมง**
- ใช้ `slowapi` หรือ custom middleware + Redis counter

### 8.4 Input Validation (อ้างอิง `design/server.md` Section 6)

- Allowed file types: `image/jpeg`, `image/png`
- Max file size: **10MB**
- ถ้าไม่ผ่าน -> return HTTP 400 Bad Request

### 8.5 Graceful Degradation

หาก AI Inference หรือ Google Vision API Timeout ให้คำนวณ Risk Score จากข้อมูลที่มี (EXIF + OCR) และบันทึก Error Log

---

## 9. Dependencies ทั้งหมด

### requirements.txt

```txt
# Web Framework
fastapi>=0.115.0
uvicorn[standard]>=0.30.0
pydantic[email]>=2.0
pydantic-settings>=2.0

# Database
sqlalchemy[asyncio]>=2.0
asyncpg>=0.30.0
alembic>=1.14.0

# Auth & Security
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4

# Redis
redis[hiredis]>=5.0

# Image Processing
Pillow>=10.0
python-multipart>=0.0.9

# AI Inference
onnxruntime>=1.18.0
numpy>=1.26,<2

# OCR (ติดตั้งแยก - ใช้ทรัพยากรสูง)
# surya-ocr

# EXIF
piexif>=1.1.3

# Rate Limiting
slowapi>=0.1.9

# Testing
pytest>=8.0
pytest-asyncio>=0.23
httpx>=0.27
```

### การติดตั้ง

```bash
cd /home/panuwat/project/server

# สร้าง Virtual Environment
python -m venv venv
source venv/bin/activate

# ติดตั้ง dependencies
pip install -r requirements.txt
```

---

## 10. API Endpoints สรุปรวม

อ้างอิงจาก `design/server.md` Section 5 และ `doc/server/server.md` Section 5:

| Method | Endpoint | หน้าที่ | Auth |
|:---:|---|---|:---:|
| GET | `/health` | Health Check | - |
| POST | `/api/v1/auth/register` | สมัครสมาชิก | - |
| POST | `/api/v1/auth/login` | เข้าสู่ระบบ รับ JWT Token | - |
| POST | `/api/v1/scan` | อัปโหลดรูปภาพเพื่อตรวจวิเคราะห์ | User |
| GET | `/api/v1/scan/{id}` | ดูผลลัพธ์การสแกนย้อนหลัง | User |
| POST | `/api/v1/report` | รายงานภาพหลอกลวง | User |
| POST | `/api/v1/admin/train` | สั่ง Incremental Training | Admin |
| POST | `/api/v1/admin/model` | อัปโหลดโมเดล ONNX ใหม่ | Admin |

---

## 11. Database Schema สรุปรวม

อ้างอิงจาก `design/server.md` Section 4:

| ตาราง | หน้าที่ | คอลัมน์สำคัญ |
|---|---|---|
| `users` | บัญชีผู้ใช้ | id, email, hashed_password, role, is_active |
| `scans` | ประวัติการสแกน | id(UUID), user_id, image_hash, scores, exif_data, ocr_text, status |
| `consent_logs` | การยินยอม PDPA | user_id, system_consent, research_consent |
| `scam_reports` | รายงานภาพหลอกลวง | user_id, scan_id, reason, status, moderated_by |

---

## 12. Environment Variables

สร้างไฟล์ `.env` (ห้าม commit ขึ้น git):

```env
# App
APP_NAME=ScamGuard API
APP_VERSION=0.1.0
DEBUG=true

# Database (PostgreSQL)
DATABASE_URL=postgresql+asyncpg://scamguard:password@localhost:5432/scamguard_db

# JWT
JWT_SECRET_KEY=your-super-secret-key-change-in-production
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=60

# Redis
REDIS_URL=redis://localhost:6379/0

# Storage
STORAGE_BACKEND=local
LOCAL_UPLOAD_DIR=./uploads

# AI Model
ONNX_MODEL_PATH=../model/segformer/work_dirs/latest.onnx

# Rate Limit
RATE_LIMIT_PER_HOUR=60
```

---

## 13. คำสั่งเริ่มต้นใช้งาน

### ด้วย Docker Compose (แนะนำ)

```bash
# สร้าง docker-compose.yml ที่มี PostgreSQL + Redis + API
docker compose up -d

# ดู logs
docker compose logs -f api
```

### ด้วย Manual (สำหรับ Dev)

```bash
# 1. ติดตั้ง PostgreSQL + Redis ในเครื่อง (หรือใช้ Docker แค่ DB)
docker run -d --name scamguard-db \
  -e POSTGRES_USER=scamguard \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=scamguard_db \
  -p 5432:5432 postgres:16

docker run -d --name scamguard-redis \
  -p 6379:6379 redis:7-alpine

# 2. Activate venv + install
cd /home/panuwat/project/server
source venv/bin/activate
pip install -r requirements.txt

# 3. Run DB migrations
alembic upgrade head

# 4. Start server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 5. เปิด Swagger UI
# -> http://localhost:8000/docs
```

---

## สิ่งที่ควรทำถัดไปหลังจากอ่านเอกสารนี้

1. ตัดสินใจว่าจะเริ่ม Phase 1 ด้วยตนเอง หรือจะให้ Agent ช่วยสร้างโค้ด Foundation ให้
2. เตรียม PostgreSQL + Redis (ใช้ Docker ง่ายที่สุด)
3. ตรวจสอบว่ามีไฟล์ ONNX พร้อมใช้งานหรือยัง (หากยังไม่มี ให้ Mock AI ไปก่อนใน Phase 3 แล้วค่อยเชื่อม ONNX จริงใน Phase 4)
