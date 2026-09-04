import logging
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
            if layer_type in ["temperature", "wind", "rainfall", "humidity", "pressure", "uv_index", "precipitation", "cloud_cover"]:
                # Fetch real weather for the requested coordinate ONLY. No fabricated grid points.
                weather_resp = await self.weather.get_current_weather(lat=lat, lon=lon)
                weather_data = weather_resp.current
                
                if layer_type == "temperature":
                    features.append(GISFeature(latitude=lat, longitude=lon, value=weather_data.temperature, unit="°C", properties={"condition": weather_data.condition}))
                elif layer_type == "wind":
                    features.append(GISFeature(latitude=lat, longitude=lon, value=weather_data.wind_speed, unit="km/h", properties={"direction": weather_data.wind_direction}))
                elif layer_type == "rainfall":
                    features.append(GISFeature(latitude=lat, longitude=lon, value=weather_data.precipitation, unit="mm", properties={"condition": weather_data.condition}))
                elif layer_type == "humidity":
                    features.append(GISFeature(latitude=lat, longitude=lon, value=float(weather_data.humidity), unit="%", properties={"condition": weather_data.condition}))
                elif layer_type == "pressure":
                    features.append(GISFeature(latitude=lat, longitude=lon, value=float(weather_data.pressure), unit="hPa", properties={"condition": weather_data.condition}))
                elif layer_type == "uv_index":
                    features.append(GISFeature(latitude=lat, longitude=lon, value=float(weather_data.uv_index), unit="", properties={"condition": weather_data.condition}))
                elif layer_type == "precipitation":
                    features.append(GISFeature(latitude=lat, longitude=lon, value=weather_data.precipitation, unit="mm/h", properties={"condition": weather_data.condition}))
                elif layer_type == "cloud_cover":
                    features.append(GISFeature(latitude=lat, longitude=lon, value=float(weather_data.cloud_cover), unit="%", properties={"condition": weather_data.condition}))
                        
            elif layer_type == "alerts":
                alerts = await self.alert.get_active_alerts(lat, lon)
                for alert in alerts:
                    features.append(GISFeature(
                        latitude=lat, longitude=lon, 
                        value=alert.severity,
                        properties={"event": alert.event_type, "headline": alert.headline, "description": alert.description}
                    ))
                    
            elif layer_type == "cyclones":
                # Real cyclone data requires dedicated IBTrACS or RSMC endpoints.
                # Here, we only return a feature if the rule engine generated a cyclone/strong wind alert.
                alerts = await self.alert.get_active_alerts(lat, lon)
                for alert in alerts:
                    if alert.event_type == "strong_wind" and alert.severity == "SEVERE":
                        features.append(GISFeature(
                            latitude=lat, longitude=lon, 
                            value="High Wind Risk",
                            properties={"headline": alert.headline}
                        ))
                
            elif layer_type == "flood":
                alerts = await self.alert.get_active_alerts(lat, lon)
                for alert in alerts:
                    if alert.event_type in ["heavy_rainfall", "moderate_rainfall"]:
                        features.append(GISFeature(
                            latitude=lat, longitude=lon, 
                            value="Rain/Flood Risk",
                            properties={"headline": alert.headline}
                        ))
                
        except Exception as e:
            logger.error(f"Error fetching GIS layer {layer_type}: {e}")
            
        return GISLayer(layer=layer_type, timestamp=timestamp, features=features)
