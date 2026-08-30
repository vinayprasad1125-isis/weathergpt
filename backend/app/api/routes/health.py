from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def root():
    return {"message": "WeatherGPT API"}

@router.get("/health")
async def health_check():
    return {
        "status": "ok",
        "service": "WeatherGPT API"
    }
