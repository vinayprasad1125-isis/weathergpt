from pydantic import BaseModel
from typing import Optional, List

class Location(BaseModel):
    name: str
    region: Optional[str] = None
    country: str
    latitude: float
    longitude: float
    timezone: Optional[str] = None

class LocationSearchResponse(BaseModel):
    results: List[Location]
