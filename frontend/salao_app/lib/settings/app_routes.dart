import 'package:flutter/widgets.dart';

import '../ui/screens/alertas/alertas_screen.dart';
import '../ui/screens/atendimentos/atendimentos_screen.dart';
import '../ui/screens/auth/login_screen.dart';
import '../ui/screens/estoque/estoque_screen.dart';
import '../ui/screens/gastos/gastos_screen.dart';
import '../ui/screens/perfil/perfil_screen.dart';
import '../ui/screens/resumo/resumo_screen.dart';
import 'app_enums.dart';
import 'app_globals.dart' as globals;

/// Navegação imperativa com Navigator 1.0, centralizada. Sem `go_router`.
///
/// Junto com `app_globals.dart`, este é o único arquivo autorizado a tocar no
/// [navigatorKey] (regra 7). É ele que permite navegar de dentro do interceptor
/// do Dio e traduzir de dentro de um model, sem carregar `BuildContext`.
class AppRoutes {
  const AppRoutes._();

  static const pageTransitionDuration = Duration(milliseconds: 220);

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final routeObserver = RouteObserver<ModalRoute<void>>();

  static const defaultRoute = '/';
  static const loginRoute = '/login';
  static const atendimentosRoute = '/atendimentos';
  static const gastosRoute = '/gastos';
  static const resumoRoute = '/resumo';
  static const estoqueRoute = '/estoque';
  static const perfilRoute = '/perfil';
  static const alertasRoute = '/alertas';

  /// Rota inicial de quem está logado. O resumo responde primeiro se o mês está
  /// dando lucro ou prejuízo.
  static const homeRoute = resumoRoute;

  /// O guard é feito **no builder**, ternário por ternário. Funciona sem
  /// `FutureBuilder` porque `globals.isLogged` lê o storage de forma síncrona.
  static final routeList = <String, Widget Function(BuildContext)>{
    defaultRoute: (context) =>
        globals.isLogged ? const ResumoScreen() : const LoginScreen(),
    loginRoute: (context) =>
        globals.isLogged ? const ResumoScreen() : const LoginScreen(),
    atendimentosRoute: (context) =>
        globals.isLogged ? const AtendimentosScreen() : const LoginScreen(),
    gastosRoute: (context) =>
        globals.isLogged ? const GastosScreen() : const LoginScreen(),
    resumoRoute: (context) =>
        globals.isLogged ? const ResumoScreen() : const LoginScreen(),
    estoqueRoute: (context) =>
        globals.isLogged ? const EstoqueScreen() : const LoginScreen(),
    perfilRoute: (context) =>
        globals.isLogged ? const PerfilScreen() : const LoginScreen(),
    alertasRoute: (context) =>
        globals.isLogged ? const AlertasScreen() : const LoginScreen(),
  };

  /// Rota ↔ item ativo da navegação, nas duas cascas.
  static const routeToCurrentPage = <String, AppCurrentRoute>{
    atendimentosRoute: AppCurrentRoute.atendimentos,
    gastosRoute: AppCurrentRoute.gastos,
    resumoRoute: AppCurrentRoute.resumo,
    estoqueRoute: AppCurrentRoute.estoque,
    perfilRoute: AppCurrentRoute.perfil,
    alertasRoute: AppCurrentRoute.alertas,
  };

  static String routeOf(AppCurrentRoute page) => switch (page) {
        AppCurrentRoute.atendimentos => atendimentosRoute,
        AppCurrentRoute.gastos => gastosRoute,
        AppCurrentRoute.resumo => resumoRoute,
        AppCurrentRoute.estoque => estoqueRoute,
        AppCurrentRoute.perfil => perfilRoute,
        AppCurrentRoute.alertas => alertasRoute,
      };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? defaultRoute;
    final uri = Uri.parse(name);
    final builder = routeList[uri.path];

    return PageRouteBuilder<dynamic>(
      settings: settings,
      // 404 não quebra o app: cai na rota padrão.
      pageBuilder: (context, _, __) =>
          (builder ?? routeList[defaultRoute]!).call(context),
      transitionDuration: pageTransitionDuration,
      reverseTransitionDuration: pageTransitionDuration,
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.035, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Future<dynamic> push(
    String name, {
    Map<String, dynamic>? data,
    bool Function(Route<dynamic> route)? removeUntil,
  }) async {
    final state = navigatorKey.currentState;
    if (state == null) return null;

    if (removeUntil != null) {
      return state.pushNamedAndRemoveUntil(name, removeUntil, arguments: data);
    }
    return state.pushNamed(name, arguments: data);
  }

  /// Troca de aba: substitui em vez de empilhar, senão o botão voltar percorre
  /// todas as abas já visitadas.
  static Future<dynamic> replace(String name,
      {Map<String, dynamic>? data}) async {
    final state = navigatorKey.currentState;
    if (state == null) return null;
    return state.pushReplacementNamed(name, arguments: data);
  }

  static Future<bool> pop({dynamic result}) async {
    final state = navigatorKey.currentState;
    if (state == null || !state.canPop()) return false;
    state.pop(result);
    return true;
  }
}
