import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/auth/auth_cubit.dart';
import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_enums.dart';
import '../../settings/app_extensions.dart';
import '../../settings/app_fonts.dart';
import '../../settings/app_routes.dart';
import 'app_dialog.dart';
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

/// Barra inferior — casca mobile (≤1024).
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
                              child: isActive
                                  ? Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryDark,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
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
                icon: item.page == currentPage ? item.activeIcon : item.icon,
                label: item.label(context),
                isActive: item.page == currentPage,
                badgeCount:
                    item.page == AppCurrentRoute.estoque ? alertCount : 0,
                onTap: item.page == currentPage
                    ? null
                    : () => AppRoutes.replace(AppRoutes.routeOf(item.page)),
              ),
            ),
            const Spacer(),
            // Sair fecha a lista, no lugar onde estavam os alertas: na web eles
            // já moram no sino do cabeçalho, e tê-los duas vezes gastava o
            // único lugar do menu que ainda não tinha dono.
            _SideMenuItem(
              icon: AppAssets.logout,
              label: context.l10n.logout,
              isActive: false,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      );

  /// A mesma confirmação do Perfil — sair é irreversível o bastante para não
  /// acontecer por um clique perdido no canto do menu.
  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: context.l10n.logout,
      message: context.l10n.logoutQuestion,
      confirmLabel: context.l10n.logout,
    );

    if (!confirmed || !context.mounted) return;

    // Aqui se espera o cubit em vez de ouvir o estado: o menu vive em todas as
    // telas da casca, e nenhuma delas escuta `logoutSubState`.
    await BlocProvider.of<AuthCubit>(context).logout();
    await AppRoutes.push(AppRoutes.loginRoute, removeUntil: (_) => false);
  }
}

/// Uma linha do menu lateral. Recebe ícone, rótulo e ação prontos porque nem
/// toda linha é um destino: a última é o logout.
class _SideMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback? onTap;

  const _SideMenuItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = AppIcon(
      icon,
      size: 17,
      color: isActive ? AppColors.primaryDark : AppColors.text2,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: AppTappable(
        onTap: onTap,
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
              AppBadge(count: badgeCount, child: iconWidget),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
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
