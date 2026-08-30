from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.db.database import get_db

router = APIRouter()

@router.get("/ingestion/status")
async def ingestion_status(db: AsyncSession = Depends(get_db)):
    try:
        await db.execute(text("SELECT 1"))
        db_status = "Healthy"
    except Exception as e:
        db_status = f"Unhealthy: {str(e)}"
        
    return {
        "database": db_status,
        "providers": {
            "HTTP_REST_PROVIDER": {"status": "Ready", "last_attempt": "N/A"},
            "MQTT_BROKER_PROVIDER": {"status": "Ready", "last_attempt": "N/A"},
            "WIS2_GLOBAL_PROVIDER": {"status": "Ready", "last_attempt": "N/A"}
        }
    }
