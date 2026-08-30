import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'
tests = {
    'tests/test_location.py': '''from fastapi.testclient import TestClient
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
''',
    
    'tests/test_advisory.py': '''from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_advisory_agriculture():
    response = client.post("/api/v1/advisory", json={
        "domain": "agriculture",
        "location": {"latitude": 13.0827, "longitude": 80.2707},
        "time_range": "tomorrow"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["domain"] == "agriculture"
    assert "summary" in data

def test_advisory_aviation():
    response = client.post("/api/v1/advisory", json={
        "domain": "aviation",
        "location": {"latitude": 13.0827, "longitude": 80.2707}
    })
    assert response.status_code == 200
    data = response.json()
    assert data["domain"] == "aviation"

def test_advisory_disaster():
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
'''
}

for filepath, content in tests.items():
    full_path = os.path.join(base_dir, filepath)
    with open(full_path, 'w') as f:
        f.write(content)

print("Location and Advisory tests created.")
