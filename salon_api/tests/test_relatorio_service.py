"""
Testes unitários do serviço de relatório mensal.

O Supabase é mockado para que os testes rodem sem banco de dados.
Cada teste valida uma regra de negócio específica do CONTEXTO_IA.md.

Rodar com: pytest tests/test_relatorio_service.py -v
"""

import pytest
from unittest.mock import MagicMock, patch
from app.services.relatorio_service import calcular_resumo_mensal, _intervalo_mes


# ── Helpers de mock ─────────────────────────────────────────────────

def mock_supabase(
    atendimentos=None,
    servicos=None,
    insumos=None,
    fixos=None,
    gastos=None,
):
    """
    Cria um mock do cliente Supabase que retorna dados controlados.
    Encadeia .table().select().eq()...execute() como o Supabase real faz.
    """
    def make_chain(data):
        resp = MagicMock()
        resp.data = data or []
        chain = MagicMock()
        chain.execute.return_value = resp
        chain.select.return_value = chain
        chain.eq.return_value = chain
        chain.in_.return_value = chain
        chain.gte.return_value = chain
        chain.lte.return_value = chain
        chain.limit.return_value = chain
        return chain

    client = MagicMock()

    # Mapeia cada tabela para seu dataset
    tabelas = {
        "atendimentos": make_chain(atendimentos),
        "atendimento_servicos": make_chain(servicos),
        "atendimento_insumos": make_chain(insumos),
        "custos_fixos": make_chain(fixos),
        "gastos": make_chain(gastos),
    }
    client.table.side_effect = lambda nome: tabelas[nome]
    return client


# ── Fixtures ────────────────────────────────────────────────────────

USER_ID = "user-123"
ANO = 2025
MES = 5


# ── Testes ──────────────────────────────────────────────────────────

