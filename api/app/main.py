"""
Ponto de entrada da API do salão.

Responsabilidade desta camada:
  - Montar o app FastAPI com CORS, routers e metadata
  - Não conter nenhuma lógica de negócio

Divisão de trabalho (ver CONTEXTO_IA.md):
  - CRUD puro → Supabase REST API (Flutter chama diretamente)
  - Cálculos e relatórios → FastAPI (este serviço)
  - Automações e notificações → n8n (chama esta API via webhooks)
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.schemas.envelope import registrar_exception_handlers
from app.routers import auth, relatorio, precificacao, webhooks, health

cfg = get_settings()

app = FastAPI(
    title="Salon API",
    description=(
        "Backend de cálculos e relatórios do app de gestão de salão. "
        "CRUD básico fica no Supabase — este serviço contém apenas "
        "lógica que o Supabase não resolve sozinho."
    ),
    version="1.0.0",
    # Docs desativadas em produção para não expor schema
    docs_url=None if cfg.is_production else "/docs",
    redoc_url=None if cfg.is_production else "/redoc",
)

# ── CORS ───────────────────────────────────────────────────────────
# Flutter (PWA) roda em origem diferente da API
app.add_middleware(
    CORSMiddleware,
    allow_origins=cfg.cors_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PATCH", "DELETE"],
    allow_headers=["*"],
)

# ── Envelope de resposta ──────────────────────────────────────────
# HTTPException, erro de validação (422) e exceção genérica (500) — as três
# fontes possíveis de erro — passam a sair sempre como
# { total, mensagem, codigo, result }, nunca no formato padrão do FastAPI.
registrar_exception_handlers(app)

# ── Routers ────────────────────────────────────────────────────────
# Prefixo /v1 obrigatório (endpoints-backend.md §0 — base URL termina em /v1).
router_prefix = "/v1"
app.include_router(health.router, prefix=router_prefix)
app.include_router(auth.router, prefix=router_prefix)
app.include_router(relatorio.router, prefix=router_prefix)
app.include_router(precificacao.router, prefix=router_prefix)
app.include_router(webhooks.router, prefix=router_prefix)


@app.get("/", include_in_schema=False)
def root():
    return {"servico": "Salon API", "docs": "/docs", "health": "/health"}
