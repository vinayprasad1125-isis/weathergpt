import httpx
from fastapi import HTTPException
from typing import List
from app.schemas.location import Location

# Exact coordinates used by the frontend map
INDIAN_STATES = {
    'andhra pradesh': (15.9129, 79.7400),
    'andhra': (15.9129, 79.7400),
    'arunachal pradesh': (28.2180, 94.7278),
    'assam': (26.2006, 92.9376),
    'bihar': (25.0961, 85.3131),
    'chhattisgarh': (21.2787, 81.8661),
    'goa': (15.2993, 74.1240),
    'gujarat': (22.2587, 71.1924),
    'haryana': (29.0588, 76.0856),
    'himachal pradesh': (31.1048, 77.1665),
    'jharkhand': (23.6102, 85.2799),
    'karnataka': (15.3173, 75.7139),
    'kerala': (10.8505, 76.2711),
    'madhya pradesh': (22.9734, 78.6569),
    'maharashtra': (19.7515, 75.7139),
    'manipur': (24.6637, 93.9063),
    'meghalaya': (25.4670, 91.3662),
    'mizoram': (23.1645, 92.9376),
    'nagaland': (26.1584, 94.5624),
    'odisha': (20.9517, 85.0985),
    'orissa': (20.9517, 85.0985),
    'punjab': (31.1471, 75.3412),
    'rajasthan': (27.0238, 74.2179),
    'sikkim': (27.5330, 88.5122),
    'tamil nadu': (11.1271, 78.6569),
    'tamilnadu': (11.1271, 78.6569),
    'telangana': (18.1124, 79.0193),
    'tripura': (23.9408, 91.9882),
    'uttar pradesh': (26.8467, 80.9462),
    'uttarakhand': (30.0668, 79.0193),
    'west bengal': (22.9868, 87.8550),
}

class LocationService:
    async def search(self, query: str) -> List[Location]:
        # Fast path for known Indian states to avoid OpenMeteo geocoding errors
        q_lower = query.lower().strip()
        if q_lower in INDIAN_STATES:
            lat, lon = INDIAN_STATES[q_lower]
            return [Location(
                name=query.title(),
                region=query.title(),
                country="India",
                latitude=lat,
                longitude=lon,
                timezone="Asia/Kolkata"
            )]

        url = f"https://geocoding-api.open-meteo.com/v1/search?name={query}&count=5&language=en&format=json"
        async with httpx.AsyncClient() as client:
            response = await client.get(url)
            if response.status_code != 200:
                raise HTTPException(status_code=502, detail="Failed to fetch location data")
            
            data = response.json()
            results = data.get('results', [])
            
            locations = []
            for r in results:
                locations.append(Location(
                    name=r.get('name', ''),
                    region=r.get('admin1', ''),
                    country=r.get('country', ''),
                    latitude=r.get('latitude', 0.0),
                    longitude=r.get('longitude', 0.0),
                    timezone=r.get('timezone', '')
                ))
            return locations
