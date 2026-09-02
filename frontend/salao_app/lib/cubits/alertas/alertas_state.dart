part of 'alertas_cubit.dart';

class AlertasState {
  final BlocSubState getAlertasSubState;
  final BlocSubState marcarLidoSubState;
  final BlocSubState marcarTodosLidosSubState;

  const AlertasState({
    this.getAlertasSubState = const BlocSubState(),
    this.marcarLidoSubState = const BlocSubState(),
    this.marcarTodosLidosSubState = const BlocSubState(),
  });

  /// Contador do badge, direto do último `getAlertas` bem-sucedido. Zero
  /// enquanto não carregou — badge que aparece antes do dado pisca à toa.
  int get badgeCount =>
      getAlertasSubState.value<GetAlertasResponseModel>()?.badgeCount ?? 0;

  AlertasState copyWith({
    BlocSubState? getAlertasSubState,
    BlocSubState? marcarLidoSubState,
    BlocSubState? marcarTodosLidosSubState,
  }) =>
      AlertasState(
        getAlertasSubState: getAlertasSubState ?? this.getAlertasSubState,
        marcarLidoSubState: marcarLidoSubState ?? this.marcarLidoSubState,
        marcarTodosLidosSubState:
            marcarTodosLidosSubState ?? this.marcarTodosLidosSubState,
      );
}
