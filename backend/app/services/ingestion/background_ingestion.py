import asyncio
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
