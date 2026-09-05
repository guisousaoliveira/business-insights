"""Schemas para o módulo de gastos (endpoints-backend.md §3)."""

from datetime import date, datetime
from typing import Literal
from pydantic import BaseModel, Field


FormaPagamento = Literal["a_vista", "credito", "debito", "pix"]
CategoriaGasto = Literal["fixo", "material", "outros"]


class GastoItem(BaseModel):
    nome: str
    preco: float = Field(ge=0)


class GastoIn(BaseModel):
    nome: str = Field(min_length=1)
    valor: float = Field(gt=0)
    prazo_pagamento: date
    forma_pagamento: FormaPagamento = "a_vista"
    categoria: CategoriaGasto = "outros"
    pago: bool = False
    pago_em: datetime | None = None
    itens: list[GastoItem] = Field(default_factory=list)


class GastoPatchIn(BaseModel):
    nome: str | None = Field(default=None, min_length=1)
    valor: float | None = Field(default=None, gt=0)
    prazo_pagamento: date | None = None
    forma_pagamento: FormaPagamento | None = None
    categoria: CategoriaGasto | None = None
    pago: bool | None = None
    pago_em: datetime | None = None
    itens: list[GastoItem] | None = None


class GastoPagarIn(BaseModel):
    pago_em: date | datetime | None = None


class GastoOut(BaseModel):
    id: str
    nome: str
    valor: float
    prazo_pagamento: date
    forma_pagamento: FormaPagamento
    categoria: CategoriaGasto
    pago: bool
    pago_em: datetime | None = None
    vence_em_dias: int
    itens: list[GastoItem] = Field(default_factory=list)


class GastosListaOut(BaseModel):
    total_pendente: float
    total_pago_mes: float
    gastos: list[GastoOut]
