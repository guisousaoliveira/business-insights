import 'package:flutter/widgets.dart';

import 'app_enums.dart';

/// Funções de nível superior, sem classe — copiado do padrão base.
///
/// Breakpoints: ≤640 mobile · ≤1024 tablet · ≤1280 small desktop · >1280 desktop.
/// Este app usa **todos** eles: a casca troca de barra inferior para menu lateral
/// acima de 1024 (S3 da adaptação).

double deviceWidth(BuildContext context) => MediaQuery.sizeOf(context).width;

double deviceHeight(BuildContext context) => MediaQuery.sizeOf(context).height;

Orientation deviceOrientation(BuildContext context) =>
    MediaQuery.orientationOf(context);

DeviceType deviceType(BuildContext context) {
  final width = deviceWidth(context);
  if (width <= 640) return DeviceType.mobile;
  if (width <= 1024) {
    return deviceOrientation(context) == Orientation.landscape
        ? DeviceType.tabletLandscape
        : DeviceType.tablet;
  }
  if (width <= 1280) return DeviceType.smallDesktop;
  return DeviceType.desktop;
}

/// A única pergunta que a casca faz: menu lateral ou barra inferior?
///
/// Acima de 1024 o protótipo mostra sidebar de 172px e ação primária no
/// cabeçalho; abaixo, barra inferior de 5 itens e FAB.
bool isWideLayout(BuildContext context) => deviceWidth(context) > 1024;
