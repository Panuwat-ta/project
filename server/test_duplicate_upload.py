import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import SessionLocal
from app.services.scan_service import analyze_image
from fastapi import UploadFile
import io

async def run():
    async with SessionLocal() as db:
        # Create a mock file
        content = b"fake image data 12345"
        file = UploadFile(filename="test.png", file=io.BytesIO(content))
        
        try:
            scan1 = await analyze_image(file, 1, db, "Test 1")
            print("Scan 1 success, id:", scan1.id)
            
            # Reset file pointer
            await file.seek(0)
            
            scan2 = await analyze_image(file, 1, db, "Test 2")
            print("Scan 2 success, id:", scan2.id)
        except Exception as e:
            print("Error:", e)

if __name__ == "__main__":
    asyncio.run(run())
