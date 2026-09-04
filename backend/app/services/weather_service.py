from app.clients.weather_api_client import WeatherApiClient
from app.schemas.weather import CurrentWeatherResponse, Location, CurrentWeather, SunInformation, WeatherSource, ForecastResponse, HourlyForecast, DailyForecast

def map_weather_code(code: int) -> str:
    mapping = {
        0: "Clear sky",
        1: "Mainly clear",
        2: "Partly cloudy",
        3: "Overcast",
        45: "Fog",
        48: "Depositing rime fog",
        51: "Light drizzle",
        53: "Moderate drizzle",
        55: "Dense drizzle",
        61: "Slight rain",
        63: "Moderate rain",
        65: "Heavy rain",
        71: "Slight snow fall",
        73: "Moderate snow fall",
        75: "Heavy snow fall",
        77: "Snow grains",
        80: "Slight rain showers",
        81: "Moderate rain showers",
        82: "Violent rain showers",
        95: "Thunderstorm",
        96: "Thunderstorm with slight hail",
        99: "Thunderstorm with heavy hail",
    }
    return mapping.get(code, "Unknown")

def map_wind_direction(degrees: int) -> str:
    dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
            "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    ix = int((degrees + 11.25) / 22.5)
    return dirs[ix % 16]

class WeatherService:
    def __init__(self):
        self.client = WeatherApiClient()

    async def get_current_weather(self, city: str = None, lat: float = None, lon: float = None) -> CurrentWeatherResponse:
        if lat is not None and lon is not None:
            location_data = {"latitude": lat, "longitude": lon, "name": city or "Unknown", "country": ""}
        else:
            location_data = await self.client.get_coordinates(city or "Chennai")
        weather_data = await self.client.get_current_weather(
            location_data["latitude"], location_data["longitude"]
        )

        current = weather_data["current"]
        daily = weather_data.get("daily", {})
        
        sunrise = daily.get("sunrise", [""])[0]
        if "T" in sunrise:
            sunrise = sunrise.split("T")[1]
            
        sunset = daily.get("sunset", [""])[0]
        if "T" in sunset:
            sunset = sunset.split("T")[1]

        uv_index = daily.get("uv_index_max", [0.0])[0]

        return CurrentWeatherResponse(
            location=Location(**location_data),
            current=CurrentWeather(
                temperature=current["temperature_2m"],
                feels_like=current["apparent_temperature"],
                condition=map_weather_code(current["weather_code"]),
                humidity=current["relative_humidity_2m"],
                wind_speed=current["wind_speed_10m"],
                wind_direction=map_wind_direction(current["wind_direction_10m"]),
                visibility=10.0, # Not provided cleanly by standard current API, mock with 10
                pressure=int(current["surface_pressure"]),
                uv_index=float(uv_index) if uv_index else 0.0,
                precipitation=current["precipitation"],
                cloud_cover=current["cloud_cover"]
            ),
            sun=SunInformation(
                sunrise=sunrise,
                sunset=sunset
            ),
            source=WeatherSource(provider="Open-Meteo")
        )

    async def get_forecast(self, city: str = None, lat: float = None, lon: float = None) -> ForecastResponse:
        if lat is not None and lon is not None:
            location_data = {"latitude": lat, "longitude": lon, "name": city or "Unknown", "country": ""}
        else:
            location_data = await self.client.get_coordinates(city or "Chennai")
            
        data = await self.client.get_forecast(location_data["latitude"], location_data["longitude"])
        
        hourly = []
        for i in range(24):
            # Take the next 24 hours
            hourly.append(HourlyForecast(
                time=data["hourly"]["time"][i],
                temperature=data["hourly"]["temperature_2m"][i],
                precipitation_probability=data["hourly"]["precipitation_probability"][i],
                condition=map_weather_code(data["hourly"]["weather_code"][i])
            ))
            
        daily = []
        for i in range(7):
            daily.append(DailyForecast(
                date=data["daily"]["time"][i],
                temperature_min=data["daily"]["temperature_2m_min"][i],
                temperature_max=data["daily"]["temperature_2m_max"][i],
                precipitation_probability=data["daily"]["precipitation_probability_max"][i],
                condition=map_weather_code(data["daily"]["weather_code"][i])
            ))
            
        return ForecastResponse(
            location=Location(**location_data),
            hourly=hourly,
            daily=daily
        )

    async def get_marine_weather(self, lat: float, lon: float) -> dict:
        return await self.client.get_marine_weather(lat, lon)

    async def close(self):
        await self.client.close()
