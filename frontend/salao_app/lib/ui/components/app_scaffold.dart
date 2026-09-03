import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';

import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_enums.dart';
import '../../settings/app_fonts.dart';
import '../../settings/app_routes.dart';
import 'app_icon.dart';
import 'app_nav.dart';
import 'app_tappable.dart';

/// A casca de toda tela do app (Android/iOS): app bar, barra inferior de 5
/// itens e FAB para a ação primária.
///
/// Desde A10 existe **uma** casca só — a web é o app React em
/// `frontend/salao_web`. A tela continua sem saber onde está: descreve título,
/// ação primária e conteúdo.
class AppScaffold extends StatelessWidget {
  final AppCurrentRoute currentPage;
  final String title;
  final Widget child;

  /// "Agendar", "Novo gasto", "Novo item" — o FAB do canto inferior direito.
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final IconData primaryActionIcon;

  /// Ação secundária do canto (o relógio de histórico em Estoque).
  final IconData? trailingIcon;
  final VoidCallback? onTrailingAction;

  final Widget? headerLeading;
  final Widget? headerTitle;

  final int alertCount;
  final bool isScrollable;
  final bool isPadded;

  const AppScaffold({
    super.key,
    required this.currentPage,
    required this.title,
    required this.child,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.primaryActionIcon = AppAssets.add,
    this.trailingIcon,
    this.onTrailingAction,
    this.headerLeading,
    this.headerTitle,
    this.alertCount = 0,
    this.isScrollable = true,
    this.isPadded = true,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          bottom: false,
          child: _PageEnter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: isPadded
                            ? const EdgeInsets.all(12)
                            : EdgeInsets.zero,
                        child: isScrollable
                            ? SingleChildScrollView(
                                // Espaço para o FAB não cobrir o último item.
                                padding: EdgeInsets.only(
                                  bottom: primaryActionLabel != null ? 64 : 0,
                                ),
                                child: child,
                              )
                            : child,
                      ),
                      if (primaryActionLabel != null)
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: _Fab(
                            label: primaryActionLabel!,
                            icon: primaryActionIcon,
                            onTap: onPrimaryAction,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentPage: currentPage,
          alertCount: alertCount,
        ),
      );

  Widget _buildAppBar(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
        child: Row(
          children: [
            if (headerLeading != null) ...[
              headerLeading!,
              const SizedBox(width: 10),
            ],
            Expanded(
              child: headerTitle ??
                  Text(title, style: AppFonts.appBarTitle(context)),
            ),
            if (trailingIcon != null)
              AppTappable(
                onTap: onTrailingAction,
                minSize: 40,
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AppIcon(trailingIcon!, size: 18),
              ),
            AppTappable(
              onTap: () => AppRoutes.push(AppRoutes.alertasRoute),
              minSize: 40,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AppBadge(
                count: alertCount,
                child: const AppIcon(AppAssets.alert, size: 19),
              ),
            ),
          ],
        ),
      );
}

/// A entrada do conteúdo da página: ~230ms subindo 10px enquanto aparece.
///
/// É a **única** animação da troca de aba. A rota entre telas da casca troca
/// sem transição (ver `AppRoutes.isShellRoute`), então a barra inferior fica
/// imóvel, como se fosse uma casca só; o movimento acontece daqui para dentro. Cada rota constrói um `_PageEnter` novo — que é
/// exatamente uma vez por troca de aba.
class _PageEnter extends StatefulWidget {
  final Widget child;

  const _PageEnter({required this.child});

  @override
  State<_PageEnter> createState() => _PageEnterState();
}

class _PageEnterState extends State<_PageEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 230),
  )..forward();

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _curve,
        child: AnimatedBuilder(
          animation: _curve,
          // O filho fica fora do builder: ele não depende do valor, e assim a
          // página inteira não reconstrói a 60fps durante a animação.
          child: widget.child,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, 10 * (1 - _curve.value)),
            child: child,
          ),
        ),
      );
}

class _Fab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _Fab({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => AppTappable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.primaryShadow,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, size: 16, color: AppColors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style:
                    AppFonts.button(context).copyWith(color: AppColors.white),
              ),
            ],
          ),
        ),
      );
}
