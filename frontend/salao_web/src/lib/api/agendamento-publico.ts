import { AppApi } from "../http";
import type { AgendamentoCriado, AgendamentoPublicoPagina, HorariosDisponiveis } from "../types";
import { Paths } from "./paths";

/**
 * `agendamento_publico` — 3 operações (§10 do contrato).
 *
 * Único módulo sem sessão: o `slug` na URL identifica o salão (link fixo,
 * decisão B1). Confirmação é automática — não existe "pendente" aqui (B4).
 */

export interface AgendarBody {
  cliente_nome: string;
  cliente_telefone: string;
  /** ISO-8601 com horário e fuso. */
  data: string;
  servicos: { servico_id: string }[];
}

export const AgendamentoPublicoApi = {
  obterPagina(slug: string): Promise<AgendamentoPublicoPagina> {
    return AppApi.get<AgendamentoPublicoPagina>(Paths.agendamentoPublico(slug)).then(
      (r) => r.result,
    );
  },

  obterHorariosDisponiveis(
    slug: string,
    data: string,
    servicoIds: string[],
  ): Promise<HorariosDisponiveis> {
    return AppApi.get<HorariosDisponiveis>(Paths.horariosDisponiveisPublico(slug), {
      data,
      servico_ids: servicoIds.join(","),
    }).then((r) => r.result);
  },

  agendar(slug: string, body: AgendarBody): Promise<AgendamentoCriado> {
    return AppApi.post<AgendamentoCriado>(Paths.agendarPublico(slug), body).then((r) => r.result);
  },
} as const;
