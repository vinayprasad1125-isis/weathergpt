from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_get_nwp_forecast_gfs():
    # Since GFS is a live Open-Meteo endpoint, this will actually make a request
    # and verify normalization works correctly.
    response = client.get("/api/v1/nwp/forecast?model=gfs&lat=13.08&lon=80.27")
    assert response.status_code == 200
    data = response.json()
    assert data["model"] == "GFS"
    assert "temperature" in data["variables"]

def test_get_nwp_forecast_wrf():
    # WRF is our test fixture
    response = client.get("/api/v1/nwp/forecast?model=wrf&lat=13.08&lon=80.27")
    assert response.status_code == 200
    data = response.json()
    assert data["model"] == "WRF"
    assert data["variables"]["temperature"] == 31.2

def test_get_nwp_forecast_invalid():
    response = client.get("/api/v1/nwp/forecast?model=unknown&lat=13.08&lon=80.27")
    assert response.status_code == 400
