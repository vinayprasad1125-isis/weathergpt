import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

models_py = """from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.db.database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    preferred_language = Column(String, default="en")
    conversations = relationship("Conversation", back_populates="user")

class DBLocation(Base):
    __tablename__ = "locations"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    region = Column(String, nullable=True)
    country = Column(String, nullable=True)
    latitude = Column(Float)
    longitude = Column(Float)
    timezone = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    historical_data = relationship("HistoricalWeather", back_populates="location")
    weather_observations = relationship("WeatherObservation", back_populates="location")
    forecasts = relationship("Forecast", back_populates="location")
    alerts = relationship("Alert", back_populates="location")
    advisories = relationship("Advisory", back_populates="location")

class WeatherObservation(Base):
    __tablename__ = "weather_observations"
    id = Column(Integer, primary_key=True, index=True)
    location_id = Column(Integer, ForeignKey("locations.id"))
    timestamp = Column(DateTime, index=True)
    temperature = Column(Float)
    humidity = Column(Float, nullable=True)
    rainfall = Column(Float, nullable=True)
    wind_speed = Column(Float, nullable=True)
    wind_direction = Column(Float, nullable=True)
    pressure = Column(Float, nullable=True)
    visibility = Column(Float, nullable=True)
    cloud_cover = Column(Float, nullable=True)
    source = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

    location = relationship("DBLocation", back_populates="weather_observations")

class Forecast(Base):
    __tablename__ = "forecasts"
    id = Column(Integer, primary_key=True, index=True)
    location_id = Column(Integer, ForeignKey("locations.id"))
    forecast_time = Column(DateTime, index=True)
    generated_at = Column(DateTime, index=True)
    temperature = Column(Float)
    precipitation = Column(Float, nullable=True)
    precipitation_probability = Column(Float, nullable=True)
    humidity = Column(Float, nullable=True)
    wind_speed = Column(Float, nullable=True)
    wind_direction = Column(Float, nullable=True)
    pressure = Column(Float, nullable=True)
    source = Column(String)
    model = Column(String, nullable=True) # GFS, WRF, etc.
    
    location = relationship("DBLocation", back_populates="forecasts")

class HistoricalWeather(Base):
    __tablename__ = "historical_weather"
    id = Column(Integer, primary_key=True, index=True)
    location_id = Column(Integer, ForeignKey("locations.id"))
    timestamp = Column(DateTime, index=True)
    temperature = Column(Float)
    rainfall = Column(Float)
    wind_speed = Column(Float)
    source = Column(String)
    
    location = relationship("DBLocation", back_populates="historical_data")

class Alert(Base):
    __tablename__ = "alerts"
    id = Column(Integer, primary_key=True, index=True)
    external_id = Column(String, index=True, nullable=True)
    event_type = Column(String, index=True)
    severity = Column(String, index=True)
    status = Column(String, index=True)
    location_id = Column(Integer, ForeignKey("locations.id"))
    headline = Column(String)
    description = Column(String)
    issued_at = Column(DateTime)
    effective_from = Column(DateTime)
    expires_at = Column(DateTime)
    source = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    location = relationship("DBLocation", back_populates="alerts")

class Advisory(Base):
    __tablename__ = "advisories"
    id = Column(Integer, primary_key=True, index=True)
    location_id = Column(Integer, ForeignKey("locations.id"))
    domain = Column(String, index=True)
    valid_from = Column(DateTime, nullable=True)
    valid_until = Column(DateTime, nullable=True)
    summary = Column(String)
    source = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    location = relationship("DBLocation", back_populates="advisories")

class Conversation(Base):
    __tablename__ = "conversations"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    language = Column(String, default="en")
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="conversations")
    messages = relationship("Message", back_populates="conversation")

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id"))
    role = Column(String) # user, assistant, system
    content = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    conversation = relationship("Conversation", back_populates="messages")
"""

repositories_py = """from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List, Optional
from app.db.models import DBLocation, WeatherObservation, Forecast, Alert, User, Conversation, Message

class BaseRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

class LocationRepository(BaseRepository):
    async def get_by_coords(self, lat: float, lon: float) -> Optional[DBLocation]:
        result = await self.session.execute(
            select(DBLocation).where(DBLocation.latitude == lat, DBLocation.longitude == lon)
        )
        return result.scalars().first()

    async def create(self, data: dict) -> DBLocation:
        loc = DBLocation(**data)
        self.session.add(loc)
        await self.session.commit()
        await self.session.refresh(loc)
        return loc

class WeatherObservationRepository(BaseRepository):
    async def create(self, data: dict) -> WeatherObservation:
        obs = WeatherObservation(**data)
        self.session.add(obs)
        await self.session.commit()
        await self.session.refresh(obs)
        return obs
        
    async def get_latest_for_location(self, location_id: int) -> Optional[WeatherObservation]:
        result = await self.session.execute(
            select(WeatherObservation)
            .where(WeatherObservation.location_id == location_id)
            .order_by(WeatherObservation.timestamp.desc())
            .limit(1)
        )
        return result.scalars().first()
"""

database_py = """import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base

# Fallback to SQLite if PostgreSQL is not provided
# Recommend setting DATABASE_URL="postgresql+asyncpg://user:pass@localhost:5432/dbname"
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./historical.db")

engine = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
"""

