from pydantic import BaseModel, Field
from typing import Optional


# ── Entrada ────────────────────────────────────────────────────────

class FiltroRelatorio(BaseModel):
    """Parâmetros de query para /relatorio/mensal"""
    ano: int = Field(..., ge=2020, le=2100, description="Ano de referência")
    mes: int = Field(..., ge=1, le=12, description="Mês de referência (1–12)")


# ── Saída ──────────────────────────────────────────────────────────

class ServicoRanking(BaseModel):
    nome: str
    quantidade: int
    total_receita: float


class ResumoReceita(BaseModel):
    total_servicos: float = Field(description="Soma bruta dos serviços realizados")
    total_insumos: float = Field(description="Soma dos insumos descartáveis usados")
    liquido_atendimentos: float = Field(description="total_servicos - total_insumos")
    quantidade_atendimentos: int
    servicos_mais_realizados: list[ServicoRanking]


class ResumoGastos(BaseModel):
    total_custos_fixos: float = Field(description="Soma dos custos fixos mensais cadastrados no perfil")
    total_gastos_variaveis: float = Field(description="Soma dos gastos registrados no mês")
    total_saiu: float = Field(description="total_custos_fixos + total_gastos_variaveis")


class ResumoMensal(BaseModel):
    ano: int
    mes: int
    receita: ResumoReceita
    gastos: ResumoGastos
    saldo_final: float = Field(description="liquido_atendimentos - total_saiu")
    alerta_zero_a_zero: bool = Field(
        description="True quando saldo_final < 100 — sinaliza para o Flutter exibir aviso de precificação"
    )


# ── Entrada ────────────────────────────────────────────────────────

class FiltroPrecificacao(BaseModel):
    """
    Dados necessários para calcular o preço mínimo de um serviço.
    O Flutter envia isso quando a usuária quer saber se está cobrindo os custos.
    """
    custo_material: float = Field(..., ge=0, description="Custo dos materiais usados no serviço (R$)")
    tempo_minutos: int = Field(..., ge=1, description="Duração do serviço em minutos")
    meta_hora: float = Field(
        ..., ge=0,
        description="Quanto a proprietária quer ganhar por hora de trabalho (R$)"
    )
    percentual_overhead: float = Field(
        default=0.30,
        ge=0,
        le=1,
        description="Fração dos custos fixos alocada neste serviço (padrão 30%)"
    )
    percentual_lucro: float = Field(
        default=0.20,
        ge=0,
        le=1,
        description="Margem de lucro desejada sobre o custo total (padrão 20%)"
    )


class ResultadoPrecificacao(BaseModel):
    custo_material: float
    custo_tempo: float = Field(description="meta_hora × (tempo_minutos / 60)")
    custo_overhead: float = Field(description="(custo_material + custo_tempo) × percentual_overhead")
    custo_total: float = Field(description="custo_material + custo_tempo + custo_overhead")
    preco_minimo: float = Field(description="custo_total × (1 + percentual_lucro)")
    preco_sugerido: float = Field(description="preco_minimo arredondado para o próximo R$5")
    cobrindo_custos: Optional[bool] = Field(
        default=None,
        description="Se um preço atual foi informado, indica se está acima do mínimo"
    )
    preco_atual: Optional[float] = None
    diferenca: Optional[float] = Field(
        default=None,
        description="preco_atual - preco_minimo (negativo = está no prejuízo)"
    )
