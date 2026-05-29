import httpx
from app.core.config import get_settings
import logging

logger = logging.getLogger(__name__)


async def disparar_webhook(path: str, payload: dict) -> bool:
    """
    Dispara um webhook no n8n de forma assíncrona.
    Falha silenciosamente — nunca interrompe o fluxo principal do usuário.

    Args:
        path: caminho do webhook (ex: "webhook/alerta-saldo-mensal")
        payload: dados enviados no corpo da requisição

    Returns:
        True se o n8n respondeu 2xx, False caso contrário
    """
    cfg = get_settings()

    if not cfg.n8n_base_url:
        logger.warning("N8N_BASE_URL não configurado — webhook ignorado: %s", path)
        return False

    url = f"{cfg.n8n_base_url.rstrip('/')}/{path}"

    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resposta = await client.post(url, json=payload)
            resposta.raise_for_status()
            logger.info("Webhook n8n disparado com sucesso: %s", url)
            return True
    except httpx.TimeoutException:
        logger.warning("Timeout ao disparar webhook n8n: %s", url)
    except httpx.HTTPStatusError as e:
        logger.error("Erro HTTP no webhook n8n %s: %s", url, e.response.status_code)
    except Exception as e:
        logger.error("Erro inesperado no webhook n8n %s: %s", url, str(e))

    return False
