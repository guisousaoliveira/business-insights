import 'package:intl/intl.dart';

import 'app_enums.dart';
import 'app_globals.dart' as globals;
import 'app_routes.dart';
import 'app_storage.dart';

/// Helpers puros: formatação, conversão `String da API ↔ enum do app`, logout.
///
/// **Toda conversão enum ↔ API mora aqui**, nunca espalhada nos models (regra 6).
/// O contrato usa **strings**, não inteiros — reordenar um enum não pode virar
/// quebra silenciosa (§0 de `endpoints-backend.md`).
class AppUtils {
  const AppUtils._();

  static String get _locale => globals.l10n?.localeName ?? 'pt_BR';

  // ── Formatação ─────────────────────────────────────────────────────────────

  /// `R$ 1.240,00`. Com `withCents: false`, trunca — usado só onde o protótipo
  /// mostra valor redondo.
  static String numToMoney(num value, {bool withCents = true}) =>
      NumberFormat.simpleCurrency(
        locale: _locale,
        decimalDigits: withCents ? 2 : 0,
      ).format(withCents ? value : value.truncate());

  /// `45,00` — valor cru para pré-preencher campo de dinheiro. Sem símbolo:
  /// `R$` dentro do campo faz a máscara de entrada brigar com o texto.
  static String numToInput(num value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  /// `41.5%` — margem, variação.
  static String numToPercent(num value, {int decimals = 1}) =>
      '${value.toStringAsFixed(decimals)}%';

  /// `+18.0%` / `−12.4%`. O sinal é informação: diz se subiu ou desceu.
  static String numToSignedPercent(num value, {int decimals = 1}) {
    final sign = value > 0 ? '+' : (value < 0 ? '−' : '');
    return '$sign${value.abs().toStringAsFixed(decimals)}%';
  }

  /// Quantidade de estoque: `30` e não `30.0`, mas `1.5` quando fracionária.
  static String quantityToString(num value) =>
      value == value.truncate() ? value.toInt().toString() : value.toString();

  static String dateToShort(DateTime date) =>
      DateFormat('dd/MM', _locale).format(date);

  static String dateToFull(DateTime date) =>
      DateFormat('dd/MM/yyyy', _locale).format(date);

  static String dateToMonthYear(DateTime date) =>
      DateFormat('MMM/yyyy', _locale).format(date);

  static String dateToMonthName(DateTime date) =>
      _capitalize(DateFormat('MMMM', _locale).format(date));

  static String dateToMonthYearLong(DateTime date) =>
      _capitalize(DateFormat("MMMM 'de' yyyy", _locale).format(date));

  static String dateToMonthShort(DateTime date) =>
      DateFormat('MMM', _locale).format(date).replaceAll('.', '');

  static String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  /// Data por extenso do jeito que o protótipo escreve: "2 dias atrás",
  /// "amanhã", "hoje". Cai para `dd/MM` acima de 30 dias.
  static String dateToRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final days = target.difference(today).inDays;

    return switch (days) {
      0 => 'hoje',
      1 => 'amanhã',
      -1 => 'ontem',
      > 1 && <= 30 => 'em $days dias',
      < -1 && >= -30 => '${-days} dias atrás',
      _ => dateToShort(date),
    };
  }

