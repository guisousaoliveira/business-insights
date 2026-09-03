/**
 * Tipos do contrato — espelho de `.specs/endpoints-backend.md`.
 *
 * Os campos são **snake_case**, iguais ao JSON do FastAPI: renomear na
 * fronteira criaria dois vocabulários para o mesmo dado, e a primeira
 * divergência apareceria só em produção. O que a tela quer com outro nome, a
 * tela apelida.
 *
 * Nada aqui é calculado no cliente. `status`, `deficit`, `saldo`, `margem`,
 * `vence_em_dias` e os totais vêm prontos do servidor (decisão A1) — a mesma
 * conta alimenta o resumo, o push e o n8n, e não pode divergir entre eles.
 */

// ── Enums ────────────────────────────────────────────────────────────────────

export type StatusAtendimento = "agendado" | "finalizado" | "cancelado";

export type CategoriaGasto = "fixo" | "material" | "outros";

export type FormaPagamento = "a_vista" | "credito" | "debito" | "pix";

/** `negativo` é distinto de `critico`: "devo mais do que tenho" ≠ "acabou" (A5). */
export type StatusEstoque = "ok" | "alerta" | "critico" | "negativo";

export type UnidadeEstoque = "un" | "ml" | "g" | "cx";

export type CategoriaEstoque = "cilios" | "sobrancelha" | "limpeza_pele" | "descartavel" | "outro";

export type TipoMovimentacao = "entrada" | "saida" | "ajuste";

export type SeveridadeAlerta = "critico" | "alerta" | "info";

export type TipoAlerta =
  | "estoque_negativo"
  | "estoque_critico"
  | "estoque_baixo"
  | "gasto_a_vencer"
  | "gasto_vencido"
  | "custo_fixo_a_vencer"
  | "custo_fixo_vencido"
  | "saldo_negativo"
  | "zero_a_zero";

export type ReferenciaAlerta = "estoque_item" | "gasto" | "custo_fixo" | null;

// ── auth ─────────────────────────────────────────────────────────────────────

export interface Usuario {
  id: string;
  nome: string;
  email: string;
}

export interface Salao {
  id: string;
  nome: string;
  foto_url: string | null;
}

export interface Sessao {
  token: string;
  refresh_token: string;
  expira_em: number;
  usuario: Usuario;
  salao: Salao;
}

// ── atendimentos ─────────────────────────────────────────────────────────────

/** Snapshot: preço congelado no atendimento, não o preço de hoje do catálogo. */
export interface AtendimentoServico {
  servico_id: string | null;
  nome: string;
  preco: number;
}

/** `item_estoque_id` nulo = material avulso, que não mexe no saldo do estoque. */
export interface AtendimentoMaterial {
  item_estoque_id: string | null;
  nome: string;
  quantidade: number;
  preco: number;
}

export interface Atendimento {
  id: string;
  cliente_nome: string;
  cliente_telefone: string | null;
  /** ISO-8601 com timezone. Data e hora são um campo só. */
  data: string;
  status: StatusAtendimento;
  servicos: AtendimentoServico[];
  materiais: AtendimentoMaterial[];
  total_servicos: number;
  total_materiais: number;
  saldo: number;
}

export interface AtendimentosPagina {
  saldo_liquido: number;
  quantidade: number;
  atendimentos: Atendimento[];
}

// ── gastos ───────────────────────────────────────────────────────────────────

export interface Gasto {
  id: string;
  nome: string;
  valor: number;
  /** `date` puro — é prazo, não registro. */
  prazo_pagamento: string;
  forma_pagamento: FormaPagamento;
  categoria: CategoriaGasto;
  pago: boolean;
  pago_em: string | null;
  /** Negativo = vencido. Quem calcula prazo é o servidor. */
  vence_em_dias: number;
  itens: { nome: string; preco: number }[];
}

export interface GastosPagina {
  total_pendente: number;
  total_pago_mes: number;
  gastos: Gasto[];
}

// ── estoque ──────────────────────────────────────────────────────────────────

export interface ItemEstoque {
  id: string;
  nome: string;
  unidade: UnidadeEstoque;
  categoria: CategoriaEstoque;
  quantidade_atual: number;
  quantidade_minima: number;
  /** Média ponderada móvel (A6) — é este que vale para margem e custo. */
  custo_medio: number;
  /** Informativo: quanto ela pagou na última vez. */
  custo_ultima_compra: number;
  status: StatusEstoque;
  deficit: number;
  ativo: boolean;
}

export interface EstoquePagina {
  total_alertas: number;
  valor_total: number;
  itens: ItemEstoque[];
}

