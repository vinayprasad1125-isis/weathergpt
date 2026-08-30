import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

# 1. Update requirements.txt
req_path = os.path.join(base_dir, 'requirements.txt')
with open(req_path, 'r') as f:
    reqs = f.read()
if 'sqlalchemy' not in reqs:
    with open(req_path, 'a') as f:
        f.write('\\nsqlalchemy\\naiosqlite\\n')

# 2. Files to create
files = {
    'app/services/language_detection_service.py': '''class LanguageDetectionService:
    def detect_language(self, text: str) -> dict:
        # Simple heuristic based on Unicode blocks for speed and reliability
        # Tamil: U+0B80 - U+0BFF
        # Devanagari (Hindi): U+0900 - U+097F
        
        tamil_count = sum(1 for c in text if 0x0B80 <= ord(c) <= 0x0BFF)
        hindi_count = sum(1 for c in text if 0x0900 <= ord(c) <= 0x097F)
        
        if tamil_count > 0 and tamil_count >= hindi_count:
            return {"language": "ta", "confidence": 0.9}
        elif hindi_count > 0:
            return {"language": "hi", "confidence": 0.9}
        return {"language": "en", "confidence": 0.9}
''',

    'app/db/database.py': '''import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base

# Use sqlite for local dev, allowing seamless Postgres transition via DATABASE_URL
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./historical.db")

engine = create_async_engine(DATABASE_URL, echo=False)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
''',

    'app/db/models.py': '''from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.db.database import Base

class DBLocation(Base):
    __tablename__ = "locations"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    latitude = Column(Float)
    longitude = Column(Float)
    historical_data = relationship("HistoricalWeather", back_populates="location")

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
''',

    'app/schemas/climate.py': '''from pydantic import BaseModel
from typing import Optional, Dict, Any, List

class TimeRange(BaseModel):
    start: str
    end: str

class ClimateLocation(BaseModel):
    latitude: float
    longitude: float
    name: Optional[str] = "Unknown"

class ClimateAnalyzeRequest(BaseModel):
    location: ClimateLocation
    time_range: TimeRange
    parameter: str
    analysis: str

class ClimateAnalyzeResponse(BaseModel):
    location: dict
    period: dict
    parameter: str
    analysis: str
    result: dict
    data_points: int
    source: dict
    
class ClimateTrendResponse(BaseModel):
    parameter: str
    analysis: str
    trend: dict
    historical_series: List[dict]
''',

    'app/services/historical_weather_provider.py': '''import httpx
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.db.models import DBLocation, HistoricalWeather
import logging

logger = logging.getLogger(__name__)

class HistoricalWeatherProvider:
    async def fetch_and_store(self, lat: float, lon: float, start_date: str, end_date: str, db: AsyncSession):
        # Check if location exists
        result = await db.execute(select(DBLocation).filter(DBLocation.latitude == lat, DBLocation.longitude == lon))
        loc = result.scalars().first()
        if not loc:
            loc = DBLocation(name="Unknown", latitude=lat, longitude=lon)
            db.add(loc)
            await db.commit()
            await db.refresh(loc)

        # Basic check to avoid re-fetching large datasets unnecessarily (for MVP)
        existing = await db.execute(select(HistoricalWeather).filter(HistoricalWeather.location_id == loc.id).limit(1))
        if existing.scalars().first():
            return  # Already populated for this location

        # Fetch from Open-Meteo Archive API
        url = f"https://archive-api.open-meteo.com/v1/archive?latitude={lat}&longitude={lon}&start_date={start_date}&end_date={end_date}&daily=temperature_2m_mean,precipitation_sum,wind_speed_10m_max&timezone=auto"
        async with httpx.AsyncClient() as client:
            resp = await client.get(url, timeout=30.0)
            if resp.status_code != 200:
                logger.error(f"Failed to fetch historical data: {resp.text}")
                return

            data = resp.json().get('daily', {})
            times = data.get('time', [])
            temps = data.get('temperature_2m_mean', [])
            precips = data.get('precipitation_sum', [])
            winds = data.get('wind_speed_10m_max', [])
            
            records = []
            for i in range(len(times)):
                if temps[i] is None: continue
                records.append(HistoricalWeather(
                    location_id=loc.id,
                    timestamp=datetime.strptime(times[i], "%Y-%m-%d"),
                    temperature=temps[i],
                    rainfall=precips[i] if precips[i] is not None else 0.0,
                    wind_speed=winds[i] if winds[i] is not None else 0.0,
                    source="Open-Meteo Archive"
                ))
            
            db.add_all(records)
            await db.commit()
''',

    'app/services/climate_analytics_service.py': '''from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from datetime import datetime
from app.db.models import DBLocation, HistoricalWeather
from app.schemas.climate import ClimateAnalyzeRequest, ClimateAnalyzeResponse, ClimateTrendResponse

class ClimateAnalyticsService:
    async def analyze(self, req: ClimateAnalyzeRequest, db: AsyncSession):
        # Find Location ID
        result = await db.execute(select(DBLocation.id).filter(
            DBLocation.latitude == req.location.latitude,
            DBLocation.longitude == req.location.longitude
        ))
        loc_id = result.scalars().first()
        
        if not loc_id:
            return None # No data

        start_dt = datetime.strptime(req.time_range.start, "%Y-%m-%d")
        end_dt = datetime.strptime(req.time_range.end, "%Y-%m-%d")

        query = select(HistoricalWeather).filter(
            HistoricalWeather.location_id == loc_id,
            HistoricalWeather.timestamp >= start_dt,
            HistoricalWeather.timestamp <= end_dt
        )
        
        records = (await db.execute(query)).scalars().all()
        if not records:
            return None
            
        data_points = len(records)
        
        if req.analysis == "trend":
            # Basic linear trend (y = mx + b)
            if req.parameter == "temperature":
                vals = [r.temperature for r in records]
                unit = "°C/year"
            else:
                vals = [r.rainfall for r in records]
                unit = "mm/year"
                
            n = len(vals)
            x = list(range(n))
            mean_x = sum(x) / n
            mean_y = sum(vals) / n
            numerator = sum((xi - mean_x) * (yi - mean_y) for xi, yi in zip(x, vals))
            denominator = sum((xi - mean_x)**2 for xi in x)
            slope = (numerator / denominator) * 365.25 if denominator != 0 else 0
            
            direction = "increasing" if slope > 0 else "decreasing"
            if abs(slope) < 0.01:
                direction = "stable"
                
            series = [{"date": r.timestamp.strftime("%Y-%m-%d"), "value": r.temperature if req.parameter=="temperature" else r.rainfall} for r in records]
            
            return ClimateTrendResponse(
                parameter=req.parameter,
                analysis="trend",
                trend={"direction": direction, "slope": round(slope, 3), "unit": unit},
                historical_series=series[::len(series)//20 or 1] # Sample 20 points for chart
            )

        elif req.analysis == "average":
            if req.parameter == "temperature":
                val = sum(r.temperature for r in records) / data_points
                unit = "°C"
            elif req.parameter == "rainfall":
                val = sum(r.rainfall for r in records) / data_points
                unit = "mm"
                
            return ClimateAnalyzeResponse(
                location={"name": req.location.name},
                period={"start": req.time_range.start, "end": req.time_range.end},
                parameter=req.parameter,
                analysis="average",
                result={"value": round(val, 2), "unit": unit},
                data_points=data_points,
                source={"name": "Open-Meteo Archive"}
            )
            
        elif req.analysis == "total" and req.parameter == "rainfall":
            val = sum(r.rainfall for r in records)
            return ClimateAnalyzeResponse(
                location={"name": req.location.name},
                period={"start": req.time_range.start, "end": req.time_range.end},
                parameter="rainfall",
                analysis="total",
                result={"value": round(val, 2), "unit": "mm"},
                data_points=data_points,
                source={"name": "Open-Meteo Archive"}
            )
''',

    'app/api/routes/climate.py': '''from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.climate import ClimateAnalyzeRequest
from app.db.database import get_db
from app.services.climate_analytics_service import ClimateAnalyticsService
from app.services.historical_weather_provider import HistoricalWeatherProvider

router = APIRouter()
analytics = ClimateAnalyticsService()
provider = HistoricalWeatherProvider()

@router.post("/analyze")
async def analyze_climate(req: ClimateAnalyzeRequest, db: AsyncSession = Depends(get_db)):
    # Trigger ingestion if not exists
    await provider.fetch_and_store(req.location.latitude, req.location.longitude, req.time_range.start, req.time_range.end, db)
    
    # Calculate
    result = await analytics.analyze(req, db)
    if not result:
        raise HTTPException(status_code=404, detail="No historical data available for this range.")
    return result
'''
}

os.makedirs(os.path.join(base_dir, 'app/db'), exist_ok=True)
open(os.path.join(base_dir, 'app/db/__init__.py'), 'a').close()

for filepath, content in files.items():
    full_path = os.path.join(base_dir, filepath)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w') as f:
        f.write(content)
print("Step 11/12 backend files created.")
