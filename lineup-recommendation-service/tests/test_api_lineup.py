from fastapi.testclient import TestClient

from app.presentation.main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_recommendations_happy_path():
    payload = {
        "matchId": 42,
        "players": [
            {
                "playerId": 7,
                "presenceRate": 0.86,
                "recentPerformanceRating": 7.2,
                "acuteChronicWorkloadRatio": 1.05,
                "daysSinceLastMatch": 3,
            }
        ],
    }
    response = client.post("/api/v1/lineup/recommendations", json=payload)
    assert response.status_code == 200
    body = response.json()
    assert body["matchId"] == 42
    assert "weightsVersion" in body
    rec = body["recommendations"][0]
    assert rec["playerId"] == 7
    assert 0 <= rec["finalScore"] <= 100
    assert rec["recommendedStatus"] in {"STARTER", "SUBSTITUTE", "NOT_SELECTED"}


def test_empty_players_rejected():
    response = client.post("/api/v1/lineup/recommendations", json={"matchId": 1, "players": []})
    assert response.status_code == 422


def test_out_of_range_presence_rate_rejected():
    payload = {
        "matchId": 1,
        "players": [
            {
                "playerId": 1,
                "presenceRate": 1.5,
                "recentPerformanceRating": 5.0,
                "acuteChronicWorkloadRatio": 1.0,
                "daysSinceLastMatch": 2,
            }
        ],
    }
    response = client.post("/api/v1/lineup/recommendations", json=payload)
    assert response.status_code == 422
