from fastapi import APIRouter, HTTPException, Query
from app.schemas.gis import GISLayer
from app.services.gis_service import GISService

router = APIRouter()
gis_service = GISService()

@router.get("/layers/{layer_type}", response_model=GISLayer)
async def get_gis_layer(layer_type: str, lat: float = Query(...), lon: float = Query(...)):
    """
    Available layers: temperature, wind, rainfall, alerts, cyclones, flood
    """
    valid_layers = ["temperature", "wind", "rainfall", "alerts", "cyclones", "flood"]
    if layer_type not in valid_layers:
        raise HTTPException(status_code=400, detail=f"Invalid layer type. Must be one of {valid_layers}")
        
    return await gis_service.get_layer(layer_type, lat, lon)
