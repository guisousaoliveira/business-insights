/// Todos os enums do app moram aqui — regra 5 do padrão.
/// Nenhum enum é declarado em model, cubit ou tela.
library;

// ── Infra ────────────────────────────────────────────────────────────────────

/// Não existe estado de erro: erro é o *tipo* do dado em `BlocSubState.data`.
enum BlocDataState { idle, loading, completed }

enum SnackBarStatus { sucess, error, alert }

enum DeviceType { tablet, tabletLandscape, mobile }

/// Item ativo da navegação — consumido pela barra inferior.
enum AppCurrentRoute { atendimentos, gastos, resumo, estoque, perfil, alertas }

// ── Atendimentos ─────────────────────────────────────────────────────────────

enum StatusAtendimento { agendado, finalizado, cancelado }

/// A janela que a lista de atendimentos mostra. Mora aqui, e não na tela,
/// porque o intervalo de datas de cada uma é regra (`AppUtils.rangeDoPeriodo`),
/// não rótulo.
enum PeriodoAtendimentos { esteMes, mesPassado, ultimosTresMeses, todos }

// ── Gastos ───────────────────────────────────────────────────────────────────

enum FormaPagamento { aVista, credito, debito, pix }

enum CategoriaGasto { fixo, material, outros }

enum FiltroSituacaoGasto { todos, pendentes, pagos, vencidos }

// ── Estoque ──────────────────────────────────────────────────────────────────

/// `negativo` é estado válido: vem de finalizar atendimento sem saldo com a
/// confirmação da usuária (§2 de `endpoints-backend.md`). Precisa ser distinto
/// de `critico` — "acabou" e "devo mais do que tenho" pedem ações diferentes.
enum StatusEstoque { ok, alerta, critico, negativo }

enum CategoriaEstoque { cilios, sobrancelha, limpezaPele, descartavel, outro }

enum UnidadeEstoque { un, ml, g, cx }

enum TipoMovimentacao { entrada, saida, ajuste }

enum SecaoEstoque { produtos, kits, movimentacoes }

enum SecaoPerfil { dados, custos, servicos }

// ── Alertas ──────────────────────────────────────────────────────────────────

enum TipoAlerta {
  estoqueNegativo,
  estoqueCritico,
  estoqueBaixo,
  gastoAVencer,
  gastoVencido,
  custoFixoAVencer,
  custoFixoVencido,
  saldoNegativo,
  zeroAZero,
}

enum SeveridadeAlerta { info, alerta, critico }

enum CanalAlerta { inApp, push, whatsapp, email }

enum PlataformaDispositivo { android, ios, web }
