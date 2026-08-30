import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

files_to_create = {
    'app/core/config.py': '''from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    WEATHER_API_BASE_URL: str = "https://api.open-meteo.com/v1"
    GEOCODING_API_BASE_URL: str = "https://geocoding-api.open-meteo.com/v1"
    
    class Config:
        env_file = ".env"

settings = Settings()
''',

    'app/schemas/weather.py': '''from pydantic import BaseModel
from typing import Optional

class Location(BaseModel):
    name: str
    country: str
    latitude: float
    longitude: float

class CurrentWeather(BaseModel):
    temperature: float
    feels_like: float
    condition: str
    humidity: int
    wind_speed: float
    wind_direction: str
    visibility: float
    pressure: int
    uv_index: float
    precipitation: float
    cloud_cover: int

class SunInformation(BaseModel):
    sunrise: str
    sunset: str

class WeatherSource(BaseModel):
    provider: str

class CurrentWeatherResponse(BaseModel):
    location: Location
    current: CurrentWeather
    sun: SunInformation
    source: WeatherSource
''',

    'app/clients/weather_api_client.py': '''import httpx
from fastapi import HTTPException
from app.core.config import settings

class WeatherApiClient:
    def __init__(self):
        self.weather_url = settings.WEATHER_API_BASE_URL
        self.geo_url = settings.GEOCODING_API_BASE_URL
        self.client = httpx.AsyncClient(timeout=10.0)

    async def get_coordinates(self, city: str):
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
            return {
                "name": result["name"],
                "country": result.get("country", ""),
                "latitude": result["latitude"],
                "longitude": result["longitude"]
            }
        except httpx.RequestError:
            raise HTTPException(status_code=502, detail="Weather provider unavailable")

    async def get_current_weather(self, lat: float, lon: float):
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
            return response.json()
        except httpx.RequestError:
            raise HTTPException(status_code=502, detail="Weather provider unavailable")

    async def close(self):
        await self.client.aclose()
''',
    'app/services/weather_service.py': '''from app.clients.weather_api_client import WeatherApiClient
from app.schemas.weather import CurrentWeatherResponse, Location, CurrentWeather, SunInformation, WeatherSource

def map_weather_code(code: int) -> str:
    mapping = {
        0: "Clear sky",
        1: "Mainly clear",
        2: "Partly cloudy",
        3: "Overcast",
        45: "Fog",
        48: "Depositing rime fog",
        51: "Light drizzle",
        53: "Moderate drizzle",
        55: "Dense drizzle",
        61: "Slight rain",
        63: "Moderate rain",
        65: "Heavy rain",
        71: "Slight snow fall",
        73: "Moderate snow fall",
        75: "Heavy snow fall",
        77: "Snow grains",
        80: "Slight rain showers",
        81: "Moderate rain showers",
        82: "Violent rain showers",
        95: "Thunderstorm",
        96: "Thunderstorm with slight hail",
        99: "Thunderstorm with heavy hail",
    }
    return mapping.get(code, "Unknown")

def map_wind_direction(degrees: int) -> str:
    dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
            "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    ix = int((degrees + 11.25) / 22.5)
    return dirs[ix % 16]

class WeatherService:
    def __init__(self):
        self.client = WeatherApiClient()

    async def get_current_weather(self, city: str) -> CurrentWeatherResponse:
        location_data = await self.client.get_coordinates(city)
        weather_data = await self.client.get_current_weather(
            location_data["latitude"], location_data["longitude"]
        )

        current = weather_data["current"]
        daily = weather_data.get("daily", {})
        
        sunrise = daily.get("sunrise", [""])[0]
        if "T" in sunrise:
            sunrise = sunrise.split("T")[1]
            
        sunset = daily.get("sunset", [""])[0]
        if "T" in sunset:
            sunset = sunset.split("T")[1]

        uv_index = daily.get("uv_index_max", [0.0])[0]

        return CurrentWeatherResponse(
            location=Location(**location_data),
            current=CurrentWeather(
                temperature=current["temperature_2m"],
                feels_like=current["apparent_temperature"],
                condition=map_weather_code(current["weather_code"]),
                humidity=current["relative_humidity_2m"],
                wind_speed=current["wind_speed_10m"],
                wind_direction=map_wind_direction(current["wind_direction_10m"]),
                visibility=10.0, # Not provided cleanly by standard current API, mock with 10
                pressure=int(current["surface_pressure"]),
                uv_index=float(uv_index) if uv_index else 0.0,
                precipitation=current["precipitation"],
                cloud_cover=current["cloud_cover"]
            ),
            sun=SunInformation(
                sunrise=sunrise,
                sunset=sunset
            ),
            source=WeatherSource(provider="Open-Meteo")
        )

    async def close(self):
        await self.client.close()
''',

    'app/api/routes/health.py': '''from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def root():
    return {"message": "WeatherGPT API"}

@router.get("/health")
async def health_check():
    return {
        "status": "ok",
        "service": "WeatherGPT API"
    }
''',

    'app/api/routes/weather.py': '''from fastapi import APIRouter, Query, HTTPException, Depends
from app.schemas.weather import CurrentWeatherResponse
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
    city: str = Query(..., description="City name"),
    service: WeatherService = Depends(get_weather_service)
):
    logger.info(f"Weather request received for location: {city}")
    return await service.get_current_weather(city)
''',

    'app/main.py': '''from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import health, weather
import logging

logging.basicConfig(level=logging.INFO)

app = FastAPI(title="WeatherGPT API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Configured broadly for development, adjust for prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(weather.router, prefix="/api/v1/weather", tags=["Weather"])
''',

    'tests/test_health.py': '''from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "WeatherGPT API"}

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "WeatherGPT API"}
'''
}

for filepath, content in files_to_create.items():
    full_path = os.path.join(base_dir, filepath)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w') as f:
        f.write(content)
print("Files created successfully.")

