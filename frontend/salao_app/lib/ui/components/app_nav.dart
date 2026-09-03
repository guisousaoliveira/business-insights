import 'package:flutter/widgets.dart';

import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_enums.dart';
import '../../settings/app_extensions.dart';
import '../../settings/app_routes.dart';
import 'app_icon.dart';
import 'app_tappable.dart';

/// Os cinco destinos do app, em ordem. Uma lista só, consumida pela barra
/// inferior — a única casca que existe desde A10 (a web é o app React em
/// `frontend/salao_web`).
class AppNavItem {
  final AppCurrentRoute page;
  final IconData icon;
  final IconData activeIcon;
  final String Function(BuildContext context) label;

  const AppNavItem({
    required this.page,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  static List<AppNavItem> all() => [
        AppNavItem(
          page: AppCurrentRoute.resumo,
          icon: AppAssets.resumo,
          activeIcon: AppAssets.resumoActive,
          label: (context) => context.l10n.navSummary,
        ),
        AppNavItem(
          page: AppCurrentRoute.atendimentos,
          icon: AppAssets.atendimentos,
          activeIcon: AppAssets.atendimentosActive,
          label: (context) => context.l10n.navAppointments,
        ),
        AppNavItem(
          page: AppCurrentRoute.gastos,
          icon: AppAssets.gastos,
          activeIcon: AppAssets.gastosActive,
          label: (context) => context.l10n.navExpenses,
        ),
        AppNavItem(
          page: AppCurrentRoute.estoque,
          icon: AppAssets.estoque,
          activeIcon: AppAssets.estoqueActive,
          label: (context) => context.l10n.navStock,
        ),
        AppNavItem(
          page: AppCurrentRoute.perfil,
          icon: AppAssets.perfil,
          activeIcon: AppAssets.perfilActive,
          label: (context) => context.l10n.navProfile,
        ),
      ];
}

/// Contador roxo sobre um ícone. Zero não desenha nada — badge com "0" é
/// ruído que treina a usuária a ignorar o badge.
///
/// A cor é a identidade (`primaryAccent`), não `danger`: vermelho neste app
/// significa dinheiro saindo ou saldo negativo, e um contador de avisos não é
/// prejuízo — misturar os dois ensina a usuária a ler vermelho como ruído.
class AppBadge extends StatelessWidget {
  final Widget child;
  final int count;

  const AppBadge({super.key, required this.child, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    // O `Center` não é enfeite. O sino da app bar mora num alvo de toque de
    // 40dp, bem mais alto que o ícone de 19: sozinho, o `Icon` se centraliza
    // nessa sobra, mas o `Stack` a preenche e encosta o ícone no topo — o ícone
    // subia 10dp assim que o contador passava de zero, saindo do eixo do
    // título. Os fatores 1 fazem o `Center` medir pelo filho: o `Stack` volta a
    // ter o tamanho do ícone (então o badge continua ancorado no canto do
    // ícone, e não no do alvo de toque) e é o `Center` que absorve a sobra.
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 15),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra inferior — a casca do app (Android/iOS).
///
/// O item ativo troca **sem** animação, de propósito: a troca de aba recria a
/// rota inteira, então esta barra é um widget novo a cada toque e qualquer
/// `Animated*` aqui nasceria já no valor final, animando nada. Quem se move é
/// o conteúdo da página (`_PageEnter`, em `app_scaffold.dart`) — a barra
/// parada é o que faz a casca parecer fixa.
class AppBottomNav extends StatelessWidget {
  final AppCurrentRoute currentPage;
  final int alertCount;

  const AppBottomNav({
    super.key,
    required this.currentPage,
    this.alertCount = 0,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: AppNavItem.all().map((item) {
                  final isActive = item.page == currentPage;
                  final label = item.label(context);
                  final icon = AppIcon(
                    isActive ? item.activeIcon : item.icon,
                    size: 20,
                    color: isActive
                        ? AppColors.primaryAccent
                        : AppColors.text3,
                  );

                  return Expanded(
                    child: AppTappable(
                      onTap: isActive
                          ? null
                          : () =>
                              AppRoutes.replace(AppRoutes.routeOf(item.page)),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.fromLTRB(2, 7, 2, 5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 26,
                              child: Center(
                                child: Transform.scale(
                                  scale: isActive ? 1.08 : 1,
                                  child: item.page == AppCurrentRoute.estoque
                                      ? AppBadge(
                                          count: alertCount,
                                          child: icon,
                                        )
                                      : icon,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            SizedBox(
                              height: 14,
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isActive
                                      ? AppColors.primaryAccent
                                      : AppColors.text3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
}
