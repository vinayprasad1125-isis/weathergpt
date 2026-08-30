from pydantic import BaseModel
from typing import List, Dict, Any, Optional

class GISFeature(BaseModel):
    latitude: float
    longitude: float
    value: Any
    unit: Optional[str] = None
    properties: Optional[Dict[str, Any]] = None

class GISLayer(BaseModel):
    layer: str
    timestamp: str
    features: List[GISFeature]
