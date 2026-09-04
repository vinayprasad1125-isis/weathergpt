import asyncio
import logging
from app.services.ingestion.background_ingestion import start_mqtt_ingestion
from app.services.sachet_service import SachetService
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def run_worker():
    logger.info("Starting standalone Ingestion Worker...")
    # start_mqtt_ingestion runs an infinite asyncio background task
    start_mqtt_ingestion()
    
    sachet_service = SachetService()
    poll_interval = int(os.getenv("SACHET_POLL_INTERVAL_MINUTES", "5"))
    logger.info(f"Starting SACHET polling every {poll_interval} minutes.")
    
    # Keep the main thread alive to allow background task to run
    while True:
        try:
            await sachet_service.poll_sachet_alerts()
        except Exception as e:
            logger.error(f"Error in SACHET polling loop: {e}")
        await asyncio.sleep(poll_interval * 60)

if __name__ == "__main__":
    try:
        asyncio.run(run_worker())
    except KeyboardInterrupt:
        logger.info("Ingestion Worker shutting down.")
