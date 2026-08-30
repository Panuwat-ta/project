import asyncio
import asyncpg
async def main():
    try:
        conn = await asyncpg.connect('postgresql://scamguard:password@localhost:5432/scamguard_db')
        print("Success")
    except Exception as e:
        print("Failed localhost:", e)
        
    try:
        conn = await asyncpg.connect('postgresql://scamguard:password@127.0.0.1:5432/scamguard_db')
        print("Success 127.0.0.1")
    except Exception as e:
        print("Failed 127.0.0.1:", e)
asyncio.run(main())
