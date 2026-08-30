import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

normalizer_py = """from app.db.models import WeatherObservation
import logging

logger = logging.getLogger(__name__)

class DataNormalizer:
    @staticmethod
    def normalize_weather_observation(provider_name: str, raw_data: dict, location_id: int) -> dict:
        \"\"\"
        Normalize provider specific raw data into the WeatherObservation dictionary format.
        \"\"\"
        normalized = {
            "location_id": location_id,
            "source": provider_name,
            "temperature": None,
            "humidity": None,
            "wind_speed": None,
            "pressure": None
        }
        
        if provider_name == "HTTP_REST_PROVIDER":
            # Assuming raw_data comes from Open-Meteo
            current = raw_data.get("current_weather", {})
            normalized["temperature"] = current.get("temperature")
            normalized["wind_speed"] = current.get("windspeed")
            # Open meteo has time in current_weather
            
        elif provider_name == "MQTT_BROKER_PROVIDER":
            # Mock MQTT payload normalization
            # Let's say raw_data is {"topic": "weather", "payload": {"temp": 25, "hum": 60}}
            if isinstance(raw_data.get("payload"), dict):
                payload = raw_data["payload"]
                normalized["temperature"] = payload.get("temp")
                normalized["humidity"] = payload.get("hum")
                
        elif provider_name == "WIS2_GLOBAL_PROVIDER":
            # Mock WIS2 normalization
            pass
            
        logger.info(f"Normalized data from {provider_name}")
        return normalized
"""

test_py = """import pytest
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.db.database import Base
from app.db.models import DBLocation, WeatherObservation
from app.db.repositories import LocationRepository, WeatherObservationRepository
from app.services.ingestion.base import DataIngestionService
from app.services.ingestion.mqtt_provider import MQTTProvider
from app.services.ingestion.wis2_provider import WIS2Provider
from app.services.ingestion.normalizer import DataNormalizer

# Use an in-memory SQLite for testing
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

@pytest.fixture
async def async_session():
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with AsyncSessionLocal() as session:
        yield session

@pytest.mark.asyncio
async def test_db_models(async_session: AsyncSession):
    # Test Location
    loc_repo = LocationRepository(async_session)
    loc = await loc_repo.create({
        "name": "New Delhi",
        "latitude": 28.6139,
        "longitude": 77.2090
    })
    assert loc.id is not None
    assert loc.name == "New Delhi"
    
    # Test WeatherObservation
    obs_repo = WeatherObservationRepository(async_session)
    obs = await obs_repo.create({
        "location_id": loc.id,
        "temperature": 35.5,
        "humidity": 45.0,
        "source": "MOCK_PROVIDER"
    })
    
    assert obs.id is not None
    assert obs.temperature == 35.5
    
    # Test repository fetch
    latest = await obs_repo.get_latest_for_location(loc.id)
    assert latest.id == obs.id

@pytest.mark.asyncio
async def test_ingestion_service(async_session: AsyncSession):
    mqtt_provider = MQTTProvider()
    wis2_provider = WIS2Provider()
    
    ingestion_service = DataIngestionService(
        providers=[mqtt_provider, wis2_provider],
        session=async_session
    )
    
    # Test MQTT Mock Ingestion
    raw_mqtt_data = await ingestion_service.ingest_from_provider("MQTT_BROKER_PROVIDER", topic="test/topic")
    assert raw_mqtt_data["topic"] == "test/topic"
    
    # Test Normalizer
    norm_data = DataNormalizer.normalize_weather_observation(
        provider_name="MQTT_BROKER_PROVIDER", 
        raw_data={"topic": "test", "payload": {"temp": 28.0, "hum": 70}}, 
        location_id=1
    )
    assert norm_data["temperature"] == 28.0
    assert norm_data["humidity"] == 70
    assert norm_data["source"] == "MQTT_BROKER_PROVIDER"

"""

def update_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)
    print(f"Updated {path}")

if __name__ == '__main__':
    update_file(os.path.join(base_dir, 'app/services/ingestion/normalizer.py'), normalizer_py)
    update_file(os.path.join(base_dir, 'tests/test_ingestion_and_db.py'), test_py)
    print("Test and Normalizer files created successfully!")
