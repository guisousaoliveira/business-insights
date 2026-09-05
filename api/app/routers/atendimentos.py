"""
Router: /atendimentos (endpoints-backend.md §2, 7 operações).
"""

from fastapi import APIRouter, Depends, Query
from supabase import Client

from app.core.security import usuario_atual
from app.core.supabase_client import get_supabase
from app.schemas.atendimentos import AtendimentoBodyIn, AtendimentoOut, AtendimentosPaginaOut, FinalizarBodyIn
from app.schemas.envelope import ResponseModel, sucesso
from app.services import atendimentos_service as service

router = APIRouter(prefix="/atendimentos", tags=["Atendimentos"])


@router.get("", response_model=ResponseModel[AtendimentosPaginaOut], summary="Lista atendimentos do período")
def listar(
    inicio: str = Query(...),
    fim: str = Query(...),
    status: str | None = Query(None),
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    status_lista = status.split(",") if status else None
    resultado = service.listar(supabase, user_id, inicio, fim, status_lista)
    return sucesso(resultado, total=resultado["quantidade"])


@router.post("", response_model=ResponseModel[AtendimentoOut], summary="Cria atendimento agendado")
def criar(
    body: AtendimentoBodyIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.criar(supabase, user_id, body)
    return sucesso(resultado)


@router.get("/{atendimento_id}", response_model=ResponseModel[AtendimentoOut], summary="Detalhe de um atendimento")
def obter(
    atendimento_id: str,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.obter(supabase, user_id, atendimento_id)
    return sucesso(resultado)


@router.patch("/{atendimento_id}", response_model=ResponseModel[AtendimentoOut], summary="Edita cliente, data e serviços")
def editar(
    atendimento_id: str,
    body: AtendimentoBodyIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.editar(supabase, user_id, atendimento_id, body)
    return sucesso(resultado)


@router.patch(
    "/{atendimento_id}/finalizar",
    response_model=ResponseModel[AtendimentoOut],
    summary="Finaliza e dá baixa no estoque (A5: duas passadas)",
)
def finalizar(
    atendimento_id: str,
    body: FinalizarBodyIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.finalizar(supabase, user_id, atendimento_id, body)
    return sucesso(resultado)


@router.patch(
    "/{atendimento_id}/cancelar",
    response_model=ResponseModel[AtendimentoOut],
    summary="Cancela e estorna estoque se já finalizado",
)
def cancelar(
    atendimento_id: str,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.cancelar(supabase, user_id, atendimento_id)
    return sucesso(resultado)


@router.delete("/{atendimento_id}", response_model=ResponseModel[None], summary="Exclui atendimento agendado")
def excluir(
    atendimento_id: str,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    service.excluir(supabase, user_id, atendimento_id)
    return sucesso(None)
