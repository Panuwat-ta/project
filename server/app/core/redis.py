import redis.asyncio as redis
from app.core.config import settings

# Global redis client instance
redis_client: redis.Redis | None = None

async def init_redis():
    global redis_client
    # decode_responses=True ensures we get string responses instead of bytes
    redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)

async def close_redis():
    global redis_client
    if redis_client:
        await redis_client.aclose()
        redis_client = None
