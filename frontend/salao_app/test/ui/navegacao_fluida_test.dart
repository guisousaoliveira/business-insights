import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app/cubits/bloc_substate.dart';
import 'package:salon_app/l10n/app_localizations.dart';
import 'package:salon_app/models/error_model.dart';
import 'package:salon_app/settings/app_enums.dart';
import 'package:salon_app/ui/components/app_loading.dart';
import 'package:salon_app/ui/components/app_nav.dart';
import 'package:salon_app/ui/components/app_sub_state_builder.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  group('recarga não apaga a tela', () {
    test('toLoading preserva o dado e descarta o erro', () {
      final comDado = BlocSubState.completed('lucro').toLoading();
      expect(comDado.isLoading, isTrue);
      expect(comDado.value<String>(), 'lucro');

      final comErro = BlocSubState.completed(
        const ErrorModel(message: 'caiu a rede'),
      ).toLoading();
      expect(comErro.data, isNull);
    });

    testWidgets('o builder mostra o dado antigo enquanto recarrega',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          AppSubStateBuilder<String>(
            subState: BlocSubState.completed('R\$ 1.200,00').toLoading(),
            onData: Text.new,
          ),
        ),
      );

      expect(find.text('R\$ 1.200,00'), findsOneWidget);
      expect(find.byType(AppLoading), findsNothing);
    });

    testWidgets('a primeira carga, sem dado nenhum, ainda mostra o loading',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppSubStateBuilder<String>(
            subState: BlocSubState.loading,
            onData: Text.new,
          ),
        ),
      );

      expect(find.byType(AppLoading), findsOneWidget);
    });
  });

  testWidgets('o menu lateral fecha com Sair, não com Alertas', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppSideMenu(
          currentPage: AppCurrentRoute.resumo,
          salonName: 'Thamires Beauty',
          alertCount: 3,
        ),
      ),
    );

    expect(find.text('Sair'), findsOneWidget);
    expect(find.text('Alertas'), findsNothing);
  });
}
