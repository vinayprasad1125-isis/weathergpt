from pydantic import BaseModel
from typing import Optional, List, Dict, Any

class AdvisoryFactor(BaseModel):
    parameter: str
    value: Any

class AdvisoryRequestLocation(BaseModel):
    latitude: float
    longitude: float

class AdvisoryRequest(BaseModel):
    domain: str
    location: AdvisoryRequestLocation
    time_range: Optional[str] = "today"

class AdvisoryResponse(BaseModel):
    domain: str
    location: dict
    summary: str
    factors: List[AdvisoryFactor]
    recommendations: List[str]
    source: str
