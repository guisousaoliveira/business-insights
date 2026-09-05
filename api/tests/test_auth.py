"""
Testes unitários e de integração para o módulo de autenticação (/auth) e segurança (JWT).
"""

import uuid
import pytest
from unittest.mock import MagicMock
from fastapi.testclient import TestClient
from jose import jwt

import os
os.environ.setdefault("SUPABASE_URL", "https://mock.supabase.co")
os.environ.setdefault("SUPABASE_SERVICE_KEY", "mock-service-key")
os.environ.setdefault("SUPABASE_ANON_KEY", "mock-anon-key")
os.environ.setdefault("SUPABASE_JWT_SECRET", "mock-jwt-secret-very-long-and-secure-123456")
os.environ.setdefault("N8N_SECRET", "mock-n8n-secret")

from app.main import app
from app.core.security import usuario_atual
from app.core.supabase_client import get_supabase, get_supabase_auth


TEST_USER_ID = str(uuid.uuid4())
TEST_SALAO_ID = str(uuid.uuid4())
JWT_SECRET = "mock-jwt-secret-very-long-and-secure-123456"


@pytest.fixture(autouse=True)
def mock_jwt_settings(monkeypatch):
    from app.core.config import get_settings
    settings = get_settings()
    monkeypatch.setattr(settings, "supabase_jwt_secret", JWT_SECRET)


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def valid_jwt_token():
    payload = {
        "sub": TEST_USER_ID,
        "email": "teste@salao.app",
        "aud": "authenticated",
        "exp": 9999999999,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")


class TestSecurityJWT:
    def test_missing_authorization_header(self, client):
        response = client.get("/v1/auth/eu")
        assert response.status_code == 401
        data = response.json()
        assert data["codigo"] == "AUTH_TOKEN_AUSENTE"
        assert "mensagem" in data
        assert data["result"] is None

    def test_invalid_token(self, client):
        response = client.get(
            "/v1/auth/eu",
            headers={"Authorization": "Bearer invalid.token.here"},
        )
        assert response.status_code == 401
        data = response.json()
        assert data["codigo"] == "AUTH_TOKEN_AUSENTE"

    def test_valid_token_decoding(self, valid_jwt_token):
        user_id = usuario_atual(f"Bearer {valid_jwt_token}")
        assert user_id == TEST_USER_ID


class TestAuthEndpoints:
    def test_login_success(self, client):
        mock_auth_resp = MagicMock()
        mock_auth_resp.session.access_token = "mock-access-token"
        mock_auth_resp.session.refresh_token = "mock-refresh-token"
        mock_auth_resp.session.expires_in = 3600
        mock_auth_resp.user.id = TEST_USER_ID
        mock_auth_resp.user.email = "teste@salao.app"
        mock_auth_resp.user.user_metadata = {"nome": "Thamires Borges"}

        mock_sb_auth = MagicMock()
        mock_sb_auth.auth.sign_in_with_password.return_value = mock_auth_resp

        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.single.return_value = mock_table
        mock_table.execute.return_value.data = {
            "id": TEST_SALAO_ID,
            "nome_salao": "Thamires Beauty",
            "foto_url": None,
        }
        mock_sb.table.return_value = mock_table

        app.dependency_overrides[get_supabase_auth] = lambda: mock_sb_auth
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.post(
                "/v1/auth/login",
                json={"email": "teste@salao.app", "senha": "password123"},
            )
            assert response.status_code == 200
            data = response.json()
            assert data["mensagem"] == "ok"
            assert data["codigo"] is None
            assert data["total"] == 1
            assert data["result"]["token"] == "mock-access-token"
            assert data["result"]["refresh_token"] == "mock-refresh-token"
            assert data["result"]["usuario"]["nome"] == "Thamires Borges"
            assert data["result"]["salao"]["nome"] == "Thamires Beauty"
        finally:
            app.dependency_overrides.clear()

    def test_login_invalid_credentials(self, client):
        mock_sb_auth = MagicMock()
        mock_sb_auth.auth.sign_in_with_password.side_effect = Exception("Invalid login")

        app.dependency_overrides[get_supabase_auth] = lambda: mock_sb_auth
        try:
            response = client.post(
                "/v1/auth/login",
                json={"email": "wrong@salao.app", "senha": "wrong"},
            )
            assert response.status_code == 401
            data = response.json()
            assert data["codigo"] == "AUTH_CREDENCIAIS_INVALIDAS"
            assert data["result"] is None
        finally:
            app.dependency_overrides.clear()

    def test_refresh_token_success(self, client):
        mock_auth_resp = MagicMock()
        mock_auth_resp.session.access_token = "new-access-token"
        mock_auth_resp.session.refresh_token = "new-refresh-token"
        mock_auth_resp.session.expires_in = 3600
        mock_auth_resp.user.id = TEST_USER_ID
        mock_auth_resp.user.email = "teste@salao.app"
        mock_auth_resp.user.user_metadata = {"nome": "Thamires Borges"}

        mock_sb_auth = MagicMock()
        mock_sb_auth.auth.refresh_session.return_value = mock_auth_resp

        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.single.return_value = mock_table
        mock_table.execute.return_value.data = {"nome_salao": "Thamires Beauty"}
        mock_sb.table.return_value = mock_table

        app.dependency_overrides[get_supabase_auth] = lambda: mock_sb_auth
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.post(
                "/v1/auth/refresh",
                json={"refresh_token": "valid-refresh-token"},
            )
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["token"] == "new-access-token"
        finally:
            app.dependency_overrides.clear()

    def test_refresh_token_invalid(self, client):
        mock_sb_auth = MagicMock()
        mock_sb_auth.auth.refresh_session.side_effect = Exception("Expired refresh token")

        app.dependency_overrides[get_supabase_auth] = lambda: mock_sb_auth
        try:
            response = client.post(
                "/v1/auth/refresh",
                json={"refresh_token": "expired-token"},
            )
            assert response.status_code == 401
            data = response.json()
            assert data["codigo"] == "AUTH_REFRESH_INVALIDO"
        finally:
            app.dependency_overrides.clear()

    def test_logout_endpoint(self, client, valid_jwt_token):
        mock_sb_auth = MagicMock()
        app.dependency_overrides[get_supabase_auth] = lambda: mock_sb_auth

        try:
            response = client.post(
                "/v1/auth/logout",
                headers={"Authorization": f"Bearer {valid_jwt_token}"},
            )
            assert response.status_code == 200
            data = response.json()
            assert data["mensagem"] == "ok"
            assert data["total"] == 0
        finally:
            app.dependency_overrides.clear()

    def test_eu_endpoint(self, client, valid_jwt_token):
        mock_user = MagicMock()
        mock_user.id = TEST_USER_ID
        mock_user.email = "teste@salao.app"
        mock_user.user_metadata = {"nome": "Thamires Borges"}

        mock_resp = MagicMock()
        mock_resp.user = mock_user

        mock_sb = MagicMock()
        mock_sb.auth.admin.get_user_by_id.return_value = mock_resp

        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.single.return_value = mock_table
        mock_table.execute.return_value.data = {
            "id": TEST_SALAO_ID,
            "nome_salao": "Thamires Beauty",
            "foto_url": None,
        }
        mock_sb.table.return_value = mock_table

        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.get(
                "/v1/auth/eu",
                headers={"Authorization": f"Bearer {valid_jwt_token}"},
            )
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["usuario"]["email"] == "teste@salao.app"
            assert data["result"]["usuario"]["id"] == TEST_USER_ID
            assert data["result"]["salao"]["nome"] == "Thamires Beauty"
        finally:
            app.dependency_overrides.clear()
