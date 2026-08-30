import httpx
import json
import logging
import os
import redis.asyncio as redis
from fastapi import HTTPException
from app.core.config import settings

logger = logging.getLogger(__name__)

class WeatherApiClient:
    def __init__(self):
        self.weather_url = settings.WEATHER_API_BASE_URL
        self.geo_url = settings.GEOCODING_API_BASE_URL
        self.client = httpx.AsyncClient(timeout=10.0)
        
        redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
        try:
            self.redis = redis.from_url(redis_url, decode_responses=True)
        except Exception as e:
            logger.error(f"Failed to connect to Redis: {e}")
            self.redis = None

    async def get_coordinates(self, city: str):
        cache_key = f"geo:{city.lower().replace(' ', '_')}"
        if self.redis:
            try:
                cached = await self.redis.get(cache_key)
                if cached:
                    return json.loads(cached)
            except Exception:
                pass
                
        try:
            response = await self.client.get(
                f"{self.geo_url}/search",
                params={"name": city, "count": 1, "language": "en", "format": "json"}
            )
            response.raise_for_status()
            data = response.json()
            if not data.get("results"):
                raise HTTPException(status_code=400, detail="Invalid location")
            result = data["results"][0]
            
            coord_data = {
                "name": result["name"],
                "country": result.get("country", ""),
                "latitude": result["latitude"],
                "longitude": result["longitude"]
            }
            
            if self.redis:
                try:
                    await self.redis.set(cache_key, json.dumps(coord_data), ex=86400) # Cache for 24 hours
                except Exception:
                    pass
                    
            return coord_data
        except httpx.RequestError:
            raise HTTPException(status_code=502, detail="Weather provider unavailable")

    async def get_current_weather(self, lat: float, lon: float):
        cache_key = f"weather:{round(lat, 4)}:{round(lon, 4)}"
        if self.redis:
            try:
                cached = await self.redis.get(cache_key)
                if cached:
                    return json.loads(cached)
            except Exception:
                pass

        params = {
            "latitude": lat,
            "longitude": lon,
            "current": "temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,cloud_cover,surface_pressure,wind_speed_10m,wind_direction_10m",
            "daily": "sunrise,sunset,uv_index_max",
            "timezone": "auto"
        }
        try:
            response = await self.client.get(f"{self.weather_url}/forecast", params=params)
            response.raise_for_status()
            data = response.json()
            
            if self.redis:
                try:
                    await self.redis.set(cache_key, json.dumps(data), ex=900) # Cache for 15 minutes
                except Exception:
                    pass
                    
            return data
        except httpx.RequestError:
            raise HTTPException(status_code=502, detail="Weather provider unavailable")

    async def get_forecast(self, lat: float, lon: float):
        cache_key = f"forecast:{round(lat, 4)}:{round(lon, 4)}"
        if self.redis:
            try:
                cached = await self.redis.get(cache_key)
                if cached:
                    return json.loads(cached)
            except Exception:
                pass

        params = {
            "latitude": lat,
            "longitude": lon,
            "hourly": "temperature_2m,precipitation_probability,weather_code",
            "daily": "temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code",
            "timezone": "auto",
            "forecast_days": 7
        }
        try:
            response = await self.client.get(f"{self.weather_url}/forecast", params=params)
            response.raise_for_status()
            data = response.json()
            
            if self.redis:
                try:
                    await self.redis.set(cache_key, json.dumps(data), ex=1800) # Cache for 30 minutes
                except Exception:
                    pass
                    
            return data
        except httpx.RequestError:
            raise HTTPException(status_code=502, detail="Weather provider unavailable")

    async def close(self):
        await self.client.aclose()
        if self.redis:
            await self.redis.close()
