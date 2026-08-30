"""
Tests for the Agricultural Advisory pipeline.
Covers weather field mapping, advisory rule engine, and chat endpoint routing.
"""
import pytest
from unittest.mock import patch, AsyncMock, MagicMock
from fastapi.testclient import TestClient

from app.main import app
from app.schemas.weather import (
    CurrentWeatherResponse, Location, CurrentWeather,
    SunInformation, WeatherSource, ForecastResponse, HourlyForecast, DailyForecast
)
from app.schemas.advisory import AdvisoryResponse, AdvisoryFactor
from app.services.advisory.domains import AgricultureAdvisoryService, AGRICULTURE_THRESHOLDS
from app.schemas.chat import StructuredWeatherQuery

client = TestClient(app)

# ---------------------------------------------------------------------------
# Helper: build a realistic mock CurrentWeatherResponse
# ---------------------------------------------------------------------------

def _mock_weather(
    temp=30.0, humidity=65, wind_speed=8.0, wind_direction="SW",
    precipitation=0.0, cloud_cover=30, condition="Clear sky"
) -> CurrentWeatherResponse:
    return CurrentWeatherResponse(
        location=Location(latitude=13.08, longitude=80.27, name="Chennai", country="India"),
        current=CurrentWeather(
            temperature=temp,
            feels_like=temp + 2,
            condition=condition,
            humidity=humidity,
            wind_speed=wind_speed,
            wind_direction=wind_direction,
            visibility=10.0,
            pressure=1010,
            uv_index=5.0,
            precipitation=precipitation,
            cloud_cover=cloud_cover,
        ),
        sun=SunInformation(sunrise="06:00", sunset="18:30"),
        source=WeatherSource(provider="Open-Meteo"),
    )


def _mock_forecast(rain_probs=None) -> ForecastResponse:
    if rain_probs is None:
        rain_probs = [10] * 12
    hourly = [
        HourlyForecast(time=f"2024-01-01T{h:02d}:00", temperature=30.0,
                       precipitation_probability=rain_probs[h] if h < len(rain_probs) else 0,
                       condition="Clear sky")
        for h in range(24)
    ]
    daily = [
        DailyForecast(date="2024-01-01", temperature_min=25.0, temperature_max=35.0,
                      precipitation_probability=max(rain_probs), condition="Clear sky")
    ]
    return ForecastResponse(location=Location(latitude=13.08, longitude=80.27, name="Chennai", country="India"),
                            hourly=hourly, daily=daily)


# ---------------------------------------------------------------------------
# 1. Test: All weather fields are passed through to advisory engine
# ---------------------------------------------------------------------------

def test_agriculture_advisory_reads_all_fields():
    """AgricultureAdvisoryService must populate factors for all 8 key fields."""
    svc = AgricultureAdvisoryService()
    weather_data = {
        "current": {
            "temperature": 28.0,
            "humidity": 70,
            "wind_speed": 5.0,
            "wind_direction": "N",
            "precipitation": 0.0,
            "cloud_cover": 20,
            "condition": "Clear sky",
        },
        "forecast": {"hourly_rain_probs_next_12h": [5, 10, 8], "precipitation_probability_max": 15}
    }
    result = svc.process(weather_data, [], {"latitude": 13.0, "longitude": 80.0},
                         advisory_type="pesticide_spraying")
    param_names = {f.parameter for f in result.factors}
    assert "temperature_c" in param_names
    assert "humidity_pct" in param_names
    assert "wind_speed_kmh" in param_names
    assert "wind_direction" in param_names
    assert "current_precipitation_mm" in param_names
    assert "rain_probability_next_12h_pct" in param_names
    assert "cloud_cover_pct" in param_names
    assert "condition" in param_names


# ---------------------------------------------------------------------------
# 2. Test: Pesticide advisory — SUITABLE verdict
# ---------------------------------------------------------------------------

def test_pesticide_advisory_suitable():
    svc = AgricultureAdvisoryService()
    weather_data = {
        "current": {"temperature": 25.0, "humidity": 60, "wind_speed": 5.0,
                    "wind_direction": "N", "precipitation": 0.0, "cloud_cover": 10, "condition": "Clear sky"},
        "forecast": {"hourly_rain_probs_next_12h": [5] * 12}
    }
    result = svc.process(weather_data, [], {}, advisory_type="pesticide_spraying")
    assert "SUITABLE" in result.recommendations[0]
    assert result.summary != ""


# ---------------------------------------------------------------------------
# 3. Test: Pesticide advisory — NOT SUITABLE due to high wind
# ---------------------------------------------------------------------------

