from abc import ABC, abstractmethod
from typing import Any
import logging

logger = logging.getLogger(__name__)

class Provider(ABC):
    @property
    @abstractmethod
    def name(self) -> str:
        pass
        
    @abstractmethod
    async def connect(self):
        pass
        
    @abstractmethod
    async def disconnect(self):
        pass
        
    @abstractmethod
    async def fetch_data(self, *args, **kwargs) -> Any:
        pass

class DataIngestionService:
    def __init__(self, providers: list[Provider], session):
        self.providers = {p.name: p for p in providers}
        self.session = session
        
    async def ingest_from_provider(self, provider_name: str, *args, **kwargs):
        provider = self.providers.get(provider_name)
        if not provider:
            raise ValueError(f"Provider {provider_name} not found")
            
        try:
            await provider.connect()
            data = await provider.fetch_data(*args, **kwargs)
            # Normalization and Persistence would follow here
            logger.info(f"Successfully ingested data from {provider_name}")
            return data
        except Exception as e:
            logger.error(f"Ingestion failed for {provider_name}: {e}")
            raise
        finally:
            await provider.disconnect()
