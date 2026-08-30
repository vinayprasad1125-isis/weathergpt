from fastapi.testclient import TestClient
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
