import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Adicione a importação do provider

// Importe seus providers
import 'providers/atendimento_provider.dart';
import 'providers/gasto_provider.dart';
import 'providers/relatorio_provider.dart';
import 'providers/perfil_provider.dart';
// No topo:
import 'providers/estoque_provider.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await initializeDateFormatting('en_US', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AtendimentoProvider()),
        ChangeNotifierProvider(create: (_) => GastoProvider()),
        ChangeNotifierProvider(create: (_) => RelatorioProvider()),
        ChangeNotifierProvider(create: (_) => PerfilProvider()),
        ChangeNotifierProvider(create: (_) => EstoqueProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salon App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
