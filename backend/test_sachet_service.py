import asyncio
from app.services.sachet_service import SachetService
import logging

logging.basicConfig(level=logging.INFO)

async def test():
    service = SachetService()
    await service.poll_sachet_alerts()

if __name__ == "__main__":
    asyncio.run(test())
