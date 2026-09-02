import 'dart:ui';

import 'package:flutter/material.dart'
    show MaterialApp, MaterialScrollBehavior, ScaffoldMessenger;
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'cubits/alertas/alertas_cubit.dart';
import 'cubits/atendimentos/atendimentos_cubit.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/estoque/estoque_cubit.dart';
import 'cubits/gastos/gastos_cubit.dart';
import 'cubits/kits/kits_cubit.dart';
import 'cubits/perfil/perfil_cubit.dart';
import 'cubits/resumo/resumo_cubit.dart';
import 'cubits/servicos/servicos_cubit.dart';
import 'l10n/app_localizations.dart';
import 'settings/app_routes.dart';
import 'settings/app_storage.dart';
import 'settings/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ANTES do runApp: o route guard lê o token de forma síncrona na primeira
  // rota. Invertida a ordem, quem está logado cai no login.
  await AppStorage.initialize();

  // Formatação de data em pt-BR fora de widget (AppUtils).
  await initializeDateFormatting('pt_BR', null);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        // Um cubit por módulo, registrados uma vez e vivos enquanto o app viver.
        // Por isso toda tela dispara o fetch no `initState`, sem confiar no
        // estado remanescente da visita anterior.
        providers: [
          BlocProvider(create: (_) => AuthCubit()),
          BlocProvider(create: (_) => AtendimentosCubit()),
          BlocProvider(create: (_) => GastosCubit()),
          BlocProvider(create: (_) => ResumoCubit()),
          BlocProvider(create: (_) => EstoqueCubit()),
          BlocProvider(create: (_) => KitsCubit()),
          BlocProvider(create: (_) => PerfilCubit()),
          BlocProvider(create: (_) => ServicosCubit()),
          BlocProvider(create: (_) => AlertasCubit()),
        ],
        // Envolve o MaterialApp para o AppSnackBar funcionar de qualquer rota.
        child: ScaffoldMessenger(
          child: MaterialApp(
            title: 'Thamires Borges Beauty',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            navigatorKey: AppRoutes.navigatorKey,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            navigatorObservers: [AppRoutes.routeObserver],
            initialRoute: AppRoutes.defaultRoute,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            // Na web, arrastar com o mouse tem que rolar a lista como o dedo
            // rola no celular.
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
              scrollbars: false,
            ),
          ),
        ),
      );
}
