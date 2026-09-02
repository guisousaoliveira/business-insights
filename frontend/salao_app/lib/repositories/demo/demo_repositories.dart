import '../../models/alertas/get_alertas_response_model.dart';
import '../../models/atendimentos/create_atendimento_request_model.dart';
import '../../models/atendimentos/finalizar_atendimento_request_model.dart';
import '../../models/atendimentos/get_atendimentos_response_model.dart';
import '../../models/auth/login_request_model.dart';
import '../../models/auth/login_response_model.dart';
import '../../models/estoque/create_estoque_item_request_model.dart';
import '../../models/estoque/create_movimentacao_request_model.dart';
import '../../models/estoque/get_estoque_itens_response_model.dart';
import '../../models/estoque/get_movimentacoes_response_model.dart';
import '../../models/gastos/create_gasto_request_model.dart';
import '../../models/gastos/get_gastos_response_model.dart';
import '../../models/kits/get_kits_response_model.dart';
import '../../models/kits/kit_model.dart';
import '../../models/perfil/custo_fixo_model.dart';
import '../../models/perfil/perfil_model.dart';
import '../../models/resumo/get_resumo_mensal_response_model.dart';
import '../../models/servicos/servico_model.dart';
import '../../settings/app_enums.dart';
import '../../settings/app_utils.dart';
import '../alertas_repository.dart';
import '../atendimentos_repository.dart';
import '../auth_repository.dart';
import '../estoque_repository.dart';
import '../gastos_repository.dart';
import '../kits_repository.dart';
import '../perfil_repository.dart';
import '../resumo_repository.dart';
import '../servicos_repository.dart';
import 'demo_database.dart';

/// Os nove repositories do modo demo.
///
/// Cada um implementa a **mesma interface** do repository de produção e faz o
/// mesmo que ele: monta o corpo com o `toBody` do request model, entrega para o
/// "servidor" (aqui, a [DemoDatabase]) e devolve o response model montado pelo
/// `fromResponse` de verdade.
///
/// Nada aqui trata exceção — quem trata é o cubit, exatamente como no caminho
/// real. Os `DioException` que a [DemoDatabase] lança chegam ao
/// `ErrorModel.fromDioException` com `codigo` e `result` no lugar.
final _db = DemoDatabase.instance;

Future<void> _latencia() => Future.delayed(DemoDatabase.latencia);

class DemoAuthRepository implements AuthRepository {
  const DemoAuthRepository();

  @override
  Future<LoginResponseModel> login(LoginRequestModel model) async {
    await _latencia();
    return LoginResponseModel.fromResponse(_db.login(model.email, model.senha));
  }

  @override
  Future<void> logout() => _latencia();
}

class DemoAtendimentosRepository implements AtendimentosRepository {
  const DemoAtendimentosRepository();

  @override
  Future<GetAtendimentosResponseModel> getAtendimentos({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    await _latencia();
    return GetAtendimentosResponseModel.fromResponse(
      _db.getAtendimentos(inicio, fim),
    );
  }

  @override
  Future<void> createAtendimento(CreateAtendimentoRequestModel model) async {
    await _latencia();
    _db.createAtendimento(model.toBody);
  }

  @override
  Future<void> finalizarAtendimento(
    FinalizarAtendimentoRequestModel model,
  ) async {
    await _latencia();
    _db.finalizarAtendimento(model.id, model.toBody);
  }

  @override
  Future<void> cancelarAtendimento(String id) async {
    await _latencia();
    _db.cancelarAtendimento(id);
  }
}

class DemoGastosRepository implements GastosRepository {
  const DemoGastosRepository();

  @override
  Future<GetGastosResponseModel> getGastos({
    required int ano,
    required int mes,
  }) async {
    await _latencia();
    return GetGastosResponseModel.fromResponse(_db.getGastos(ano, mes));
  }

  @override
  Future<void> createGasto(CreateGastoRequestModel model) async {
    await _latencia();
    _db.createGasto(model.toBody);
  }

  @override
  Future<void> pagarGasto(String id) async {
    await _latencia();
    _db.pagarGasto(id);
  }

  @override
  Future<void> deleteGasto(String id) async {
    await _latencia();
    _db.deleteGasto(id);
  }
}

class DemoResumoRepository implements ResumoRepository {
  const DemoResumoRepository();

  @override
  Future<GetResumoMensalResponseModel> getResumoMensal({
    required int ano,
    required int mes,
  }) async {
    await _latencia();
    return GetResumoMensalResponseModel.fromResponse(
      _db.getResumoMensal(ano, mes),
    );
  }
}

class DemoEstoqueRepository implements EstoqueRepository {
  const DemoEstoqueRepository();

