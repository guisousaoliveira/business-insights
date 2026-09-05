"""Router: /servicos (endpoints-backend.md §8, 4 operações)."""

from fastapi import APIRouter, Depends
from supabase import Client

from app.core.security import usuario_atual
from app.core.supabase_client import get_supabase
from app.schemas.envelope import ResponseModel, sucesso
from app.schemas.servicos import ServicoIn, ServicoOut, ServicoPatchIn, ServicosListaOut
from app.services import servicos_service as service

router = APIRouter(prefix="/servicos", tags=["Serviços"])


@router.get("", response_model=ResponseModel[ServicosListaOut], summary="Tabela de preços do salão")
def listar(
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.listar(supabase, user_id)
    return sucesso(resultado, total=len(resultado["servicos"]))


@router.post("", response_model=ResponseModel[ServicoOut], summary="Cria serviço")
def criar(
    body: ServicoIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.criar(supabase, user_id, body)
    return sucesso(resultado)


@router.patch("/{servico_id}", response_model=ResponseModel[ServicoOut], summary="Edita serviço")
def editar(
    servico_id: str,
    body: ServicoPatchIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.editar(supabase, user_id, servico_id, body)
    return sucesso(resultado)


@router.delete("/{servico_id}", response_model=ResponseModel[None], summary="Exclui serviço (soft delete)")
def excluir(
    servico_id: str,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    service.excluir(supabase, user_id, servico_id)
    return sucesso(None)
