import '../models/error_model.dart';
import '../settings/app_enums.dart';

/// Uma operação assíncrona do cubit. Compartilhado por **todos** os estados.
///
/// A assinatura do padrão: **erro não é estado, é tipo de dado**. Toda operação
/// termina em `completed`; o que diferencia sucesso de falha é o tipo do que
/// está em [data] — um `ResponseModel` ou um [ErrorModel].
///
/// Não usa `Equatable`: o filtro `buildWhen` compara **identidade de
/// instância**, e é o `copyWith` com `?? this.x` que preserva essa identidade
/// nos campos não alterados.
class BlocSubState {
  final BlocDataState state;

  /// Um `ResponseModel` **ou** um [ErrorModel].
  final Object? data;

  const BlocSubState({this.state = BlocDataState.idle, this.data});

  bool get isIdle => state == BlocDataState.idle;
  bool get isLoading => state == BlocDataState.loading;
  bool get isCompleted => state == BlocDataState.completed;

  bool get hasError => data is ErrorModel;
  ErrorModel? get error => data is ErrorModel ? data as ErrorModel : null;

  /// [data] tipado, ou `null` se for erro / ainda não carregou.
  T? value<T>() => data is T ? data as T : null;

  /// Açúcar para os três `emit` que todo método de cubit faz.
  static const loading = BlocSubState(state: BlocDataState.loading);

  static BlocSubState completed(Object? data) =>
      BlocSubState(state: BlocDataState.completed, data: data);
}
