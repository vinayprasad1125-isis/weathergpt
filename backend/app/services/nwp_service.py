import httpx
from datetime import datetime, timezone
from fastapi import HTTPException
from app.schemas.nwp import NWPForecastResponse, NWPLocation, NWPVariables
from abc import ABC, abstractmethod

class NWPProvider(ABC):
    @abstractmethod
    async def get_forecast(self, lat: float, lon: float) -> NWPForecastResponse:
        pass

class GFSService(NWPProvider):
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

class WRFService(NWPProvider):
    async def get_forecast(self, lat: float, lon: float) -> NWPForecastResponse:
        # WRF data source is currently unconfigured. We raise an error instead of returning mocked data.
        raise HTTPException(
            status_code=501, 
            detail="WRF data provider is currently unavailable. A real WRF API endpoint is required."
        )

class NWPService:
    def __init__(self):
        self.providers = {
            'gfs': GFSService(),
            'wrf': WRFService()
        }

    async def get_forecast(self, model: str, lat: float, lon: float) -> NWPForecastResponse:
        provider = self.providers.get(model.lower())
        if not provider:
            raise HTTPException(status_code=400, detail=f"Unsupported NWP model: {model}")
        return await provider.get_forecast(lat, lon)