  /// A API recebe e devolve `date` puro em prazo de gasto.
  static String dateToApi(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  // ── Sessão ─────────────────────────────────────────────────────────────────

  /// Um `clear()` derruba sessão e caches. Chamado pelo menu e pelo
  /// interceptor de 401 — nunca por um cubit diretamente.
  static Future<void> logout() async {
    await AppStorage.clear();
    await AppRoutes.push(AppRoutes.loginRoute, removeUntil: (_) => false);
  }

  // ── Atendimento ────────────────────────────────────────────────────────────

  static StatusAtendimento decodeStatusAtendimento(String? value) =>
      switch (value) {
        'agendado' => StatusAtendimento.agendado,
        'cancelado' => StatusAtendimento.cancelado,
        _ => StatusAtendimento.finalizado,
      };

  static String statusAtendimentoToApi(StatusAtendimento status) =>
      switch (status) {
        StatusAtendimento.agendado => 'agendado',
        StatusAtendimento.finalizado => 'finalizado',
        StatusAtendimento.cancelado => 'cancelado',
      };

  static String statusAtendimentoToString(StatusAtendimento status) {
    final l10n = globals.l10n;
    if (l10n == null) return statusAtendimentoToApi(status);
    return switch (status) {
      StatusAtendimento.agendado => l10n.statusScheduled,
      StatusAtendimento.finalizado => l10n.statusFinished,
      StatusAtendimento.cancelado => l10n.statusCanceled,
    };
  }

  // ── Gasto ──────────────────────────────────────────────────────────────────

  static FormaPagamento decodeFormaPagamento(String? value) => switch (value) {
        'credito' => FormaPagamento.credito,
        'debito' => FormaPagamento.debito,
        'pix' => FormaPagamento.pix,
        _ => FormaPagamento.aVista,
      };

  static String formaPagamentoToApi(FormaPagamento forma) => switch (forma) {
        FormaPagamento.aVista => 'a_vista',
        FormaPagamento.credito => 'credito',
        FormaPagamento.debito => 'debito',
        FormaPagamento.pix => 'pix',
      };

  static String formaPagamentoToString(FormaPagamento forma) {
    final l10n = globals.l10n;
    if (l10n == null) return formaPagamentoToApi(forma);
    return switch (forma) {
      FormaPagamento.aVista => l10n.paymentCash,
      FormaPagamento.credito => l10n.paymentCredit,
      FormaPagamento.debito => l10n.paymentDebit,
      FormaPagamento.pix => l10n.paymentPix,
    };
  }

  static CategoriaGasto decodeCategoriaGasto(String? value) => switch (value) {
        'fixo' => CategoriaGasto.fixo,
        'material' => CategoriaGasto.material,
        _ => CategoriaGasto.outros,
      };

  static String categoriaGastoToApi(CategoriaGasto categoria) =>
      switch (categoria) {
        CategoriaGasto.fixo => 'fixo',
        CategoriaGasto.material => 'material',
        CategoriaGasto.outros => 'outros',
      };

  static String categoriaGastoToString(CategoriaGasto categoria) {
    final l10n = globals.l10n;
    if (l10n == null) return categoriaGastoToApi(categoria);
    return switch (categoria) {
      CategoriaGasto.fixo => l10n.categoryFixed,
      CategoriaGasto.material => l10n.categoryMaterial,
      CategoriaGasto.outros => l10n.categoryOther,
    };
  }

  // ── Estoque ────────────────────────────────────────────────────────────────

  static StatusEstoque decodeStatusEstoque(String? value) => switch (value) {
        'negativo' => StatusEstoque.negativo,
        'critico' => StatusEstoque.critico,
        'alerta' => StatusEstoque.alerta,
        _ => StatusEstoque.ok,
      };

  static String statusEstoqueToString(StatusEstoque status) {
    final l10n = globals.l10n;
    if (l10n == null) return status.name;
    return switch (status) {
      StatusEstoque.negativo => l10n.stockNegative,
      StatusEstoque.critico => l10n.stockCritical,
      StatusEstoque.alerta => l10n.stockAlert,
      StatusEstoque.ok => '',
    };
  }

  static CategoriaEstoque decodeCategoriaEstoque(String? value) =>
      switch (value) {
        'cilios' => CategoriaEstoque.cilios,
        'sobrancelha' => CategoriaEstoque.sobrancelha,
        'limpeza_pele' => CategoriaEstoque.limpezaPele,
        'descartavel' => CategoriaEstoque.descartavel,
        _ => CategoriaEstoque.outro,
      };

  static String categoriaEstoqueToApi(CategoriaEstoque categoria) =>
      switch (categoria) {
        CategoriaEstoque.cilios => 'cilios',
        CategoriaEstoque.sobrancelha => 'sobrancelha',
        CategoriaEstoque.limpezaPele => 'limpeza_pele',
        CategoriaEstoque.descartavel => 'descartavel',
        CategoriaEstoque.outro => 'outro',
      };

  static UnidadeEstoque decodeUnidadeEstoque(String? value) => switch (value) {
        'ml' => UnidadeEstoque.ml,
        'g' => UnidadeEstoque.g,
        'cx' => UnidadeEstoque.cx,
        _ => UnidadeEstoque.un,
      };

  /// Sufixo exibido: `un.`, `cx.`, `ml`, `g` — como no protótipo.
  static String unidadeEstoqueToString(UnidadeEstoque unidade) =>
      switch (unidade) {
        UnidadeEstoque.un => 'un.',
        UnidadeEstoque.cx => 'cx.',
        UnidadeEstoque.ml => 'ml',
        UnidadeEstoque.g => 'g',
      };

  static TipoMovimentacao decodeTipoMovimentacao(String? value) =>
      switch (value) {
        'saida' => TipoMovimentacao.saida,
        'ajuste' => TipoMovimentacao.ajuste,
        _ => TipoMovimentacao.entrada,
      };

  static String tipoMovimentacaoToApi(TipoMovimentacao tipo) => switch (tipo) {
        TipoMovimentacao.entrada => 'entrada',
        TipoMovimentacao.saida => 'saida',
        TipoMovimentacao.ajuste => 'ajuste',
      };

  static String tipoMovimentacaoToString(TipoMovimentacao tipo) {
    final l10n = globals.l10n;
    if (l10n == null) return tipoMovimentacaoToApi(tipo);
    return switch (tipo) {
      TipoMovimentacao.entrada => l10n.stockEntry,
      TipoMovimentacao.saida => l10n.stockExit,
      TipoMovimentacao.ajuste => l10n.stockAdjustment,
    };
  }

  // ── Alertas ────────────────────────────────────────────────────────────────

  static TipoAlerta decodeTipoAlerta(String? value) => switch (value) {
        'estoque_negativo' => TipoAlerta.estoqueNegativo,
        'estoque_critico' => TipoAlerta.estoqueCritico,
        'estoque_baixo' => TipoAlerta.estoqueBaixo,
        'gasto_a_vencer' => TipoAlerta.gastoAVencer,
        'gasto_vencido' => TipoAlerta.gastoVencido,
        'saldo_negativo' => TipoAlerta.saldoNegativo,
        _ => TipoAlerta.zeroAZero,
      };

  static SeveridadeAlerta decodeSeveridadeAlerta(String? value) =>
      switch (value) {
        'critico' => SeveridadeAlerta.critico,
        'alerta' => SeveridadeAlerta.alerta,
        _ => SeveridadeAlerta.info,
      };

  /// Alerta → rota de destino. O servidor não conhece rotas de UI; o
  /// mapeamento é do app (§9 de `endpoints-backend.md`).
  static String routeForAlerta(TipoAlerta tipo) => switch (tipo) {
        TipoAlerta.estoqueNegativo ||
        TipoAlerta.estoqueCritico ||
        TipoAlerta.estoqueBaixo =>
          AppRoutes.estoqueRoute,
        TipoAlerta.gastoAVencer ||
        TipoAlerta.gastoVencido =>
          AppRoutes.gastosRoute,
        TipoAlerta.saldoNegativo ||
        TipoAlerta.zeroAZero =>
          AppRoutes.resumoRoute,
      };
}
