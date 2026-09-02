part of 'estoque_cubit.dart';

class EstoqueState {
  final BlocSubState getItensSubState;
  final BlocSubState createItemSubState;
  final BlocSubState createMovimentacaoSubState;
  final BlocSubState getMovimentacoesSubState;
  final BlocSubState deleteItemSubState;

  const EstoqueState({
    this.getItensSubState = const BlocSubState(),
    this.createItemSubState = const BlocSubState(),
    this.createMovimentacaoSubState = const BlocSubState(),
    this.getMovimentacoesSubState = const BlocSubState(),
    this.deleteItemSubState = const BlocSubState(),
  });

  EstoqueState copyWith({
    BlocSubState? getItensSubState,
    BlocSubState? createItemSubState,
    BlocSubState? createMovimentacaoSubState,
    BlocSubState? getMovimentacoesSubState,
    BlocSubState? deleteItemSubState,
  }) =>
      EstoqueState(
        getItensSubState: getItensSubState ?? this.getItensSubState,
        createItemSubState: createItemSubState ?? this.createItemSubState,
        createMovimentacaoSubState:
            createMovimentacaoSubState ?? this.createMovimentacaoSubState,
        getMovimentacoesSubState:
            getMovimentacoesSubState ?? this.getMovimentacoesSubState,
        deleteItemSubState: deleteItemSubState ?? this.deleteItemSubState,
      );
}
