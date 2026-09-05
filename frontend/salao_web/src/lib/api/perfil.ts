import { AppApi } from "../http";
import type { CustosFixosPagina, Perfil } from "../types";
import { Paths } from "./paths";

/**
 * `perfil` — 7 operações (§7 do contrato).
 *
 * O custo fixo é **cadastro recorrente**, não lançamento: o aluguel existe uma
 * vez e se comporta como pendente ou pago conforme a competência consultada.
 * É o que evita cadastrar "aluguel de setembro" e "aluguel de outubro" como
 * duas coisas diferentes.
 */

export interface PerfilBody {
  nome: string;
  proprietaria: string;
  telefone_whatsapp?: string | null;
  meta_faturamento_mensal?: number;
}

export interface CustoFixoBody {
  descricao: string;
  valor: number;
  /** Dia literal 1–31. "Todo dia 31" continua 31 em fevereiro. */
  dia_vencimento: number;
}

export const PerfilApi = {
  obter(): Promise<{ salao: Perfil }> {
    return AppApi.get<{ salao: Perfil }>(Paths.perfil).then((r) => r.result);
  },

  atualizar(body: PerfilBody): Promise<void> {
    return AppApi.put(Paths.perfil, body).then(() => undefined);
  },

  /** `competencia` no formato `AAAA-MM`; ausente vale o mês corrente. */
  listarCustosFixos(competencia?: string): Promise<CustosFixosPagina> {
    return AppApi.get<CustosFixosPagina>(Paths.custosFixos, { competencia }).then((r) => r.result);
  },

  criarCustoFixo(body: CustoFixoBody): Promise<void> {
    return AppApi.post(Paths.custosFixos, body).then(() => undefined);
  },

  editarCustoFixo(id: string, body: Partial<CustoFixoBody>): Promise<void> {
    return AppApi.patch(Paths.custoFixo(id), body).then(() => undefined);
  },

  excluirCustoFixo(id: string): Promise<void> {
    return AppApi.delete(Paths.custoFixo(id)).then(() => undefined);
  },

  /**
   * Marca (ou desmarca) o pagamento de **uma competência**.
   *
   * `pago: false` desmarca — errar o clique numa conta que ela não pagou é
   * comum, e sem isto a única saída seria apagar o cadastro do aluguel.
   */
  pagarCustoFixo(id: string, competencia: string, pago: boolean): Promise<void> {
    return AppApi.patch(Paths.pagarCustoFixo(id), { competencia, pago }).then(() => undefined);
  },
} as const;
