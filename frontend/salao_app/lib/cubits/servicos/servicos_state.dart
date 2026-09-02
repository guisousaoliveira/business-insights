part of 'servicos_cubit.dart';

class ServicosState {
  final BlocSubState getServicosSubState;
  final BlocSubState createServicoSubState;
  final BlocSubState deleteServicoSubState;

  const ServicosState({
    this.getServicosSubState = const BlocSubState(),
    this.createServicoSubState = const BlocSubState(),
    this.deleteServicoSubState = const BlocSubState(),
  });

  ServicosState copyWith({
    BlocSubState? getServicosSubState,
    BlocSubState? createServicoSubState,
    BlocSubState? deleteServicoSubState,
  }) =>
      ServicosState(
        getServicosSubState: getServicosSubState ?? this.getServicosSubState,
        createServicoSubState:
            createServicoSubState ?? this.createServicoSubState,
        deleteServicoSubState:
            deleteServicoSubState ?? this.deleteServicoSubState,
      );
}
