from pydantic import BaseModel
from typing import Optional

class NWPVariables(BaseModel):
    temperature: Optional[float] = None
    precipitation: Optional[float] = None
    wind_speed: Optional[float] = None
    wind_direction: Optional[float] = None
    humidity: Optional[float] = None
    pressure: Optional[float] = None

class NWPLocation(BaseModel):
    latitude: float
    longitude: float

class NWPForecastResponse(BaseModel):
    model: str
    run_time: str
    forecast_time: str
    location: NWPLocation
    variables: NWPVariables
