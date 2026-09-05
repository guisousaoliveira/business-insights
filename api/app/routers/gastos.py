"""Router: /gastos (endpoints-backend.md §3, 5 operações)."""

from fastapi import APIRouter, Depends, Query
from supabase import Client

from app.core.security import usuario_atual
from app.core.supabase_client import get_supabase
from app.schemas.envelope import ResponseModel, sucesso
from app.schemas.gastos import (
    GastoIn,
    GastoPatchIn,
    GastoPagarIn,
    GastoOut,
    GastosListaOut,
)
from app.services import gastos_service as service

router = APIRouter(prefix="/gastos", tags=["Gastos"])


@router.get(
    "",
    response_model=ResponseModel[GastosListaOut],
    summary="Lista gastos com totais de pendente e pago no mês",
)
def listar_gastos(
    mes: int | None = Query(None, ge=1, le=12),
    ano: int | None = Query(None, ge=2000),
    pago: bool | None = Query(None),
    categoria: str | None = Query(None),
    pagina: int = Query(1, ge=1),
    tamanho: int = Query(50, ge=1, le=100),
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.listar_gastos(
        supabase=supabase,
        user_id=user_id,
        mes=mes,
        ano=ano,
        pago=pago,
        categoria=categoria,
        pagina=pagina,
        tamanho=tamanho,
    )
    return sucesso(resultado, total=len(resultado["gastos"]))


@router.post(
    "",
    response_model=ResponseModel[GastoOut],
    summary="Cadastra um novo gasto",
)
def criar_gasto(
    body: GastoIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.criar_gasto(supabase=supabase, user_id=user_id, body=body)
    return sucesso(resultado)


@router.patch(
    "/{gasto_id}",
    response_model=ResponseModel[GastoOut],
    summary="Edita dados de um gasto",
)
def editar_gasto(
    gasto_id: str,
    body: GastoPatchIn,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.editar_gasto(supabase=supabase, user_id=user_id, gasto_id=gasto_id, body=body)
    return sucesso(resultado)


@router.patch(
    "/{gasto_id}/pagar",
    response_model=ResponseModel[GastoOut],
    summary="Marca gasto como pago (idempotente)",
)
def pagar_gasto(
    gasto_id: str,
    body: GastoPagarIn = GastoPagarIn(),
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    resultado = service.pagar_gasto(supabase=supabase, user_id=user_id, gasto_id=gasto_id, body=body)
    return sucesso(resultado)


@router.delete(
    "/{gasto_id}",
    response_model=ResponseModel[None],
    summary="Exclui um gasto",
)
def excluir_gasto(
    gasto_id: str,
    user_id: str = Depends(usuario_atual),
    supabase: Client = Depends(get_supabase),
):
    service.excluir_gasto(supabase=supabase, user_id=user_id, gasto_id=gasto_id)
    return sucesso(None, total=0)
