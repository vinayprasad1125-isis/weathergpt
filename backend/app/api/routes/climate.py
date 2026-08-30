from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.climate import ClimateAnalyzeRequest
from app.db.database import get_db
from app.services.climate_analytics_service import ClimateAnalyticsService
from app.services.historical_weather_provider import HistoricalWeatherProvider

router = APIRouter()
analytics = ClimateAnalyticsService()
provider = HistoricalWeatherProvider()

@router.post("/analyze")
async def analyze_climate(req: ClimateAnalyzeRequest, db: AsyncSession = Depends(get_db)):
    # Trigger ingestion if not exists
    await provider.fetch_and_store(req.location.latitude, req.location.longitude, req.time_range.start, req.time_range.end, db)
    
    # Calculate
    result = await analytics.analyze(req, db)
    if not result:
        raise HTTPException(status_code=404, detail="No historical data available for this range.")
    return result
