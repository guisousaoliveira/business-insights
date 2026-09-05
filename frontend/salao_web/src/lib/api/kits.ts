import { AppApi } from "../http";
import type { FormaPagamento, Kit } from "../types";
import { Paths } from "./paths";

/**
 * `kits` — 6 operações (§6 do contrato).
 *
 * Montar e vender são **fatos separados** (A7): ela monta cinco kits numa tarde
 * e vende ao longo das semanas. Por isso o kit tem saldo próprio.
 *
 * ```
 * estoque de insumos ──montar──▶ kits montados ──vender──▶ receita
 * ```
 */

export interface KitBody {
  nome: string;
  preco_venda: number;
  itens: { item_estoque_id: string; quantidade: number }[];
}

export const KitsApi = {
  listar(): Promise<{ kits: Kit[] }> {
    return AppApi.get<{ kits: Kit[] }>(Paths.kits).then((r) => r.result);
  },

  criar(body: KitBody): Promise<void> {
    return AppApi.post(Paths.kits, body).then(() => undefined);
  },

  editar(id: string, body: Partial<KitBody>): Promise<void> {
    return AppApi.patch(Paths.kit(id), body).then(() => undefined);
  },

  excluir(id: string): Promise<void> {
    return AppApi.delete(Paths.kit(id)).then(() => undefined);
  },

  /**
   * Consome insumo e incrementa `quantidade_montada`.
   *
   * Passa pelo aviso de A5: sem `confirmar_estoque_insuficiente`, falta de
   * insumo devolve `409 ESTOQUE_INSUFICIENTE` sem gravar nada.
   */
  montar(id: string, quantidade: number, confirmarEstoqueInsuficiente = false): Promise<void> {
    return AppApi.post(Paths.montarKit(id), {
      quantidade,
      confirmar_estoque_insuficiente: confirmarEstoqueInsuficiente,
    }).then(() => undefined);
  },

  /**
   * Decrementa `quantidade_montada` e grava a venda com snapshot de preço e custo.
   *
   * **Sem segunda passada**: `KIT_NAO_MONTADO` é definitivo. Estoque negativo
   * representa consumo que já aconteceu; um kit que não existe não se vende.
   *
   * `preco_unitario` ausente vale o `preco_venda` do cadastro — existe para o
   * desconto de balcão, que acontece.
   */
  vender(
    id: string,
    body: {
      quantidade: number;
      forma_pagamento: FormaPagamento;
      preco_unitario?: number;
      data?: string;
    },
  ): Promise<void> {
    return AppApi.post(Paths.venderKit(id), body).then(() => undefined);
  },
} as const;
