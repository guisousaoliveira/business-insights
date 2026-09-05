"""Schemas de `estoque` (endpoints-backend.md §5)."""

from pydantic import BaseModel, model_validator

UNIDADES = {"un", "ml", "g", "cx"}
CATEGORIAS = {"cilios", "sobrancelha", "limpeza_pele", "descartavel", "outro"}
TIPOS_MOVIMENTACAO = {"entrada", "saida", "ajuste"}


class ItemIn(BaseModel):
    nome: str
    unidade: str
    categoria: str
    quantidade_atual: float = 0
    quantidade_minima: float = 0
    custo_unitario: float = 0
    codigo_barras: str | None = None

    @model_validator(mode="after")
    def _validar(self):
        if self.unidade not in UNIDADES:
            raise ValueError(f"unidade deve ser uma de {UNIDADES}")
        if self.categoria not in CATEGORIAS:
            raise ValueError(f"categoria deve ser uma de {CATEGORIAS}")
        if self.quantidade_minima < 0:
            raise ValueError("quantidade_minima não pode ser negativa")
        if self.codigo_barras is not None:
            self.codigo_barras = self.codigo_barras.strip() or None
        return self


class ItemPatchIn(BaseModel):
    nome: str | None = None
    unidade: str | None = None
    categoria: str | None = None
    quantidade_minima: float | None = None
    codigo_barras: str | None = None

    @model_validator(mode="after")
    def _validar(self):
        if self.unidade is not None and self.unidade not in UNIDADES:
            raise ValueError(f"unidade deve ser uma de {UNIDADES}")
        if self.categoria is not None and self.categoria not in CATEGORIAS:
            raise ValueError(f"categoria deve ser uma de {CATEGORIAS}")
        if self.quantidade_minima is not None and self.quantidade_minima < 0:
            raise ValueError("quantidade_minima não pode ser negativa")
        if self.codigo_barras is not None:
            self.codigo_barras = self.codigo_barras.strip() or None
        return self


class MovimentacaoIn(BaseModel):
    tipo: str
    quantidade: float
    motivo: str = ""
    custo_unitario: float | None = None

    @model_validator(mode="after")
    def _validar(self):
        if self.tipo not in TIPOS_MOVIMENTACAO:
            raise ValueError(f"tipo deve ser um de {TIPOS_MOVIMENTACAO}")
        if self.quantidade <= 0:
            raise ValueError("quantidade deve ser maior que zero")
        return self


class ItemOut(BaseModel):
    id: str
    nome: str
    unidade: str
    categoria: str
    quantidade_atual: float
    quantidade_minima: float
    custo_medio: float
    custo_ultima_compra: float
    status: str
    deficit: float
    ativo: bool
    codigo_barras: str | None = None


class EstoquePaginaOut(BaseModel):
    total_alertas: int
    valor_total: float
    itens: list[ItemOut]


class MovimentacaoOut(BaseModel):
    id: str
    item_id: str
    item_nome: str
    tipo: str
    quantidade: float
    motivo: str
    atendimento_id: str | None
    criado_em: str


class MovimentacoesListaOut(BaseModel):
    movimentacoes: list[MovimentacaoOut]