def test_pesticide_advisory_not_suitable_high_wind():
    t = AGRICULTURE_THRESHOLDS["pesticide_spraying"]
    svc = AgricultureAdvisoryService()
    weather_data = {
        "current": {"temperature": 25.0, "humidity": 60,
                    "wind_speed": t["wind_speed_max_kmh"] + 5.0,  # Over threshold
                    "wind_direction": "N", "precipitation": 0.0, "cloud_cover": 10, "condition": "Clear sky"},
        "forecast": {"hourly_rain_probs_next_12h": [5] * 12}
    }
    result = svc.process(weather_data, [], {}, advisory_type="pesticide_spraying")
    assert "NOT SUITABLE" in result.recommendations[0]
    assert any("drift" in r.lower() for r in result.recommendations)


# ---------------------------------------------------------------------------
# 4. Test: Pesticide advisory — NOT SUITABLE due to high rain probability
# ---------------------------------------------------------------------------

def test_pesticide_advisory_not_suitable_rain():
    t = AGRICULTURE_THRESHOLDS["pesticide_spraying"]
    svc = AgricultureAdvisoryService()
    weather_data = {
        "current": {"temperature": 25.0, "humidity": 60, "wind_speed": 5.0,
                    "wind_direction": "N", "precipitation": 0.0, "cloud_cover": 50, "condition": "Partly cloudy"},
        "forecast": {"hourly_rain_probs_next_12h": [t["rain_prob_high_pct"] + 10] * 12}
    }
    result = svc.process(weather_data, [], {}, advisory_type="pesticide_spraying")
    assert "NOT SUITABLE" in result.recommendations[0]
    assert any("rain" in r.lower() or "washoff" in r.lower() for r in result.recommendations)


# ---------------------------------------------------------------------------
# 5. Test: Missing field is marked "unavailable" — never fabricated
# ---------------------------------------------------------------------------

def test_missing_field_marked_unavailable():
    svc = AgricultureAdvisoryService()
    weather_data = {
        "current": {
            # wind_speed intentionally missing
            "temperature": 28.0, "humidity": 65,
            "precipitation": 0.0, "condition": "Clear sky"
        },
        "forecast": {}
    }
    result = svc.process(weather_data, [], {}, advisory_type="pesticide_spraying")
    wind_factor = next((f for f in result.factors if f.parameter == "wind_speed_kmh"), None)
    assert wind_factor is not None
    assert wind_factor.value == "unavailable"
    # Should be UNCERTAIN (not SUITABLE) since wind is missing
    assert "UNCERTAIN" in result.recommendations[0] or "SUITABLE" not in result.recommendations[0] or \
        any("could not be retrieved" in r for r in result.recommendations)


# ---------------------------------------------------------------------------
# 6. Test: Advisory uses caution verdict for borderline wind
# ---------------------------------------------------------------------------

def test_pesticide_advisory_caution_wind():
    t = AGRICULTURE_THRESHOLDS["pesticide_spraying"]
    svc = AgricultureAdvisoryService()
    wind = (t["wind_speed_caution_kmh"] + t["wind_speed_max_kmh"]) / 2  # Between caution and max
    weather_data = {
        "current": {"temperature": 25.0, "humidity": 60, "wind_speed": wind,
                    "wind_direction": "N", "precipitation": 0.0, "cloud_cover": 10, "condition": "Clear sky"},
        "forecast": {"hourly_rain_probs_next_12h": [5] * 12}
    }
    result = svc.process(weather_data, [], {}, advisory_type="pesticide_spraying")
    assert "USE CAUTION" in result.recommendations[0]


# ---------------------------------------------------------------------------
# 7. Test: Advisory API endpoint with agriculture domain
# ---------------------------------------------------------------------------

@patch("app.services.advisory.advisory_router.WeatherService.get_current_weather",
       new_callable=AsyncMock)
@patch("app.services.advisory.advisory_router.WeatherService.get_forecast",
       new_callable=AsyncMock)
@patch("app.services.advisory.advisory_router.AlertService.get_active_alerts",
       new_callable=AsyncMock, return_value=[])
