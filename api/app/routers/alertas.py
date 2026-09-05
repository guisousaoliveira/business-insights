"""Router: /alertas e /dispositivos (endpoints-backend.md §9, 7 operações)."""

from fastapi import APIRouter, Depends, Query
from supabase import Client

from app.core.security import usuario_atual
from app.core.supabase_client import get_supabase
from app.schemas.envelope import ResponseModel, sucesso
from app.schemas.alertas import (
    AlertaOut,
    AlertasListaOut,
    MarcarLidosIn,
    PreferenciasAlertaOut,
    PreferenciasAlertaUpdateIn,
    DispositivoIn,
    DispositivoOut,
)
from app.services import alertas_service as service

router = APIRouter(tags=["Alertas"])


# ── Alertas ──────────────────────────────────────────────────────────

@router.get(
    "/alertas",
    response_model=ResponseModel[AlertasListaOut],
    summary="Lista alertas ativos com badge e resumo",
)
def listar_alertas(
    apenas_nao_lidos: bool | None = Query(None),
    tipo: str | None = Query(None),
    severidade: str | None = Query(None),
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.listar_alertas(
        supabase=supabase,
        user_id=user_id,
        apenas_nao_lidos=apenas_nao_lidos,
        tipo=tipo,
        severidade=severidade,
    )
    return sucesso(resultado.model_dump(), total=len(resultado.alertas))


@router.patch(
    "/alertas/{alerta_id}/lido",
    response_model=ResponseModel[AlertaOut],
    summary="Marca um alerta individual como lido",
)
def marcar_alerta_lido(
    alerta_id: str,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.marcar_alerta_lido(supabase=supabase, user_id=user_id, alerta_id=alerta_id)
    return sucesso(resultado.model_dump())


@router.patch(
    "/alertas/lidos",
    response_model=ResponseModel[None],
    summary="Marca todos os alertas como lidos",
)
def marcar_todos_lidos(
    dados: MarcarLidosIn = MarcarLidosIn(),
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    service.marcar_todos_lidos(supabase=supabase, user_id=user_id, dados=dados)
    return sucesso(None, total=0)


# ── Preferências de Alertas ──────────────────────────────────────────

@router.get(
    "/alertas/preferencias",
    response_model=ResponseModel[PreferenciasAlertaOut],
    summary="Obtém preferências de limites e canais de alertas",
)
def obter_preferencias(
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.obter_preferencias(supabase=supabase, user_id=user_id)
    return sucesso(resultado.model_dump())


@router.put(
    "/alertas/preferencias",
    response_model=ResponseModel[PreferenciasAlertaOut],
    summary="Atualiza preferências de limites e canais de alertas",
)
def atualizar_preferencias(
    dados: PreferenciasAlertaUpdateIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.atualizar_preferencias(supabase=supabase, user_id=user_id, dados=dados)
    return sucesso(resultado.model_dump())


# ── Dispositivos Push ────────────────────────────────────────────────

@router.post(
    "/dispositivos",
    response_model=ResponseModel[DispositivoOut],
    summary="Registra token de dispositivo (idempotente)",
)
def registrar_dispositivo(
    dados: DispositivoIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.registrar_dispositivo(supabase=supabase, user_id=user_id, dados=dados)
    return sucesso(resultado.model_dump())


@router.delete(
    "/dispositivos/{token}",
    response_model=ResponseModel[None],
    summary="Remove token de dispositivo (no logout)",
)
def remover_dispositivo(
    token: str,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    service.remover_dispositivo(supabase=supabase, user_id=user_id, token=token)
    return sucesso(None, total=0)
