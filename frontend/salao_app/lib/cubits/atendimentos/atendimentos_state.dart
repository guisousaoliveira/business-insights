part of 'atendimentos_cubit.dart';

class AtendimentosState {
  final BlocSubState getAtendimentosSubState;
  final BlocSubState createAtendimentoSubState;
  final BlocSubState finalizarAtendimentoSubState;
  final BlocSubState cancelarAtendimentoSubState;

  const AtendimentosState({
    this.getAtendimentosSubState = const BlocSubState(),
    this.createAtendimentoSubState = const BlocSubState(),
    this.finalizarAtendimentoSubState = const BlocSubState(),
    this.cancelarAtendimentoSubState = const BlocSubState(),
  });

  AtendimentosState copyWith({
    BlocSubState? getAtendimentosSubState,
    BlocSubState? createAtendimentoSubState,
    BlocSubState? finalizarAtendimentoSubState,
    BlocSubState? cancelarAtendimentoSubState,
  }) =>
      AtendimentosState(
        getAtendimentosSubState:
            getAtendimentosSubState ?? this.getAtendimentosSubState,
        createAtendimentoSubState:
            createAtendimentoSubState ?? this.createAtendimentoSubState,
        finalizarAtendimentoSubState:
            finalizarAtendimentoSubState ?? this.finalizarAtendimentoSubState,
        cancelarAtendimentoSubState:
            cancelarAtendimentoSubState ?? this.cancelarAtendimentoSubState,
      );
}
