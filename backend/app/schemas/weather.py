from pydantic import BaseModel
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
    precipitation_probability: int = 0
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

class HourlyForecast(BaseModel):
    time: str
    temperature: float
    precipitation_probability: int
    condition: str

class DailyForecast(BaseModel):
    date: str
    temperature_min: float
    temperature_max: float
    precipitation_probability: int
    condition: str

class ForecastResponse(BaseModel):
    location: Location
    hourly: list[HourlyForecast]
    daily: list[DailyForecast]
