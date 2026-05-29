"""
Testes unitários do serviço de precificação.

Não precisam de banco nem de rede — são cálculos puros.
Rodar com: pytest tests/test_precificacao.py -v
"""

import pytest
from app.schemas.relatorio import FiltroPrecificacao
from app.services.precificacao_service import calcular_preco_minimo, _arredondar_para_cinco


# ── Fixtures ────────────────────────────────────────────────────────

@pytest.fixture
def dados_extensao_cilios():
    """
    Extensão de cílios: situação real da usuária.
    Cobra R$180, mas vamos ver se está cobrindo.
    """
    return FiltroPrecificacao(
        custo_material=32.0,    # cola + fios (descartáveis por sessão)
        tempo_minutos=120,      # 2 horas
        meta_hora=50.0,         # quer ganhar R$50/h
        percentual_overhead=0.30,
        percentual_lucro=0.20,
    )


@pytest.fixture
def dados_limpeza_pele():
    return FiltroPrecificacao(
        custo_material=13.0,
        tempo_minutos=60,
        meta_hora=50.0,
        percentual_overhead=0.30,
        percentual_lucro=0.20,
    )


# ── Testes de cálculo ───────────────────────────────────────────────

class TestCalculoPrecificacao:

    def test_custo_tempo_calculado_corretamente(self, dados_extensao_cilios):
        resultado = calcular_preco_minimo(dados_extensao_cilios)
        # 50 × (120/60) = 100
        assert resultado.custo_tempo == 100.0

    def test_custo_overhead_sobre_base(self, dados_extensao_cilios):
        resultado = calcular_preco_minimo(dados_extensao_cilios)
        # base = 32 + 100 = 132; overhead = 132 × 0.30 = 39.60
        assert resultado.custo_overhead == 39.60

    def test_custo_total(self, dados_extensao_cilios):
        resultado = calcular_preco_minimo(dados_extensao_cilios)
        # 32 + 100 + 39.60 = 171.60
        assert resultado.custo_total == 171.60

    def test_preco_minimo_com_lucro(self, dados_extensao_cilios):
        resultado = calcular_preco_minimo(dados_extensao_cilios)
        # 171.60 × 1.20 = 205.92
        assert resultado.preco_minimo == 205.92

    def test_preco_sugerido_arredondado(self, dados_extensao_cilios):
        resultado = calcular_preco_minimo(dados_extensao_cilios)
        # 205.92 → próximo múltiplo de 5 = 210
        assert resultado.preco_sugerido == 210.0

    def test_preco_sugerido_ja_multiplo_de_cinco(self):
        dados = FiltroPrecificacao(
            custo_material=0.0,
            tempo_minutos=60,
            meta_hora=100.0,   # custo_tempo=100, overhead=30, total=130, min=156 → 160
            percentual_overhead=0.30,
            percentual_lucro=0.20,
        )
        resultado = calcular_preco_minimo(dados)
        assert resultado.preco_sugerido % 5 == 0

    def test_limpeza_pele_60min(self, dados_limpeza_pele):
        resultado = calcular_preco_minimo(dados_limpeza_pele)
        # custo_tempo = 50×1 = 50; base = 63; overhead = 18.90; total = 81.90; min = 98.28 → 100
        assert resultado.preco_sugerido == 100.0


# ── Testes de diagnóstico (preço atual) ────────────────────────────

class TestDiagnosticoPrecificacao:

    def test_diagnostico_quando_cobrindo_custos(self, dados_extensao_cilios):
        resultado = calcular_preco_minimo(dados_extensao_cilios, preco_atual=220.0)
        assert resultado.cobrindo_custos is True
        assert resultado.diferenca == pytest.approx(220.0 - 205.92, abs=0.01)

    def test_diagnostico_pagando_para_trabalhar(self, dados_extensao_cilios):
        # Cobra R$180 mas mínimo é R$205.92
        resultado = calcular_preco_minimo(dados_extensao_cilios, preco_atual=180.0)
        assert resultado.cobrindo_custos is False
        assert resultado.diferenca == pytest.approx(180.0 - 205.92, abs=0.01)
        assert resultado.diferenca < 0  # prejuízo

    def test_sem_preco_atual_nao_tem_diagnostico(self, dados_extensao_cilios):
        resultado = calcular_preco_minimo(dados_extensao_cilios, preco_atual=None)
        assert resultado.cobrindo_custos is None
        assert resultado.diferenca is None
        assert resultado.preco_atual is None

    def test_preco_exatamente_no_minimo(self, dados_extensao_cilios):
        resultado = calcular_preco_minimo(dados_extensao_cilios, preco_atual=205.92)
        assert resultado.cobrindo_custos is True
        assert resultado.diferenca == pytest.approx(0.0, abs=0.01)


# ── Testes do helper de arredondamento ─────────────────────────────

class TestArredondamento:

    @pytest.mark.parametrize("valor, esperado", [
        (180.01, 185.0),
        (185.00, 185.0),
        (185.01, 190.0),
        (100.00, 100.0),
        (101.00, 105.0),
        (0.01,    5.0),
    ])
    def test_arredondamentos(self, valor, esperado):
        assert _arredondar_para_cinco(valor) == esperado
