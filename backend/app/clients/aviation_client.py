import httpx
from typing import Optional, Dict, Any, List

class AviationWeatherClient:
    BASE_URL = "https://aviationweather.gov/api/data"
    
    def __init__(self):
        self.client = httpx.AsyncClient(base_url=self.BASE_URL)

    async def get_metar(self, station: str) -> List[Dict[str, Any]]:
        """
        Fetches decoded METAR for a given ICAO station.
        Example: station='VOMM'
        """
        params = {
            "ids": station,
            "format": "json"
        }
        
        try:
            response = await self.client.get("/metar", params=params)
            response.raise_for_status()
            data = response.json()
            return data
        except httpx.HTTPError as e:
            print(f"Aviation METAR API Error: {e}")
            return []
            
    async def get_taf(self, station: str) -> List[Dict[str, Any]]:
        """
        Fetches decoded TAF for a given ICAO station.
        """
        params = {
            "ids": station,
            "format": "json"
        }
        
        try:
            response = await self.client.get("/taf", params=params)
            response.raise_for_status()
            data = response.json()
            return data
        except httpx.HTTPError as e:
            print(f"Aviation TAF API Error: {e}")
            return []

aviation_client = AviationWeatherClient()
