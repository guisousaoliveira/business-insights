"""Schemas para o módulo de alertas e dispositivos (endpoints-backend.md §9)."""

from datetime import datetime
from typing import Literal
from pydantic import BaseModel, Field


SeveridadeAlerta = Literal["critico", "alerta", "info"]
TipoAlerta = Literal[
    "estoque_negativo",
    "estoque_critico",
    "estoque_baixo",
    "gasto_a_vencer",
    "gasto_vencido",
    "custo_fixo_a_vencer",
    "custo_fixo_vencido",
    "saldo_negativo",
    "zero_a_zero",
]
PlataformaDispositivo = Literal["android", "ios", "web"]


# ── Alertas ──────────────────────────────────────────────────────────

class AlertaOut(BaseModel):
    id: str
    tipo: str
    severidade: str
    titulo: str
    mensagem: str
    referencia_tipo: str | None = None
    referencia_id: str | None = None
    criado_em: str | datetime
    lido_em: str | datetime | None = None


class AlertasResumo(BaseModel):
    critico: int = 0
    alerta: int = 0
    info: int = 0


class AlertasListaOut(BaseModel):
    total_nao_lidos: int
    resumo: AlertasResumo
    alertas: list[AlertaOut]


class MarcarLidosIn(BaseModel):
    tipo: str | None = None


# ── Preferências de Alertas ──────────────────────────────────────────

class CanalStatus(BaseModel):
    ativo: bool


class CanaisPreferencias(BaseModel):
    in_app: CanalStatus = Field(default_factory=lambda: CanalStatus(ativo=True))
    push: CanalStatus = Field(default_factory=lambda: CanalStatus(ativo=True))
    whatsapp: CanalStatus = Field(default_factory=lambda: CanalStatus(ativo=False))
    email: CanalStatus = Field(default_factory=lambda: CanalStatus(ativo=False))


class PreferenciasAlertaOut(BaseModel):
    limite_saldo_alerta: float
    dias_antecedencia_vencimento: int
    canais: CanaisPreferencias
    tipos_silenciados: list[str] = Field(default_factory=list)


class PreferenciasAlertaUpdateIn(BaseModel):
    limite_saldo_alerta: float = Field(ge=0, default=0.0)
    dias_antecedencia_vencimento: int = Field(ge=0, default=7)
    canais: CanaisPreferencias = Field(default_factory=CanaisPreferencias)
    tipos_silenciados: list[str] = Field(default_factory=list)


# ── Dispositivos Push ────────────────────────────────────────────────

class DispositivoIn(BaseModel):
    token: str = Field(min_length=1)
    plataforma: PlataformaDispositivo
    modelo: str = Field(default="")


class DispositivoOut(BaseModel):
    id: str
    token: str
    plataforma: str
    modelo: str
    ativo: bool
