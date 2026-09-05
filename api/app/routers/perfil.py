"""
Router: /perfil (parcial)

Só cobre o que o lote L8 (agendamento público) precisa —
GET/PUT /perfil/horario-funcionamento e GET /perfil/link-agendamento.
O resto do módulo perfil (GET/PUT /perfil, custos-fixos) ainda não existe.
"""

from fastapi import APIRouter, Depends, HTTPException
from supabase import Client

from app.core.config import get_settings
from app.core.security import usuario_atual
from app.core.supabase_client import get_supabase
from app.schemas.envelope import ResponseModel, sucesso
from app.schemas.perfil import (
    HorarioDia,
    HorarioFuncionamentoIn,
    HorarioFuncionamentoOut,
    LinkAgendamentoOut,
)

router = APIRouter(prefix="/perfil", tags=["Perfil"])


@router.get(
    "/horario-funcionamento",
    response_model=ResponseModel[HorarioFuncionamentoOut],
    summary="Expediente por dia da semana",
)
def obter_horario_funcionamento(
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resp = (
        supabase.table("horario_funcionamento")
        .select("dia_semana, ativo, hora_inicio, hora_fim")
        .eq("user_id", user_id)
        .order("dia_semana")
        .execute()
    )
    horarios = [HorarioDia(**linha) for linha in (resp.data or [])]
    return sucesso(HorarioFuncionamentoOut(horarios=horarios).model_dump(mode="json"))


@router.put(
    "/horario-funcionamento",
    response_model=ResponseModel[HorarioFuncionamentoOut],
    summary="Substitui o expediente dos 7 dias de uma vez",
)
def atualizar_horario_funcionamento(
    dados: HorarioFuncionamentoIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    # Substitui os 7 dias de uma vez — mesma filosofia do PATCH /servicos/{id}
    # com produtos_padrao (§7): o cliente manda o estado final da tela, o
    # servidor não faz diff.
    linhas = [
        {
            "user_id": user_id,
            "dia_semana": h.dia_semana,
            "ativo": h.ativo,
            "hora_inicio": h.hora_inicio.isoformat() if h.hora_inicio else None,
            "hora_fim": h.hora_fim.isoformat() if h.hora_fim else None,
        }
        for h in dados.horarios
    ]
    supabase.table("horario_funcionamento").upsert(linhas, on_conflict="user_id,dia_semana").execute()
    return obter_horario_funcionamento(user_id=user_id, supabase=supabase)


@router.get(
    "/link-agendamento",
    response_model=ResponseModel[LinkAgendamentoOut],
    summary="Link fixo de agendamento público do salão",
)
def obter_link_agendamento(
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resp = (
        supabase.table("perfil_salao")
        .select("slug_agendamento")
        .eq("user_id", user_id)
        .single()
        .execute()
    )
    slug = (resp.data or {}).get("slug_agendamento")
    if not slug:
        raise HTTPException(
            status_code=404,
            detail={"codigo": "RECURSO_NAO_ENCONTRADO", "mensagem": "Perfil do salão não encontrado"},
        )

    cfg = get_settings()
    url = f"{cfg.link_agendamento_base_url.rstrip('/')}/{slug}"
    return sucesso(LinkAgendamentoOut(slug=slug, url=url).model_dump())
