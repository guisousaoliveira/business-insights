"""
Regras do agendamento público (endpoints-backend.md §10, lote L8).

Único módulo sem Authorization: o `slug` na URL identifica o salão e não é
secreto (a ideia é ser compartilhável). Por isso nenhuma consulta aqui pode
vazar dado sensível do módulo `perfil` (telefone, custo fixo, estoque) — só
nome, foto, serviços e preços, que já são públicos num cartão de visita.

Fuso horário: o salão opera num único fuso (Brasil, UTC-3, sem horário de
verão desde 2019) — fixo aqui em vez de por-usuária, porque não há motivo
para complicar um app de salão único com fusos múltiplos.
"""

from datetime import date, datetime, time, timedelta, timezone

from fastapi import HTTPException
from supabase import Client
from app.core.supabase_client import row, rows

STEP_MINUTOS = 30
TZ_SALAO = timezone(timedelta(hours=-3))


def buscar_salao_por_slug(supabase: Client, slug: str) -> dict:
    resp = (
        supabase.table("perfil_salao")
        .select("user_id, nome_salao, foto_url")
        .eq("slug_agendamento", slug)
        .execute()
    )
    linhas = rows(resp.data)
    if not linhas:
        raise HTTPException(
            status_code=404,
            detail={"codigo": "RECURSO_NAO_ENCONTRADO", "mensagem": "Link de agendamento inválido"},
        )
    return linhas[0]


def listar_servicos_publicos(supabase: Client, user_id: str) -> list[dict]:
    resp = (
        supabase.table("servicos")
        .select("id, nome, preco, duracao_minutos")
        .eq("user_id", user_id)
        .eq("ativo", True)
        .order("nome")
        .execute()
    )
    # Serviço sem duracao_minutos preenchida não pode ser oferecido no link
    # público — sem duração não dá para calcular horário livre nenhum (§8).
    return [s for s in rows(resp.data) if s.get("duracao_minutos")]


def _buscar_servicos_solicitados(supabase: Client, user_id: str, servico_ids: list[str]) -> list[dict]:
    if not servico_ids:
        raise HTTPException(
            status_code=422,
            detail={"codigo": "VALIDACAO_INVALIDA", "mensagem": "Selecione ao menos um serviço"},
        )
    resp = (
        supabase.table("servicos")
        .select("id, nome, preco, duracao_minutos, ativo")
        .eq("user_id", user_id)
        .in_("id", servico_ids)
        .execute()
    )
    encontrados = {str(s["id"]): s for s in rows(resp.data)}
    faltantes = [sid for sid in servico_ids if sid not in encontrados]
    if faltantes:
        raise HTTPException(
            status_code=422,
            detail={
                "codigo": "VALIDACAO_INVALIDA",
                "mensagem": "Serviço inválido para este salão",
                "result": {"servico_ids": faltantes},
            },
        )
    sem_duracao = [s["nome"] for s in encontrados.values() if not s.get("ativo") or not s.get("duracao_minutos")]
    if sem_duracao:
        raise HTTPException(
            status_code=422,
            detail={
                "codigo": "SERVICO_SEM_DURACAO",
                "mensagem": "Serviço sem duração cadastrada — fale com o salão",
                "result": {"servicos": sem_duracao},
            },
        )
    return [encontrados[sid] for sid in servico_ids]


def _dia_semana_app(d: date) -> int:
    # Python: segunda=0 ... domingo=6. App (§7 do mapa): domingo=0 ... sábado=6.
    return (d.weekday() + 1) % 7


def _buscar_expediente(supabase: Client, user_id: str, d: date) -> dict | None:
    resp = (
        supabase.table("horario_funcionamento")
        .select("ativo, hora_inicio, hora_fim")
        .eq("user_id", user_id)
        .eq("dia_semana", _dia_semana_app(d))
        .execute()
    )
    linhas = rows(resp.data)
    return linhas[0] if linhas else None


def _intervalos_ocupados(supabase: Client, user_id: str, d: date) -> list[tuple[datetime, datetime]]:
    inicio_dia = datetime.combine(d, time.min, tzinfo=TZ_SALAO)
    fim_dia = datetime.combine(d, time.max, tzinfo=TZ_SALAO)
    resp_atend = (
        supabase.table("atendimentos")
        .select("id, data")
        .eq("user_id", user_id)
        .in_("status", ["agendado", "finalizado"])
        .gte("data", inicio_dia.isoformat())
        .lte("data", fim_dia.isoformat())
        .execute()
    )
    atendimentos = rows(resp_atend.data)
    if not atendimentos:
        return []

    ids = [str(a["id"]) for a in atendimentos]
    resp_serv = (
        supabase.table("atendimento_servicos")
        .select("atendimento_id, servico_id")
        .in_("atendimento_id", ids)
        .execute()
    )
    servicos_linhas = rows(resp_serv.data)
    servico_ids = {str(s["servico_id"]) for s in servicos_linhas if s.get("servico_id")}
    duracoes: dict[str, int] = {}
    if servico_ids:
        resp_dur = (
            supabase.table("servicos")
            .select("id, duracao_minutos")
            .in_("id", list(servico_ids))
            .execute()
        )
        duracoes = {str(s["id"]): int(s["duracao_minutos"] or 0) for s in rows(resp_dur.data)}

    duracao_por_atendimento: dict[str, int] = {}
    for s in servicos_linhas:
        aid = str(s["atendimento_id"])
        sid = str(s.get("servico_id", ""))
        duracao_por_atendimento[aid] = (
            duracao_por_atendimento.get(aid, 0) + duracoes.get(sid, 0)
        )

    intervalos = []
    for a in atendimentos:
        inicio = datetime.fromisoformat(str(a["data"]))
        # Atendimento sem serviço vinculado (edge case raro) bloqueia um slot
        # mínimo em vez de não bloquear nada — evita sobreposição por engano.
        duracao = duracao_por_atendimento.get(str(a["id"])) or STEP_MINUTOS
        intervalos.append((inicio, inicio + timedelta(minutes=duracao)))
    return intervalos


