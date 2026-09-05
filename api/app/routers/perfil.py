"""
Router: /perfil (endpoints-backend.md §7, 7 operações + expediente e link).
"""

from fastapi import APIRouter, Depends, Query, HTTPException
from supabase import Client

from app.core.config import get_settings
from app.core.security import usuario_atual
from app.core.supabase_client import get_supabase, rows, row
from app.schemas.envelope import ResponseModel, sucesso
from app.schemas.perfil import (
    PerfilOut,
    PerfilUpdateIn,
    CustoFixoIn,
    CustoFixoPatchIn,
    CustoFixoPagarIn,
    CustoFixoOut,
    CustosFixosListaOut,
    HorarioDia,
    HorarioFuncionamentoIn,
    HorarioFuncionamentoOut,
    LinkAgendamentoOut,
)
from app.services import perfil_service as service

router = APIRouter(prefix="/perfil", tags=["Perfil"])


# ── Perfil do Salão ──────────────────────────────────────────────────

@router.get(
    "",
    response_model=ResponseModel[PerfilOut],
    summary="Dados do salão e metas",
)
def obter_perfil(
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.obter_perfil(supabase=supabase, user_id=user_id)
    return sucesso(resultado.model_dump())


@router.put(
    "",
    response_model=ResponseModel[PerfilOut],
    summary="Atualiza dados do salão e metas",
)
def atualizar_perfil(
    dados: PerfilUpdateIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.atualizar_perfil(supabase=supabase, user_id=user_id, dados=dados)
    return sucesso(resultado.model_dump())


# ── Custos Fixos ─────────────────────────────────────────────────────

@router.get(
    "/custos-fixos",
    response_model=ResponseModel[CustosFixosListaOut],
    summary="Lista custos fixos e status de pagamento por competência",
)
def listar_custos_fixos(
    competencia: str | None = Query(None, description="Formato AAAA-MM (padrão: mês atual)"),
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.listar_custos_fixos(supabase=supabase, user_id=user_id, competencia=competencia)
    return sucesso(resultado.model_dump(), total=len(resultado.custos))


@router.post(
    "/custos-fixos",
    response_model=ResponseModel[CustoFixoOut],
    summary="Cadastra novo custo fixo",
)
def criar_custo_fixo(
    dados: CustoFixoIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.criar_custo_fixo(supabase=supabase, user_id=user_id, dados=dados)
    return sucesso(resultado.model_dump())


@router.patch(
    "/custos-fixos/{custo_id}",
    response_model=ResponseModel[CustoFixoOut],
    summary="Edita dados de um custo fixo",
)
def editar_custo_fixo(
    custo_id: str,
    dados: CustoFixoPatchIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.editar_custo_fixo(supabase=supabase, user_id=user_id, custo_id=custo_id, dados=dados)
    return sucesso(resultado.model_dump())


@router.patch(
    "/custos-fixos/{custo_id}/pagar",
    response_model=ResponseModel[CustoFixoOut],
    summary="Marca ou desmarca pagamento de custo fixo na competência",
)
def pagar_custo_fixo(
    custo_id: str,
    dados: CustoFixoPagarIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.pagar_custo_fixo(supabase=supabase, user_id=user_id, custo_id=custo_id, dados=dados)
    return sucesso(resultado.model_dump())


@router.delete(
    "/custos-fixos/{custo_id}",
    response_model=ResponseModel[None],
    summary="Exclui custo fixo e histórico de pagamentos",
)
def excluir_custo_fixo(
    custo_id: str,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    service.excluir_custo_fixo(supabase=supabase, user_id=user_id, custo_id=custo_id)
    return sucesso(None, total=0)


# ── Expediente e Link de Agendamento ─────────────────────────────────

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
    horarios = [HorarioDia.model_validate(linha) for linha in rows(resp.data)]
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
    slug = row(resp.data).get("slug_agendamento")
    if not slug:
        raise HTTPException(
            status_code=404,
            detail={"codigo": "RECURSO_NAO_ENCONTRADO", "mensagem": "Perfil do salão não encontrado"},
        )

    cfg = get_settings()
    url = f"{cfg.link_agendamento_base_url.rstrip('/')}/{slug}"
    return sucesso(LinkAgendamentoOut(slug=slug, url=url).model_dump())
