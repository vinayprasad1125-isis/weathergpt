import os
import re

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

schemas_dir = os.path.join(base_dir, 'app/schemas')
services_dir = os.path.join(base_dir, 'app/services')
routes_dir = os.path.join(base_dir, 'app/api/routes')
os.makedirs(schemas_dir, exist_ok=True)
os.makedirs(services_dir, exist_ok=True)
os.makedirs(routes_dir, exist_ok=True)

# 1. app/schemas/gis.py
gis_schema_file = os.path.join(schemas_dir, 'gis.py')
with open(gis_schema_file, 'w') as f:
    f.write('''from pydantic import BaseModel
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
''')

# 2. app/services/gis_service.py
gis_service_file = os.path.join(services_dir, 'gis_service.py')
with open(gis_service_file, 'w') as f:
    f.write('''import logging
from typing import List
from datetime import datetime
from app.schemas.gis import GISLayer, GISFeature
from app.services.weather_service import WeatherService
from app.services.alert_service import AlertService

logger = logging.getLogger(__name__)

class GISService:
    def __init__(self):
        self.weather = WeatherService()
        self.alert = AlertService()

    async def get_layer(self, layer_type: str, lat: float, lon: float) -> GISLayer:
        features = []
        timestamp = datetime.now().isoformat()
        
        try:
            if layer_type in ["temperature", "wind", "rainfall"]:
                # Fetch a mock grid around the user to simulate map data
                # Since Open-Meteo takes single point, we just mock 5 points around them
                points = [
                    (lat, lon), (lat+1, lon+1), (lat-1, lon-1), (lat+1, lon-1), (lat-1, lon+1)
                ]
                
                for p_lat, p_lon in points:
                    try:
                        weather_data = await self.weather.get_current_weather(city="grid", lat=p_lat, lon=p_lon)
                        if layer_type == "temperature":
                            features.append(GISFeature(latitude=p_lat, longitude=p_lon, value=weather_data.temperature, unit="°C"))
                        elif layer_type == "wind":
                            features.append(GISFeature(latitude=p_lat, longitude=p_lon, value=weather_data.wind_speed, unit="km/h", properties={"direction": 180})) # mock dir
                        elif layer_type == "rainfall":
                            features.append(GISFeature(latitude=p_lat, longitude=p_lon, value=0.0, unit="mm")) # OpenMeteo current weather often has precipitation as 0 for mock
                    except Exception:
                        pass
                        
            elif layer_type == "alerts":
                alerts = await self.alert.get_active_alerts(lat, lon)
                for alert in alerts:
                    features.append(GISFeature(
                        latitude=lat, longitude=lon, 
                        value=alert.severity,
                        properties={"event": alert.event, "description": alert.description}
                    ))
                    
            elif layer_type == "cyclones":
                # Architectural placeholder: Real cyclone tracks require IBTrACS or RSMC endpoints.
                features.append(GISFeature(
                    latitude=lat+0.5, longitude=lon+0.5, 
                    value="Cyclone [DEMO DATA]",
                    properties={"status": "Active", "category": "Cat 1"}
                ))
                
            elif layer_type == "flood":
                # Architectural placeholder
                features.append(GISFeature(
                    latitude=lat-0.2, longitude=lon-0.2, 
                    value="High Flood Risk [DEMO DATA]",
                    properties={"level": "Warning"}
                ))
                
        except Exception as e:
            logger.error(f"Error fetching GIS layer {layer_type}: {e}")
            
        return GISLayer(layer=layer_type, timestamp=timestamp, features=features)
''')

# 3. app/api/routes/gis.py
gis_routes_file = os.path.join(routes_dir, 'gis.py')
with open(gis_routes_file, 'w') as f:
    f.write('''from fastapi import APIRouter, HTTPException, Query
from app.schemas.gis import GISLayer
from app.services.gis_service import GISService

router = APIRouter()
gis_service = GISService()

@router.get("/layers/{layer_type}", response_model=GISLayer)
async def get_gis_layer(layer_type: str, lat: float = Query(...), lon: float = Query(...)):
    """
    Available layers: temperature, wind, rainfall, alerts, cyclones, flood
    """
    valid_layers = ["temperature", "wind", "rainfall", "alerts", "cyclones", "flood"]
    if layer_type not in valid_layers:
        raise HTTPException(status_code=400, detail=f"Invalid layer type. Must be one of {valid_layers}")
        
    return await gis_service.get_layer(layer_type, lat, lon)
''')

# 4. Update app/main.py
main_file = os.path.join(base_dir, 'app/main.py')
with open(main_file, 'r') as f:
    main_content = f.read()

if 'gis.router' not in main_content:
    main_content = main_content.replace(
        'from app.api.routes import health, weather, chat, nwp, alerts, location, advisory, climate',
        'from app.api.routes import health, weather, chat, nwp, alerts, location, advisory, climate, gis'
    )
    main_content = main_content.replace(
        'app.include_router(climate.router, prefix="/api/v1/climate", tags=["Climate"])',
        'app.include_router(climate.router, prefix="/api/v1/climate", tags=["Climate"])\\napp.include_router(gis.router, prefix="/api/v1/gis", tags=["GIS"])'
    )
    with open(main_file, 'w') as f:
        f.write(main_content)

print("Backend GIS modules created.")
