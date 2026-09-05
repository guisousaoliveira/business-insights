from supabase import create_client, Client
from app.core.config import get_settings
from functools import lru_cache


@lru_cache
def get_supabase() -> Client:
    """
    Cliente Supabase singleton usando a service key. A service key bypassa o
    RLS — use apenas para operação administrativa/de servidor (consultas com
    a autorização derivada do JWT já validado, não do Supabase Auth).

    NUNCA chame `.auth.sign_in_with_password` / `.refresh_session` /
    `.sign_out` neste cliente: a lib troca o header `Authorization` do
    cliente inteiro para o token da sessão a cada evento de auth (
    `SIGNED_IN`/`TOKEN_REFRESHED`/`SIGNED_OUT`), e como esta instância é
    cacheada e compartilhada por TODAS as requisições do processo, isso
    apagaria a identidade de `service_role` globalmente — a próxima chamada
    administrativa (ex.: `auth.admin.get_user_by_id`) passaria a rodar com o
    token de uma usuária qualquer e devolveria `403 User not allowed`. Use
    `get_supabase_auth()` para essas três chamadas.
    """
    cfg = get_settings()
    return create_client(cfg.supabase_url, cfg.supabase_service_key)


def get_supabase_auth() -> Client:
    """
    Cliente novo a cada chamada, com a chave `anon` — é o que `login`,
    `refresh` e `logout` devem usar para `sign_in_with_password` /
    `refresh_session` / `sign_out`. Descartável de propósito: não é cacheado
    porque cada um desses três métodos muta o header `Authorization` do
    cliente que os chama (ver aviso em `get_supabase`), e aqui isso não tem
    efeito colateral nenhum — o cliente morre no fim da requisição.
    """
    cfg = get_settings()
    return create_client(cfg.supabase_url, cfg.supabase_anon_key)
