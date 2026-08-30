from app.db.models import WeatherObservation
import logging

logger = logging.getLogger(__name__)

class DataNormalizer:
    @staticmethod
    def normalize_weather_observation(provider_name: str, raw_data: dict, location_id: int) -> dict:
        """
        Normalize provider specific raw data into the WeatherObservation dictionary format.
        """
        normalized = {
            "location_id": location_id,
            "source": provider_name,
            "temperature": None,
            "humidity": None,
            "wind_speed": None,
            "pressure": None,
            "rainfall": None
        }
        
        if provider_name == "HTTP_REST_PROVIDER":
            current = raw_data.get("current_weather", {})
            normalized["temperature"] = current.get("temperature")
            normalized["wind_speed"] = current.get("windspeed")
            
        elif provider_name == "MQTT_BROKER_PROVIDER":
            if isinstance(raw_data.get("payload"), dict):
                payload = raw_data["payload"]
                normalized["temperature"] = payload.get("temperature")
                normalized["humidity"] = payload.get("humidity")
                normalized["rainfall"] = payload.get("rainfall")
                
        elif provider_name == "WIS2_GLOBAL_PROVIDER":
            pass
            
        logger.info(f"Normalized data from {provider_name}")
        return normalized
