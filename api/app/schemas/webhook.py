from pydantic import BaseModel


class PayloadAlertaSaldo(BaseModel):
    """Enviado ao n8n quando o saldo do mês fecha negativo ou no zero a zero."""
    user_id: str
    mes: int
    ano: int
    saldo_final: float
    total_entrou: float
    total_saiu: float
    mensagem: str


class PayloadResumoSemanal(BaseModel):
    """Enviado ao n8n toda semana (cron) com um resumo rápido."""
    user_id: str
    semana_inicio: str   # ISO date ex: "2025-05-12"
    semana_fim: str      # ISO date ex: "2025-05-18"
    atendimentos: int
    receita_bruta: float
    gastos_pendentes: float
    saldo_semana: float
