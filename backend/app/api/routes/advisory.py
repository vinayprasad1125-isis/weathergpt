from fastapi import APIRouter
from app.schemas.advisory import AdvisoryRequest, AdvisoryResponse
from app.services.advisory.advisory_router import AdvisoryRouter

router = APIRouter()
advisory_router = AdvisoryRouter()

@router.post("", response_model=AdvisoryResponse)
async def get_advisory(request: AdvisoryRequest):
    return await advisory_router.process_advisory(request)
