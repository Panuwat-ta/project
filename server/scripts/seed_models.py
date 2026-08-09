import asyncio
from datetime import datetime, timedelta
import uuid
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.models.model_version import ModelVersion
from app.core.config import settings, TH_TIMEZONE

async def seed():
    engine = create_async_engine(settings.DATABASE_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        now = datetime.now(TH_TIMEZONE)
        
        models = [
            ModelVersion(
                version_tag="v1.0.0-resnet50",
                file_path="/models/resnet50.onnx",
                framework_compatibility="onnx",
                a_acc=0.92,
                m_iou=0.85,
                m_acc=0.88,
                m_dice=0.90,
                status="active",
                is_active=True,
                deployed_at=now - timedelta(days=29)
            ),
            ModelVersion(
                version_tag="v1.1.0-effnet",
                file_path="/models/effnet.onnx",
                framework_compatibility="onnx",
                a_acc=0.94,
                m_iou=0.88,
                m_acc=0.90,
                m_dice=0.93,
                status="inactive",
                is_active=False,
                deployed_at=now - timedelta(days=14)
            ),
            ModelVersion(
                version_tag="v1.2.0-beta",
                file_path="/models/beta.onnx",
                framework_compatibility="onnx",
                a_acc=0.96,
                m_iou=0.91,
                m_acc=0.92,
                m_dice=0.95,
                status="pending",
                is_active=False,
                deployed_at=None
            )
        ]
        
        db.add_all(models)
        await db.commit()
        print(f"Seeded {len(models)} model versions successfully.")

asyncio.run(seed())
