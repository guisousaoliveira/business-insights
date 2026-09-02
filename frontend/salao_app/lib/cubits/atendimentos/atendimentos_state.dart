part of 'atendimentos_cubit.dart';

class AtendimentosState {
  final BlocSubState getAtendimentosSubState;
  final BlocSubState createAtendimentoSubState;
  final BlocSubState editAtendimentoSubState;
  final BlocSubState finalizarAtendimentoSubState;
  final BlocSubState cancelarAtendimentoSubState;

  const AtendimentosState({
    this.getAtendimentosSubState = const BlocSubState(),
    this.createAtendimentoSubState = const BlocSubState(),
    this.editAtendimentoSubState = const BlocSubState(),
    this.finalizarAtendimentoSubState = const BlocSubState(),
    this.cancelarAtendimentoSubState = const BlocSubState(),
  });

  AtendimentosState copyWith({
    BlocSubState? getAtendimentosSubState,
    BlocSubState? createAtendimentoSubState,
    BlocSubState? editAtendimentoSubState,
    BlocSubState? finalizarAtendimentoSubState,
    BlocSubState? cancelarAtendimentoSubState,
  }) =>
      AtendimentosState(
        getAtendimentosSubState:
            getAtendimentosSubState ?? this.getAtendimentosSubState,
        createAtendimentoSubState:
            createAtendimentoSubState ?? this.createAtendimentoSubState,
        editAtendimentoSubState:
            editAtendimentoSubState ?? this.editAtendimentoSubState,
        finalizarAtendimentoSubState:
            finalizarAtendimentoSubState ?? this.finalizarAtendimentoSubState,
        cancelarAtendimentoSubState:
            cancelarAtendimentoSubState ?? this.cancelarAtendimentoSubState,
      );
}
