"""
Router: /health

Endpoint simples para o orquestrador de containers (Railway, Render, etc.)
e para o n8n verificar se a API está de pé antes de chamar endpoints.
"""

from fastapi import APIRouter, Depends
from supabase import Client
from app.core.supabase_client import get_supabase
from app.core.config import get_settings

router = APIRouter(tags=["Health"])


@router.get("/health", summary="Verifica se a API está operacional")
async def health(supabase: Client = Depends(get_supabase)):
    cfg = get_settings()

    # Testa conectividade com o Supabase com uma query leve
    try:
        supabase.table("custos_fixos").select("id").limit(1).execute()
        db_status = "ok"
    except Exception as e:
        db_status = f"erro: {str(e)}"

    return {
        "status": "ok" if db_status == "ok" else "degradado",
        "environment": cfg.environment,
        "database": db_status,
    }
