from fastapi import APIRouter, Query
from app.schemas.location import LocationSearchResponse
from app.services.location_service import LocationService

router = APIRouter()
location_service = LocationService()

@router.get("/search", response_model=LocationSearchResponse)
async def search_location(q: str = Query(..., description="City or place name")):
    results = await location_service.search(q)
    return LocationSearchResponse(results=results)
