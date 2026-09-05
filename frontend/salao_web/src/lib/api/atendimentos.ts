import { AppApi } from "../http";
import type { Atendimento, AtendimentosPagina, StatusAtendimento } from "../types";
import { Paths } from "./paths";

/**
 * `atendimentos` — 7 operações (§2 do contrato).
 *
 * Um atendimento tem **N serviços**, não um só: "sobrancelha + cílios na mesma
 * cadeira" é um atendimento, e é assim que o saldo do dia fecha.
 */

/** Do catálogo (`servico_id`) ou avulso (`nome` + `preco`) — nunca os dois. */
export type ServicoEntrada = { servico_id: string } | { nome: string; preco: number };

/**
 * Do estoque (`item_estoque_id`, baixa o saldo) ou avulso (`nome` + `preco`,
 * só entra no custo).
 */
export type MaterialEntrada =
  | { item_estoque_id: string; quantidade: number }
  | { nome: string; quantidade: number; preco: number };

export interface AtendimentoBody {
  cliente_nome: string;
  cliente_telefone?: string | null;
  /** ISO-8601 com offset. Data e hora são um campo só. */
  data: string;
  servicos: ServicoEntrada[];
}

export interface FinalizarBody {
  materiais: MaterialEntrada[];
  /**
   * Segunda passada de A5. `false` na primeira tentativa: o servidor não grava
   * nada e devolve `409 ESTOQUE_INSUFICIENTE` com `result.faltantes`. Só depois
   * do "registrar mesmo assim" isto vai `true` — e aí o saldo fica negativo de
   * propósito, porque o produto foi usado de verdade.
   */
  confirmar_estoque_insuficiente: boolean;
}

export const AtendimentosApi = {
  listar(params: {
    inicio: string;
    fim: string;
    status?: StatusAtendimento[];
  }): Promise<AtendimentosPagina> {
    return AppApi.get<AtendimentosPagina>(Paths.atendimentos, {
      inicio: params.inicio,
      fim: params.fim,
      // Filtro vazio é filtro ausente: "todos" não vira `status=` para o
      // servidor ter que interpretar.
      status: params.status?.length ? params.status.join(",") : undefined,
    }).then((r) => r.result);
  },

  obter(id: string): Promise<Atendimento> {
    return AppApi.get<Atendimento>(Paths.atendimento(id)).then((r) => r.result);
  },

  criar(body: AtendimentoBody): Promise<void> {
    return AppApi.post(Paths.atendimentos, body).then(() => undefined);
  },

  editar(id: string, body: AtendimentoBody): Promise<void> {
    return AppApi.patch(Paths.atendimento(id), body).then(() => undefined);
  },

  /** Lança `ApiError` com `ESTOQUE_INSUFICIENTE` na primeira passada (A5). */
  finalizar(id: string, body: FinalizarBody): Promise<void> {
    return AppApi.patch(Paths.finalizarAtendimento(id), body).then(() => undefined);
  },

  /** Devolve ao estoque o que um atendimento já finalizado tinha consumido. */
  cancelar(id: string): Promise<void> {
    return AppApi.patch(Paths.cancelarAtendimento(id)).then(() => undefined);
  },

  excluir(id: string): Promise<void> {
    return AppApi.delete(Paths.atendimento(id)).then(() => undefined);
  },
} as const;
