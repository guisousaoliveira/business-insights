part of 'resumo_cubit.dart';

class ResumoState {
  final BlocSubState getResumoMensalSubState;

  /// Período selecionado no cabeçalho. Não é um `BlocSubState` porque não
  /// envolve I/O — é escolha da usuária, e o estado do módulo é o lugar dela.
  final DateTime periodo;

  ResumoState({
    this.getResumoMensalSubState = const BlocSubState(),
    DateTime? periodo,
  }) : periodo = periodo ?? DateTime(DateTime.now().year, DateTime.now().month);

  ResumoState copyWith({
    BlocSubState? getResumoMensalSubState,
    DateTime? periodo,
  }) =>
      ResumoState(
        getResumoMensalSubState:
            getResumoMensalSubState ?? this.getResumoMensalSubState,
        periodo: periodo ?? this.periodo,
      );
}
