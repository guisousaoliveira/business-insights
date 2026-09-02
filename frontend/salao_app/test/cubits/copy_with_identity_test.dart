import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app/cubits/alertas/alertas_cubit.dart';
import 'package:salon_app/cubits/atendimentos/atendimentos_cubit.dart';
import 'package:salon_app/cubits/auth/auth_cubit.dart';
import 'package:salon_app/cubits/bloc_substate.dart';
import 'package:salon_app/cubits/estoque/estoque_cubit.dart';
import 'package:salon_app/cubits/gastos/gastos_cubit.dart';
import 'package:salon_app/cubits/kits/kits_cubit.dart';
import 'package:salon_app/cubits/perfil/perfil_cubit.dart';
import 'package:salon_app/cubits/resumo/resumo_cubit.dart';
import 'package:salon_app/cubits/servicos/servicos_cubit.dart';

/// Um teste por módulo, protegendo a regra dura do `copyWith`.
///
/// Sem `Equatable`, o filtro `buildWhen` compara **identidade de instância**.
/// Se um `copyWith` reconstruir um sub-estado que não mudou, a tela inteira
/// passa a reconstruir a cada `emit` — sem erro, sem aviso, só lentidão. É
/// justamente o tipo de regressão que só um teste pega.
void main() {
  const loading = BlocSubState.loading;

  test('AuthState', () {
    const estado = AuthState();
    final novo = estado.copyWith(loginSubState: loading);

    expect(identical(estado.loginSubState, novo.loginSubState), isFalse);
    expect(identical(estado.logoutSubState, novo.logoutSubState), isTrue);
  });

  test('AtendimentosState', () {
    const estado = AtendimentosState();
    final novo = estado.copyWith(getAtendimentosSubState: loading);

    expect(
      identical(estado.getAtendimentosSubState, novo.getAtendimentosSubState),
      isFalse,
    );
    expect(
      identical(
        estado.createAtendimentoSubState,
        novo.createAtendimentoSubState,
      ),
      isTrue,
    );
    expect(
      identical(
        estado.finalizarAtendimentoSubState,
        novo.finalizarAtendimentoSubState,
      ),
      isTrue,
    );
    expect(
      identical(
        estado.cancelarAtendimentoSubState,
        novo.cancelarAtendimentoSubState,
      ),
      isTrue,
    );
  });

  test('GastosState', () {
    const estado = GastosState();
    final novo = estado.copyWith(getGastosSubState: loading);

    expect(
        identical(estado.getGastosSubState, novo.getGastosSubState), isFalse);
    expect(
      identical(estado.createGastoSubState, novo.createGastoSubState),
      isTrue,
    );
    expect(
      identical(estado.pagarGastoSubState, novo.pagarGastoSubState),
      isTrue,
    );
    expect(
      identical(estado.deleteGastoSubState, novo.deleteGastoSubState),
      isTrue,
    );
  });

  test('ResumoState preserva o período quando só o sub-estado muda', () {
    final estado = ResumoState();
    final novo = estado.copyWith(getResumoMensalSubState: loading);

    expect(
      identical(estado.getResumoMensalSubState, novo.getResumoMensalSubState),
      isFalse,
    );
    expect(novo.periodo, estado.periodo);
  });

  test('EstoqueState', () {
    const estado = EstoqueState();
    final novo = estado.copyWith(getItensSubState: loading);

    expect(identical(estado.getItensSubState, novo.getItensSubState), isFalse);
    expect(
      identical(estado.createItemSubState, novo.createItemSubState),
      isTrue,
    );
    expect(
      identical(
        estado.createMovimentacaoSubState,
        novo.createMovimentacaoSubState,
      ),
      isTrue,
    );
    expect(
      identical(
        estado.getMovimentacoesSubState,
        novo.getMovimentacoesSubState,
      ),
      isTrue,
    );
    expect(
      identical(estado.deleteItemSubState, novo.deleteItemSubState),
      isTrue,
    );
  });

  test('KitsState', () {
    const estado = KitsState();
    final novo = estado.copyWith(getKitsSubState: loading);

    expect(identical(estado.getKitsSubState, novo.getKitsSubState), isFalse);
    expect(identical(estado.createKitSubState, novo.createKitSubState), isTrue);
    expect(identical(estado.deleteKitSubState, novo.deleteKitSubState), isTrue);
    expect(identical(estado.montarKitSubState, novo.montarKitSubState), isTrue);
    expect(identical(estado.venderKitSubState, novo.venderKitSubState), isTrue);
  });

  test('PerfilState', () {
    const estado = PerfilState();
    final novo = estado.copyWith(getPerfilSubState: loading);

    expect(
        identical(estado.getPerfilSubState, novo.getPerfilSubState), isFalse);
    expect(
      identical(estado.updatePerfilSubState, novo.updatePerfilSubState),
      isTrue,
    );
    expect(
      identical(estado.getCustosFixosSubState, novo.getCustosFixosSubState),
      isTrue,
    );
    expect(
      identical(
        estado.createCustoFixoSubState,
        novo.createCustoFixoSubState,
      ),
      isTrue,
    );
    expect(
      identical(estado.editCustoFixoSubState, novo.editCustoFixoSubState),
      isTrue,
    );
    expect(
      identical(
        estado.deleteCustoFixoSubState,
        novo.deleteCustoFixoSubState,
      ),
      isTrue,
    );
    expect(
      identical(estado.pagarCustoFixoSubState, novo.pagarCustoFixoSubState),
      isTrue,
    );
  });

  test('ServicosState', () {
    const estado = ServicosState();
    final novo = estado.copyWith(getServicosSubState: loading);

    expect(
      identical(estado.getServicosSubState, novo.getServicosSubState),
      isFalse,
    );
    expect(
      identical(estado.createServicoSubState, novo.createServicoSubState),
      isTrue,
    );
    expect(
      identical(estado.editServicoSubState, novo.editServicoSubState),
      isTrue,
    );
    expect(
      identical(estado.deleteServicoSubState, novo.deleteServicoSubState),
      isTrue,
    );
  });

  test('AlertasState', () {
    const estado = AlertasState(badgeCount: 3);
    final novo = estado.copyWith(getAlertasSubState: loading);

    expect(
      identical(estado.getAlertasSubState, novo.getAlertasSubState),
      isFalse,
    );
    expect(
      identical(estado.marcarLidoSubState, novo.marcarLidoSubState),
      isTrue,
    );
    expect(
      identical(
        estado.marcarTodosLidosSubState,
        novo.marcarTodosLidosSubState,
      ),
      isTrue,
    );
    expect(novo.badgeCount, 3);
  });
}
