FROM python:3.12-slim

WORKDIR /app

# Dependências do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Dependências Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Código da aplicação
COPY app/ ./app/

# Usuário não-root por segurança
RUN useradd -m -u 1000 appuser && chown -R appuser /app
USER appuser

EXPOSE 8080

# Cloud Run injeta a variável PORT (padrão 8080) — o container precisa escutar
# nela, não numa porta fixa. Forma shell (não exec) pra $PORT ser expandida.
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}
