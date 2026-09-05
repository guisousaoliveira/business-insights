"""
Schemas de `atendimentos` (endpoints-backend.md §2).

`ServicoEntradaIn` e `MaterialEntradaIn` aceitam duas formas mutuamente
exclusivas — catálogo (`servico_id` / `item_estoque_id`) ou avulso
(`nome` + `preco`) — espelhando `ServicoEntrada`/`MaterialEntrada` do
frontend (frontend/salao_web/src/lib/api/atendimentos.ts).
"""

from datetime import datetime

from pydantic import BaseModel, model_validator


class ServicoEntradaIn(BaseModel):
    servico_id: str | None = None
    nome: str | None = None
    preco: float | None = None

    @model_validator(mode="after")
    def _validar(self):
        if self.servico_id is not None:
            return self
        if self.nome and self.preco is not None:
            return self
        raise ValueError("serviço precisa de servico_id ou de nome + preco")


class MaterialEntradaIn(BaseModel):
    item_estoque_id: str | None = None
    nome: str | None = None
    quantidade: float
    preco: float | None = None

    @model_validator(mode="after")
    def _validar(self):
        if self.item_estoque_id is not None:
            return self
        if self.nome and self.preco is not None:
            return self
        raise ValueError("material precisa de item_estoque_id ou de nome + preco")


class AtendimentoBodyIn(BaseModel):
    cliente_nome: str
    cliente_telefone: str | None = None
    data: datetime
    servicos: list[ServicoEntradaIn]

    @model_validator(mode="after")
    def _validar(self):
        if not self.servicos:
            raise ValueError("selecione ao menos um serviço")
        return self


class FinalizarBodyIn(BaseModel):
    materiais: list[MaterialEntradaIn]
    confirmar_estoque_insuficiente: bool = False


class AtendimentoServicoOut(BaseModel):
    servico_id: str | None
    nome: str
    preco: float


class AtendimentoMaterialOut(BaseModel):
    item_estoque_id: str | None
    nome: str
    quantidade: float
    preco: float


class AtendimentoOut(BaseModel):
    id: str
    cliente_nome: str
    cliente_telefone: str | None
    data: str
    status: str
    servicos: list[AtendimentoServicoOut]
    materiais: list[AtendimentoMaterialOut]
    total_servicos: float
    total_materiais: float
    saldo: float


class AtendimentosPaginaOut(BaseModel):
    saldo_liquido: float
    quantidade: int
    atendimentos: list[AtendimentoOut]
