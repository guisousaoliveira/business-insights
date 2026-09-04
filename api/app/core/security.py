"""
Autenticação — validação de JWT emitido pelo Supabase Auth.

Substitui o antigo `_extrair_user_id` de `routers/relatorio.py`, que decodificava
o token em base64 e confiava no `sub` sem checar a assinatura. Isso era tolerável
enquanto o Flutter falava direto com o Supabase (a RLS segurava a ponta). Com o
FastAPI virando a única barreira (decisão A1), qualquer pessoa conseguia montar
um token com o `sub` de outra usuária e ler os dados dela.

Agora todo endpoint autenticado depende de `usuario_atual`, que:
  1. Exige o header Authorization: Bearer <token>
  2. Verifica a assinatura do JWT com SUPABASE_JWT_SECRET (HS256)
  3. Confere a expiração (a lib já faz isso, mas deixamos explícito no leeway)
  4. Devolve o user_id (claim `sub`) — nunca aceito vindo de body/query
"""

from fastapi import Header, HTTPException
from jose import jwt, JWTError

from app.core.config import get_settings

# Claim de audiência que o Supabase Auth usa por padrão nos tokens de usuário.
_SUPABASE_AUDIENCE = "authenticated"


def _decodificar_token(token: str) -> dict:
    cfg = get_settings()
    try:
        return jwt.decode(
            token,
            cfg.supabase_jwt_secret,
            algorithms=["HS256"],
            audience=_SUPABASE_AUDIENCE,
        )
    except JWTError:
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
