"""
Router: /auth

Bloqueia todo o resto (L0.4 em 00-ENTREGA-BACKEND.md): sem login o app não
passa da tela inicial.

Implementação: delega a autenticação em si para o Supabase Auth (GoTrue),
via `supabase.auth.sign_in_with_password` / `refresh_session` / `sign_out`.
O FastAPI não guarda senha nem emite JWT próprio — apenas repassa o
token/refresh_token que o Supabase já emite e assina com o mesmo
SUPABASE_JWT_SECRET que `usuario_atual` valida em todo outro endpoint.
Isso evita duplicar uma tabela de refresh tokens e uma lógica de expiração
que o Supabase já resolve.
"""

from fastapi import APIRouter, Depends, HTTPException
from supabase import Client

from app.core.supabase_client import get_supabase, get_supabase_auth
from app.core.security import usuario_atual
from app.schemas.auth import (
    LoginRequest,
    RefreshRequest,
    SessaoOut,
    EuOut,
    UsuarioOut,
    SalaoOut,
)
from app.schemas.envelope import sucesso, ResponseModel

router = APIRouter(prefix="/auth", tags=["Auth"])


def _buscar_salao(supabase: Client, user_id: str) -> SalaoOut:
    resp = (
        supabase.table("perfil_salao")
        .select("id, nome_salao, foto_url")
        .eq("user_id", user_id)
        .single()
        .execute()
    )
    linha = resp.data or {}
    return SalaoOut(
        id=linha.get("id", user_id),
        nome=linha.get("nome_salao", "Meu Salão"),
        foto_url=linha.get("foto_url"),
    )


def _montar_sessao(supabase: Client, auth_response) -> SessaoOut:
    session = auth_response.session
    user = auth_response.user
    if session is None or user is None:
        raise HTTPException(
            status_code=401,
            detail={"codigo": "AUTH_CREDENCIAIS_INVALIDAS", "mensagem": "E-mail ou senha incorretos"},
        )

    usuario = UsuarioOut(
        id=user.id,
        nome=(user.user_metadata or {}).get("nome", user.email or ""),
        email=user.email or "",
    )
    salao = _buscar_salao(supabase, user.id)

    return SessaoOut(
        token=session.access_token,
        refresh_token=session.refresh_token,
        expira_em=session.expires_in,
        usuario=usuario,
        salao=salao,
    )


@router.post(
    "/login",
    response_model=ResponseModel[SessaoOut],
    summary="Autentica com e-mail e senha",
)
def login(
    dados: LoginRequest,
    supabase: Client = Depends(get_supabase),
    supabase_auth: Client = Depends(get_supabase_auth),
):
    try:
        auth_response = supabase_auth.auth.sign_in_with_password(
            {"email": dados.email, "password": dados.senha}
        )
    except Exception:
        raise HTTPException(
            status_code=401,
            detail={"codigo": "AUTH_CREDENCIAIS_INVALIDAS", "mensagem": "E-mail ou senha incorretos"},
        )

    sessao = _montar_sessao(supabase, auth_response)
    return sucesso(sessao.model_dump())


@router.post(
    "/refresh",
    response_model=ResponseModel[SessaoOut],
    summary="Renova o token a partir do refresh_token",
)
def refresh(
    dados: RefreshRequest,
    supabase: Client = Depends(get_supabase),
    supabase_auth: Client = Depends(get_supabase_auth),
):
    try:
        auth_response = supabase_auth.auth.refresh_session(dados.refresh_token)
    except Exception:
        raise HTTPException(
            status_code=401,
            detail={"codigo": "AUTH_REFRESH_INVALIDO", "mensagem": "Sessão expirada, faça login novamente"},
        )

    sessao = _montar_sessao(supabase, auth_response)
    return sucesso(sessao.model_dump())


@router.post(
    "/logout",
    response_model=ResponseModel[None],
    summary="Invalida a sessão corrente",
)
def logout(
    user_id: str = Depends(usuario_atual),
    supabase_auth: Client = Depends(get_supabase_auth),
):
    try:
        supabase_auth.auth.sign_out()
    except Exception:
        # Logout é best-effort — mesmo se a revogação no Supabase falhar,
        # o app já descarta o token localmente.
        pass
    return sucesso(None, total=0)


@router.get(
    "/eu",
    response_model=ResponseModel[EuOut],
    summary="Dados da sessão corrente (usuária + salão)",
)
def eu(user_id: str = Depends(usuario_atual), supabase: Client = Depends(get_supabase)):
    resp = supabase.auth.admin.get_user_by_id(user_id)
    user = resp.user if hasattr(resp, "user") else resp

    usuario = UsuarioOut(
        id=user_id,
        nome=(getattr(user, "user_metadata", None) or {}).get("nome", getattr(user, "email", "") or ""),
        email=getattr(user, "email", "") or "",
    )
    salao = _buscar_salao(supabase, user_id)

    return sucesso(EuOut(usuario=usuario, salao=salao).model_dump())
