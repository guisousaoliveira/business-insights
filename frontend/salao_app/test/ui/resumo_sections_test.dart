import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app/l10n/app_localizations.dart';
import 'package:salon_app/models/resumo/get_resumo_mensal_response_model.dart';
import 'package:salon_app/repositories/demo/demo_database.dart';
import 'package:salon_app/ui/screens/resumo/widgets/resumo_ranking_widget.dart';
import 'package:salon_app/ui/screens/resumo/widgets/resumo_sections.dart';

void main() {
  final resumo = GetResumoMensalResponseModel.fromResponse(
    DemoDatabase.paraTeste().getResumoMensal(2026, 9),
  );

  Widget montar(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        home: Scaffold(
          body: SizedBox(width: 900, child: child),
        ),
      );

  testWidgets('gráfico exibe valores detalhados ao passar o mouse',
      (tester) async {
    await tester.pumpWidget(
      montar(ResumoHistoryCard(historico: resumo.historicoSeisMeses)),
    );

    expect(find.byKey(const ValueKey('chart-tooltip-5')), findsNothing);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('set').last));
    await tester.pump();

    expect(find.byKey(const ValueKey('chart-tooltip-5')), findsOneWidget);
    expect(find.textContaining('Receitas: R\$'), findsOneWidget);
    expect(find.textContaining('Gastos: R\$'), findsOneWidget);
  });

  testWidgets('ranking deixa clara a colocação após o campeão', (tester) async {
    await tester.pumpWidget(montar(ResumoRankingWidget(
      servicos: resumo.servicosMaisRealizados,
      maiorReceita: resumo.maiorReceitaDoRanking,
    )));

    expect(find.text('2º'), findsOneWidget);
    expect(find.text('3º'), findsOneWidget);
    expect(find.textContaining('lucro de R\$'), findsOneWidget);
  });
}
