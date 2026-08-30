from typing import Optional
from fastapi import HTTPException
from app.schemas.chat import ChatRequest, ChatResponse
from app.schemas.advisory import AdvisoryRequest, AdvisoryRequestLocation
from app.schemas.climate import ClimateAnalyzeRequest, ClimateLocation, TimeRange
from app.services.llm_service import OpenAILLMService
from app.services.weather_service import WeatherService
from app.services.alert_service import AlertService
from app.services.nwp_service import NWPService
from app.services.location_service import LocationService
from app.services.advisory.advisory_router import AdvisoryRouter
from app.services.climate_analytics_service import ClimateAnalyticsService
from app.services.historical_weather_provider import HistoricalWeatherProvider
from app.services.language_detection_service import LanguageDetectionService
from app.db.database import AsyncSessionLocal
import logging

logger = logging.getLogger(__name__)

class AIQueryService:
    def __init__(self):
        self.llm = OpenAILLMService()
        self.weather = WeatherService()
        self.alert = AlertService()
        self.nwp = NWPService()
        self.location_service = LocationService()
        self.advisory_router = AdvisoryRouter()
        self.language_detector = LanguageDetectionService()
        self.climate_analytics = ClimateAnalyticsService()
        self.historical_provider = HistoricalWeatherProvider()

    async def process_chat(self, request: ChatRequest) -> ChatResponse:
        logger.info(f"Processing chat message: {request.message}")
        
        # 1. Language Detection
        detected_lang = request.language
        if detected_lang == "auto":
            lang_res = self.language_detector.detect_language(request.message)
            detected_lang = lang_res["language"]
            
        # 2. Parse client device location if provided as dict
        client_lat, client_lon = None, None
        if isinstance(request.location, dict) and 'latitude' in request.location:
            client_lat = request.location['latitude']
            client_lon = request.location['longitude']

        # 3. Extract Query Intent
        context_loc_str = request.location if isinstance(request.location, str) else None
        try:
            query = await self.llm.extract_query(request.message, context_loc_str)
        except Exception as e:
            raise HTTPException(status_code=500, detail="Failed to understand the query")

        # 4. Location Precedence Resolution
        target_lat, target_lon = client_lat, client_lon
        target_name = query.location
        
        if query.location and query.location.lower() not in ['here', 'my location', 'current']:
            try:
                results = await self.location_service.search(query.location)
                if results:
                    target_lat = results[0].latitude
                    target_lon = results[0].longitude
                    target_name = results[0].name
            except Exception:
                pass
        
        if target_lat is None or target_lon is None:
            target_lat, target_lon = 13.0827, 80.2707
            target_name = "Chennai (Default)"
            
        query.location = target_name

        context_data = {}
        source = {}

        try:
            if getattr(query, 'intent', '') == 'climate_analysis':
                start_year = "2014-01-01" # Default MVP 10 years
                end_year = "2023-12-31"
                async with AsyncSessionLocal() as db:
                    await self.historical_provider.fetch_and_store(target_lat, target_lon, start_year, end_year, db)
                    cli_req = ClimateAnalyzeRequest(
                        location=ClimateLocation(latitude=target_lat, longitude=target_lon, name=target_name),
                        time_range=TimeRange(start=start_year, end=end_year),
                        parameter=query.parameter or "temperature",
                        analysis=getattr(query, 'analysis', "average") or "average"
                    )
                    res = await self.climate_analytics.analyze(cli_req, db)
                    if res:
                        context_data = res.model_dump()
                        source = {"provider": "Historical Engine"}
                    else:
                        raise HTTPException(status_code=404, detail="No historical data found")
                
            elif getattr(query, 'intent', '') == 'advisory' and getattr(query, 'user_type', None):
                domain = query.user_type
                advisory_type = getattr(query, 'advisory_type', None)
                adv_req = AdvisoryRequest(
                    domain=domain,
                    location=AdvisoryRequestLocation(latitude=target_lat, longitude=target_lon)
                )
                adv_resp = await self.advisory_router.process_advisory(adv_req, advisory_type=advisory_type)
                context_data = adv_resp.model_dump()
                source = {"provider": f"Advisory Engine ({domain})"}
                
            elif query.intent == 'alerts':
                alerts = await self.alert.get_active_alerts(target_lat, target_lon)
                weather_resp = await self.weather.get_current_weather(city=target_name, lat=target_lat, lon=target_lon)
                context_data = weather_resp.model_dump()
                context_data["alerts"] = [a.model_dump() for a in alerts]
                source = {"provider": "IMD"}
            
            elif query.data_source and query.data_source.lower() in ['gfs', 'wrf']:
                nwp_forecast = await self.nwp.get_forecast(query.data_source, target_lat, target_lon)
                context_data = nwp_forecast.model_dump()
                source = {"provider": query.data_source.upper()}
                
            elif query.intent == 'forecast':
                weather_resp = await self.weather.get_forecast(city=target_name, lat=target_lat, lon=target_lon)
                context_data = weather_resp.model_dump()
                source = {"provider": "Open-Meteo"}
            
            else:
                weather_resp = await self.weather.get_current_weather(city=target_name, lat=target_lat, lon=target_lon)
                context_data = weather_resp.model_dump()
                source = {"provider": "Open-Meteo"}
                
        except HTTPException as e:
            return ChatResponse(message=f"I couldn't retrieve data for {target_name}: {e.detail}")
        except Exception as e:
            raise HTTPException(status_code=500, detail="Failed to fetch weather data")

        try:
            is_advisory = getattr(query, 'intent', '') == 'advisory'
            if is_advisory and context_data.get('domain'):
                advisory_type = getattr(query, 'advisory_type', None)
                natural_response = await self.llm.generate_advisory_response(
                    request.message, context_data, detected_lang, advisory_type=advisory_type
                )
            else:
                natural_response = await self.llm.generate_response(request.message, context_data, detected_lang)
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
