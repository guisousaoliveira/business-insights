"""
Autenticação — validação de JWT emitido pelo Supabase Auth.

Substitui o antigo `_extrair_user_id` de `routers/relatorio.py`, que decodificava
o token em base64 e confiava no `sub` sem checar a assinatura. Isso era tolerável
enquanto o Flutter falava direto com o Supabase (a RLS segurava a ponta). Com o
FastAPI virando a única barreira (decisão A1), qualquer pessoa conseguia montar
um token com o `sub` de outra usuária e ler os dados dela.

Projeto Supabase novo assina com **chave assimétrica** (ES256/RS256) via JWKS, não
mais com o "JWT Secret" compartilhado (HS256) — o `alg` do header do token diz qual
dos dois esquemas está em uso, e cada projeto usa só um. Por isso os dois caminhos
abaixo coexistem: HS256 valida com `SUPABASE_JWT_SECRET` (projeto legado); qualquer
outro `alg` busca a chave pública correspondente no JWKS do projeto (cacheado em
memória — as chaves não trocam a cada request).

Todo endpoint autenticado depende de `usuario_atual`, que:
  1. Exige o header Authorization: Bearer <token>
  2. Verifica a assinatura do JWT (HS256 com secret, ou JWKS)
  3. Confere a expiração (a lib já faz isso, mas deixamos explícito no leeway)
  4. Devolve o user_id (claim `sub`) — nunca aceito vindo de body/query
"""

import time

import httpx
from fastapi import Header, HTTPException
from jose import jwt, JWTError

from app.core.config import get_settings

# Claim de audiência que o Supabase Auth usa por padrão nos tokens de usuário.
_SUPABASE_AUDIENCE = "authenticated"

# Cache simples do JWKS em memória — as chaves de assinatura giram raramente,
# não há motivo para buscar a cada request.
_JWKS_TTL_SEGUNDOS = 3600
_jwks_cache: dict = {"chaves": [], "buscado_em": 0.0}


def _buscar_jwks(supabase_url: str) -> list[dict]:
    agora = time.time()
    if not _jwks_cache["chaves"] or agora - _jwks_cache["buscado_em"] > _JWKS_TTL_SEGUNDOS:
        resp = httpx.get(f"{supabase_url}/auth/v1/.well-known/jwks.json", timeout=5)
        resp.raise_for_status()
        _jwks_cache["chaves"] = resp.json().get("keys", [])
        _jwks_cache["buscado_em"] = agora
    return _jwks_cache["chaves"]


def _decodificar_token(token: str) -> dict:
    cfg = get_settings()
    try:
        header = jwt.get_unverified_header(token)
        alg = header.get("alg", "HS256")

        if alg == "HS256":
            if not cfg.supabase_jwt_secret:
                raise JWTError("Projeto usa HS256 mas SUPABASE_JWT_SECRET não está configurado")
            chave = cfg.supabase_jwt_secret
        else:
            kid = header.get("kid")
            chave = next(
                (k for k in _buscar_jwks(cfg.supabase_url) if k.get("kid") == kid),
                None,
            )
            if chave is None:
                raise JWTError(f"Chave '{kid}' não encontrada no JWKS do projeto")

        return jwt.decode(
            token,
            chave,
            algorithms=[alg],
            audience=_SUPABASE_AUDIENCE,
        )
    except (JWTError, httpx.HTTPError):
        raise HTTPException(
            status_code=401,
            detail={"codigo": "AUTH_TOKEN_AUSENTE", "mensagem": "Token inválido ou expirado"},
        )


def usuario_atual(authorization: str | None = Header(default=None)) -> str:
    """
    Dependency usada por TODO endpoint autenticado. Retorna o user_id (uuid, string)
    extraído e VALIDADO do JWT. Nunca leia user_id do corpo ou da query — se um
    endpoint aceitar isso, é falha de servidor (ver endpoints-backend.md §0).
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail={"codigo": "AUTH_TOKEN_AUSENTE", "mensagem": "Token de autorização ausente"},
        )

    token = authorization.removeprefix("Bearer ").strip()
    payload = _decodificar_token(token)

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=401,
            detail={"codigo": "AUTH_TOKEN_AUSENTE", "mensagem": "Token sem identificador de usuária"},
        )
    return user_id
