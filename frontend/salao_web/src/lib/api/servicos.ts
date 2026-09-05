import { AppApi } from "../http";
import type { Servico } from "../types";
import { Paths } from "./paths";

/**
 * `servicos` — 4 operações (§8 do contrato).
 *
 * A tabela de preços, com os `produtos_padrao` de cada serviço: é o que faz o
 * "finalizar atendimento" já vir com os materiais preenchidos, em vez de ela
 * lembrar toda vez quanta cola gasta numa aplicação.
 */

export interface ServicoBody {
  nome: string;
  preco: number;
  produtos_padrao: { item_estoque_id: string; quantidade: number }[];
}

export const ServicosApi = {
  listar(): Promise<{ servicos: Servico[] }> {
    return AppApi.get<{ servicos: Servico[] }>(Paths.servicos).then((r) => r.result);
  },

  criar(body: ServicoBody): Promise<void> {
    return AppApi.post(Paths.servicos, body).then(() => undefined);
  },

  /** Mudar o preço não mexe em atendimento passado: lá o preço está congelado. */
  editar(id: string, body: Partial<ServicoBody>): Promise<void> {
    return AppApi.patch(Paths.servico(id), body).then(() => undefined);
  },

  excluir(id: string): Promise<void> {
    return AppApi.delete(Paths.servico(id)).then(() => undefined);
  },
} as const;
