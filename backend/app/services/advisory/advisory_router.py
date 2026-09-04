from fastapi import HTTPException
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
import logging

logger = logging.getLogger(__name__)

# Domain synonyms mapping
DOMAIN_ALIASES = {
    "farmer": "agriculture", "farming": "agriculture",
    "crop": "agriculture", "crops": "agriculture",
    "pilot": "aviation", "flight": "aviation", "flying": "aviation",
    "sailor": "marine", "ship": "marine", "fishing": "marine", "fisherman": "marine",
    "city": "urban", "town": "urban",
}


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

    async def process_advisory(self, request: AdvisoryRequest,
                               advisory_type: str = None) -> AdvisoryResponse:
        raw_domain = request.domain.lower()
        domain = DOMAIN_ALIASES.get(raw_domain, raw_domain)

        if domain not in self.domains:
            raise HTTPException(status_code=400, detail=f"Unsupported advisory domain: {request.domain}")

        lat = request.location.latitude
        lon = request.location.longitude

        # Fetch current weather (all fields via WeatherService → WeatherApiClient)
        weather_resp = await self.weather.get_current_weather(lat=lat, lon=lon)
        weather_data = weather_resp.model_dump()

        # Fetch hourly forecast to get precipitation_probability for next 12 hours
        try:
            forecast_resp = await self.weather.get_forecast(lat=lat, lon=lon)
            forecast_dump = forecast_resp.model_dump()
            hourly = forecast_dump.get("hourly", [])
            rain_probs_next_12h = [
                h.get("precipitation_probability", 0)
                for h in hourly[:12]
                if h.get("precipitation_probability") is not None
            ]
            daily = forecast_dump.get("daily", [])
            daily_rain_prob_max = daily[0].get("precipitation_probability") if daily else None

            weather_data["forecast"] = {
                "hourly_rain_probs_next_12h": rain_probs_next_12h,
                "precipitation_probability_max": daily_rain_prob_max,
            }
        except Exception as e:
            logger.warning(f"Could not fetch forecast for advisory enrichment: {e}")
            weather_data["forecast"] = {}

        if domain == "marine":
            try:
                marine_resp = await self.weather.get_marine_weather(lat=lat, lon=lon)
                weather_data["marine"] = marine_resp
            except Exception as e:
                logger.warning(f"Could not fetch marine data: {e}")

        # Fetch alerts
        alerts_list = await self.alert.get_active_alerts(lat=lat, lon=lon)
        alerts_data = [a.model_dump() for a in alerts_list]

        service = self.domains[domain]
        
        # Determine base processing params
        time_range = request.time_range.lower() if request.time_range else "today"
        return service.process(
            weather_data=weather_data,
            alerts=alerts_data,
            location={"latitude": lat, "longitude": lon, "name": request.location.name},
            advisory_type=advisory_type,
            time_range=time_range
        )
