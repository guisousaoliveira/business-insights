"""
Router: /precificacao

Resolve o problema mais crítico da usuária: ela está "pagando para trabalhar"
porque nunca calculou o preço mínimo real dos serviços.

Este router não toca no banco — é cálculo puro.
O Flutter envia os parâmetros, recebe o resultado e exibe o diagnóstico.
"""

from fastapi import APIRouter, Query
from app.schemas.relatorio import FiltroPrecificacao, ResultadoPrecificacao
from app.services.precificacao_service import calcular_preco_minimo

router = APIRouter(prefix="/precificacao", tags=["Precificação"])


@router.post(
    "/calcular",
    response_model=ResultadoPrecificacao,
    summary="Calcula o preço mínimo de um serviço",
    description=(
        "Recebe custo de material, tempo e meta de hora trabalhada. "
        "Retorna o breakdown completo de custos e o preço mínimo sugerido. "
        "Se o preço_atual for informado via query param, inclui diagnóstico "
        "de se está cobrindo os custos."
    ),
)
def calcular(
    dados: FiltroPrecificacao,
    preco_atual: float | None = Query(
        default=None,
        ge=0,
        description="Preço que a proprietária cobra hoje — para comparação diagnóstica",
    ),
) -> ResultadoPrecificacao:
    return calcular_preco_minimo(dados, preco_atual)
