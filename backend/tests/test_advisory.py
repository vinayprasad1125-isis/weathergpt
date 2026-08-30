from fastapi.testclient import TestClient
from unittest.mock import patch, AsyncMock
from app.main import app
from app.schemas.weather import CurrentWeatherResponse, Location, CurrentWeather, SunInformation, WeatherSource

client = TestClient(app)

def get_mock_weather(*args, **kwargs):
    return CurrentWeatherResponse(
        location=Location(latitude=13.0, longitude=80.0, name="Mock", country="Mock"),
        current=CurrentWeather(temperature=30.0, feels_like=32.0, condition="Clear", humidity=50, wind_speed=10.0, wind_direction="N", visibility=10.0, pressure=1010, uv_index=5.0, precipitation=0.0, cloud_cover=10),
        sun=SunInformation(sunrise="06:00", sunset="18:00"),
        source=WeatherSource(provider="Mock")
    )

@patch("app.services.advisory.advisory_router.WeatherService.get_current_weather", new_callable=AsyncMock, side_effect=get_mock_weather)
@patch("app.services.advisory.advisory_router.AlertService.get_active_alerts", new_callable=AsyncMock, return_value=[])
def test_advisory_agriculture(mock_alerts, mock_weather):
    response = client.post("/api/v1/advisory", json={
        "domain": "agriculture",
        "location": {"latitude": 13.0827, "longitude": 80.2707},
        "time_range": "tomorrow"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["domain"] == "agriculture"
    assert "summary" in data

@patch("app.services.advisory.advisory_router.WeatherService.get_current_weather", new_callable=AsyncMock, side_effect=get_mock_weather)
@patch("app.services.advisory.advisory_router.AlertService.get_active_alerts", new_callable=AsyncMock, return_value=[])
def test_advisory_aviation(mock_alerts, mock_weather):
    response = client.post("/api/v1/advisory", json={
        "domain": "aviation",
        "location": {"latitude": 13.0827, "longitude": 80.2707}
    })
    assert response.status_code == 200
    data = response.json()
    assert data["domain"] == "aviation"

@patch("app.services.advisory.advisory_router.WeatherService.get_current_weather", new_callable=AsyncMock, side_effect=get_mock_weather)
@patch("app.services.advisory.advisory_router.AlertService.get_active_alerts", new_callable=AsyncMock, return_value=[])
def test_advisory_disaster(mock_alerts, mock_weather):
    response = client.post("/api/v1/advisory", json={
        "domain": "disaster",
        "location": {"latitude": 13.0827, "longitude": 80.2707}
    })
    assert response.status_code == 200
    data = response.json()
    assert data["domain"] == "disaster"

def test_advisory_invalid_domain():
    response = client.post("/api/v1/advisory", json={
        "domain": "unknown",
        "location": {"latitude": 13.0827, "longitude": 80.2707}
    })
    assert response.status_code == 400
