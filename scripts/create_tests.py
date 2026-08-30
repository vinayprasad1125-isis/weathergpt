import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'
tests = {
    'tests/test_nwp.py': '''from fastapi.testclient import TestClient
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
''',
    
    'tests/test_alerts.py': '''from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_get_active_alerts():
    response = client.get("/api/v1/alerts")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 1
    assert data[0]["id"] == "TEST-ALERT-001"

def test_get_alert_by_id():
    response = client.get("/api/v1/alerts/TEST-ALERT-001")
    assert response.status_code == 200
    data = response.json()
    assert data["headline"].startswith("DEMO ALERT")

def test_get_alert_by_id_not_found():
    response = client.get("/api/v1/alerts/NON-EXISTENT")
    assert response.status_code == 404
'''
}

for filepath, content in tests.items():
    full_path = os.path.join(base_dir, filepath)
    with open(full_path, 'w') as f:
        f.write(content)

print("Tests created.")
