import { AppApi } from "../http";
import type { CategoriaGasto, FormaPagamento, GastosPagina } from "../types";
import { Paths } from "./paths";

/**
 * `gastos` — 5 operações (§3 do contrato).
 *
 * Gasto é compromisso com prazo, não lançamento no caixa: nasce pendente e a
 * baixa é um ato separado (`/pagar`). `vence_em_dias` vem do servidor — é a
 * mesma conta que gera o alerta de vencimento.
 */
export interface GastoBody {
  nome: string;
  valor: number;
  /** `date` puro, `AAAA-MM-DD`. */
  prazo_pagamento: string;
  forma_pagamento: FormaPagamento;
  categoria: CategoriaGasto;
  itens?: { nome: string; preco: number }[];
}

export const GastosApi = {
  listar(params: { ano: number; mes: number }): Promise<GastosPagina> {
    return AppApi.get<GastosPagina>(Paths.gastos, params).then((r) => r.result);
  },

  criar(body: GastoBody): Promise<void> {
    return AppApi.post(Paths.gastos, body).then(() => undefined);
  },

  editar(id: string, body: Partial<GastoBody>): Promise<void> {
    return AppApi.patch(Paths.gasto(id), body).then(() => undefined);
  },

  /** Pagar de novo é `409 GASTO_JA_PAGO` — a baixa não é idempotente à toa. */
  pagar(id: string): Promise<void> {
    return AppApi.patch(Paths.pagarGasto(id)).then(() => undefined);
  },

  excluir(id: string): Promise<void> {
    return AppApi.delete(Paths.gasto(id)).then(() => undefined);
  },
} as const;
