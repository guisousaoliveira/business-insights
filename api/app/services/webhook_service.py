"""
Serviço de webhooks.

Chamado após operações que devem notificar o n8n.
O n8n decide o que fazer: mandar WhatsApp, e-mail, etc.

Regras de quando disparar:
  - alerta_saldo: quando o resumo mensal é calculado e saldo < 100
  - resumo_semanal: chamado pelo cron do n8n via GET /relatorio/semanal
    (o n8n agenda e chama; FastAPI apenas consolida e responde)
"""

import logging
from datetime import date, timedelta

from app.core.config import get_settings
from app.core.n8n_client import disparar_webhook
from app.schemas.relatorio import ResumoMensal
from app.schemas.webhook import PayloadAlertaSaldo, PayloadResumoSemanal

logger = logging.getLogger(__name__)


async def notificar_alerta_saldo(user_id: str, resumo: ResumoMensal) -> None:
    """
    Dispara alerta ao n8n quando o saldo do mês está no zero a zero.
    Chamado internamente pelo router de relatório após calcular o resumo.
    """
    if not resumo.alerta_zero_a_zero:
        return  # tudo bem, não precisa alertar

    cfg = get_settings()
    meses_pt = [
        "", "janeiro", "fevereiro", "março", "abril", "maio", "junho",
        "julho", "agosto", "setembro", "outubro", "novembro", "dezembro",
    ]
    nome_mes = meses_pt[resumo.mes]

    payload = PayloadAlertaSaldo(
        user_id=user_id,
        mes=resumo.mes,
        ano=resumo.ano,
        saldo_final=resumo.saldo_final,
        total_entrou=resumo.receita.liquido_atendimentos,
        total_saiu=resumo.gastos.total_saiu,
        mensagem=(
            f"⚠️ Atenção! Em {nome_mes}/{resumo.ano} o saldo do salão ficou em "
            f"R$ {resumo.saldo_final:.2f}. "
            "Pode ser hora de revisar a precificação dos serviços."
        ),
    )

    await disparar_webhook(cfg.n8n_webhook_alerta_saldo, payload.model_dump())
    logger.info(
        "Alerta de saldo disparado para user_id=%s mês=%d/%d saldo=%.2f",
        user_id, resumo.mes, resumo.ano, resumo.saldo_final,
    )


async def notificar_resumo_semanal(
    user_id: str,
    atendimentos: int,
    receita_bruta: float,
    gastos_pendentes: float,
) -> None:
    """
    Envia resumo semanal ao n8n.
    Normalmente chamado pelo endpoint GET /relatorio/semanal que o n8n
    chama via cron toda semana.
    """
    hoje = date.today()
    inicio_semana = hoje - timedelta(days=hoje.weekday())  # segunda-feira
    fim_semana = inicio_semana + timedelta(days=6)          # domingo

    saldo_semana = receita_bruta - gastos_pendentes

    cfg = get_settings()
    payload = PayloadResumoSemanal(
        user_id=user_id,
        semana_inicio=inicio_semana.isoformat(),
        semana_fim=fim_semana.isoformat(),
        atendimentos=atendimentos,
        receita_bruta=receita_bruta,
        gastos_pendentes=gastos_pendentes,
        saldo_semana=saldo_semana,
    )

    await disparar_webhook(cfg.n8n_webhook_resumo_semanal, payload.model_dump())
