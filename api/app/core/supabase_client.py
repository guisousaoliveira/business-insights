from supabase import create_client, Client
from app.core.config import get_settings
from functools import lru_cache


@lru_cache
def get_supabase() -> Client:
    """
    Retorna um cliente Supabase singleton usando a service key.
    A service key bypassa o RLS — use apenas no backend, nunca exponha ao frontend.
    O Flutter usa a anon key diretamente para operações de CRUD simples.
    """
    cfg = get_settings()
    return create_client(cfg.supabase_url, cfg.supabase_service_key)
