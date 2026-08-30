from fastapi import APIRouter, Query, HTTPException
from app.schemas.nwp import NWPForecastResponse
from app.services.nwp_service import NWPService

router = APIRouter()
nwp_service = NWPService()

@router.get("/forecast", response_model=NWPForecastResponse)
async def get_nwp_forecast(
    model: str = Query(..., description="NWP Model (gfs or wrf)"),
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude")
):
    return await nwp_service.get_forecast(model, lat, lon)
