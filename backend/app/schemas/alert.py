from pydantic import BaseModel
from typing import Optional, List

class AlertLocation(BaseModel):
    name: Optional[str] = None
    latitude: float
    longitude: float

class AlertSource(BaseModel):
    name: str
    type: str

class NormalizedAlert(BaseModel):
    id: str
    event_type: str
    severity: str
    location: AlertLocation
    issued_at: str
    effective_from: str
    expires_at: str
    headline: str
    description: str
    recommended_actions: List[str] = []
    source: AlertSource
    status: str
