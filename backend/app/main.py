from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import health, weather, chat, nwp, alerts, location, advisory, climate, gis, system, auth
from app.db.database import engine, Base
import logging

logging.basicConfig(level=logging.INFO)

app = FastAPI(title="WeatherGPT API")

@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Configured broadly for development, adjust for prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(weather.router, prefix="/api/v1/weather", tags=["Weather"])
app.include_router(chat.router, prefix="/api/v1/chat", tags=["Chat"])
app.include_router(nwp.router, prefix="/api/v1/nwp", tags=["NWP"])
app.include_router(alerts.router, prefix="/api/v1/alerts", tags=["Alerts"])
app.include_router(location.router, prefix="/api/v1/location", tags=["Location"])
app.include_router(advisory.router, prefix="/api/v1/advisory", tags=["Advisory"])
app.include_router(climate.router, prefix="/api/v1/climate", tags=["Climate"])
app.include_router(gis.router, prefix="/api/v1/gis", tags=["GIS"])

app.include_router(system.router, prefix="/api/v1/system", tags=["System"])