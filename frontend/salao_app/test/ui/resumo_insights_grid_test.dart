import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app/l10n/app_localizations.dart';
import 'package:salon_app/models/resumo/get_resumo_mensal_response_model.dart';
import 'package:salon_app/repositories/demo/demo_database.dart';
import 'package:salon_app/ui/screens/resumo/widgets/resumo_insights_grid.dart';

/// O grid de insights mora dentro de uma tela que rola, então a altura que
/// chega até ele é infinita. Duas `Row` com `crossAxisAlignment.stretch` nessa
/// condição derrubam o layout inteiro do Resumo — foi o que aconteceu na
/// primeira vez que a tela renderizou com dados de verdade. Este teste
/// reproduz a condição.
void main() {
  final resumo = GetResumoMensalResponseModel.fromResponse(
    DemoDatabase.paraTeste().getResumoMensal(2026, 9),
  );

  Widget montar(Size tela) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        home: MediaQuery(
          data: MediaQueryData(size: tela),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ResumoInsightsGrid(resumo: resumo),
            ),
          ),
        ),
      );

  testWidgets('renderiza dentro de uma tela que rola, no mobile', (
    tester,
  ) async {
    await tester.pumpWidget(montar(const Size(360, 800)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renderiza dentro de uma tela que rola, na web', (tester) async {
    await tester.pumpWidget(montar(const Size(1400, 900)));
    expect(tester.takeException(), isNull);

    final equalizer = find.byType(IntrinsicHeight).first;
    final row = tester.widget<Row>(
      find.descendant(of: equalizer, matching: find.byType(Row)).first,
    );
    final alturas = row.children
        .whereType<Expanded>()
        .map((item) => tester.getSize(find.byWidget(item)).height)
        .toSet();
    expect(alturas, hasLength(1),
        reason: 'os cinco indicadores devem ser iguais');
  });

  testWidgets('os dois cartões de uma linha têm a mesma altura', (
    tester,
  ) async {
    await tester.pumpWidget(montar(const Size(360, 800)));

    final cartoes = tester
        .widgetList<IntrinsicHeight>(find.byType(IntrinsicHeight))
        .toList();
    expect(cartoes, hasLength(2), reason: 'duas linhas de dois cartões');

    for (final linha in find.byType(IntrinsicHeight).evaluate()) {
      final row = tester.widget<Row>(
        find
            .descendant(
              of: find.byWidget(linha.widget),
              matching: find.byType(Row),
            )
            .first,
      );
      final alturas = row.children
          .whereType<Expanded>()
          .map((e) => tester.getSize(find.byWidget(e)).height)
          .toSet();
      expect(alturas, hasLength(1));
    }
  });
}
