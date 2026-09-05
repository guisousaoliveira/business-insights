from datetime import time as time_

from pydantic import BaseModel, model_validator


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
            # Dia inativo não abre horário nenhum, mesmo que hora_inicio/hora_fim
            # tenham vindo preenchidos (endpoints-backend.md §7).
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
