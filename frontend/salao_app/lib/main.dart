// ─────────────────────────────────────────────────────────────────────────────
// main.dart — Entry point
//
// Responsabilidades:
//   1. Registrar os Providers globais de estado (MultiProvider na raiz)
//   2. Definir o tema Material 3 com paleta teal #1D9E75
//   3. Decidir tela inicial via mock auth local
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/atendimento_provider.dart';
import 'providers/gasto_provider.dart';
import 'providers/relatorio_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_nav_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AtendimentoProvider()),
        ChangeNotifierProvider(create: (_) => GastoProvider()),
        ChangeNotifierProvider(create: (_) => RelatorioProvider()),
      ],
      child: const SalaoApp(),
    ),
  );
}

class SalaoApp extends StatelessWidget {
  const SalaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão do Salão',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0.5,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A1A),
        ),
      ),
      home: ValueListenableBuilder<bool>(
        valueListenable: ApiService.authState,
        builder: (context, loggedIn, child) {
          return loggedIn ? const MainNavScreen() : const LoginScreen();
        },
      ),
    );
  }
}
