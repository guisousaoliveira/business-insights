/**
 * Rotas — espelho de `settings/app_api.dart` (Flutter) e de
 * `.specs/endpoints-backend.md`.
 *
 * **Nenhuma string de URL mora fora daqui.** É o item da checklist de
 * conformidade que faz um `PATCH` renomeado no backend virar um diff de uma
 * linha, e não uma caçada por `fetch(` no projeto inteiro.
 *
 * O prefixo `/v1` e o host vêm do `AppEnvironment` — estes paths são relativos
 * à base, como no Dio.
 */
export const Paths = {
  // auth
  login: "/auth/login",
  refresh: "/auth/refresh",
  logout: "/auth/logout",
  eu: "/auth/eu",

  // atendimentos
  atendimentos: "/atendimentos",
  atendimento: (id: string) => `/atendimentos/${id}`,
  finalizarAtendimento: (id: string) => `/atendimentos/${id}/finalizar`,
  cancelarAtendimento: (id: string) => `/atendimentos/${id}/cancelar`,

  // gastos
  gastos: "/gastos",
  gasto: (id: string) => `/gastos/${id}`,
  pagarGasto: (id: string) => `/gastos/${id}/pagar`,

  // resumo
  resumoMensal: "/resumo/mensal",
  precificacao: "/precificacao/calcular",

  // estoque
  estoqueItens: "/estoque/itens",
  estoqueItem: (id: string) => `/estoque/itens/${id}`,
  movimentacoesDoItem: (id: string) => `/estoque/itens/${id}/movimentacoes`,
  movimentacoes: "/estoque/movimentacoes",

  // kits
  kits: "/kits",
  kit: (id: string) => `/kits/${id}`,
  montarKit: (id: string) => `/kits/${id}/montar`,
  venderKit: (id: string) => `/kits/${id}/vender`,

  // perfil
  perfil: "/perfil",
  custosFixos: "/perfil/custos-fixos",
  custoFixo: (id: string) => `/perfil/custos-fixos/${id}`,
  pagarCustoFixo: (id: string) => `/perfil/custos-fixos/${id}/pagar`,

  // servicos
  servicos: "/servicos",
  servico: (id: string) => `/servicos/${id}`,

  // alertas
  alertas: "/alertas",
  lerAlerta: (id: string) => `/alertas/${id}/lido`,
  lerTodosAlertas: "/alertas/lidos",
  preferenciasAlerta: "/alertas/preferencias",
  dispositivos: "/dispositivos",
  dispositivo: (token: string) => `/dispositivos/${encodeURIComponent(token)}`,
} as const;
