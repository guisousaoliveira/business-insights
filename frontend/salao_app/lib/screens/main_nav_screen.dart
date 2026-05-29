// ─────────────────────────────────────────────────────────────────────────────
// screens/main_nav_screen.dart
//
// Navegação principal com NavigationBar (Material 3).
// IndexedStack preserva o estado de cada aba ao navegar entre elas.
//
// Abas:
//   0 → HomeScreen          (painel mensal — Fase 2)
//   1 → AtendimentosScreen  (collapsables de atendimento — Fase 1, central)
//   2 → GastosScreen        (gastos da semana — Fase 1)
//   3 → PerfilScreen        (custos fixos e configurações — Fase 1)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'atendimentos_screen.dart';
import 'gastos_screen.dart';
import 'perfil_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  // Abre direto em Atendimentos — é o fluxo mais usado no dia a dia
  int _aba = 1;

  static const _telas = [
    HomeScreen(),
    AtendimentosScreen(),
    GastosScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantém estado das abas — gastos não recarregam
      // quando a usuária troca de aba e volta
      body: IndexedStack(index: _aba, children: _telas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label:        'Painel',
          ),
          NavigationDestination(
            icon:         Icon(Icons.content_cut_outlined),
            selectedIcon: Icon(Icons.content_cut),
            label:        'Atendimentos',
          ),
          NavigationDestination(
            icon:         Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label:        'Gastos',
          ),
          NavigationDestination(
            icon:         Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label:        'Perfil',
          ),
        ],
      ),
    );
  }
}
