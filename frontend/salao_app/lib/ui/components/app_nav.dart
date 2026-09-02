import 'package:flutter/widgets.dart';

import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_enums.dart';
import '../../settings/app_extensions.dart';
import '../../settings/app_fonts.dart';
import '../../settings/app_routes.dart';
import 'app_icon.dart';
import 'app_tappable.dart';

/// Os cinco destinos do app, em ordem. Uma lista só, consumida pelas duas
/// cascas — é o que garante que menu lateral e barra inferior nunca divirjam.
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

/// Contador vermelho sobre um ícone. Zero não desenha nada — badge com "0" é
/// ruído que treina a usuária a ignorar o badge.
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
                color: AppColors.danger,
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

/// Barra inferior — casca mobile (≤1024).
class AppBottomNav extends StatelessWidget {
  static const _animationDuration = Duration(milliseconds: 220);

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
                    size: 22,
                    color: isActive ? AppColors.primaryDark : AppColors.text3,
                  );

                  return Expanded(
                    child: AppTappable(
                      onTap: isActive
                          ? null
                          : () =>
                              AppRoutes.replace(AppRoutes.routeOf(item.page)),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: _animationDuration,
                        curve: Curves.easeOutCubic,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.fromLTRB(2, 7, 2, 5),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 26,
                              child: Center(
                                child: AnimatedScale(
                                  scale: isActive ? 1.08 : 1,
                                  duration: _animationDuration,
                                  curve: Curves.easeOutBack,
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
                              child: AnimatedSwitcher(
                                duration: _animationDuration,
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: SizeTransition(
                                    sizeFactor: animation,
                                    axis: Axis.horizontal,
                                    child: child,
                                  ),
                                ),
                                child: isActive
                                    ? Text(
                                        label,
                                        key: ValueKey(item.page),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryDark,
                                        ),
                                      )
                                    : SizedBox(
                                        key: ValueKey('${item.page}-inactive'),
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

/// Menu lateral de 172px — casca web (>1024).
class AppSideMenu extends StatelessWidget {
  final AppCurrentRoute currentPage;
  final int alertCount;
  final String salonName;

  const AppSideMenu({
    super.key,
    required this.currentPage,
    required this.salonName,
    this.alertCount = 0,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: 172,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            right: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const AppIcon(
                      AppAssets.scissors,
                      size: 15,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      salonName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: AppColors.text1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...AppNavItem.all().map(
              (item) => _SideMenuItem(
                item: item,
                isActive: item.page == currentPage,
                badgeCount:
                    item.page == AppCurrentRoute.estoque ? alertCount : 0,
              ),
            ),
            const Spacer(),
            _SideMenuItem(
              item: AppNavItem(
                page: AppCurrentRoute.alertas,
                icon: AppAssets.alert,
                activeIcon: AppAssets.alertActive,
                label: (context) => context.l10n.navAlerts,
              ),
              isActive: currentPage == AppCurrentRoute.alertas,
              badgeCount: alertCount,
            ),
          ],
        ),
      );
}

class _SideMenuItem extends StatelessWidget {
  final AppNavItem item;
  final bool isActive;
  final int badgeCount;

  const _SideMenuItem({
    required this.item,
    required this.isActive,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final icon = AppIcon(
      isActive ? item.activeIcon : item.icon,
      size: 17,
      color: isActive ? AppColors.primaryDark : AppColors.text2,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: AppTappable(
        onTap: isActive
            ? null
            : () => AppRoutes.replace(AppRoutes.routeOf(item.page)),
        borderRadius: BorderRadius.circular(8),
        minSize: 38,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              AppBadge(count: badgeCount, child: icon),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  item.label(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.caption(context).copyWith(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? AppColors.primaryDark : AppColors.text2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
