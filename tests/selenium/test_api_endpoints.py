import requests
import pytest


class TestHealthEndpoint:
    def test_health_returns_ok(self, base_url):
        response = requests.get(f"{base_url}/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert "timestamp" in data

    def test_health_returns_json(self, base_url):
        response = requests.get(f"{base_url}/health")
        assert "application/json" in response.headers["content-type"]


class TestAuthEndpoints:
    def test_login_requires_body(self, base_url):
        response = requests.post(f"{base_url}/api/v1/auth/login", json={})
        assert response.status_code in [400, 422]

    def test_login_invalid_credentials(self, base_url):
        response = requests.post(f"{base_url}/api/v1/auth/login", json={
            "email": "test@test.com",
            "password": "wrongpassword"
        })
        assert response.status_code in [400, 401, 422]


class TestProtectedEndpoints:
    def test_teams_requires_auth(self, base_url):
        response = requests.get(f"{base_url}/api/v1/teams")
        assert response.status_code == 401

    def test_players_requires_auth(self, base_url):
        response = requests.get(f"{base_url}/api/v1/players")
        assert response.status_code == 401

    def test_matches_requires_auth(self, base_url):
        response = requests.get(f"{base_url}/api/v1/matches")
        assert response.status_code == 401
