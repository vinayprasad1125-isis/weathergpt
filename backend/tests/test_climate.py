import pytest
from app.services.climate_analytics_service import ClimateAnalyticsService
from app.schemas.climate import ClimateAnalyzeRequest, ClimateLocation, TimeRange
from app.db.models import DBLocation, HistoricalWeather
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.db.database import Base
from datetime import datetime

@pytest.mark.asyncio
async def test_climate_average_temperature():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        
    AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with AsyncSessionLocal() as db:
        loc = DBLocation(name="Test City", latitude=10.0, longitude=20.0)
        db.add(loc)
        await db.commit()
        await db.refresh(loc)
        
        # Inject mock rows
        db.add_all([
            HistoricalWeather(location_id=loc.id, timestamp=datetime(2020, 1, 1), temperature=30.0, rainfall=0.0, wind_speed=0.0, source="test"),
            HistoricalWeather(location_id=loc.id, timestamp=datetime(2020, 1, 2), temperature=40.0, rainfall=0.0, wind_speed=0.0, source="test")
        ])
        await db.commit()
        
        service = ClimateAnalyticsService()
        req = ClimateAnalyzeRequest(
            location=ClimateLocation(latitude=10.0, longitude=20.0, name="Test City"),
            time_range=TimeRange(start="2020-01-01", end="2020-01-31"),
            parameter="temperature",
            analysis="average"
        )
        
        res = await service.analyze(req, db)
        assert res.parameter == "temperature"
        assert res.analysis == "average"
        assert res.result["value"] == 35.0  # (30+40)/2
