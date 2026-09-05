"""
Testes unitários e de integração para o módulo /estoque.
"""

import uuid
from unittest.mock import MagicMock
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.security import usuario_atual
from app.core.supabase_client import get_supabase


TEST_USER_ID = str(uuid.uuid4())
TEST_ITEM_ID = str(uuid.uuid4())


@pytest.fixture
def client():
    return TestClient(app)


class TestEstoqueEndpoints:
    def test_listar_itens_estoque(self, client):
        mock_itens = [
            {
                "id": TEST_ITEM_ID,
                "user_id": TEST_USER_ID,
                "nome": "Cola adesiva para cílios",
                "unidade": "un",
                "categoria": "cilios",
                "quantidade_atual": 0.0,
                "quantidade_minima": 2.0,
                "custo_medio": 28.0,
                "custo_ultima_compra": 30.0,
                "status": "critico",
                "deficit": 2.0,
                "ativo": True,
                "codigo_barras": None,
            }
        ]

        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.order.return_value = mock_table
        mock_table.execute.return_value = MagicMock(data=mock_itens)
        mock_sb.table.return_value = mock_table

        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.get("/v1/estoque/itens")
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["total_alertas"] == 1
            assert len(data["result"]["itens"]) == 1
            assert data["result"]["itens"][0]["status"] == "critico"
        finally:
            app.dependency_overrides.clear()

    def test_criar_movimentacao_entrada_recalcula_custo_medio(self, client):
        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.update.return_value = mock_table
        mock_table.insert.return_value = mock_table

        # Item atual: saldo 2, custo_medio 20.0
        # Entrada: 2 unidades a 30.0 -> novo saldo 4, novo custo_medio = (2*20 + 2*30)/4 = 25.0
        item_inicial = {
            "id": TEST_ITEM_ID,
            "user_id": TEST_USER_ID,
            "nome": "Cola adesiva para cílios",
            "unidade": "un",
            "categoria": "cilios",
            "quantidade_atual": 2.0,
            "quantidade_minima": 2.0,
            "custo_medio": 20.0,
            "custo_ultima_compra": 20.0,
            "status": "ok",
            "deficit": 0.0,
            "ativo": True,
            "codigo_barras": None,
        }
        item_pos_entrada = {
            **item_inicial,
            "quantidade_atual": 4.0,
            "custo_medio": 25.0,
            "custo_ultima_compra": 30.0,
        }

        mock_table.execute.side_effect = [
            MagicMock(data=[item_inicial]),     # buscar item antes
            MagicMock(data=[]),                 # insert movimentacao
            MagicMock(data=[]),                 # update item
            MagicMock(data=[item_pos_entrada]), # buscar item depois
        ]
        mock_sb.table.return_value = mock_table

        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.post(
                f"/v1/estoque/itens/{TEST_ITEM_ID}/movimentacoes",
                json={
                    "tipo": "entrada",
                    "quantidade": 2,
                    "motivo": "Compra fornecedor",
                    "custo_unitario": 30.0,
                },
            )
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["quantidade_atual"] == 4.0
            assert data["result"]["custo_medio"] == 25.0
            assert data["result"]["custo_ultima_compra"] == 30.0
        finally:
            app.dependency_overrides.clear()

    def test_saida_manual_sem_saldo_retorna_409(self, client):
        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table

        item_inicial = {
            "id": TEST_ITEM_ID,
            "user_id": TEST_USER_ID,
            "nome": "Cola adesiva para cílios",
            "unidade": "un",
            "categoria": "cilios",
            "quantidade_atual": 1.0,
            "quantidade_minima": 2.0,
            "custo_medio": 20.0,
            "custo_ultima_compra": 20.0,
            "status": "alerta",
            "deficit": 1.0,
            "ativo": True,
            "codigo_barras": None,
        }

        mock_table.execute.return_value = MagicMock(data=[item_inicial])
        mock_sb.table.return_value = mock_table

        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.post(
                f"/v1/estoque/itens/{TEST_ITEM_ID}/movimentacoes",
                json={
                    "tipo": "saida",
                    "quantidade": 5,
                    "motivo": "Uso avulso",
                },
            )
            assert response.status_code == 409
            data = response.json()
            assert data["codigo"] == "ESTOQUE_INSUFICIENTE"
            assert "faltantes" in data["result"]
        finally:
            app.dependency_overrides.clear()
