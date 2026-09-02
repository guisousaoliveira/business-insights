part of 'alertas_cubit.dart';

class AlertasState {
  final BlocSubState getAlertasSubState;
  final BlocSubState marcarLidoSubState;
  final BlocSubState marcarTodosLidosSubState;

  /// Último contador confirmado pelo servidor. Fica separado do subestado para
  /// não voltar a zero durante um refresh ou uma falha de rede.
  final int badgeCount;

  const AlertasState({
    this.getAlertasSubState = const BlocSubState(),
    this.marcarLidoSubState = const BlocSubState(),
    this.marcarTodosLidosSubState = const BlocSubState(),
    this.badgeCount = 0,
  });

  AlertasState copyWith({
    BlocSubState? getAlertasSubState,
    BlocSubState? marcarLidoSubState,
    BlocSubState? marcarTodosLidosSubState,
    int? badgeCount,
  }) =>
      AlertasState(
        getAlertasSubState: getAlertasSubState ?? this.getAlertasSubState,
        marcarLidoSubState: marcarLidoSubState ?? this.marcarLidoSubState,
        marcarTodosLidosSubState:
            marcarTodosLidosSubState ?? this.marcarTodosLidosSubState,
        badgeCount: badgeCount ?? this.badgeCount,
      );
}
