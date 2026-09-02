import asyncio
from app.core.database import async_session_maker
from app.services.scan_service import analyze_image
from fastapi import UploadFile
import io
import os

async def main():
    # Make sure uploads dir exists
    os.makedirs("/home/panuwat/project/server/uploads/heatmaps", exist_ok=True)

    async with async_session_maker() as db:
        content = b"fake image content for testing duplicate"
        file1 = UploadFile(filename="test.png", file=io.BytesIO(content))
        try:
            print("First upload...")
            scan1 = await analyze_image(file1, 1, db, "Title 1")
            print("Scan 1 ID:", scan1.id)
            
            # Need a new UploadFile object since the first one is consumed
            file2 = UploadFile(filename="test.png", file=io.BytesIO(content))
            print("Second upload...")
            scan2 = await analyze_image(file2, 1, db, "Title 2")
            print("Scan 2 ID:", scan2.id)
        except Exception as e:
            print(f"Exception caught: {type(e).__name__} - {e}")

if __name__ == "__main__":
    asyncio.run(main())