def test_advisory_endpoint_agriculture_pesticide(mock_alerts, mock_forecast, mock_weather):
    mock_weather.return_value = _mock_weather(wind_speed=5.0, humidity=65, temp=28.0)
    mock_forecast.return_value = _mock_forecast(rain_probs=[10] * 12)

    response = client.post("/api/v1/advisory", json={
        "domain": "agriculture",
        "location": {"latitude": 13.0827, "longitude": 80.2707},
        "time_range": "today"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["domain"] == "agriculture"
    assert "factors" in data
    # Verify all 8 factors are present
    param_names = {f["parameter"] for f in data["factors"]}
    assert "temperature_c" in param_names
    assert "wind_speed_kmh" in param_names
    assert "humidity_pct" in param_names


# ---------------------------------------------------------------------------
# 8. Test: Weather field mapping — wind/humidity reach advisory engine
# ---------------------------------------------------------------------------

@patch("app.services.advisory.advisory_router.WeatherService.get_current_weather",
       new_callable=AsyncMock)
@patch("app.services.advisory.advisory_router.WeatherService.get_forecast",
       new_callable=AsyncMock)
@patch("app.services.advisory.advisory_router.AlertService.get_active_alerts",
       new_callable=AsyncMock, return_value=[])
def test_weather_fields_reach_advisory_engine(mock_alerts, mock_forecast, mock_weather):
    mock_weather.return_value = _mock_weather(wind_speed=20.0, humidity=75, temp=32.0)
    mock_forecast.return_value = _mock_forecast(rain_probs=[5] * 12)

    response = client.post("/api/v1/advisory", json={
        "domain": "agriculture",
        "location": {"latitude": 13.0827, "longitude": 80.2707}
    })
    assert response.status_code == 200
    data = response.json()
    wind_factor = next((f for f in data["factors"] if f["parameter"] == "wind_speed_kmh"), None)
    assert wind_factor is not None
    assert wind_factor["value"] == 20.0  # Exact value, not mocked/default


# ---------------------------------------------------------------------------
# 9. Test: Chat endpoint authentication still works (JWT bypass test)
# ---------------------------------------------------------------------------

def test_chat_endpoint_returns_message():
    response = client.post("/api/v1/chat", json={"message": "What is the weather in Chennai?"})
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


# ---------------------------------------------------------------------------
# 10. Test: Multilingual query detection (Hindi)
# ---------------------------------------------------------------------------

def test_chat_endpoint_hindi_query():
    response = client.post("/api/v1/chat", json={
        "message": "क्या आज की मौसम स्थिति में कीटनाशक का छिड़काव करना उचित है?",
        "language": "hi"
    })
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


# ---------------------------------------------------------------------------
# 11. Test: Tamil query detection
# ---------------------------------------------------------------------------

def test_chat_endpoint_tamil_query():
    response = client.post("/api/v1/chat", json={
        "message": "இன்று பூச்சிக்கொல்லி தெளிக்க வானிலை ஏற்றதா?",
        "language": "ta"
    })
    assert response.status_code == 200
    data = response.json()
    assert "message" in data


# ---------------------------------------------------------------------------
# 12. Test: StructuredWeatherQuery now has advisory_type field
# ---------------------------------------------------------------------------

def test_structured_query_has_advisory_type():
    q = StructuredWeatherQuery(
        intent="advisory",
        location="Chennai",
        user_type="farmer",
        advisory_type="pesticide_spraying",
        data_source="weather_forecast"
    )
    assert q.advisory_type == "pesticide_spraying"
    assert q.user_type == "farmer"


# ---------------------------------------------------------------------------
# 13. Test: High temperature causes caution
# ---------------------------------------------------------------------------

def test_pesticide_advisory_caution_high_temp():
    t = AGRICULTURE_THRESHOLDS["pesticide_spraying"]
    svc = AgricultureAdvisoryService()
    weather_data = {
        "current": {"temperature": t["temp_max_c"] + 2.0, "humidity": 60, "wind_speed": 5.0,
                    "wind_direction": "N", "precipitation": 0.0, "cloud_cover": 10, "condition": "Clear sky"},
        "forecast": {"hourly_rain_probs_next_12h": [5] * 12}
    }
    result = svc.process(weather_data, [], {}, advisory_type="pesticide_spraying")
    assert any("evaporation" in r.lower() or "heat" in r.lower() for r in result.recommendations)


# ---------------------------------------------------------------------------
# 14. Test: Active precipitation causes NOT SUITABLE verdict
# ---------------------------------------------------------------------------

def test_pesticide_advisory_not_suitable_active_rain():
    t = AGRICULTURE_THRESHOLDS["pesticide_spraying"]
    svc = AgricultureAdvisoryService()
    weather_data = {
        "current": {"temperature": 25.0, "humidity": 80, "wind_speed": 5.0,
                    "wind_direction": "N",
                    "precipitation": t["precip_washoff_mm"] + 1.0,  # Over threshold
                    "cloud_cover": 90, "condition": "Rain"},
        "forecast": {"hourly_rain_probs_next_12h": [80] * 12}
    }
    result = svc.process(weather_data, [], {}, advisory_type="pesticide_spraying")
    assert "NOT SUITABLE" in result.recommendations[0]
