from pydantic_settings import BaseSettings
from pydantic import Field
from functools import lru_cache


class Settings(BaseSettings):
    # Supabase
    supabase_url: str = Field(..., env="SUPABASE_URL")
    supabase_service_key: str = Field(..., env="SUPABASE_SERVICE_KEY")
    # Chave pública (Dashboard > Settings > API > "anon" "public"). Usada só
    # para login/refresh/logout — nunca para consulta administrativa (ver
    # core/supabase_client.py sobre por que as duas chaves não podem
    # compartilhar o mesmo cliente).
    supabase_anon_key: str = Field(..., env="SUPABASE_ANON_KEY")

    # JWT — só necessário em projetos Supabase antigos, que ainda assinam com o
    # "JWT Secret" legado (HS256). Projeto novo assina com chave assimétrica
    # (ES256/RS256) e é validado via JWKS (ver core/security.py) — não usa isto.
    supabase_jwt_secret: str = Field(default="", env="SUPABASE_JWT_SECRET")

    # CORS — lista separada por vírgula no .env
    cors_origins: str = Field(
        default="http://localhost:3000,http://localhost:8080",
        env="CORS_ORIGINS",
    )

    # n8n
    n8n_base_url: str = Field(default="", env="N8N_BASE_URL")
    n8n_webhook_alerta_saldo: str = Field(
        default="webhook/alerta-saldo-mensal",
        env="N8N_WEBHOOK_ALERTA_SALDO",
    )
    n8n_webhook_resumo_semanal: str = Field(
        default="webhook/resumo-semanal",
        env="N8N_WEBHOOK_RESUMO_SEMANAL",
    )
    # Secret compartilhado que autentica as chamadas n8n -> FastAPI (rota inversa).
    # Antes só era exigido em produção; agora é exigido em TODO ambiente (dev/homolog
    # inclusive), conforme pedido em .specs/00-ENTREGA-BACKEND.md §7.
    n8n_secret: str = Field(..., env="N8N_SECRET")

    # App
    environment: str = Field(default="development", env="ENVIRONMENT")

    # Base da URL do link de agendamento público (§7 do mapa de endpoints).
    # GET /perfil/link-agendamento monta a url final como f"{base}/{slug}".
    # Sem domínio próprio ainda — aponta pro front local até existir um.
    link_agendamento_base_url: str = Field(
        default="http://localhost:8082/agendar",
        env="LINK_AGENDAMENTO_BASE_URL",
    )

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",")]

    @property
    def is_production(self) -> bool:
        return self.environment == "production"

    model_config = {"env_file": ".env", "extra": "ignore"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
