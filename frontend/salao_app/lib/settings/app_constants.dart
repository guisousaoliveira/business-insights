import 'package:flutter/widgets.dart';

import '../models/dropdown_model.dart';
import 'app_enums.dart';
import 'app_utils.dart';

/// Listas de opções para a UI.
///
/// **São sempre funções que recebem `context`, nunca campos `static`** (regra 8):
/// campo estático é resolvido uma vez e não reage a troca de idioma — e, se for
/// lido antes do primeiro frame, `l10n` é `null` e explode.
///
/// Esta é a exceção tolerada do grafo de dependências: `settings/` monta opções
/// para a UI.
class AppConstants {
  const AppConstants._();

  static List<DropdownModel> formasPagamento(BuildContext context) =>
      FormaPagamento.values
          .map((e) => DropdownModel(
                key: AppUtils.formaPagamentoToString(e),
                value: e,
              ))
          .toList();

  static List<DropdownModel> categoriasGasto(BuildContext context) =>
      CategoriaGasto.values
          .map((e) => DropdownModel(
                key: AppUtils.categoriaGastoToString(e),
                value: e,
              ))
          .toList();

  static List<DropdownModel> categoriasEstoque(BuildContext context) =>
      CategoriaEstoque.values
          .map((e) => DropdownModel(key: _categoriaEstoqueLabel(e), value: e))
          .toList();

  static List<DropdownModel> unidadesEstoque(BuildContext context) =>
      UnidadeEstoque.values
          .map((e) => DropdownModel(
                key: AppUtils.unidadeEstoqueToString(e),
                value: e,
              ))
          .toList();

  /// Últimos 12 meses, do mais recente para o mais antigo — o seletor de
  /// período da tela de Resumo.
  static List<DropdownModel> periodos(BuildContext context) {
    final now = DateTime.now();
    return List.generate(12, (index) {
      final date = DateTime(now.year, now.month - index);
      return DropdownModel(key: AppUtils.dateToMonthYear(date), value: date);
    });
  }

  /// Rótulos de categoria de estoque não estão no ARB porque são vocabulário do
  /// negócio, não texto de interface — mudam com o salão, não com o idioma.
  static String _categoriaEstoqueLabel(CategoriaEstoque categoria) =>
      switch (categoria) {
        CategoriaEstoque.cilios => 'Cílios',
        CategoriaEstoque.sobrancelha => 'Sobrancelha',
        CategoriaEstoque.limpezaPele => 'Limpeza de pele',
        CategoriaEstoque.descartavel => 'Descartável',
        CategoriaEstoque.outro => 'Outro',
      };

  static String categoriaEstoqueLabel(CategoriaEstoque categoria) =>
      _categoriaEstoqueLabel(categoria);
}
