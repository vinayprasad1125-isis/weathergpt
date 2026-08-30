import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

# Update chat schema
chat_schema_path = os.path.join(base_dir, 'app/schemas/chat.py')
with open(chat_schema_path, 'r') as f:
    content = f.read()
if 'location: Optional[str] = None' in content:
    content = content.replace(
        'location: Optional[str] = None',
        'location: Optional[Any] = None  # Can be a string or a dict of {latitude, longitude}'
    )
with open(chat_schema_path, 'w') as f:
    f.write(content)


# Update weather_service.py
ws_path = os.path.join(base_dir, 'app/services/weather_service.py')
with open(ws_path, 'r') as f:
    ws_content = f.read()

# Make get_current_weather take optional lat/lon
if 'async def get_current_weather(self, city: str) -> CurrentWeatherResponse:' in ws_content:
    ws_content = ws_content.replace(
        'async def get_current_weather(self, city: str) -> CurrentWeatherResponse:',
        'async def get_current_weather(self, city: str = None, lat: float = None, lon: float = None) -> CurrentWeatherResponse:'
    ).replace(
        'location_data = await self.client.get_coordinates(city)',
        '''if lat is not None and lon is not None:
            location_data = {"latitude": lat, "longitude": lon, "name": city or "Unknown", "country": ""}
        else:
            location_data = await self.client.get_coordinates(city or "Chennai")'''
    )
with open(ws_path, 'w') as f:
    f.write(ws_content)


# Update ai_query_service.py
ai_path = os.path.join(base_dir, 'app/services/ai_query_service.py')
with open(ai_path, 'r') as f:
    ai_content = f.read()

new_ai_content = '''from typing import Optional
from fastapi import HTTPException
from app.schemas.chat import ChatRequest, ChatResponse
from app.schemas.advisory import AdvisoryRequest, AdvisoryRequestLocation
from app.services.llm_service import GeminiLLMService
from app.services.weather_service import WeatherService
from app.services.alert_service import AlertService
from app.services.nwp_service import NWPService
from app.services.location_service import LocationService
from app.services.advisory.advisory_router import AdvisoryRouter
import logging

logger = logging.getLogger(__name__)

class AIQueryService:
    def __init__(self):
        self.llm = GeminiLLMService()
        self.weather = WeatherService()
        self.alert = AlertService()
        self.nwp = NWPService()
        self.location_service = LocationService()
        self.advisory_router = AdvisoryRouter()

    async def process_chat(self, request: ChatRequest) -> ChatResponse:
        logger.info(f"Processing chat message: {request.message}")
        
        # 1. Parse client device location if provided as dict
        client_lat, client_lon = None, None
        if isinstance(request.location, dict) and 'latitude' in request.location:
            client_lat = request.location['latitude']
            client_lon = request.location['longitude']

        # 2. Extract Query Intent
        context_loc_str = request.location if isinstance(request.location, str) else None
        try:
            query = await self.llm.extract_query(request.message, context_loc_str)
        except Exception as e:
            raise HTTPException(status_code=500, detail="Failed to understand the query")

        # 3. Location Precedence Resolution
        target_lat, target_lon = client_lat, client_lon
        target_name = query.location
        
        if query.location and query.location.lower() not in ['here', 'my location', 'current']:
            # Explicit location takes precedence -> Geocode
            try:
                results = await self.location_service.search(query.location)
                if results:
                    target_lat = results[0].latitude
                    target_lon = results[0].longitude
                    target_name = results[0].name
            except Exception:
                pass
        
        # Fallback to defaults if neither explicitly given nor device coordinates provided
        if target_lat is None or target_lon is None:
            target_lat, target_lon = 13.0827, 80.2707
            target_name = "Chennai (Default)"
            
        query.location = target_name

        context_data = {}
        source = {}

        try:
            # Domain: Advisory
            if getattr(query, 'intent', '') == 'advisory' and getattr(query, 'user_type', None):
                domain = query.user_type
                adv_req = AdvisoryRequest(
                    domain=domain, 
                    location=AdvisoryRequestLocation(latitude=target_lat, longitude=target_lon)
                )
                adv_resp = await self.advisory_router.process_advisory(adv_req)
                context_data = adv_resp.model_dump()
                source = {"provider": f"Advisory Engine ({domain})"}
                
            # Intent: Alerts
            elif query.intent == 'alerts':
                alerts = await self.alert.get_active_alerts(target_lat, target_lon)
                context_data = {"alerts": [a.model_dump() for a in alerts]}
                source = {"provider": "IMD"}
            
            # NWP Data Source
            elif query.data_source and query.data_source.lower() in ['gfs', 'wrf']:
                nwp_forecast = await self.nwp.get_forecast(query.data_source, target_lat, target_lon)
                context_data = nwp_forecast.model_dump()
                source = {"provider": query.data_source.upper()}
            
            # Default Weather
            else:
                weather_resp = await self.weather.get_current_weather(city=target_name, lat=target_lat, lon=target_lon)
                context_data = weather_resp.model_dump()
                source = {"provider": "Open-Meteo"}
                
        except HTTPException as e:
            return ChatResponse(message=f"I couldn't retrieve data for {target_name}: {e.detail}")
        except Exception as e:
            raise HTTPException(status_code=500, detail="Failed to fetch weather data")

        try:
            natural_response = await self.llm.generate_response(request.message, context_data)
        except Exception as e:
            raise HTTPException(status_code=500, detail="Failed to generate AI response")

        return ChatResponse(
            message=natural_response,
            query=query,
            weather_data=context_data,
            source=source
        )

    async def close(self):
        await self.weather.close()
'''
with open(ai_path, 'w') as f:
    f.write(new_ai_content)


# Update main.py
main_path = os.path.join(base_dir, 'app/main.py')
with open(main_path, 'r') as f:
    main_content = f.read()

if 'from app.api.routes import health, weather, chat, nwp, alerts' in main_content:
    main_content = main_content.replace(
        'from app.api.routes import health, weather, chat, nwp, alerts',
        'from app.api.routes import health, weather, chat, nwp, alerts, location, advisory'
    )
if 'app.include_router(alerts.router, prefix="/api/v1/alerts", tags=["Alerts"])' in main_content:
    main_content = main_content.replace(
        'app.include_router(alerts.router, prefix="/api/v1/alerts", tags=["Alerts"])',
        'app.include_router(alerts.router, prefix="/api/v1/alerts", tags=["Alerts"])\\napp.include_router(location.router, prefix="/api/v1/location", tags=["Location"])\\napp.include_router(advisory.router, prefix="/api/v1/advisory", tags=["Advisory"])'
    )

with open(main_path, 'w') as f:
    f.write(main_content)

print("Backend wiring completed.")
