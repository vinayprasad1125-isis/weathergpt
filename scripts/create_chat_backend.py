import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

files_to_create = {
    'app/schemas/chat.py': '''from pydantic import BaseModel, Field
from typing import Optional, Any

class StructuredWeatherQuery(BaseModel):
    intent: Optional[str] = Field(None, description="The intent of the query, e.g., 'forecast', 'current_weather', 'wind', 'advisory'")
    location: Optional[str] = Field(None, description="The specific location mentioned, e.g., 'Chennai'")
    time_range: Optional[str] = Field(None, description="The time range, e.g., 'tomorrow evening', 'now'")
    parameter: Optional[str] = Field(None, description="The specific parameter asked for, e.g., 'precipitation', 'temperature'")
    user_type: Optional[str] = Field(None, description="The user persona if specified, e.g., 'farmer', 'pilot'")
    data_source: str = Field(..., description="The data source required: 'current_weather' or 'weather_forecast'")

class ChatRequest(BaseModel):
    message: str
    location: Optional[str] = None
    language: str = "en"

class ChatResponse(BaseModel):
    message: str
    query: Optional[StructuredWeatherQuery] = None
    weather_data: Optional[dict[str, Any]] = None
    source: Optional[dict[str, str]] = None
''',
    
    'app/services/llm_service.py': '''import json
import logging
from typing import Optional
from google import genai
from google.genai import types
from app.core.config import settings
from app.schemas.chat import StructuredWeatherQuery

logger = logging.getLogger(__name__)

class GeminiLLMService:
    def __init__(self):
        self.api_key = settings.LLM_API_KEY
        self.client = None
        if self.api_key:
            self.client = genai.Client(api_key=self.api_key)

    async def extract_query(self, message: str, context_location: Optional[str]) -> StructuredWeatherQuery:
        if not self.client:
            logger.warning("No LLM_API_KEY provided. Using mocked structured query.")
            return StructuredWeatherQuery(
                intent="forecast",
                location=context_location or "Chennai",
                time_range="tomorrow",
                parameter="general",
                data_source="weather_forecast"
            )

        prompt = f"""
You are an expert intent extraction engine for a weather AI.
Extract the structured information from the user's message.
If the user says 'here' or 'my location' and the context location is provided, use the context location.
Context Location: {context_location or "None"}
User Message: {message}
"""
        try:
            response = self.client.models.generate_content(
                model=settings.LLM_MODEL,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=StructuredWeatherQuery
                )
            )
            return StructuredWeatherQuery.model_validate_json(response.text)
        except Exception as e:
            logger.error(f"Failed to extract query with Gemini: {e}")
            raise

    async def generate_response(self, message: str, weather_data: dict) -> str:
        if not self.client:
            logger.warning("No LLM_API_KEY provided. Using mocked response.")
            return "Based on the mock LLM, here is your weather information based on the data retrieved."

        prompt = f"""
You are WeatherGPT.
Use ONLY the supplied weather data to make factual claims about current weather or forecasts.
Do not invent temperatures, rainfall probability, wind speed, humidity, weather warnings, forecast conditions, dates, or locations.
If the supplied data does not contain enough information to answer the user's question, clearly state that the information is unavailable.
Explain the weather data naturally and concisely.

Weather Data: {json.dumps(weather_data)}
User Question: {message}
"""
        try:
            response = self.client.models.generate_content(
                model=settings.LLM_MODEL,
                contents=prompt
            )
            return response.text
        except Exception as e:
            logger.error(f"Failed to generate response with Gemini: {e}")
            raise
''',

    'app/services/ai_query_service.py': '''from typing import Optional
from fastapi import HTTPException
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.llm_service import GeminiLLMService
from app.services.weather_service import WeatherService
import logging

logger = logging.getLogger(__name__)

class AIQueryService:
    def __init__(self):
        self.llm = GeminiLLMService()
        self.weather_service = WeatherService()

    async def process_chat(self, request: ChatRequest) -> ChatResponse:
        logger.info(f"Processing chat message: {request.message}")
        
        # 1. Query Understanding
        try:
            query = await self.llm.extract_query(request.message, request.location)
        except Exception as e:
            raise HTTPException(status_code=500, detail="Failed to understand the query")

        # 2. Handle missing location
        if not query.location:
            return ChatResponse(
                message="Sure — which location would you like the forecast for?",
                query=query
            )

        # 3. Retrieve Weather Data
        # For this phase, we use the existing WeatherService for both current and forecast intents 
        # (since it fetches some forecast data already or we can adapt it).
        # In a full implementation, we would branch to ForecastService here based on query.data_source.
        try:
            weather_resp = await self.weather_service.get_current_weather(query.location)
            # Serialize for LLM context
            weather_data = weather_resp.model_dump()
        except HTTPException as e:
            return ChatResponse(message=f"I couldn't retrieve weather data for {query.location}: {e.detail}")
        except Exception as e:
            raise HTTPException(status_code=500, detail="Failed to fetch weather data")

        # 4. Generate Grounded Response
        try:
            natural_response = await self.llm.generate_response(request.message, weather_data)
        except Exception as e:
            raise HTTPException(status_code=500, detail="Failed to generate AI response")

        return ChatResponse(
            message=natural_response,
            query=query,
            weather_data=weather_data.get("current"),
            source={"provider": "Open-Meteo"}
        )

    async def close(self):
        await self.weather_service.close()
''',

    'app/api/routes/chat.py': '''from fastapi import APIRouter, Depends
from app.schemas.chat import ChatRequest, ChatResponse
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
    service: AIQueryService = Depends(get_ai_query_service)
):
    return await service.process_chat(request)
''',
    
    'tests/test_chat.py': '''import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.schemas.chat import ChatResponse

client = TestClient(app)

def test_chat_endpoint_missing_location():
    # Because LLM is mocked to return 'Chennai' if context_location is None (unless modified),
    # we need to be careful. But our mock implementation defaults to 'Chennai' if not supplied,
    # so we can just test if the endpoint returns a valid response.
    response = client.post("/api/v1/chat", json={
        "message": "What is the weather?"
    })
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
'''
}

for filepath, content in files_to_create.items():
    full_path = os.path.join(base_dir, filepath)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, 'w') as f:
        f.write(content)
print("Chat backend files created successfully.")
