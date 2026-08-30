from fastapi import APIRouter, Depends
from app.schemas.chat import ChatRequest, ChatResponse
from app.core.security import get_current_user
from app.services.ai_query_service import AIQueryService

router = APIRouter()

async def get_ai_query_service():
    service = AIQueryService()
    try:
        yield service
    finally:
        await service.close()

@router.post("", response_model=ChatResponse)
async def chat_endpoint(
    request: ChatRequest,
    service: AIQueryService = Depends(get_ai_query_service),
    current_user: dict = Depends(get_current_user)
):
    return await service.process_chat(request)
