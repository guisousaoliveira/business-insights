import 'package:flutter/material.dart';
import 'package:salon_app/providers/relatorio_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/estoque_widgets.dart';
import 'atendimentos_screen.dart';
import 'gastos_screen.dart';
import 'resumo_screen.dart';
import 'perfil_screen.dart';
import 'estoque_screen.dart';
import 'package:provider/provider.dart';
import '../providers/estoque_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AtendimentosScreen(),
    GastosScreen(),
    ResumoScreen(),
    EstoqueScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final alertas = context.watch<EstoqueProvider>().totalAlertas;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() => _currentIndex = i);

            if (i == 2) {
              context.read<RelatorioProvider>().carregar();
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined, size: 22),
              activeIcon: Icon(Icons.calendar_today, size: 22),
              label: 'Atendimentos',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.wallet_outlined, size: 22),
              activeIcon: Icon(Icons.wallet, size: 22),
              label: 'Gastos',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined, size: 22),
              activeIcon: Icon(Icons.bar_chart, size: 22),
              label: 'Resumo',
            ),
            // Estoque — com badge de alertas
            BottomNavigationBarItem(
              icon: BadgeIcon(
                icon: Icons.inventory_2_outlined,
                count: alertas,
                ativo: false,
              ),
              activeIcon: BadgeIcon(
                icon: Icons.inventory_2,
                count: alertas,
                ativo: true,
              ),
              label: 'Estoque',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined, size: 22),
              activeIcon: Icon(Icons.store, size: 22),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
