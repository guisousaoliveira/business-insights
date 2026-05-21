"""
Serviço de precificação mínima.

Resolve o problema central da usuária: ela está "pagando para trabalhar"
porque nunca calculou o preço mínimo dos serviços.

Fórmula adotada (método de markup sobre custo total):
  custo_tempo    = meta_hora × (tempo_minutos / 60)
  custo_overhead = (custo_material + custo_tempo) × percentual_overhead
  custo_total    = custo_material + custo_tempo + custo_overhead
  preco_minimo   = custo_total × (1 + percentual_lucro)
  preco_sugerido = arredonda preco_minimo para o próximo múltiplo de R$5
"""

import math
from app.schemas.relatorio import FiltroPrecificacao, ResultadoPrecificacao


def calcular_preco_minimo(dados: FiltroPrecificacao, preco_atual: float | None = None) -> ResultadoPrecificacao:
    """
    Calcula o preço mínimo de um serviço e compara com o preço atual se fornecido.

    Args:
        dados: parâmetros do serviço (custo de material, tempo, meta de hora)
        preco_atual: preço que a proprietária cobra hoje (opcional)

    Returns:
        ResultadoPrecificacao com breakdown completo e diagnóstico
    """
    custo_tempo = round(dados.meta_hora * (dados.tempo_minutos / 60), 2)
    base = dados.custo_material + custo_tempo
    custo_overhead = round(base * dados.percentual_overhead, 2)
    custo_total = round(base + custo_overhead, 2)
    preco_minimo = round(custo_total * (1 + dados.percentual_lucro), 2)
    preco_sugerido = _arredondar_para_cinco(preco_minimo)

    cobrindo_custos = None
    diferenca = None
    if preco_atual is not None:
        cobrindo_custos = preco_atual >= preco_minimo
        diferenca = round(preco_atual - preco_minimo, 2)

    return ResultadoPrecificacao(
        custo_material=dados.custo_material,
        custo_tempo=custo_tempo,
        custo_overhead=custo_overhead,
        custo_total=custo_total,
        preco_minimo=preco_minimo,
        preco_sugerido=preco_sugerido,
        cobrindo_custos=cobrindo_custos,
        preco_atual=preco_atual,
        diferenca=diferenca,
    )


def _arredondar_para_cinco(valor: float) -> float:
    """
    Arredonda para cima até o próximo múltiplo de R$5.
    Ex: 182.30 → 185.00 | 185.00 → 185.00 | 186.00 → 190.00
    """
    return math.ceil(valor / 5) * 5