class TestCalculoResumoMensal:

    @pytest.mark.asyncio
    async def test_saldo_positivo_simples(self):
        """Serviços cobrem gastos → saldo positivo."""
        sb = mock_supabase(
            atendimentos=[{"id": "a1"}],
            servicos=[{"nome_servico": "Extensão de cílios", "preco_snapshot": 180.0}],
            insumos=[{"preco": 20.0}],
            fixos=[{"valor": 100.0}],
            gastos=[{"valor": 50.0}],
        )
        resumo = await calcular_resumo_mensal(sb, USER_ID, ANO, MES)

        # líquido_atendimentos = 180 - 20 = 160
        # total_saiu = 100 + 50 = 150
        # saldo = 160 - 150 = 10
        assert resumo.receita.liquido_atendimentos == 160.0
        assert resumo.gastos.total_saiu == 150.0
        assert resumo.saldo_final == 10.0

    @pytest.mark.asyncio
    async def test_alerta_zero_a_zero_ativado(self):
        """Saldo < R$100 → alerta_zero_a_zero True."""
        sb = mock_supabase(
            atendimentos=[{"id": "a1"}],
            servicos=[{"nome_servico": "Limpeza de pele", "preco_snapshot": 150.0}],
            insumos=[{"preco": 10.0}],
            fixos=[{"valor": 120.0}],
            gastos=[{"valor": 15.0}],
        )
        resumo = await calcular_resumo_mensal(sb, USER_ID, ANO, MES)
        # saldo = (150-10) - (120+15) = 140 - 135 = 5
        assert resumo.saldo_final == 5.0
        assert resumo.alerta_zero_a_zero is True

    @pytest.mark.asyncio
    async def test_alerta_zero_a_zero_desativado_quando_saldo_ok(self):
        """Saldo >= R$100 → alerta_zero_a_zero False."""
        sb = mock_supabase(
            atendimentos=[{"id": "a1"}, {"id": "a2"}],
            servicos=[
                {"nome_servico": "Extensão de cílios", "preco_snapshot": 180.0},
                {"nome_servico": "Extensão de cílios", "preco_snapshot": 180.0},
            ],
            insumos=[{"preco": 20.0}, {"preco": 20.0}],
            fixos=[{"valor": 100.0}],
            gastos=[{"valor": 50.0}],
        )
        resumo = await calcular_resumo_mensal(sb, USER_ID, ANO, MES)
        # líquido = 360-40 = 320; saiu = 150; saldo = 170
        assert resumo.saldo_final == 170.0
        assert resumo.alerta_zero_a_zero is False

    @pytest.mark.asyncio
    async def test_saldo_negativo(self):
        """Gastos maiores que receita → saldo negativo."""
        sb = mock_supabase(
            atendimentos=[{"id": "a1"}],
            servicos=[{"nome_servico": "Sobrancelha", "preco_snapshot": 60.0}],
            insumos=[],
            fixos=[{"valor": 1200.0}],
            gastos=[{"valor": 200.0}],
        )
        resumo = await calcular_resumo_mensal(sb, USER_ID, ANO, MES)
        assert resumo.saldo_final < 0
        assert resumo.alerta_zero_a_zero is True  # abs < 100 é False, mas negativo tb dispara

    @pytest.mark.asyncio
    async def test_sem_atendimentos_no_mes(self):
        """Mês sem atendimentos → receita zero, saldo negativo."""
        sb = mock_supabase(
            atendimentos=[],
            servicos=[],
            insumos=[],
            fixos=[{"valor": 1200.0}],
            gastos=[],
        )
        resumo = await calcular_resumo_mensal(sb, USER_ID, ANO, MES)
        assert resumo.receita.quantidade_atendimentos == 0
        assert resumo.receita.total_servicos == 0.0
        assert resumo.saldo_final == -1200.0

    @pytest.mark.asyncio
    async def test_ranking_servicos_mais_realizados(self):
        """Serviço com mais atendimentos aparece primeiro no ranking."""
        sb = mock_supabase(
            atendimentos=[{"id": "a1"}, {"id": "a2"}, {"id": "a3"}],
            servicos=[
                {"nome_servico": "Extensão de cílios", "preco_snapshot": 180.0},
                {"nome_servico": "Extensão de cílios", "preco_snapshot": 180.0},
                {"nome_servico": "Limpeza de pele", "preco_snapshot": 150.0},
            ],
            insumos=[],
            fixos=[],
            gastos=[],
        )
        resumo = await calcular_resumo_mensal(sb, USER_ID, ANO, MES)
        ranking = resumo.receita.servicos_mais_realizados
        assert ranking[0].nome == "Extensão de cílios"
        assert ranking[0].quantidade == 2
        assert ranking[1].nome == "Limpeza de pele"
        assert ranking[1].quantidade == 1

    @pytest.mark.asyncio
    async def test_custos_fixos_entram_no_total_saiu(self):
        """Custos fixos do perfil são somados ao total_saiu."""
        sb = mock_supabase(
            atendimentos=[],
            servicos=[],
            insumos=[],
            fixos=[
                {"valor": 1200.0},  # aluguel
                {"valor": 99.0},    # internet
                {"valor": 49.0},    # app agendamento
            ],
            gastos=[],
        )
        resumo = await calcular_resumo_mensal(sb, USER_ID, ANO, MES)
        assert resumo.gastos.total_custos_fixos == 1348.0
        assert resumo.gastos.total_saiu == 1348.0


# ── Testes do helper de intervalo de datas ──────────────────────────

class TestIntervaloMes:

    def test_mes_com_31_dias(self):
        inicio, fim = _intervalo_mes(2025, 1)
        assert inicio == "2025-01-01"
        assert fim == "2025-01-31"

    def test_fevereiro_ano_normal(self):
        inicio, fim = _intervalo_mes(2025, 2)
        assert fim == "2025-02-28"

    def test_fevereiro_ano_bissexto(self):
        inicio, fim = _intervalo_mes(2024, 2)
        assert fim == "2024-02-29"

    def test_mes_com_30_dias(self):
        _, fim = _intervalo_mes(2025, 4)
        assert fim == "2025-04-30"
