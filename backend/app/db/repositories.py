from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List, Optional
from app.db.models import DBLocation, WeatherObservation, Forecast, Alert, User, Conversation, Message

class BaseRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

class LocationRepository(BaseRepository):
    async def get_by_coords(self, lat: float, lon: float) -> Optional[DBLocation]:
        result = await self.session.execute(
            select(DBLocation).where(DBLocation.latitude == lat, DBLocation.longitude == lon)
        )
        return result.scalars().first()

    async def create(self, data: dict) -> DBLocation:
        loc = DBLocation(**data)
        self.session.add(loc)
        await self.session.commit()
        await self.session.refresh(loc)
        return loc

class WeatherObservationRepository(BaseRepository):
    async def create(self, data: dict) -> WeatherObservation:
        obs = WeatherObservation(**data)
        self.session.add(obs)
        await self.session.commit()
        await self.session.refresh(obs)
        return obs
        
    async def get_latest_for_location(self, location_id: int) -> Optional[WeatherObservation]:
        result = await self.session.execute(
            select(WeatherObservation)
            .where(WeatherObservation.location_id == location_id)
            .order_by(WeatherObservation.timestamp.desc())
            .limit(1)
        )
        return result.scalars().first()
