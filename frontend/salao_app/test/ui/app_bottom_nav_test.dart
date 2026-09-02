import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app/l10n/app_localizations.dart';
import 'package:salon_app/settings/app_enums.dart';
import 'package:salon_app/settings/app_routes.dart';
import 'package:salon_app/ui/components/app_nav.dart';

void main() {
  late ValueNotifier<AppCurrentRoute> currentPage;

  setUp(() => currentPage = ValueNotifier(AppCurrentRoute.resumo));
  tearDown(() => currentPage.dispose());

  Future<void> pumpBottomNav(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            bottomNavigationBar: ValueListenableBuilder<AppCurrentRoute>(
              valueListenable: currentPage,
              builder: (context, page, _) => AppBottomNav(
                currentPage: page,
                alertCount: 3,
              ),
            ),
          ),
        ),
      );

  testWidgets('mostra somente o nome do item selecionado', (tester) async {
    await pumpBottomNav(tester);
    await tester.pumpAndSettle();

    expect(find.text('Resumo'), findsOneWidget);
    expect(find.text('Atendimentos'), findsNothing);
    expect(find.text('Gastos'), findsNothing);
    expect(find.text('Estoque'), findsNothing);
    expect(find.text('Perfil'), findsNothing);
    expect(tester.getSize(find.byType(AppBottomNav)).height,
        greaterThanOrEqualTo(72));
  });

  testWidgets('troca o nome selecionado usando widgets animados',
      (tester) async {
    await pumpBottomNav(tester);
    await tester.pumpAndSettle();

    currentPage.value = AppCurrentRoute.estoque;
    await tester.pump();

    expect(find.text('Estoque'), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsNWidgets(5));
    expect(find.byType(AnimatedScale), findsNWidgets(5));

    await tester.pumpAndSettle();
    expect(find.text('Resumo'), findsNothing);
    expect(find.text('Estoque'), findsOneWidget);
  });

  test('rotas usam transição em vez de troca instantânea', () {
    final route = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutes.gastosRoute),
    ) as PageRouteBuilder<dynamic>;

    expect(route.transitionDuration, AppRoutes.pageTransitionDuration);
    expect(route.transitionDuration, isNot(Duration.zero));
  });
}
