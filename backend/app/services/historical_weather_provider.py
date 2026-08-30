import httpx
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.db.models import DBLocation, HistoricalWeather
import logging

logger = logging.getLogger(__name__)

class HistoricalWeatherProvider:
    async def fetch_and_store(self, lat: float, lon: float, start_date: str, end_date: str, db: AsyncSession):
        # Check if location exists
        result = await db.execute(select(DBLocation).filter(DBLocation.latitude == lat, DBLocation.longitude == lon))
        loc = result.scalars().first()
        if not loc:
            loc = DBLocation(name="Unknown", latitude=lat, longitude=lon)
            db.add(loc)
            await db.commit()
            await db.refresh(loc)

        # Basic check to avoid re-fetching large datasets unnecessarily (for MVP)
        existing = await db.execute(select(HistoricalWeather).filter(HistoricalWeather.location_id == loc.id).limit(1))
        if existing.scalars().first():
            return  # Already populated for this location

        # Fetch from Open-Meteo Archive API
        url = f"https://archive-api.open-meteo.com/v1/archive?latitude={lat}&longitude={lon}&start_date={start_date}&end_date={end_date}&daily=temperature_2m_mean,precipitation_sum,wind_speed_10m_max&timezone=auto"
        async with httpx.AsyncClient() as client:
            resp = await client.get(url, timeout=30.0)
            if resp.status_code != 200:
                logger.error(f"Failed to fetch historical data: {resp.text}")
                return

            data = resp.json().get('daily', {})
            times = data.get('time', [])
            temps = data.get('temperature_2m_mean', [])
            precips = data.get('precipitation_sum', [])
            winds = data.get('wind_speed_10m_max', [])
            
            records = []
            for i in range(len(times)):
                if temps[i] is None: continue
                records.append(HistoricalWeather(
                    location_id=loc.id,
                    timestamp=datetime.strptime(times[i], "%Y-%m-%d"),
                    temperature=temps[i],
                    rainfall=precips[i] if precips[i] is not None else 0.0,
                    wind_speed=winds[i] if winds[i] is not None else 0.0,
                    source="Open-Meteo Archive"
                ))
            
            db.add_all(records)
            await db.commit()