  @override
  Future<GetEstoqueItensResponseModel> getItens() async {
    await _latencia();
    return GetEstoqueItensResponseModel.fromResponse(_db.getItens());
  }

  @override
  Future<void> createItem(CreateEstoqueItemRequestModel model) async {
    await _latencia();
    _db.createItem(model.toBody);
  }

  @override
  Future<void> deleteItem(String id) async {
    await _latencia();
    _db.deleteItem(id);
  }

  @override
  Future<void> createMovimentacao(CreateMovimentacaoRequestModel model) async {
    await _latencia();
    _db.createMovimentacao(model.itemId, model.toBody);
  }

  @override
  Future<GetMovimentacoesResponseModel> getMovimentacoes({
    String? itemId,
  }) async {
    await _latencia();
    return GetMovimentacoesResponseModel.fromResponse(
      _db.getMovimentacoes(itemId),
    );
  }
}

class DemoKitsRepository implements KitsRepository {
  const DemoKitsRepository();

  @override
  Future<GetKitsResponseModel> getKits() async {
    await _latencia();
    return GetKitsResponseModel.fromResponse(_db.getKits());
  }

  @override
  Future<void> createKit({
    required String nome,
    required double precoVenda,
    required List<KitItemModel> itens,
  }) async {
    await _latencia();
    _db.createKit({
      'nome': nome,
      'preco_venda': precoVenda,
      'itens': itens.map((e) => e.toBody).toList(),
    });
  }

  @override
  Future<void> deleteKit(String id) async {
    await _latencia();
    _db.deleteKit(id);
  }

  @override
  Future<void> montarKit({
    required String id,
    required double quantidade,
    bool confirmarEstoqueInsuficiente = false,
  }) async {
    await _latencia();
    _db.montarKit(id, {
      'quantidade': quantidade,
      'confirmar_estoque_insuficiente': confirmarEstoqueInsuficiente,
    });
  }

  @override
  Future<void> venderKit({
    required String id,
    required double quantidade,
    required FormaPagamento formaPagamento,
    double? precoUnitario,
  }) async {
    await _latencia();
    _db.venderKit(id, {
      'quantidade': quantidade,
      'forma_pagamento': AppUtils.formaPagamentoToApi(formaPagamento),
      if (precoUnitario != null) 'preco_unitario': precoUnitario,
    });
  }
}

class DemoPerfilRepository implements PerfilRepository {
  const DemoPerfilRepository();

  @override
  Future<GetPerfilResponseModel> getPerfil() async {
    await _latencia();
    return GetPerfilResponseModel.fromResponse(_db.getPerfil());
  }

  @override
  Future<void> updatePerfil(PerfilModel model) async {
    await _latencia();
    _db.updatePerfil(model.toBody);
  }

  @override
  Future<GetCustosFixosResponseModel> getCustosFixos() async {
    await _latencia();
    return GetCustosFixosResponseModel.fromResponse(_db.getCustosFixos());
  }

  @override
  Future<void> createCustoFixo(CustoFixoModel model) async {
    await _latencia();
    _db.createCustoFixo(model.toBody);
  }

  @override
  Future<void> deleteCustoFixo(String id) async {
    await _latencia();
    _db.deleteCustoFixo(id);
  }
}

class DemoServicosRepository implements ServicosRepository {
  const DemoServicosRepository();

  @override
  Future<GetServicosResponseModel> getServicos() async {
    await _latencia();
    return GetServicosResponseModel.fromResponse(_db.getServicos());
  }

  @override
  Future<void> createServico(ServicoModel model) async {
    await _latencia();
    _db.createServico(model.toBody);
  }

  @override
  Future<void> deleteServico(String id) async {
    await _latencia();
    _db.deleteServico(id);
  }
}

class DemoAlertasRepository implements AlertasRepository {
  const DemoAlertasRepository();

  @override
  Future<GetAlertasResponseModel> getAlertas({bool? apenasNaoLidos}) async {
    await _latencia();
    return GetAlertasResponseModel.fromResponse(_db.getAlertas(apenasNaoLidos));
  }

  @override
  Future<void> marcarLido(String id) async {
    await _latencia();
    _db.marcarLido(id);
  }

  @override
  Future<void> marcarTodosLidos() async {
    await _latencia();
    _db.marcarTodosLidos();
  }
}
