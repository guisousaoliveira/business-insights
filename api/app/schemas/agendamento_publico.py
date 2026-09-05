from datetime import datetime

from pydantic import BaseModel, Field


class SalaoPublicoOut(BaseModel):
    nome: str
    foto_url: str | None = None


class ServicoPublicoOut(BaseModel):
    id: str
    nome: str
    preco: float
    duracao_minutos: int


class AgendamentoPublicoOut(BaseModel):
    salao: SalaoPublicoOut
    servicos: list[ServicoPublicoOut]


class HorariosDisponiveisOut(BaseModel):
    duracao_total_minutos: int
    horarios: list[str]


class AgendarServicoItem(BaseModel):
    servico_id: str


class AgendarRequest(BaseModel):
    cliente_nome: str = Field(min_length=1)
    cliente_telefone: str = Field(min_length=1)
    data: datetime
    servicos: list[AgendarServicoItem] = Field(min_length=1)


class ServicoAgendadoOut(BaseModel):
    servico_id: str
    nome: str
    preco: float


class AgendamentoCriadoOut(BaseModel):
    id: str
    data: datetime
    status: str
    servicos: list[ServicoAgendadoOut]
