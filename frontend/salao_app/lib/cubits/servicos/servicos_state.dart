part of 'servicos_cubit.dart';

class ServicosState {
  final BlocSubState getServicosSubState;
  final BlocSubState createServicoSubState;
  final BlocSubState editServicoSubState;
  final BlocSubState deleteServicoSubState;

  const ServicosState({
    this.getServicosSubState = const BlocSubState(),
    this.createServicoSubState = const BlocSubState(),
    this.editServicoSubState = const BlocSubState(),
    this.deleteServicoSubState = const BlocSubState(),
  });

  ServicosState copyWith({
    BlocSubState? getServicosSubState,
    BlocSubState? createServicoSubState,
    BlocSubState? editServicoSubState,
    BlocSubState? deleteServicoSubState,
  }) =>
      ServicosState(
        getServicosSubState: getServicosSubState ?? this.getServicosSubState,
        createServicoSubState:
            createServicoSubState ?? this.createServicoSubState,
        editServicoSubState: editServicoSubState ?? this.editServicoSubState,
        deleteServicoSubState:
            deleteServicoSubState ?? this.deleteServicoSubState,
      );
}