ingestion_base_py = """from abc import ABC, abstractmethod
from typing import Any
import logging

logger = logging.getLogger(__name__)

class Provider(ABC):
    @property
    @abstractmethod
    def name(self) -> str:
        pass
        
    @abstractmethod
    async def connect(self):
        pass
        
    @abstractmethod
    async def disconnect(self):
        pass
        
    @abstractmethod
    async def fetch_data(self, *args, **kwargs) -> Any:
        pass

class DataIngestionService:
    def __init__(self, providers: list[Provider], session):
        self.providers = {p.name: p for p in providers}
        self.session = session
        
    async def ingest_from_provider(self, provider_name: str, *args, **kwargs):
        provider = self.providers.get(provider_name)
        if not provider:
            raise ValueError(f"Provider {provider_name} not found")
            
        try:
            await provider.connect()
            data = await provider.fetch_data(*args, **kwargs)
            # Normalization and Persistence would follow here
            logger.info(f"Successfully ingested data from {provider_name}")
            return data
        except Exception as e:
            logger.error(f"Ingestion failed for {provider_name}: {e}")
            raise
        finally:
            await provider.disconnect()
"""

ingestion_http_py = """from app.services.ingestion.base import Provider
import httpx
import logging

logger = logging.getLogger(__name__)

class HTTPProvider(Provider):
    @property
    def name(self) -> str:
        return "HTTP_REST_PROVIDER"
        
    async def connect(self):
        self.client = httpx.AsyncClient()
        
    async def disconnect(self):
        await self.client.aclose()
        
    async def fetch_data(self, url: str, params: dict = None):
        try:
            response = await self.client.get(url, params=params)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            logger.error(f"HTTP Error: {e}")
            raise
"""

ingestion_mqtt_py = """from app.services.ingestion.base import Provider
import logging
import asyncio

logger = logging.getLogger(__name__)

class MQTTProvider(Provider):
    @property
    def name(self) -> str:
        return "MQTT_BROKER_PROVIDER"
        
    def __init__(self, broker_url: str = "localhost"):
        self.broker_url = broker_url
        self.connected = False
        
    async def connect(self):
        logger.info(f"Connecting to MQTT Broker at {self.broker_url}")
        await asyncio.sleep(0.1)
        self.connected = True
        
    async def disconnect(self):
        logger.info(f"Disconnecting from MQTT Broker at {self.broker_url}")
        self.connected = False
        
    async def fetch_data(self, topic: str):
        if not self.connected:
            raise ConnectionError("MQTT Broker not connected")
        logger.info(f"Subscribing/Fetching from topic: {topic}")
        return {"topic": topic, "payload": "TEST MQTT MESSAGE"}
"""

ingestion_wis2_py = """from app.services.ingestion.base import Provider
import logging

logger = logging.getLogger(__name__)

class WIS2Provider(Provider):
    @property
    def name(self) -> str:
        return "WIS2_GLOBAL_PROVIDER"
        
    async def connect(self):
        logger.info("Connecting to WIS2 node...")
        
    async def disconnect(self):
        logger.info("Disconnecting from WIS2 node...")
        
    async def fetch_data(self, query: dict):
        logger.info(f"Fetching WIS2 data for query: {query}")
        return {"wis2_id": "urn:wmo:md:int.wmo.wis2:mock", "data": "TEST WIS2 MESSAGE"}
"""

system_routes_py = """from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.db.database import get_db

router = APIRouter()

@router.get("/ingestion/status")
async def ingestion_status(db: AsyncSession = Depends(get_db)):
    try:
        await db.execute(text("SELECT 1"))
        db_status = "Healthy"
    except Exception as e:
        db_status = f"Unhealthy: {str(e)}"
        
    return {
        "database": db_status,
        "providers": {
            "HTTP_REST_PROVIDER": {"status": "Ready", "last_attempt": "N/A"},
            "MQTT_BROKER_PROVIDER": {"status": "Ready", "last_attempt": "N/A"},
            "WIS2_GLOBAL_PROVIDER": {"status": "Ready", "last_attempt": "N/A"}
        }
    }
"""

def update_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)
    print(f"Updated {path}")

def modify_main():
    main_path = os.path.join(base_dir, 'app/main.py')
    with open(main_path, 'r') as f:
        content = f.read()
        
    if 'system.router' not in content:
        content = content.replace(
            'from app.api.routes import health, weather, chat, nwp, alerts, location, advisory, climate, gis',
            'from app.api.routes import health, weather, chat, nwp, alerts, location, advisory, climate, gis, system'
        )
        content += '\\napp.include_router(system.router, prefix="/api/v1/system", tags=["System"])'
        
    with open(main_path, 'w') as f:
        f.write(content)
    print(f"Updated {main_path}")

def update_requirements():
    req_path = os.path.join(base_dir, 'requirements.txt')
    with open(req_path, 'r') as f:
        content = f.read()
    
    deps_to_add = ['asyncpg', 'aiomqtt', 'psycopg2-binary']
    for dep in deps_to_add:
        if dep not in content:
            content += f'\\n{dep}'
            
    with open(req_path, 'w') as f:
        f.write(content)
    print(f"Updated requirements.txt")

if __name__ == '__main__':
    update_file(os.path.join(base_dir, 'app/db/models.py'), models_py)
    update_file(os.path.join(base_dir, 'app/db/repositories.py'), repositories_py)
    update_file(os.path.join(base_dir, 'app/db/database.py'), database_py)
    update_file(os.path.join(base_dir, 'app/services/ingestion/__init__.py'), '')
    update_file(os.path.join(base_dir, 'app/services/ingestion/base.py'), ingestion_base_py)
    update_file(os.path.join(base_dir, 'app/services/ingestion/http_provider.py'), ingestion_http_py)
    update_file(os.path.join(base_dir, 'app/services/ingestion/mqtt_provider.py'), ingestion_mqtt_py)
    update_file(os.path.join(base_dir, 'app/services/ingestion/wis2_provider.py'), ingestion_wis2_py)
    update_file(os.path.join(base_dir, 'app/api/routes/system.py'), system_routes_py)
    
    modify_main()
    update_requirements()
    print("Backend successfully updated for Step 15 & 16!")
