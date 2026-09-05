"""
Testes unitários e de integração para o módulo /perfil e /perfil/custos-fixos.
"""

import uuid
from unittest.mock import MagicMock
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.security import usuario_atual
from app.core.supabase_client import get_supabase


TEST_USER_ID = str(uuid.uuid4())
TEST_CUSTO_ID = str(uuid.uuid4())


@pytest.fixture
def client():
    return TestClient(app)


class TestPerfilEndpoints:
    def test_obter_perfil(self, client):
        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.single.return_value = mock_table
        mock_table.execute.return_value = MagicMock(
            data={
                "id": str(uuid.uuid4()),
                "user_id": TEST_USER_ID,
                "nome_salao": "Thamires Borges Beauty",
                "nome_proprietaria": "Thamires Borges",
                "foto_url": None,
                "telefone": "5511999990000",
                "meta_faturamento_mensal": 9000.0,
            }
        )
        mock_sb.table.return_value = mock_table
        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.get("/v1/perfil")
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["salao"]["nome"] == "Thamires Borges Beauty"
            assert data["result"]["salao"]["meta_faturamento_mensal"] == 9000.0
        finally:
            app.dependency_overrides.clear()

    def test_listar_custos_fixos_com_pagamento_por_competencia(self, client):
        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.order.return_value = mock_table

        # 1. custos_fixos
        # 2. custos_fixos_pagamentos
        mock_table.execute.side_effect = [
            MagicMock(data=[{
                "id": TEST_CUSTO_ID,
                "descricao": "Aluguel",
                "valor": 1200.0,
                "dia_vencimento": 5,
            }]),
            MagicMock(data=[{
                "custo_fixo_id": TEST_CUSTO_ID,
                "pago_em": "2026-09-03T10:00:00Z",
            }]),
        ]
        mock_sb.table.return_value = mock_table
        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.get("/v1/perfil/custos-fixos?competencia=2026-09")
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["total_mensal"] == 1200.0
            assert data["result"]["total_pago"] == 1200.0
            assert data["result"]["total_pendente"] == 0.0
            assert len(data["result"]["custos"]) == 1
            assert data["result"]["custos"][0]["pago"] is True
            assert data["result"]["custos"][0]["competencia"] == "2026-09"
        finally:
            app.dependency_overrides.clear()

    def test_pagar_custo_fixo_competencia(self, client):
        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.upsert.return_value = mock_table

        mock_table.execute.side_effect = [
            MagicMock(data=[{
                "id": TEST_CUSTO_ID,
                "descricao": "Aluguel",
                "valor": 1200.0,
                "dia_vencimento": 5,
            }]),
            MagicMock(data=[]),  # upsert
        ]
        mock_sb.table.return_value = mock_table
        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.patch(
                f"/v1/perfil/custos-fixos/{TEST_CUSTO_ID}/pagar",
                json={"competencia": "2026-09", "pago": True},
            )
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["pago"] is True
            assert data["result"]["competencia"] == "2026-09"
        finally:
            app.dependency_overrides.clear()
