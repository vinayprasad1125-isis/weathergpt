import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_auth_login_success():
    response = client.post("/api/v1/auth/login", data={"username": "user", "password": "password"})
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_auth_login_failure():
    response = client.post("/api/v1/auth/login", data={"username": "wrong", "password": "wrong"})
    assert response.status_code == 401

def test_chat_secured_without_token():
    # Because chat is secured with Depends(get_current_user), it should fail 401
    response = client.post("/api/v1/chat", json={"query": "hello", "location": {"latitude": 13, "longitude": 80}})
    assert response.status_code == 401

def test_nwp_wrf_disabled():
    response = client.get("/api/v1/nwp/forecast?model=wrf&lat=13.08&lon=80.27")
    assert response.status_code == 501
    assert "WRF data provider is currently unavailable" in response.json()["detail"]

def test_gis_feature_endpoint():
    response = client.get("/api/v1/gis/layers/temperature?lat=13.0827&lon=80.2707")
    # Will be 200 even if provider is down, returning empty features, but the endpoint exists and isn't mocked
    assert response.status_code == 200
    assert "features" in response.json()
