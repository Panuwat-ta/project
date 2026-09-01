import asyncio
from app.main import app
from httpx import AsyncClient

async def main():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.get("/health")
        print("Health Check Response:")
        print(response.json())

if __name__ == '__main__':
    asyncio.run(main())
