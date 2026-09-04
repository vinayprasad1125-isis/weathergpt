from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Any
from app.clients.aviation_client import aviation_client

router = APIRouter()

@router.get("/metar", response_model=List[Dict[str, Any]])
async def get_metar(station: str = Query(..., description="ICAO Station ID (e.g. VOMM)")):
    data = await aviation_client.get_metar(station.upper())
    if not data:
        raise HTTPException(status_code=404, detail=f"No METAR data found for station {station}")
    return data

@router.get("/taf", response_model=List[Dict[str, Any]])
async def get_taf(station: str = Query(..., description="ICAO Station ID (e.g. VOMM)")):
    data = await aviation_client.get_taf(station.upper())
    if not data:
        raise HTTPException(status_code=404, detail=f"No TAF data found for station {station}")
    return data
