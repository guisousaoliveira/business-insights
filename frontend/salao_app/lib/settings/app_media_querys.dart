import 'package:flutter/widgets.dart';

import 'app_enums.dart';

/// Funções de nível superior, sem classe — copiado do padrão base.
///
/// Breakpoints: ≤640 mobile · acima disso tablet (retrato ou paisagem).
/// **Não há casca de desktop** (A10): a web é o app React em
/// `frontend/salao_web`, e este projeto responde só por Android e iOS.

double deviceWidth(BuildContext context) => MediaQuery.sizeOf(context).width;

double deviceHeight(BuildContext context) => MediaQuery.sizeOf(context).height;

Orientation deviceOrientation(BuildContext context) =>
    MediaQuery.orientationOf(context);

DeviceType deviceType(BuildContext context) {
  if (deviceWidth(context) <= 640) return DeviceType.mobile;
  return deviceOrientation(context) == Orientation.landscape
      ? DeviceType.tabletLandscape
      : DeviceType.tablet;
}