def _slots_livres(supabase: Client, user_id: str, d: date, duracao_total_minutos: int) -> list[str]:
    if d < datetime.now(TZ_SALAO).date():
        return []

    expediente = _buscar_expediente(supabase, user_id, d)
    if expediente is None or not expediente["ativo"]:
        return []

    hora_inicio = time.fromisoformat(str(expediente["hora_inicio"]))
    hora_fim = time.fromisoformat(str(expediente["hora_fim"]))
    inicio_expediente = datetime.combine(d, hora_inicio, tzinfo=TZ_SALAO)
    fim_expediente = datetime.combine(d, hora_fim, tzinfo=TZ_SALAO)

    ocupados = _intervalos_ocupados(supabase, user_id, d)
    agora = datetime.now(TZ_SALAO)
    duracao_delta = timedelta(minutes=duracao_total_minutos)
    passo = timedelta(minutes=STEP_MINUTOS)

    horarios = []
    slot_inicio = inicio_expediente
    while slot_inicio + duracao_delta <= fim_expediente:
        slot_fim = slot_inicio + duracao_delta
        if slot_inicio >= agora:
            colide = any(slot_inicio < fim_o and inicio_o < slot_fim for inicio_o, fim_o in ocupados)
            if not colide:
                horarios.append(slot_inicio.strftime("%H:%M"))
        slot_inicio += passo

    return horarios


def calcular_horarios_disponiveis(
    supabase: Client, user_id: str, data_str: str, servico_ids: list[str]
) -> tuple[int, list[str]]:
    servicos = _buscar_servicos_solicitados(supabase, user_id, servico_ids)
    duracao_total = sum(int(s["duracao_minutos"]) for s in servicos)
    d = date.fromisoformat(data_str)
    horarios = _slots_livres(supabase, user_id, d, duracao_total)
    return duracao_total, horarios


def criar_agendamento(
    supabase: Client,
    user_id: str,
    cliente_nome: str,
    cliente_telefone: str,
    data_hora: datetime,
    servico_ids: list[str],
) -> dict:
    servicos = _buscar_servicos_solicitados(supabase, user_id, servico_ids)
    duracao_total = sum(int(s["duracao_minutos"]) for s in servicos)

    data_hora_salao = data_hora.astimezone(TZ_SALAO)
    horarios_livres = _slots_livres(supabase, user_id, data_hora_salao.date(), duracao_total)

    # Revalida contra a agenda no exato momento de gravar (§10): não confia no
    # que o GET horarios-disponiveis devolveu segundos atrás — dois clientes
    # podem estar olhando o mesmo horário ao mesmo tempo. Ainda existe uma
    # janela de corrida entre esta checagem e o insert abaixo (não há
    # constraint de exclusão no banco); aceitável para o volume de um salão
    # só, mas é a limitação conhecida deste endpoint.
    if data_hora_salao.strftime("%H:%M") not in horarios_livres:
        raise HTTPException(
            status_code=409,
            detail={
                "codigo": "HORARIO_INDISPONIVEL",
                "mensagem": "Esse horário acabou de ficar indisponível, escolha outro",
            },
        )

    resp_atend = (
        supabase.table("atendimentos")
        .insert({
            "user_id": user_id,
            "nome_cliente": cliente_nome,
            "telefone_cliente": cliente_telefone,
            "data": data_hora.isoformat(),
            "status": "agendado",
            "origem": "publico",
        })
        .execute()
    )
    atendimento = row(resp_atend.data)

    linhas_servico = [
        {
            "atendimento_id": atendimento["id"],
            "servico_id": s["id"],
            "nome_servico": s["nome"],
            "preco_snapshot": s["preco"],
        }
        for s in servicos
    ]
    supabase.table("atendimento_servicos").insert(linhas_servico).execute()

    supabase.table("alertas").insert({
        "user_id": user_id,
        "tipo": "agendamento_publico_novo",
        "severidade": "info",
        "titulo": f"Novo agendamento pelo link: {cliente_nome}",
        "mensagem": f"{cliente_nome} marcou horário para {data_hora_salao.strftime('%d/%m às %H:%M')}",
        "referencia_tipo": "atendimento",
        "referencia_id": atendimento["id"],
        "chave_dedupe": f"agendamento_publico:{atendimento['id']}",
    }).execute()

    return {
        "id": atendimento["id"],
        "data": atendimento["data"],
        "status": atendimento["status"],
        "servicos": [{"servico_id": s["id"], "nome": s["nome"], "preco": s["preco"]} for s in servicos],
    }
