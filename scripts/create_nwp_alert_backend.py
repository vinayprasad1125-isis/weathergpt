import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

files_to_create = {
    'app/schemas/nwp.py': '''from pydantic import BaseModel
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
''',
    
    'app/schemas/alert.py': '''from pydantic import BaseModel
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
''',
    
    'app/services/nwp_service.py': '''import httpx
from datetime import datetime, timezone
from fastapi import HTTPException
from app.schemas.nwp import NWPForecastResponse, NWPLocation, NWPVariables

class GFSService:
    async def get_forecast(self, lat: float, lon: float) -> NWPForecastResponse:
        url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,precipitation,wind_speed_10m,wind_direction_10m,relative_humidity_2m,surface_pressure&models=gfs_seamless"
        async with httpx.AsyncClient() as client:
            response = await client.get(url)
            if response.status_code != 200:
                raise HTTPException(status_code=502, detail="Failed to fetch GFS data")
            data = response.json()
            current = data.get('current', {})
            return NWPForecastResponse(
                model="GFS",
                run_time=datetime.now(timezone.utc).isoformat(),
                forecast_time=current.get('time', ''),
                location=NWPLocation(latitude=lat, longitude=lon),
                variables=NWPVariables(
                    temperature=current.get('temperature_2m'),
                    precipitation=current.get('precipitation'),
                    wind_speed=current.get('wind_speed_10m'),
                    wind_direction=current.get('wind_direction_10m'),
                    humidity=current.get('relative_humidity_2m'),
                    pressure=current.get('surface_pressure')
                )
            )

class WRFService:
    async def get_forecast(self, lat: float, lon: float) -> NWPForecastResponse:
        # WRF mock adapter - explicitly labelled as test data as requested in prompt
        return NWPForecastResponse(
            model="WRF",
            run_time=datetime.now(timezone.utc).isoformat(),
            forecast_time=datetime.now(timezone.utc).isoformat(),
            location=NWPLocation(latitude=lat, longitude=lon),
            variables=NWPVariables(
                temperature=31.2,
                precipitation=0.0,
                wind_speed=12.5,
                wind_direction=180.0,
                humidity=68.0,
                pressure=1008.5
            )
        )

class NWPService:
    def __init__(self):
        self.gfs = GFSService()
        self.wrf = WRFService()

    async def get_forecast(self, model: str, lat: float, lon: float) -> NWPForecastResponse:
        if model.lower() == 'gfs':
            return await self.gfs.get_forecast(lat, lon)
        elif model.lower() == 'wrf':
            return await self.wrf.get_forecast(lat, lon)
        else:
            raise HTTPException(status_code=400, detail=f"Unsupported NWP model: {model}")
''',

    'app/services/alert_service.py': '''from typing import List, Optional
from datetime import datetime, timezone, timedelta
from app.schemas.alert import NormalizedAlert, AlertLocation, AlertSource
import math

class AlertService:
    def __init__(self):
        # We start with a test fixture representing an IMD alert. 
        self.mock_alerts: List[NormalizedAlert] = [
            NormalizedAlert(
                id="TEST-ALERT-001",
                event_type="heavy_rainfall",
                severity="SEVERE",
                location=AlertLocation(name="Chennai", latitude=13.0827, longitude=80.2707),
                issued_at=datetime.now(timezone.utc).isoformat(),
                effective_from=datetime.now(timezone.utc).isoformat(),
                expires_at=(datetime.now(timezone.utc) + timedelta(hours=24)).isoformat(),
                headline="DEMO ALERT: Heavy Rainfall Warning",
                description="Isolated extremely heavy rainfall is expected.",
                recommended_actions=["Avoid low-lying areas", "Avoid unnecessary travel"],
                source=AlertSource(name="IMD", type="Authoritative"),
                status="ACTIVE"
            )
        ]

    def _haversine_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        R = 6371.0 # Earth radius in km
        lat1_rad = math.radians(lat1)
        lon1_rad = math.radians(lon1)
        lat2_rad = math.radians(lat2)
        lon2_rad = math.radians(lon2)
        
        dlat = lat2_rad - lat1_rad
        dlon = lon2_rad - lon1_rad
        
        a = math.sin(dlat / 2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c

    async def get_active_alerts(self, lat: Optional[float] = None, lon: Optional[float] = None, active: bool = True) -> List[NormalizedAlert]:
        alerts = [a for a in self.mock_alerts if not active or a.status == "ACTIVE"]
        if lat is not None and lon is not None:
            filtered_alerts = []
            for alert in alerts:
                # Simple location matching: within 50km radius
                if self._haversine_distance(lat, lon, alert.location.latitude, alert.location.longitude) <= 50.0:
                    filtered_alerts.append(alert)
            return filtered_alerts
        return alerts

    async def get_alert_by_id(self, alert_id: str) -> NormalizedAlert:
        for alert in self.mock_alerts:
            if alert.id == alert_id:
                return alert
        return None
''',

    'app/api/routes/nwp.py': '''from fastapi import APIRouter, Query, HTTPException
from app.schemas.nwp import NWPForecastResponse
from app.services.nwp_service import NWPService

router = APIRouter()
nwp_service = NWPService()

@router.get("/forecast", response_model=NWPForecastResponse)
async def get_nwp_forecast(
    model: str = Query(..., description="NWP Model (gfs or wrf)"),
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude")
):
    return await nwp_service.get_forecast(model, lat, lon)
''',

    'app/api/routes/alerts.py': '''from fastapi import APIRouter, Query, HTTPException
from typing import List, Optional
from app.schemas.alert import NormalizedAlert
from app.services.alert_service import AlertService

router = APIRouter()
alert_service = AlertService()

@router.get("", response_model=List[NormalizedAlert])
async def get_alerts(
    lat: Optional[float] = None,
    lon: Optional[float] = None,
    active: bool = True
):
    return await alert_service.get_active_alerts(lat, lon, active)

@router.get("/{alert_id}", response_model=NormalizedAlert)
async def get_alert(alert_id: str):
    alert = await alert_service.get_alert_by_id(alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    return alert
'''
}

for filepath, content in files_to_create.items():
    full_path = os.path.join(base_dir, filepath)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w') as f:
        f.write(content)
print("NWP and Alert backend files created successfully.")
