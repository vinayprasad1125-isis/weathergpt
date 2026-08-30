from fastapi import APIRouter, Query, HTTPException, Depends
from app.schemas.weather import CurrentWeatherResponse, ForecastResponse
from app.services.weather_service import WeatherService
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

async def get_weather_service():
    service = WeatherService()
    try:
        yield service
    finally:
        await service.close()

@router.get("/current", response_model=CurrentWeatherResponse)
async def get_current_weather(
    city: str = Query(None, description="City name"),
    lat: float = Query(None, description="Latitude"),
    lon: float = Query(None, description="Longitude"),
    service: WeatherService = Depends(get_weather_service)
):
    if not city and (lat is None or lon is None):
        raise HTTPException(status_code=400, detail="Must provide either city or lat/lon")
    return await service.get_current_weather(city=city, lat=lat, lon=lon)

@router.get("/forecast", response_model=ForecastResponse)
async def get_forecast(
    city: str = Query(..., description="City name"),
    service: WeatherService = Depends(get_weather_service)
):
    logger.info(f"Forecast request received for location: {city}")
    return await service.get_forecast(city)


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
