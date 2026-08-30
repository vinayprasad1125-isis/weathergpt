from app.services.ingestion.base import Provider
import httpx
import logging

logger = logging.getLogger(__name__)

class HTTPProvider(Provider):
    @property
    def name(self) -> str:
        return "HTTP_REST_PROVIDER"
        
    async def connect(self):
        self.client = httpx.AsyncClient()
        
    async def disconnect(self):
        await self.client.aclose()
        
    async def fetch_data(self, url: str, params: dict = None):
        try:
            response = await self.client.get(url, params=params)
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            logger.error(f"HTTP Error: {e}")
            raise
