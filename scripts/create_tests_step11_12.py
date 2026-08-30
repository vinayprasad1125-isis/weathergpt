import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

tests = {
    'tests/test_language.py': '''from app.services.language_detection_service import LanguageDetectionService

def test_language_detection_english():
    detector = LanguageDetectionService()
    res = detector.detect_language("What is the weather in Chennai tomorrow?")
    assert res["language"] == "en"

def test_language_detection_tamil():
    detector = LanguageDetectionService()
    res = detector.detect_language("நாளைக்கு சென்னையில் மழை பெய்யுமா?")
    assert res["language"] == "ta"

def test_language_detection_hindi():
    detector = LanguageDetectionService()
    res = detector.detect_language("क्या कल चेन्नई में बारिश होगी?")
    assert res["language"] == "hi"
''',

    'tests/test_climate.py': '''import pytest
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
'''
}

for filepath, content in tests.items():
    full_path = os.path.join(base_dir, filepath)
    with open(full_path, 'w') as f:
        f.write(content)

print("Tests created.")
