"""Router: /estoque (endpoints-backend.md §5, 6 operações)."""

from fastapi import APIRouter, Depends, Query
from supabase import Client

from app.core.security import usuario_atual
from app.core.supabase_client import get_supabase
from app.schemas.envelope import ResponseModel, sucesso
from app.schemas.estoque import (
    EstoquePaginaOut,
    ItemIn,
    ItemOut,
    ItemPatchIn,
    MovimentacaoIn,
    MovimentacoesListaOut,
)
from app.services import estoque_service as service

router = APIRouter(prefix="/estoque", tags=["Estoque"])


@router.get("/itens", response_model=ResponseModel[EstoquePaginaOut], summary="Lista itens do estoque")
def listar_itens(
    status: str | None = Query(None),
    categoria: str | None = Query(None),
    ativo: bool | None = Query(None),
    codigo_barras: str | None = Query(None),
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.listar(supabase, user_id, status, categoria, ativo, codigo_barras)
    return sucesso(resultado, total=len(resultado["itens"]))


@router.post("/itens", response_model=ResponseModel[ItemOut], summary="Cadastra item de estoque")
def criar_item(
    body: ItemIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.criar(supabase, user_id, body)
    return sucesso(resultado)


@router.patch("/itens/{item_id}", response_model=ResponseModel[ItemOut], summary="Edita item de estoque")
def editar_item(
    item_id: str,
    body: ItemPatchIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.editar(supabase, user_id, item_id, body)
    return sucesso(resultado)


@router.delete("/itens/{item_id}", response_model=ResponseModel[None], summary="Exclui item (soft delete se já usado)")
def excluir_item(
    item_id: str,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    service.excluir(supabase, user_id, item_id)
    return sucesso(None)


@router.post(
    "/itens/{item_id}/movimentacoes",
    response_model=ResponseModel[ItemOut],
    summary="Lança movimentação e atualiza saldo/custo médio (A6)",
)
def criar_movimentacao(
    item_id: str,
    body: MovimentacaoIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.criar_movimentacao(supabase, user_id, item_id, body)
    return sucesso(resultado)


@router.get("/movimentacoes", response_model=ResponseModel[MovimentacoesListaOut], summary="Histórico de movimentações")
def listar_movimentacoes(
    item_id: str | None = Query(None),
    inicio: str | None = Query(None),
    fim: str | None = Query(None),
    tipo: str | None = Query(None),
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.listar_movimentacoes(supabase, user_id, item_id, inicio, fim, tipo)
    return sucesso(resultado, total=len(resultado["movimentacoes"]))
