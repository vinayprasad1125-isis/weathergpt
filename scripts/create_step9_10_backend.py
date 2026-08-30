import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

files_to_create = {
    'app/schemas/location.py': '''from pydantic import BaseModel
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
''',
    
    'app/schemas/advisory.py': '''from pydantic import BaseModel
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
''',
    
    'app/services/location_service.py': '''import httpx
from fastapi import HTTPException
from typing import List
from app.schemas.location import Location

class LocationService:
    async def search(self, query: str) -> List[Location]:
        url = f"https://geocoding-api.open-meteo.com/v1/search?name={query}&count=5&language=en&format=json"
        async with httpx.AsyncClient() as client:
            response = await client.get(url)
            if response.status_code != 200:
                raise HTTPException(status_code=502, detail="Failed to fetch location data")
            
            data = response.json()
            results = data.get('results', [])
            
            locations = []
            for r in results:
                locations.append(Location(
                    name=r.get('name', ''),
                    region=r.get('admin1', ''),
                    country=r.get('country', ''),
                    latitude=r.get('latitude', 0.0),
                    longitude=r.get('longitude', 0.0),
                    timezone=r.get('timezone', '')
                ))
            return locations
''',

    'app/services/advisory/domains.py': '''from typing import Any
from app.schemas.advisory import AdvisoryResponse, AdvisoryFactor

class BaseAdvisoryService:
    def process(self, weather_data: dict, alerts: list, location: dict) -> AdvisoryResponse:
        raise NotImplementedError

class AgricultureAdvisoryService(BaseAdvisoryService):
    def process(self, weather_data: dict, alerts: list, location: dict) -> AdvisoryResponse:
        current = weather_data.get("current", {})
        precip = current.get("precipitation", 0.0)
        factors = [AdvisoryFactor(parameter="precipitation", value=precip)]
        
        if precip > 2.0:
            summary = "Rain is expected."
            recommendations = ["Consider postponing irrigation until the forecast is reassessed."]
        else:
            summary = "Dry conditions expected."
            recommendations = ["Standard irrigation schedules can be maintained."]
            
        return AdvisoryResponse(
            domain="agriculture",
            location=location,
            summary=summary,
            factors=factors,
            recommendations=recommendations,
            source="Open-Meteo"
        )

class AviationAdvisoryService(BaseAdvisoryService):
    def process(self, weather_data: dict, alerts: list, location: dict) -> AdvisoryResponse:
        current = weather_data.get("current", {})
        wind = current.get("wind_speed", 0.0)
        vis = current.get("visibility", 10.0)
        
        factors = [
            AdvisoryFactor(parameter="wind_speed", value=wind),
            AdvisoryFactor(parameter="visibility", value=vis)
        ]
        
        summary = "Aviation Weather Briefing."
        recommendations = ["Check full NOTAMs before flying."]
        if wind > 40.0:
            recommendations.append("High wind shear potential. Exercise caution during approach.")
        if vis < 3.0:
            recommendations.append("Low visibility conditions. IFR protocols may be required.")
            
        return AdvisoryResponse(
            domain="aviation", location=location, summary=summary,
            factors=factors, recommendations=recommendations, source="Open-Meteo"
        )

class MarineAdvisoryService(BaseAdvisoryService):
    def process(self, weather_data: dict, alerts: list, location: dict) -> AdvisoryResponse:
        current = weather_data.get("current", {})
        wind = current.get("wind_speed", 0.0)
        
        factors = [AdvisoryFactor(parameter="wind_speed", value=wind)]
        summary = "Marine Weather Briefing."
        recommendations = ["Wave information is not available from the current data source."]
        
        if wind > 30.0:
            recommendations.append("Strong winds. Small craft advisory conditions.")
            
        return AdvisoryResponse(
            domain="marine", location=location, summary=summary,
            factors=factors, recommendations=recommendations, source="Open-Meteo"
        )

class UrbanAdvisoryService(BaseAdvisoryService):
    def process(self, weather_data: dict, alerts: list, location: dict) -> AdvisoryResponse:
        current = weather_data.get("current", {})
        precip = current.get("precipitation", 0.0)
        temp = current.get("temperature", 25.0)
        
        factors = [
            AdvisoryFactor(parameter="precipitation", value=precip),
            AdvisoryFactor(parameter="temperature", value=temp)
        ]
        summary = "Urban Planning & Operations Briefing."
        recommendations = []
        
        if precip > 10.0:
            recommendations.append("Heavy rainfall expected. Flood-prone area awareness required.")
        if temp > 35.0:
            recommendations.append("High heat conditions. Outdoor event planning should include hydration stations.")
        if not recommendations:
            recommendations.append("Standard urban operations can continue normally.")
            
        return AdvisoryResponse(
            domain="urban", location=location, summary=summary,
            factors=factors, recommendations=recommendations, source="Open-Meteo"
        )

class DisasterAdvisoryService(BaseAdvisoryService):
    def process(self, weather_data: dict, alerts: list, location: dict) -> AdvisoryResponse:
        factors = [AdvisoryFactor(parameter="active_alerts_count", value=len(alerts))]
        recommendations = []
        
        if not alerts:
            summary = "No active official warnings."
            recommendations.append("No immediate disaster risks identified from authoritative sources.")
        else:
            summary = f"{len(alerts)} active official warning(s)."
            for a in alerts:
                headline = a.get("headline", "")
                recommendations.append(f"Official Warning: {headline}")
                
        return AdvisoryResponse(
            domain="disaster", location=location, summary=summary,
            factors=factors, recommendations=recommendations, source="IMD (Mock)"
        )
''',

    'app/services/advisory/advisory_router.py': '''from fastapi import HTTPException
from app.schemas.advisory import AdvisoryRequest, AdvisoryResponse
from app.services.advisory.domains import (
    AgricultureAdvisoryService,
    AviationAdvisoryService,
    MarineAdvisoryService,
    UrbanAdvisoryService,
    DisasterAdvisoryService
)
from app.services.weather_service import WeatherService
from app.services.alert_service import AlertService

class AdvisoryRouter:
    def __init__(self):
        self.weather = WeatherService()
        self.alert = AlertService()
        self.domains = {
            "agriculture": AgricultureAdvisoryService(),
            "aviation": AviationAdvisoryService(),
            "marine": MarineAdvisoryService(),
            "urban": UrbanAdvisoryService(),
            "disaster": DisasterAdvisoryService()
        }

    async def process_advisory(self, request: AdvisoryRequest) -> AdvisoryResponse:
        domain = request.domain.lower()
        if domain not in self.domains:
            raise HTTPException(status_code=400, detail=f"Unsupported advisory domain: {domain}")

        # Fetch Weather Context
        weather_resp = await self.weather.get_current_weather(
            lat=request.location.latitude, 
            lon=request.location.longitude
        )
        weather_data = weather_resp.model_dump()
        
        # Fetch Alerts Context
        alerts_list = await self.alert.get_active_alerts(
            lat=request.location.latitude, 
            lon=request.location.longitude
        )
        alerts_data = [a.model_dump() for a in alerts_list]
        
        # Run Domain Rule Engine
        service = self.domains[domain]
        return service.process(
            weather_data=weather_data, 
            alerts=alerts_data, 
            location={"latitude": request.location.latitude, "longitude": request.location.longitude}
        )
''',

    'app/api/routes/location.py': '''from fastapi import APIRouter, Query
from app.schemas.location import LocationSearchResponse
from app.services.location_service import LocationService

router = APIRouter()
location_service = LocationService()

@router.get("/search", response_model=LocationSearchResponse)
async def search_location(q: str = Query(..., description="City or place name")):
    results = await location_service.search(q)
    return LocationSearchResponse(results=results)
''',

    'app/api/routes/advisory.py': '''from fastapi import APIRouter
from app.schemas.advisory import AdvisoryRequest, AdvisoryResponse
from app.services.advisory.advisory_router import AdvisoryRouter

router = APIRouter()
advisory_router = AdvisoryRouter()

@router.post("", response_model=AdvisoryResponse)
async def get_advisory(request: AdvisoryRequest):
    return await advisory_router.process_advisory(request)
'''
}

os.makedirs(os.path.join(base_dir, 'app/services/advisory'), exist_ok=True)
open(os.path.join(base_dir, 'app/services/advisory/__init__.py'), 'a').close()

for filepath, content in files_to_create.items():
    full_path = os.path.join(base_dir, filepath)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w') as f:
        f.write(content)
print("Step 9 & 10 initial backend files created successfully.")
