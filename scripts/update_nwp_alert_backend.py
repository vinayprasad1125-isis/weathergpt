import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

# Update main.py
main_path = os.path.join(base_dir, 'app/main.py')
with open(main_path, 'r') as f:
    main_content = f.read()

if 'from app.api.routes import health, weather, chat' in main_content:
    main_content = main_content.replace(
        'from app.api.routes import health, weather, chat',
        'from app.api.routes import health, weather, chat, nwp, alerts'
    )
if 'app.include_router(chat.router, prefix="/api/v1/chat", tags=["Chat"])' in main_content:
    main_content = main_content.replace(
        'app.include_router(chat.router, prefix="/api/v1/chat", tags=["Chat"])',
        'app.include_router(chat.router, prefix="/api/v1/chat", tags=["Chat"])\\napp.include_router(nwp.router, prefix="/api/v1/nwp", tags=["NWP"])\\napp.include_router(alerts.router, prefix="/api/v1/alerts", tags=["Alerts"])'
    )

with open(main_path, 'w') as f:
    f.write(main_content)

# Update ai_query_service.py
ai_path = os.path.join(base_dir, 'app/services/ai_query_service.py')
with open(ai_path, 'r') as f:
    ai_content = f.read()

new_ai_content = '''from typing import Optional
from fastapi import HTTPException
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.llm_service import GeminiLLMService
from app.services.weather_service import WeatherService
from app.services.alert_service import AlertService
from app.services.nwp_service import NWPService
import logging

logger = logging.getLogger(__name__)

class AIQueryService:
    def __init__(self):
        self.llm = GeminiLLMService()
        self.weather_service = WeatherService()
        self.alert_service = AlertService()
        self.nwp_service = NWPService()

    async def process_chat(self, request: ChatRequest) -> ChatResponse:
        logger.info(f"Processing chat message: {request.message}")
        
        try:
            query = await self.llm.extract_query(request.message, request.location)
        except Exception as e:
            raise HTTPException(status_code=500, detail="Failed to understand the query")

        if not query.location:
            return ChatResponse(
                message="Sure — which location would you like the forecast for?",
                query=query
            )

        context_data = {}
        source = {}

        try:
            # 1. Alert Intent
            if query.intent == 'alerts':
                # Simplified geocoding: we would resolve the location name to lat/lon here.
                # For this implementation, we simulate Chennai coordinates.
                lat, lon = 13.0827, 80.2707
                alerts = await self.alert_service.get_active_alerts(lat, lon)
                context_data = {"alerts": [a.model_dump() for a in alerts]}
                source = {"provider": "IMD"}
            
            # 2. NWP Data Source
            elif query.data_source and query.data_source.lower() in ['gfs', 'wrf']:
                # Again, simulate lat/lon for the named location.
                lat, lon = 13.0827, 80.2707
                nwp_forecast = await self.nwp_service.get_forecast(query.data_source, lat, lon)
                context_data = nwp_forecast.model_dump()
                source = {"provider": query.data_source.upper()}
            
            # 3. Default Weather
            else:
                weather_resp = await self.weather_service.get_current_weather(query.location)
                context_data = weather_resp.model_dump()
                source = {"provider": "Open-Meteo"}
                
        except HTTPException as e:
            return ChatResponse(message=f"I couldn't retrieve data for {query.location}: {e.detail}")
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
        await self.weather_service.close()
'''
with open(ai_path, 'w') as f:
    f.write(new_ai_content)

print("Backend main and AI Query Service updated.")
