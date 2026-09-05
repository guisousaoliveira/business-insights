"""Schemas do módulo de perfil e custos fixos (endpoints-backend.md §7)."""

from datetime import time as time_, datetime
import re
from pydantic import BaseModel, Field, field_validator, model_validator


# ── Perfil do Salão ──────────────────────────────────────────────────

class SalaoDados(BaseModel):
    id: str
    nome: str
    proprietaria: str
    foto_url: str | None = None
    telefone_whatsapp: str
    meta_faturamento_mensal: float


class PerfilOut(BaseModel):
    salao: SalaoDados


class PerfilUpdateIn(BaseModel):
    nome: str = Field(min_length=1)
    proprietaria: str = Field(default="")
    foto_url: str | None = None
    telefone_whatsapp: str = Field(default="")
    meta_faturamento_mensal: float = Field(ge=0, default=9000.0)


# ── Custos Fixos ─────────────────────────────────────────────────────

class CustoFixoIn(BaseModel):
    descricao: str = Field(min_length=1)
    valor: float = Field(gt=0)
    dia_vencimento: int = Field(ge=1, le=31)


class CustoFixoPatchIn(BaseModel):
    descricao: str | None = Field(default=None, min_length=1)
    valor: float | None = Field(default=None, gt=0)
    dia_vencimento: int | None = Field(default=None, ge=1, le=31)


class CustoFixoPagarIn(BaseModel):
    competencia: str = Field(description="Formato AAAA-MM")
    pago: bool = True

    @field_validator("competencia")
    @classmethod
    def validar_competencia(cls, v: str) -> str:
        if not re.match(r"^\d{4}-(0[1-9]|1[0-2])$", v):
            raise ValueError("competencia deve estar no formato AAAA-MM")
        return v


class CustoFixoOut(BaseModel):
    id: str
    descricao: str
    valor: float
    dia_vencimento: int
    competencia: str
    pago: bool
    pago_em: datetime | None = None


class CustosFixosListaOut(BaseModel):
    total_mensal: float
    total_pago: float
    total_pendente: float
    custos: list[CustoFixoOut]


# ── Horários de Funcionamento e Agendamento Público ──────────────────

class HorarioDia(BaseModel):
    dia_semana: int
    ativo: bool
    hora_inicio: time_ | None = None
    hora_fim: time_ | None = None

    @model_validator(mode="after")
    def _validar(self):
        if not (0 <= self.dia_semana <= 6):
            raise ValueError("dia_semana deve estar entre 0 (domingo) e 6 (sábado)")
        if self.ativo:
            if self.hora_inicio is None or self.hora_fim is None:
                raise ValueError("hora_inicio e hora_fim são obrigatórios quando ativo=true")
            if self.hora_inicio >= self.hora_fim:
                raise ValueError("hora_inicio deve ser menor que hora_fim")
        else:
            self.hora_inicio = None
            self.hora_fim = None
        return self


class HorarioFuncionamentoIn(BaseModel):
    horarios: list[HorarioDia]

    @model_validator(mode="after")
    def _validar_sete_dias(self):
        dias = sorted(h.dia_semana for h in self.horarios)
        if dias != list(range(7)):
            raise ValueError("é preciso enviar exatamente um horário para cada dia da semana (0 a 6)")
        return self


class HorarioFuncionamentoOut(BaseModel):
    horarios: list[HorarioDia]


class LinkAgendamentoOut(BaseModel):
    slug: str
    url: str
