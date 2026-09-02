import 'package:salon_app/l10n/app_localizations.dart';

import 'app_l10n.dart';
import 'app_storage.dart';

/// Getters globais de biblioteca. Importe **sempre com prefixo**:
///
/// ```dart
/// import 'package:salon_app/settings/app_globals.dart' as globals;
/// if (globals.isLogged) { … }
/// ```

/// Deriva da presença do token. Síncrono porque `AppStorage.read` é síncrono —
/// é o que permite o route guard funcionar sem `FutureBuilder` nem splash.
bool get isLogged =>
    AppStorage.read<String>(AppStorage.bearerToken)?.isNotEmpty == true;

/// Único ponto do app que resolve tradução fora de widget (cubit, model, util,
/// validator, interceptor). Dentro de um `build`, use `context.l10n`.
///
/// Devolve `null` antes do primeiro frame — por isso o tipo é anulável e todo
/// chamador trata. Quem resolve de fato é o [AppL10n], que o teste substitui.
AppLocalizations? get l10n => AppL10n.current;
