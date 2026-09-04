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

  testWidgets('troca o nome selecionado no mesmo quadro', (tester) async {
    await pumpBottomNav(tester);
    await tester.pumpAndSettle();

    currentPage.value = AppCurrentRoute.estoque;
    await tester.pump();

    // Sem meio-termo: a troca de aba recria a barra, então um estado animado
    // aqui seria um quadro intermediário que a usuária nunca chega a ver.
    expect(find.text('Resumo'), findsNothing);
    expect(find.text('Estoque'), findsOneWidget);
  });

  test('troca de aba não anima a rota, para a casca não deslizar junto', () {
    final route = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutes.gastosRoute),
    ) as PageRouteBuilder<dynamic>;

    expect(AppRoutes.isShellRoute(AppRoutes.gastosRoute), isTrue);
    expect(route.transitionDuration, Duration.zero);
  });

  test('rota de fora da casca mantém a transição', () {
    final route = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutes.loginRoute),
    ) as PageRouteBuilder<dynamic>;

    expect(AppRoutes.isShellRoute(AppRoutes.loginRoute), isFalse);
    expect(route.transitionDuration, AppRoutes.pageTransitionDuration);
  });
}
