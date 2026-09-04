from pydantic import BaseModel
from typing import Optional, List, Dict, Any

class AdvisoryFactor(BaseModel):
    parameter: str
    value: Any
    category: str = "general"

class AdvisoryRequestLocation(BaseModel):
    latitude: float
    longitude: float
    name: Optional[str] = None

class AdvisoryRequest(BaseModel):
    domain: str
    location: AdvisoryRequestLocation
    time_range: Optional[str] = "today"

class MarineAssessment(BaseModel):
    category: str
    severity: str
    reasons: List[str]
    limitations: List[str]

class AdvisoryResponse(BaseModel):
    domain: str
    location: dict
    summary: str
    factors: List[AdvisoryFactor]
    recommendations: List[str]
    assessment: Optional[MarineAssessment] = None
    source: str
    forecast_time: Optional[str] = None
    last_updated: Optional[str] = None
