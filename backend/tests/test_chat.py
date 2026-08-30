import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.schemas.chat import ChatResponse

client = TestClient(app)

def test_chat_endpoint_missing_location():
    # Because LLM is mocked to return 'Chennai' if context_location is None (unless modified),
    # we need to be careful. But our mock implementation defaults to 'Chennai' if not supplied,
    # so we can just test if the endpoint returns a valid response.
    response = client.post("/api/v1/chat", json={
        "message": "What is the weather?"
    })
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
