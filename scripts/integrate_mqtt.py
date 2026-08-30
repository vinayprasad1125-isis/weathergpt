import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

config_py_content = """from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    WEATHER_API_BASE_URL: str = "https://api.open-meteo.com/v1"
    GEOCODING_API_BASE_URL: str = "https://geocoding-api.open-meteo.com/v1"
    LLM_API_KEY: str = ""
    LLM_MODEL: str = "gemini-2.5-flash"
    
    # MQTT Config
    MQTT_BROKER_URL: str = "localhost"
    MQTT_BROKER_PORT: int = 1883
    MQTT_TOPIC: str = "weather/chennai"
    
    class Config:
        env_file = ".env"

settings = Settings()
"""

normalizer_py_content = """from app.db.models import WeatherObservation
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
            "pressure": None,
            "rainfall": None
        }
        
        if provider_name == "HTTP_REST_PROVIDER":
            current = raw_data.get("current_weather", {})
            normalized["temperature"] = current.get("temperature")
            normalized["wind_speed"] = current.get("windspeed")
            
        elif provider_name == "MQTT_BROKER_PROVIDER":
            if isinstance(raw_data.get("payload"), dict):
                payload = raw_data["payload"]
                normalized["temperature"] = payload.get("temperature")
                normalized["humidity"] = payload.get("humidity")
                normalized["rainfall"] = payload.get("rainfall")
                
        elif provider_name == "WIS2_GLOBAL_PROVIDER":
            pass
            
        logger.info(f"Normalized data from {provider_name}")
        return normalized
"""

background_ingestion_py_content = """import asyncio
import logging
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings
from app.db.database import AsyncSessionLocal
from app.db.repositories import LocationRepository, WeatherObservationRepository
from app.services.ingestion.mqtt_provider import MQTTProvider
from app.services.ingestion.base import DataIngestionService
from app.services.ingestion.normalizer import DataNormalizer

logger = logging.getLogger(__name__)

async def _process_mqtt_loop():
    mqtt_provider = MQTTProvider(broker_url=settings.MQTT_BROKER_URL, broker_port=settings.MQTT_BROKER_PORT)
    
    # We don't necessarily need the whole service if we are strictly fetching from one, but let's use the architecture.
    async with AsyncSessionLocal() as session:
        service = DataIngestionService([mqtt_provider], session)
        loc_repo = LocationRepository(session)
        obs_repo = WeatherObservationRepository(session)
        
        await mqtt_provider.connect()
        logger.info(f"Connected to MQTT. Listening on {settings.MQTT_TOPIC} indefinitely...")
        
        try:
            # We want to continuously fetch data.
            # The current DataIngestionService.ingest_from_provider does a one-shot connect/fetch/disconnect.
            # So we will bypass it slightly to run a continuous loop on the provider.
            while True:
                try:
                    # fetch_data does a wait_for(queue.get())
                    raw_data = await mqtt_provider.fetch_data(settings.MQTT_TOPIC)
                    topic = raw_data.get("topic", "")
                    
                    # Extract location from topic (e.g. weather/chennai -> chennai)
                    parts = topic.split('/')
                    loc_name = parts[-1].capitalize() if parts else "Unknown"
                    
                    # Get or create location
                    # For simplicity, we just create it if missing, but normally we'd query by name.
                    # Our LocationRepository doesn't have get_by_name yet, let's just add it dynamically or do a simple select.
                    from sqlalchemy.future import select
                    from app.db.models import DBLocation
                    
                    res = await session.execute(select(DBLocation).where(DBLocation.name == loc_name))
                    loc = res.scalars().first()
                    
                    if not loc:
                        loc = DBLocation(name=loc_name, latitude=0.0, longitude=0.0) # Dummy coords for auto-created
                        session.add(loc)
                        await session.commit()
                        await session.refresh(loc)
                        
                    # Normalize
                    normalized = DataNormalizer.normalize_weather_observation("MQTT_BROKER_PROVIDER", raw_data, loc.id)
                    
                    # Persist
                    await obs_repo.create(normalized)
                    logger.info(f"Persisted MQTT observation for {loc_name}")
                    
                except Exception as e:
                    logger.error(f"Error processing MQTT message: {e}")
                    await asyncio.sleep(1) # Prevent tight loop on error
                    
        finally:
            await mqtt_provider.disconnect()

def start_mqtt_ingestion():
    asyncio.create_task(_process_mqtt_loop())
"""

