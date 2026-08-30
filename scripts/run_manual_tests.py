import asyncio
import logging
import sys
import os

# Add backend to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../backend')))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.db.database import Base
from app.db.models import DBLocation, WeatherObservation
from app.db.repositories import LocationRepository, WeatherObservationRepository
from app.services.ingestion.base import DataIngestionService
from app.services.ingestion.mqtt_provider import MQTTProvider
from app.services.ingestion.wis2_provider import WIS2Provider
from app.services.ingestion.normalizer import DataNormalizer

logging.basicConfig(level=logging.INFO)

async def main():
    print("Starting tests...")
    TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        
    AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with AsyncSessionLocal() as session:
        # Test DB Models
        print("Testing DB Models...")
        loc_repo = LocationRepository(session)
        loc = await loc_repo.create({
            "name": "New Delhi",
            "latitude": 28.6139,
            "longitude": 77.2090
        })
        assert loc.id is not None
        
        obs_repo = WeatherObservationRepository(session)
        obs = await obs_repo.create({
            "location_id": loc.id,
            "temperature": 35.5,
            "humidity": 45.0,
            "source": "MOCK_PROVIDER"
        })
        assert obs.temperature == 35.5
        
        # Test Ingestion
        print("Testing Ingestion Service...")
        mqtt = MQTTProvider()
        wis2 = WIS2Provider()
        ingest = DataIngestionService([mqtt, wis2], session)
        
        res = await ingest.ingest_from_provider("MQTT_BROKER_PROVIDER", topic="weather")
        assert res["topic"] == "weather"
        
        # Test Normalizer
        print("Testing Normalizer...")
        norm = DataNormalizer.normalize_weather_observation("MQTT_BROKER_PROVIDER", {"topic": "t", "payload": {"temp": 28, "hum": 60}}, loc.id)
        assert norm["temperature"] == 28
        assert norm["humidity"] == 60
        
        print("All tests passed successfully!")

if __name__ == "__main__":
    asyncio.run(main())
