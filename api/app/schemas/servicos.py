"""Schemas de `servicos` (endpoints-backend.md §8)."""

from pydantic import BaseModel, model_validator


class ProdutoPadraoIn(BaseModel):
    item_estoque_id: str
    quantidade: float

    @model_validator(mode="after")
    def _validar(self):
        if self.quantidade <= 0:
            raise ValueError("quantidade deve ser maior que zero")
        return self


class ServicoIn(BaseModel):
    nome: str
    preco: float
    duracao_minutos: int
    produtos_padrao: list[ProdutoPadraoIn] = []

    @model_validator(mode="after")
    def _validar(self):
        if self.duracao_minutos <= 0:
            raise ValueError("duracao_minutos deve ser maior que zero")
        ids = [p.item_estoque_id for p in self.produtos_padrao]
        if len(ids) != len(set(ids)):
            raise ValueError("item_estoque_id repetido em produtos_padrao")
        return self


class ServicoPatchIn(BaseModel):
    nome: str | None = None
    preco: float | None = None
    duracao_minutos: int | None = None
    produtos_padrao: list[ProdutoPadraoIn] | None = None

    @model_validator(mode="after")
    def _validar(self):
        if self.duracao_minutos is not None and self.duracao_minutos <= 0:
            raise ValueError("duracao_minutos deve ser maior que zero")
        if self.produtos_padrao is not None:
            ids = [p.item_estoque_id for p in self.produtos_padrao]
            if len(ids) != len(set(ids)):
                raise ValueError("item_estoque_id repetido em produtos_padrao")
        return self


class ProdutoPadraoOut(BaseModel):
    item_estoque_id: str
    nome: str
    quantidade: float
    unidade: str


class ServicoOut(BaseModel):
    id: str
    nome: str
    preco: float
    duracao_minutos: int | None
    ativo: bool
    produtos_padrao: list[ProdutoPadraoOut]


class ServicosListaOut(BaseModel):
    servicos: list[ServicoOut]