main_py_patch = """
from app.services.ingestion.background_ingestion import start_mqtt_ingestion

# We need to find @app.on_event("startup") and inject it.
"""

def patch_main_py():
    main_path = os.path.join(base_dir, 'app/main.py')
    with open(main_path, 'r') as f:
        content = f.read()
        
    if 'start_mqtt_ingestion' not in content:
        content = content.replace(
            'from app.db.database import engine, Base',
            'from app.db.database import engine, Base\\nfrom app.services.ingestion.background_ingestion import start_mqtt_ingestion'
        )
        content = content.replace(
            'await conn.run_sync(Base.metadata.create_all)',
            'await conn.run_sync(Base.metadata.create_all)\\n    start_mqtt_ingestion()'
        )
        with open(main_path, 'w') as f:
            f.write(content)
        print("Patched app/main.py")

weather_router_patch = """
from fastapi import Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.db.database import get_db
from app.db.models import DBLocation, WeatherObservation

@router.get("/mqtt/{location_name}")
async def get_mqtt_weather(location_name: str, db: AsyncSession = Depends(get_db)):
    # Find location
    res = await db.execute(select(DBLocation).where(DBLocation.name == location_name.capitalize()))
    loc = res.scalars().first()
    if not loc:
        raise HTTPException(status_code=404, detail="Location not found")
        
    # Get latest observation
    res = await db.execute(
        select(WeatherObservation)
        .where(WeatherObservation.location_id == loc.id)
        .where(WeatherObservation.source == "MQTT_BROKER_PROVIDER")
        .order_by(WeatherObservation.timestamp.desc())
        .limit(1)
    )
    obs = res.scalars().first()
    if not obs:
        raise HTTPException(status_code=404, detail="No MQTT observations found for location")
        
    return {
        "location": loc.name,
        "temperature": obs.temperature,
        "humidity": obs.humidity,
        "rainfall": obs.rainfall,
        "wind_speed": obs.wind_speed,
        "timestamp": obs.timestamp
    }
"""

def patch_weather_router():
    weather_path = os.path.join(base_dir, 'app/api/routes/weather.py')
    with open(weather_path, 'r') as f:
        content = f.read()
        
    if '/mqtt/' not in content:
        # Just append it
        content += "\\n" + weather_router_patch
        with open(weather_path, 'w') as f:
            f.write(content)
        print("Patched app/api/routes/weather.py")

def update_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)
    print(f"Updated {path}")

def update_env_example():
    env_path = os.path.join(base_dir, '.env.example')
    with open(env_path, 'r') as f:
        content = f.read()
        
    if 'MQTT_TOPIC' not in content:
        content = content.replace(
            '# MQTT_BROKER_URL=',
            'MQTT_BROKER_URL=localhost\\nMQTT_BROKER_PORT=1883\\nMQTT_TOPIC=weather/chennai'
        )
        content = content.replace('# WIS2_NODE_URL=', '')
        with open(env_path, 'w') as f:
            f.write(content)
        print("Patched .env.example")

if __name__ == '__main__':
    update_file(os.path.join(base_dir, 'app/core/config.py'), config_py_content)
    update_file(os.path.join(base_dir, 'app/services/ingestion/normalizer.py'), normalizer_py_content)
    update_file(os.path.join(base_dir, 'app/services/ingestion/background_ingestion.py'), background_ingestion_py_content)
    patch_main_py()
    patch_weather_router()
    update_env_example()
    print("MQTT Integration files successfully updated.")
