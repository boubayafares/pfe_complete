import pytest
from fastapi.testclient import TestClient

from app.presentation.main import app, create_app

client = TestClient(app)


def test_health():
    assert client.get("/health").json() == {"status": "ok"}


def test_trend_endpoint():
    payload = {
        "playerId": 7,
        "points": [
            {"date": "2026-01-01T00:00:00", "value": 5.0},
            {"date": "2026-02-01T00:00:00", "value": 6.0},
            {"date": "2026-03-01T00:00:00", "value": 7.0},
        ],
    }
    response = client.post("/api/v1/trend/detect", json=payload)
    assert response.status_code == 200
    body = response.json()
    assert body["playerId"] == 7
    assert body["direction"] == "PROGRESSING"


def test_trend_endpoint_insufficient_data():
    payload = {"playerId": 7, "points": [{"date": "2026-01-01T00:00:00", "value": 5.0}]}
    response = client.post("/api/v1/trend/detect", json=payload)
    assert response.status_code == 422


def test_clustering_endpoint():
    payload = {
        "players": [
            {"playerId": 1, "goalsPerMatch": 1.2, "assistsPerMatch": 0.1, "minutesPerMatch": 70, "heightCm": 178, "weightKg": 72},
            {"playerId": 2, "goalsPerMatch": 1.0, "assistsPerMatch": 0.2, "minutesPerMatch": 65, "heightCm": 180, "weightKg": 75},
            {"playerId": 3, "goalsPerMatch": 0.05, "assistsPerMatch": 0.6, "minutesPerMatch": 88, "heightCm": 172, "weightKg": 65},
            {"playerId": 4, "goalsPerMatch": 0.1, "assistsPerMatch": 0.5, "minutesPerMatch": 90, "heightCm": 174, "weightKg": 68},
        ],
        "nClusters": 2,
    }
    response = client.post("/api/v1/clustering/players", json=payload)
    assert response.status_code == 200
    body = response.json()
    assert body["nClusters"] == 2
    assert len(body["assignments"]) == 4


def test_tone_endpoint():
    response = client.post("/api/v1/tone/analyze", json={"comment": "Ce joueur est nul."})
    assert response.status_code == 200
    body = response.json()
    assert body["flag"] == "TOO_HARSH"
    assert body["suggestion"] is not None


def test_service_token_protects_ai_endpoints_but_not_health(monkeypatch):
    monkeypatch.setenv("AI_INSIGHTS_SERVICE_TOKEN", "test-service-token")
    secured_client = TestClient(create_app())
    assert secured_client.get("/health").status_code == 200
    assert secured_client.post("/api/v1/tone/analyze", json={"comment": "Bien."}).status_code == 401
    response = secured_client.post(
        "/api/v1/tone/analyze",
        json={"comment": "Bien."},
        headers={"X-Service-Token": "test-service-token"},
    )
    assert response.status_code == 200
