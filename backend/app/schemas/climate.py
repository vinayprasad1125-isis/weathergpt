from pydantic import BaseModel
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
