from fastapi import APIRouter, Query, HTTPException
from typing import List, Optional
from app.schemas.alert import NormalizedAlert
from app.services.alert_service import AlertService

router = APIRouter()
alert_service = AlertService()

@router.get("", response_model=List[NormalizedAlert])
async def get_alerts(
    lat: Optional[float] = None,
    lon: Optional[float] = None,
    active: bool = True
):
    return await alert_service.get_active_alerts(lat, lon, active)

@router.get("/{alert_id}", response_model=NormalizedAlert)
async def get_alert(alert_id: str):
    alert = await alert_service.get_alert_by_id(alert_id)
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    return alert
