import 'package:flutter/widgets.dart';

import '../../cubits/bloc_substate.dart';
import '../../models/error_model.dart';
import 'app_empty_list_warning.dart';
import 'app_loading.dart';

/// Loading / dado / erro / vazio a partir de um [BlocSubState], sem o ternário
/// triplo em toda tela e sem `as` espalhado.
///
/// A ordem importa: enquanto não completou, é loading; completou com [T], é
/// dado; completou com `ErrorModel`, é erro; completou com outra coisa (ou
/// `null`), é vazio.
class AppSubStateBuilder<T> extends StatelessWidget {
  final BlocSubState subState;
  final Widget Function(T data) onData;
  final Widget Function(ErrorModel error)? onError;
  final Widget? onEmpty;
  final Widget? onLoading;

  const AppSubStateBuilder({
    super.key,
    required this.subState,
    required this.onData,
    this.onError,
    this.onEmpty,
    this.onLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (!subState.isCompleted) return onLoading ?? const AppLoading();

    final data = subState.value<T>();
    if (data != null) return onData(data);

    if (subState.hasError && onError != null) return onError!(subState.error!);

    return onEmpty ?? const AppEmptyListWarning();
  }
}
