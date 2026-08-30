from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from app.schemas.chat import ChatRequest, ChatResponse, TTSRequest
from app.core.security import get_current_user, get_current_user_query
from app.services.ai_query_service import AIQueryService
from app.services.llm_service import OpenAILLMService

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

@router.get("/tts")
async def tts_endpoint(
    text: str,
    language: str = "en",
    current_user: dict = Depends(get_current_user_query)
):
    llm_service = OpenAILLMService()
    try:
        return StreamingResponse(
            llm_service.stream_tts(text),
            media_type="audio/mpeg"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
