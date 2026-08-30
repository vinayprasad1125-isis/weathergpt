from typing import List, Optional
from datetime import datetime, timezone, timedelta
from app.schemas.alert import NormalizedAlert, AlertLocation, AlertSource
from app.services.weather_service import WeatherService
import uuid

class AlertService:
    def __init__(self):
        self.weather_service = WeatherService()

    async def get_active_alerts(self, lat: Optional[float] = None, lon: Optional[float] = None, active: bool = True) -> List[NormalizedAlert]:
        alerts = []
        if lat is None or lon is None:
            return alerts # Cannot generate location-based alerts without coordinates
            
        try:
            weather_resp = await self.weather_service.get_current_weather(lat=lat, lon=lon)
            current = weather_resp.current
            
            # Rule 1: Heavy Rainfall
            if current.precipitation and current.precipitation > 20.0:
                alerts.append(self._create_alert(
                    "heavy_rainfall", "SEVERE", lat, lon,
                    "Heavy Rainfall Warning",
                    f"Current precipitation is extremely high at {current.precipitation} mm/hr.",
                    ["Avoid low-lying areas", "Stay indoors"]
                ))
            elif current.precipitation and current.precipitation > 5.0:
                alerts.append(self._create_alert(
                    "moderate_rainfall", "MODERATE", lat, lon,
                    "Moderate Rainfall Alert",
                    f"Current precipitation is {current.precipitation} mm/hr.",
                    ["Carry an umbrella", "Drive carefully"]
                ))
                
            # Rule 2: Extreme Heat
            if current.temperature > 40.0:
                alerts.append(self._create_alert(
                    "extreme_heat", "SEVERE", lat, lon,
                    "Extreme Heat Warning",
                    f"Temperatures have reached a dangerous {current.temperature}°C.",
                    ["Stay hydrated", "Avoid direct sunlight"]
                ))
                
            # Rule 3: Extreme Cold
            if current.temperature < 5.0:
                alerts.append(self._create_alert(
                    "extreme_cold", "SEVERE", lat, lon,
                    "Extreme Cold Warning",
                    f"Temperatures have dropped to {current.temperature}°C.",
                    ["Wear warm layers", "Protect pipes from freezing"]
                ))
                
            # Rule 4: Strong Wind / Cyclone risk
            if current.wind_speed > 60.0:
                alerts.append(self._create_alert(
                    "strong_wind", "SEVERE", lat, lon,
                    "Strong Wind Warning",
                    f"High wind speeds detected at {current.wind_speed} km/h.",
                    ["Secure loose outdoor objects", "Avoid tall structures"]
                ))
                
            # Rule 5: Thunderstorm (Based on weather code)
            if current.condition and "Thunderstorm" in current.condition:
                alerts.append(self._create_alert(
                    "thunderstorm", "SEVERE", lat, lon,
                    "Thunderstorm Warning",
                    "Active thunderstorms detected in your area.",
                    ["Stay indoors", "Unplug sensitive electronics"]
                ))
                
        except Exception as e:
            # If weather fetching fails, return empty alerts instead of crashing
            pass
            
        return alerts

    def _create_alert(self, event_type: str, severity: str, lat: float, lon: float, headline: str, description: str, actions: List[str]) -> NormalizedAlert:
        now = datetime.now(timezone.utc)
        return NormalizedAlert(
            id=f"ALERT-{uuid.uuid4().hex[:8].upper()}",
            event_type=event_type,
            severity=severity,
            location=AlertLocation(name="Local Area", latitude=lat, longitude=lon),
            issued_at=now.isoformat(),
            effective_from=now.isoformat(),
            expires_at=(now + timedelta(hours=4)).isoformat(),
            headline=headline,
            description=description,
            recommended_actions=actions,
            source=AlertSource(name="WeatherGPT Rule Engine", type="Derived"),
            status="ACTIVE"
        )

    async def get_alert_by_id(self, alert_id: str) -> NormalizedAlert:
        # Since alerts are dynamic, fetching by ID without storing in DB is difficult.
        # This endpoint might need DB integration later. For now, return None.
        return None
