import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
from app.db.models import HistoricalWeather

async def main():
    engine = create_async_engine("sqlite+aiosqlite:///historical.db")
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        records = (await db.execute(select(HistoricalWeather).order_by(HistoricalWeather.timestamp))).scalars().all()
        if not records:
            print("No records")
            return
            
        vals = [r.temperature for r in records]
        min_ts = records[0].timestamp
        x = [(r.timestamp - min_ts).days for r in records]
        n = len(vals)
        
        mean_x = sum(x) / n
        mean_y = sum(vals) / n
        numerator = sum((xi - mean_x) * (yi - mean_y) for xi, yi in zip(x, vals))
        denominator = sum((xi - mean_x)**2 for xi in x)
        slope = (numerator / denominator) * 365.25 if denominator != 0 else 0
        
        print(f"Count: {n}")
        print(f"Slope (degrees/year): {slope}")
        print(f"First date: {records[0].timestamp}")
        print(f"Last date: {records[-1].timestamp}")

asyncio.run(main())
