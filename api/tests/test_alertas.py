"""
Testes unitários e de integração para o módulo /alertas e /dispositivos.
"""

import uuid
from unittest.mock import MagicMock
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.security import usuario_atual
from app.core.supabase_client import get_supabase


TEST_USER_ID = str(uuid.uuid4())
TEST_ALERTA_ID = str(uuid.uuid4())


@pytest.fixture
def client():
    return TestClient(app)


class TestAlertasEndpoints:
    def test_listar_alertas_com_badge_resumo(self, client):
        mock_alerta = {
            "id": TEST_ALERTA_ID,
            "user_id": TEST_USER_ID,
            "tipo": "estoque_critico",
            "severidade": "critico",
            "titulo": "Cola adesiva acabou",
            "mensagem": "Você está com 0 un.",
            "referencia_tipo": "estoque_item",
            "referencia_id": str(uuid.uuid4()),
            "chave_dedupe": "estoque:123",
            "lido_em": None,
            "resolvido_em": None,
            "criado_em": "2026-09-01T08:00:00-03:00",
        }

        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.is_.return_value = mock_table
        mock_table.order.return_value = mock_table

        # 1. query filtrada de alertas
        # 2. query de contagem de nao lidos para o resumo/badge
        mock_table.execute.side_effect = [
            MagicMock(data=[mock_alerta]),
            MagicMock(data=[{"severidade": "critico"}]),
        ]
        mock_sb.table.return_value = mock_table

        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.get("/v1/alertas")
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["total_nao_lidos"] == 1
            assert data["result"]["resumo"]["critico"] == 1
            assert len(data["result"]["alertas"]) == 1
            assert data["result"]["alertas"][0]["tipo"] == "estoque_critico"
        finally:
            app.dependency_overrides.clear()

    def test_marcar_alerta_lido(self, client):
        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.update.return_value = mock_table
        mock_table.single.return_value = mock_table

        alerta_atualizado = {
            "id": TEST_ALERTA_ID,
            "user_id": TEST_USER_ID,
            "tipo": "estoque_critico",
            "severidade": "critico",
            "titulo": "Cola adesiva acabou",
            "mensagem": "Você está com 0 un.",
            "referencia_tipo": "estoque_item",
            "referencia_id": str(uuid.uuid4()),
            "chave_dedupe": "estoque:123",
            "lido_em": "2026-09-01T09:00:00Z",
            "resolvido_em": None,
            "criado_em": "2026-09-01T08:00:00-03:00",
        }

        mock_table.execute.side_effect = [
            MagicMock(data=[{"id": TEST_ALERTA_ID}]),  # select antes
            MagicMock(data=[]),                        # update
            MagicMock(data=alerta_atualizado),         # select depois
        ]
        mock_sb.table.return_value = mock_table

        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.patch(f"/v1/alertas/{TEST_ALERTA_ID}/lido")
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["lido_em"] is not None
        finally:
            app.dependency_overrides.clear()

    def test_preferencias_alertas(self, client):
        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.single.return_value = mock_table

        mock_pref = {
            "user_id": TEST_USER_ID,
            "limite_saldo_alerta": 150.0,
            "dias_antecedencia_vencimento": 7,
            "canal_in_app": True,
            "canal_push": True,
            "canal_whatsapp": False,
            "canal_email": False,
            "tipos_silenciados": ["zero_a_zero"],
        }
        mock_table.execute.return_value = MagicMock(data=mock_pref)
        mock_sb.table.return_value = mock_table

        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.get("/v1/alertas/preferencias")
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["limite_saldo_alerta"] == 150.0
            assert data["result"]["dias_antecedencia_vencimento"] == 7
            assert data["result"]["canais"]["in_app"]["ativo"] is True
            assert data["result"]["tipos_silenciados"] == ["zero_a_zero"]
        finally:
            app.dependency_overrides.clear()

    def test_registrar_dispositivo(self, client):
        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.upsert.return_value = mock_table
        mock_table.execute.return_value = MagicMock(
            data=[{
                "id": str(uuid.uuid4()),
                "user_id": TEST_USER_ID,
                "token": "fcm-token-12345",
                "plataforma": "android",
                "modelo": "Moto G84",
                "ativo": True,
            }]
        )
        mock_sb.table.return_value = mock_table

        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.post(
                "/v1/dispositivos",
                json={
                    "token": "fcm-token-12345",
                    "plataforma": "android",
                    "modelo": "Moto G84",
                },
            )
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["token"] == "fcm-token-12345"
            assert data["result"]["plataforma"] == "android"
        finally:
            app.dependency_overrides.clear()
