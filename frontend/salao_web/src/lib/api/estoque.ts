import { AppApi } from "../http";
import type {
  CategoriaEstoque,
  EstoquePagina,
  Movimentacao,
  TipoMovimentacao,
  UnidadeEstoque,
} from "../types";
import { Paths } from "./paths";

/**
 * `estoque` — 6 operações (§5 do contrato).
 *
 * Saldo não se edita: ele é o acumulado das movimentações. Corrigir contagem é
 * lançar um `ajuste`, e é por isso que existe histórico.
 */

export interface ItemBody {
  nome: string;
  unidade: UnidadeEstoque;
  categoria: CategoriaEstoque;
  quantidade_atual: number;
  quantidade_minima: number;
  /** Vira o `custo_medio` inicial — daí em diante, média ponderada (A6). */
  custo_unitario: number;
}

export interface MovimentacaoBody {
  tipo: TipoMovimentacao;
  quantidade: number;
  motivo: string;
  /**
   * Só na `entrada`, e é o que recalcula a média ponderada móvel (A6):
   * `(saldo × custo_medio + quantidade × custo_unitario) / (saldo + quantidade)`.
   * Uma compra cara ou promocional não reescreve o custo do saldo parado.
   * `saida` e `ajuste` nunca mexem no custo.
   */
  custo_unitario?: number;
}

export const EstoqueApi = {
  listarItens(): Promise<EstoquePagina> {
    return AppApi.get<EstoquePagina>(Paths.estoqueItens).then((r) => r.result);
  },

  criarItem(body: ItemBody): Promise<void> {
    return AppApi.post(Paths.estoqueItens, body).then(() => undefined);
  },

  editarItem(id: string, body: Partial<ItemBody>): Promise<void> {
    return AppApi.patch(Paths.estoqueItem(id), body).then(() => undefined);
  },

  /** `409 ITEM_EM_USO` quando o item compõe kit ou serviço — some o item, some a conta. */
  excluirItem(id: string): Promise<void> {
    return AppApi.delete(Paths.estoqueItem(id)).then(() => undefined);
  },

  criarMovimentacao(itemId: string, body: MovimentacaoBody): Promise<void> {
    return AppApi.post(Paths.movimentacoesDoItem(itemId), body).then(() => undefined);
  },

  listarMovimentacoes(params?: {
    item_id?: string;
    inicio?: string;
    fim?: string;
    tipo?: TipoMovimentacao;
  }): Promise<{ movimentacoes: Movimentacao[] }> {
    return AppApi.get<{ movimentacoes: Movimentacao[] }>(Paths.movimentacoes, params).then(
      (r) => r.result,
    );
  },
} as const;
