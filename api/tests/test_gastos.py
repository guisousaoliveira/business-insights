"""
Testes unitários e de integração para o módulo /gastos.
"""

import uuid
from datetime import date, timedelta
from unittest.mock import MagicMock
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.security import usuario_atual
from app.core.supabase_client import get_supabase


TEST_USER_ID = str(uuid.uuid4())


@pytest.fixture
def client():
    return TestClient(app)


class TestGastosEndpoints:
    def test_listar_gastos_com_totais(self, client):
        hoje = date.today()
        mock_gastos = [
            {
                "id": str(uuid.uuid4()),
                "user_id": TEST_USER_ID,
                "nome": "Conta de Luz",
                "valor": 120.0,
                "prazo": (hoje + timedelta(days=2)).isoformat(),
                "forma_pagamento": "pix",
                "categoria": "fixo",
                "pago": False,
                "pago_em": None,
                "itens": [],
            }
        ]

        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.gte.return_value = mock_table
        mock_table.lte.return_value = mock_table
        mock_table.order.return_value = mock_table
        mock_table.range.return_value = mock_table
        mock_table.execute.side_effect = [
            MagicMock(data=mock_gastos),  # listagem
            MagicMock(data=[{"valor": 120.0}]),  # pendentes
            MagicMock(data=[]),  # pagos
        ]
        mock_sb.table.return_value = mock_table

        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.get("/v1/gastos")
            assert response.status_code == 200
            data = response.json()
            assert data["mensagem"] == "ok"
            assert data["result"]["total_pendente"] == 120.0
            assert len(data["result"]["gastos"]) == 1
            assert data["result"]["gastos"][0]["vence_em_dias"] == 2
        finally:
            app.dependency_overrides.clear()

    def test_criar_gasto(self, client):
        mock_sb = MagicMock()
        mock_table = MagicMock()
        gasto_id = str(uuid.uuid4())
        mock_table.insert.return_value.execute.return_value = MagicMock(
            data=[{
                "id": gasto_id,
                "user_id": TEST_USER_ID,
                "nome": "Esmaltes novos",
                "valor": 85.50,
                "prazo": "2026-09-10",
                "forma_pagamento": "debito",
                "categoria": "material",
                "pago": False,
                "pago_em": None,
                "itens": [],
            }]
        )
        mock_sb.table.return_value = mock_table
        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.post(
                "/v1/gastos",
                json={
                    "nome": "Esmaltes novos",
                    "valor": 85.50,
                    "prazo_pagamento": "2026-09-10",
                    "forma_pagamento": "debito",
                    "categoria": "material",
                },
            )
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["nome"] == "Esmaltes novos"
            assert data["result"]["valor"] == 85.50
        finally:
            app.dependency_overrides.clear()

    def test_pagar_gasto_idempotente(self, client):
        gasto_id = str(uuid.uuid4())
        mock_sb = MagicMock()
        mock_table = MagicMock()
        mock_table.select.return_value = mock_table
        mock_table.eq.return_value = mock_table
        mock_table.update.return_value = mock_table

        # Primeira consulta: não pago. Segunda consulta após update: pago.
        mock_table.execute.side_effect = [
            MagicMock(data=[{
                "id": gasto_id,
                "user_id": TEST_USER_ID,
                "nome": "Conta de luz",
                "valor": 120.0,
                "prazo": "2026-09-03",
                "forma_pagamento": "pix",
                "categoria": "fixo",
                "pago": False,
                "pago_em": None,
            }]),
            MagicMock(data=[]),  # update
            MagicMock(data=[{
                "id": gasto_id,
                "user_id": TEST_USER_ID,
                "nome": "Conta de luz",
                "valor": 120.0,
                "prazo": "2026-09-03",
                "forma_pagamento": "pix",
                "categoria": "fixo",
                "pago": True,
                "pago_em": "2026-09-03T10:00:00Z",
            }]),
        ]
        mock_sb.table.return_value = mock_table
        app.dependency_overrides[usuario_atual] = lambda: TEST_USER_ID
        app.dependency_overrides[get_supabase] = lambda: mock_sb

        try:
            response = client.patch(
                f"/v1/gastos/{gasto_id}/pagar",
                json={"pago_em": "2026-09-03T10:00:00Z"},
            )
            assert response.status_code == 200
            data = response.json()
            assert data["result"]["pago"] is True
        finally:
            app.dependency_overrides.clear()
