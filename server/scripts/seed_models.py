import asyncio
import os
import re
import glob
from datetime import datetime
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
from app.models.model_version import ModelVersion
from app.core.config import settings, TH_TIMEZONE, PROJECT_ROOT

WORK_DIRS = str(PROJECT_ROOT / "model/segformer/work_dirs")

async def seed():
    engine = create_async_engine(settings.DATABASE_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    print(f"Scanning {WORK_DIRS} for models...")
    
    if not os.path.exists(WORK_DIRS):
        print("Work dirs not found.")
        return

    models_to_upsert = []
    
    for item in os.listdir(WORK_DIRS):
        dir_path = os.path.join(WORK_DIRS, item)
        # Match v1.0.0, v1.0.1, etc. Ignore segformer_v...
        if os.path.isdir(dir_path) and re.match(r'^v\d+\.\d+\.\d+$', item):
            print(f"Found version dir: {item}")
            
            # Find log file. It is inside a timestamp directory usually, or root of this dir.
            log_files = glob.glob(os.path.join(dir_path, '**/*.log'), recursive=True)
            if not log_files:
                print(f"  No log file found for {item}")
                continue
                
            # Assume the most recently modified log is the main one
            latest_log = max(log_files, key=os.path.getmtime)
            
            a_acc, m_iou, m_acc, m_dice = None, None, None, None
            
            # Parse log file for best checkpoint
            try:
                with open(latest_log, 'r') as f:
                    lines = f.readlines()
                    
                best_checkpoint_line_idx = -1
                for i, line in enumerate(lines):
                    if "The best checkpoint" in line and "is saved to" in line:
                        best_checkpoint_line_idx = i
                        
                if best_checkpoint_line_idx != -1 and best_checkpoint_line_idx > 0:
                    # Look for the metric line just before it
                    for i in range(best_checkpoint_line_idx - 1, max(-1, best_checkpoint_line_idx - 10), -1):
                        prev_line = lines[i]
                        if "aAcc:" in prev_line and "mIoU:" in prev_line:
                            # Extract metrics
                            # Example: aAcc: 98.0200  mIoU: 72.4200  mAcc: 75.6900  mDice: 81.4000
                            match = re.search(r'aAcc:\s+([\d\.]+)\s+mIoU:\s+([\d\.]+)\s+mAcc:\s+([\d\.]+)\s+mDice:\s+([\d\.]+)', prev_line)
                            if match:
                                a_acc = float(match.group(1)) / 100.0
                                m_iou = float(match.group(2)) / 100.0
                                m_acc = float(match.group(3)) / 100.0
                                m_dice = float(match.group(4)) / 100.0
                                break
            except Exception as e:
                print(f"  Error parsing log {latest_log}: {e}")
                
            # Find ONNX file
            onnx_files = glob.glob(os.path.join(dir_path, '*.onnx'))
            onnx_path = onnx_files[0] if onnx_files else f"/models/{item}.onnx"
            
            print(f"  Metrics: aAcc={a_acc}, mIoU={m_iou}, mAcc={m_acc}, mDice={m_dice}")
            
            models_to_upsert.append({
                "version_tag": item,
                "file_path": onnx_path,
                "framework_compatibility": "onnx",
                "a_acc": a_acc,
                "m_iou": m_iou,
                "m_acc": m_acc,
                "m_dice": m_dice,
                "status": "active" if item == "v1.0.0" else "inactive",
                "is_active": True if item == "v1.0.0" else False,
            })
            
    async with async_session() as db:
        now = datetime.now(TH_TIMEZONE)
        count = 0
        
        for m_data in models_to_upsert:
            # Check if exists
            result = await db.execute(select(ModelVersion).where(ModelVersion.version_tag == m_data['version_tag']))
            existing_model = result.scalars().first()
            
            if existing_model:
                existing_model.a_acc = m_data['a_acc'] or existing_model.a_acc
                existing_model.m_iou = m_data['m_iou'] or existing_model.m_iou
                existing_model.m_acc = m_data['m_acc'] or existing_model.m_acc
                existing_model.m_dice = m_data['m_dice'] or existing_model.m_dice
                existing_model.file_path = m_data['file_path']
                print(f"Updated existing model: {m_data['version_tag']}")
            else:
                new_model = ModelVersion(
                    version_tag=m_data['version_tag'],
                    file_path=m_data['file_path'],
                    framework_compatibility=m_data['framework_compatibility'],
                    a_acc=m_data['a_acc'],
                    m_iou=m_data['m_iou'],
                    m_acc=m_data['m_acc'],
                    m_dice=m_data['m_dice'],
                    status=m_data['status'],
                    is_active=m_data['is_active'],
                    deployed_at=now if m_data['is_active'] else None
                )
                db.add(new_model)
                print(f"Created new model: {m_data['version_tag']}")
            count += 1
            
        await db.commit()
        print(f"Successfully synced {count} model versions.")

if __name__ == "__main__":
    asyncio.run(seed())
