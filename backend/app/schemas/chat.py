from pydantic import BaseModel, Field
from typing import Optional, Any


class StructuredWeatherQuery(BaseModel):
    intent: Optional[str] = Field(None, description="The intent of the query, e.g., 'forecast', 'current_weather', 'wind', 'advisory'")
    location: Optional[str] = Field(None, description="The specific location mentioned, e.g., 'Chennai'")
    time_range: Optional[str] = Field(None, description="The time range, e.g., 'tomorrow evening', 'now'")
    parameter: Optional[str] = Field(None, description="The specific parameter asked for, e.g., 'precipitation', 'temperature'")
    user_type: Optional[str] = Field(None, description="The user persona if specified, e.g., 'farmer', 'pilot'")
    advisory_type: Optional[str] = Field(None, description="Specific advisory type e.g. 'pesticide_spraying', 'irrigation', 'flight_briefing'")
    data_source: str = Field(..., description="The data source required: 'current_weather' or 'weather_forecast'")


class ChatRequest(BaseModel):
    message: str
    location: Optional[Any] = None  # Can be a string or a dict of {latitude, longitude}
    language: str = "en"


class ChatResponse(BaseModel):
    message: str
    query: Optional[StructuredWeatherQuery] = None
    weather_data: Optional[dict[str, Any]] = None
    source: Optional[dict[str, str]] = None

class TTSRequest(BaseModel):
    text: str
    language: str = "en"
