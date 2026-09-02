from sqlalchemy import create_engine
from app.core.config import settings
from sqlalchemy import text

engine = create_engine(settings.DATABASE_URL.replace("postgresql+asyncpg", "postgresql"))

with engine.connect() as conn:
    # Check if there is a unique constraint on image_hash in scans table
    result = conn.execute(text("""
        SELECT indexname, indexdef
        FROM pg_indexes
        WHERE tablename = 'scans' AND indexdef LIKE '%UNIQUE%';
    """))
    print("Unique indexes on scans:")
    for row in result:
        print(row)
