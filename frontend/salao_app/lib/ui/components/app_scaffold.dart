import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';

import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_enums.dart';
import '../../settings/app_extensions.dart';
import '../../settings/app_fonts.dart';
import '../../settings/app_media_querys.dart';
import '../../settings/app_routes.dart';
import '../../settings/app_storage.dart';
import 'app_button.dart';
import 'app_icon.dart';
import 'app_nav.dart';
import 'app_tappable.dart';

/// A casca de toda tela, nas **duas** formas (S3):
///
/// - ≤1024: app bar, barra inferior de 5 itens, FAB para a ação primária;
/// - \>1024: menu lateral de 172px, cabeçalho com título e a ação primária
///   virando botão — sem barra inferior e sem FAB.
///
/// A tela não sabe em qual está: descreve título, ação primária e conteúdo.
class AppScaffold extends StatelessWidget {
  final AppCurrentRoute currentPage;
  final String title;
  final Widget child;

  /// "Agendar", "Novo gasto", "Novo item" — FAB no mobile, botão no cabeçalho
  /// na web.
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final IconData primaryActionIcon;

  /// Ação secundária do canto (o relógio de histórico em Estoque; na web ela
  /// acompanha o título).
  final IconData? trailingIcon;
  final VoidCallback? onTrailingAction;

  /// Seletor de período do cabeçalho de Resumo.
  final Widget? headerTrailing;

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
    this.headerTrailing,
    this.alertCount = 0,
    this.isScrollable = true,
    this.isPadded = true,
  });

  @override
  Widget build(BuildContext context) =>
      isWideLayout(context) ? _buildWide(context) : _buildNarrow(context);

  // ── Web ────────────────────────────────────────────────────────────────────

  Widget _buildWide(BuildContext context) => Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSideMenu(
                currentPage: currentPage,
                salonName: AppStorage.read<String>(AppStorage.salonInfoKey) ??
                    context.l10n.salonFallbackName,
                alertCount: alertCount,
              ),
              Expanded(
                child: Padding(
                  padding: isPadded
                      ? const EdgeInsets.fromLTRB(26, 22, 26, 22)
                      : EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWideHeader(context),
                      const SizedBox(height: 16),
                      Expanded(
                        child: isScrollable
                            ? SingleChildScrollView(child: child)
                            : child,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildWideHeader(BuildContext context) => Row(
        children: [
          Expanded(child: Text(title, style: AppFonts.pageTitle(context))),
          if (trailingIcon != null) ...[
            AppTappable(
              onTap: onTrailingAction,
              minSize: 38,
              borderRadius: BorderRadius.circular(8),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AppIcon(trailingIcon!, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          if (headerTrailing != null) headerTrailing!,
          if (primaryActionLabel != null) ...[
            if (headerTrailing != null) const SizedBox(width: 10),
            AppButton(
              label: primaryActionLabel!,
              icon: primaryActionIcon,
              onPressed: onPrimaryAction,
            ),
          ],
        ],
      );

  // ── Mobile ─────────────────────────────────────────────────────────────────

  Widget _buildNarrow(BuildContext context) => Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          bottom: false,
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
            Expanded(child: Text(title, style: AppFonts.appBarTitle(context))),
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
                style: AppFonts.button(context)
                    .copyWith(color: AppColors.white),
              ),
            ],
          ),
        ),
      );
}
