from pydantic_settings import BaseSettings
from pydantic import Field
from functools import lru_cache


class Settings(BaseSettings):
    # Supabase
    supabase_url: str = Field(..., env="SUPABASE_URL")
    supabase_service_key: str = Field(..., env="SUPABASE_SERVICE_KEY")

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

    # App
    environment: str = Field(default="development", env="ENVIRONMENT")

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
