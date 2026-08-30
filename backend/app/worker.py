import asyncio
import logging
from app.services.ingestion.background_ingestion import start_mqtt_ingestion

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def run_worker():
    logger.info("Starting standalone Ingestion Worker...")
    # start_mqtt_ingestion runs an infinite asyncio background task
    start_mqtt_ingestion()
    
    # Keep the main thread alive to allow background task to run
    while True:
        await asyncio.sleep(3600)

if __name__ == "__main__":
    try:
        asyncio.run(run_worker())
    except KeyboardInterrupt:
        logger.info("Ingestion Worker shutting down.")
