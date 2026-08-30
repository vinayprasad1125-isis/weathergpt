from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_location_search():
    response = client.get("/api/v1/location/search?q=Coimbatore")
    assert response.status_code == 200
    data = response.json()
    assert len(data["results"]) >= 1
    assert data["results"][0]["name"].lower() == "coimbatore"
    assert "latitude" in data["results"][0]

def test_location_search_not_found():
    # Attempting to search something completely garbage should return 200 with empty list from open-meteo
    response = client.get("/api/v1/location/search?q=XYZINVALIDGARBAGETOWN123")
    assert response.status_code == 200
    data = response.json()
    assert len(data["results"]) == 0
