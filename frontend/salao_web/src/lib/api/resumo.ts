import { AppApi } from "../http";
import type { ResumoMensal } from "../types";
import { Paths } from "./paths";

/**
 * `resumo` — 2 operações (§4 do contrato).
 *
 * A consolidação inteira vem pronta: histórico de seis meses, insights,
 * comparativo com o mês anterior. **Nada disso é somado no navegador** — é a
 * mesma conta que alimenta o push e o n8n, e não pode divergir entre eles.
 */

export interface PrecificacaoBody {
  custo_material: number;
  tempo_minutos: number;
  meta_hora: number;
  percentual_overhead?: number;
  percentual_lucro?: number;
}

export interface Precificacao {
  custo_material: number;
  custo_tempo: number;
  custo_overhead: number;
  custo_total: number;
  preco_minimo: number;
  /** `preco_minimo` arredondado para o próximo R$5 — é o número que ela cobra. */
  preco_sugerido: number;
  cobrindo_custos: boolean | null;
  diferenca: number | null;
}

export const ResumoApi = {
  mensal(params: { ano: number; mes: number }): Promise<ResumoMensal> {
    return AppApi.get<ResumoMensal>(Paths.resumoMensal, params).then((r) => r.result);
  },

  /** Cálculo puro: não toca no banco. `preco_atual` é query, não corpo. */
  calcularPreco(body: PrecificacaoBody, precoAtual?: number): Promise<Precificacao> {
    return AppApi.post<Precificacao>(Paths.precificacao, body, {
      preco_atual: precoAtual,
    }).then((r) => r.result);
  },
} as const;