export interface Movimentacao {
  id: string;
  item_id: string;
  item_nome: string;
  tipo: TipoMovimentacao;
  quantidade: number;
  motivo: string;
  atendimento_id: string | null;
  criado_em: string;
}

/** A lista que o `409 ESTOQUE_INSUFICIENTE` devolve em `result.faltantes` (A5). */
export interface FaltanteEstoque {
  item_estoque_id: string;
  nome: string;
  unidade: UnidadeEstoque;
  quantidade_solicitada: number;
  quantidade_disponivel: number;
  deficit: number;
}

// ── kits ─────────────────────────────────────────────────────────────────────

export interface KitItem {
  item_estoque_id: string;
  nome: string;
  quantidade: number;
  unidade: UnidadeEstoque;
}

export interface Kit {
  id: string;
  nome: string;
  preco_venda: number;
  custo_total: number;
  margem: number;
  /** Prontos na prateleira. */
  quantidade_montada: number;
  /** Quantos o estoque de hoje ainda cobre — `min(saldo ÷ composição)`. */
  quantidade_montavel: number;
  disponivel: boolean;
  itens: KitItem[];
}

// ── servicos ─────────────────────────────────────────────────────────────────

/** `nome` e `unidade` vêm resolvidos do item — a tela não cruza duas listas. */
export interface ProdutoPadrao {
  item_estoque_id: string;
  nome: string;
  quantidade: number;
  unidade: UnidadeEstoque;
}

export interface Servico {
  id: string;
  nome: string;
  preco: number;
  produtos_padrao: ProdutoPadrao[];
}

// ── perfil ───────────────────────────────────────────────────────────────────

export interface Perfil {
  id: string;
  nome: string;
  proprietaria: string;
  foto_url: string | null;
  telefone_whatsapp: string | null;
  meta_faturamento_mensal: number;
}

/**
 * `pago` não é campo do cadastro: é o estado do custo **naquela competência**.
 * O mesmo aluguel volta pago em setembro e pendente em outubro sem ninguém
 * desmarcar nada — é o que faz custo fixo se comportar como compromisso
 * recorrente, e não como lançamento.
 */
export interface CustoFixo {
  id: string;
  descricao: string;
  valor: number;
  /** Dia literal 1–31. "Todo dia 31" continua 31 em fevereiro. */
  dia_vencimento: number;
  competencia: string;
  pago: boolean;
  pago_em: string | null;
}

export interface CustosFixosPagina {
  total_mensal: number;
  total_pago: number;
  total_pendente: number;
  custos: CustoFixo[];
}

// ── resumo ───────────────────────────────────────────────────────────────────

export interface PontoHistorico {
  ano: number;
  mes: number;
  receitas: number;
  despesas: number;
}

export interface ServicoRealizado {
  nome: string;
  quantidade: number;
  total_receita: number;
  lucro: number;
}

export interface ResumoMensal {
  ano: number;
  mes: number;
  saldo_final: number;
  entrou: number;
  saiu: number;
  meta_faturamento_mensal: number;
  /** Sempre seis posições em ordem cronológica, inclusive meses zerados. */
  historico_seis_meses: PontoHistorico[];
  receita: {
    total_servicos: number;
    total_insumos: number;
    liquido_atendimentos: number;
    quantidade_atendimentos: number;
    total_kits: number;
    quantidade_kits_vendidos: number;
    /** Informativo: não entra em nenhuma soma do saldo. */
    custo_kits_vendidos: number;
    servicos_mais_realizados: ServicoRealizado[];
  };
  gastos: {
    total_custos_fixos: number;
    total_gastos_variaveis: number;
    total_saiu: number;
  };
  insights: {
    ticket_medio: number;
    margem_lucro_percentual: number;
    variacao_percentual_mes_anterior: number;
    saldo_mes_anterior: number;
    servico_mais_lucrativo: { nome: string; lucro: number } | null;
  };
  alerta_zero_a_zero: boolean;
}

// ── alertas ──────────────────────────────────────────────────────────────────

export interface Alerta {
  id: string;
  tipo: TipoAlerta;
  severidade: SeveridadeAlerta;
  titulo: string;
  mensagem: string;
  referencia_tipo: ReferenciaAlerta;
  referencia_id: string | null;
  criado_em: string;
  lido_em: string | null;
}

export interface AlertasPagina {
  total_nao_lidos: number;
  resumo: { critico: number; alerta: number; info?: number };
  alertas: Alerta[];
}

export interface PreferenciasAlerta {
  limite_saldo_alerta: number;
  dias_antecedencia_vencimento: number;
  canais: Record<"in_app" | "push" | "whatsapp" | "email", { ativo: boolean }>;
  tipos_silenciados: TipoAlerta[];
}
