import '../response_model.dart';
import 'servico_ranking_model.dart';

/// Consolidação do mês. Substitui o `RelatorioMensal` plano do app antigo — o
/// contrato aninhado da API vence, estendido com os insights do protótipo.
class GetResumoMensalResponseModel extends ResponseModel {
  static const _anoKey = 'ano';
  static const _mesKey = 'mes';
  static const _saldoFinalKey = 'saldo_final';
  static const _entrouKey = 'entrou';
  static const _saiuKey = 'saiu';
  static const _receitaKey = 'receita';
  static const _gastosKey = 'gastos';
  static const _insightsKey = 'insights';
  static const _alertaZeroAZeroKey = 'alerta_zero_a_zero';

  static const _totalServicosKey = 'total_servicos';
  static const _totalInsumosKey = 'total_insumos';
  static const _liquidoAtendimentosKey = 'liquido_atendimentos';
  static const _quantidadeAtendimentosKey = 'quantidade_atendimentos';
  static const _servicosMaisRealizadosKey = 'servicos_mais_realizados';
  static const _totalKitsKey = 'total_kits';
  static const _quantidadeKitsVendidosKey = 'quantidade_kits_vendidos';
  static const _custoKitsVendidosKey = 'custo_kits_vendidos';

  static const _totalCustosFixosKey = 'total_custos_fixos';
  static const _totalGastosVariaveisKey = 'total_gastos_variaveis';

  static const _ticketMedioKey = 'ticket_medio';
  static const _margemLucroKey = 'margem_lucro_percentual';
  static const _variacaoMesAnteriorKey = 'variacao_percentual_mes_anterior';
  static const _servicoMaisLucrativoKey = 'servico_mais_lucrativo';
  static const _nomeKey = 'nome';

  final int ano;
  final int mes;
  final double saldoFinal;
  final double entrou;
  final double saiu;

  final double totalServicos;
  final double totalInsumos;
  final double liquidoAtendimentos;
  final int quantidadeAtendimentos;
  final List<ServicoRankingModel> servicosMaisRealizados;

  /// Venda de kit é receita e entra no `entrou` do mês, junto com os serviços.
  /// O custo do kit **não** entra no `saiu`: ele já foi contado quando o insumo
  /// foi comprado — somar de novo contaria o mesmo dinheiro duas vezes.
  final double totalKits;
  final int quantidadeKitsVendidos;
  final double custoKitsVendidos;

  final double totalCustosFixos;
  final double totalGastosVariaveis;

  final double ticketMedio;
  final double margemLucroPercentual;
  final double variacaoPercentualMesAnterior;
  final String? servicoMaisLucrativo;

  final bool alertaZeroAZero;

  const GetResumoMensalResponseModel({
    required super.total,
    required super.message,
    required this.ano,
    required this.mes,
    required this.saldoFinal,
    required this.entrou,
    required this.saiu,
    required this.totalServicos,
    required this.totalInsumos,
    required this.liquidoAtendimentos,
    required this.quantidadeAtendimentos,
    required this.servicosMaisRealizados,
    required this.totalKits,
    required this.quantidadeKitsVendidos,
    required this.custoKitsVendidos,
    required this.totalCustosFixos,
    required this.totalGastosVariaveis,
    required this.ticketMedio,
    required this.margemLucroPercentual,
    required this.variacaoPercentualMesAnterior,
    this.servicoMaisLucrativo,
    required this.alertaZeroAZero,
  });

  bool get isPositivo => saldoFinal >= 0;

  /// Só mostra a linha de kits no resumo se houve venda — mês sem kit não
  /// precisa de uma linha zerada ocupando espaço.
  bool get temVendaDeKit => quantidadeKitsVendidos > 0;

  /// Proporção do que entrou sobre o total movimentado — a barra dividida do
  /// cartão de saldo. Sem movimento, mostra tudo verde em vez de dividir por
  /// zero.
  double get proporcaoEntrada =>
      (entrou + saiu) == 0 ? 1 : entrou / (entrou + saiu);

  /// A maior receita do ranking, para dimensionar as barrinhas.
  double get maiorReceitaDoRanking => servicosMaisRealizados.isEmpty
      ? 0
      : servicosMaisRealizados
          .map((e) => e.totalReceita)
          .reduce((a, b) => a > b ? a : b);

  factory GetResumoMensalResponseModel.fromResponse(Map<String, dynamic> map) {
    final result =
        map[ResponseModel.resultKey] as Map<String, dynamic>? ?? const {};
    final receita = result[_receitaKey] as Map<String, dynamic>? ?? const {};
    final gastos = result[_gastosKey] as Map<String, dynamic>? ?? const {};
    final insights = result[_insightsKey] as Map<String, dynamic>? ?? const {};
    final maisLucrativo =
        insights[_servicoMaisLucrativoKey] as Map<String, dynamic>?;

    return GetResumoMensalResponseModel(
      total: ResponseModel.totalFrom(map),
      message: ResponseModel.messageFrom(map),
      ano: (result[_anoKey] as num?)?.toInt() ?? DateTime.now().year,
      mes: (result[_mesKey] as num?)?.toInt() ?? DateTime.now().month,
      saldoFinal: (result[_saldoFinalKey] as num?)?.toDouble() ?? 0,
      entrou: (result[_entrouKey] as num?)?.toDouble() ?? 0,
      saiu: (result[_saiuKey] as num?)?.toDouble() ?? 0,
      totalServicos: (receita[_totalServicosKey] as num?)?.toDouble() ?? 0,
      totalInsumos: (receita[_totalInsumosKey] as num?)?.toDouble() ?? 0,
      liquidoAtendimentos:
          (receita[_liquidoAtendimentosKey] as num?)?.toDouble() ?? 0,
      quantidadeAtendimentos:
          (receita[_quantidadeAtendimentosKey] as num?)?.toInt() ?? 0,
      servicosMaisRealizados:
          (receita[_servicosMaisRealizadosKey] as List? ?? const [])
              .map((e) =>
                  ServicoRankingModel.fromResponse(e as Map<String, dynamic>))
              .toList(),
      totalKits: (receita[_totalKitsKey] as num?)?.toDouble() ?? 0,
      quantidadeKitsVendidos:
          (receita[_quantidadeKitsVendidosKey] as num?)?.toInt() ?? 0,
      custoKitsVendidos:
          (receita[_custoKitsVendidosKey] as num?)?.toDouble() ?? 0,
      totalCustosFixos: (gastos[_totalCustosFixosKey] as num?)?.toDouble() ?? 0,
      totalGastosVariaveis:
          (gastos[_totalGastosVariaveisKey] as num?)?.toDouble() ?? 0,
      ticketMedio: (insights[_ticketMedioKey] as num?)?.toDouble() ?? 0,
      margemLucroPercentual:
          (insights[_margemLucroKey] as num?)?.toDouble() ?? 0,
      variacaoPercentualMesAnterior:
          (insights[_variacaoMesAnteriorKey] as num?)?.toDouble() ?? 0,
      servicoMaisLucrativo: maisLucrativo?[_nomeKey] as String?,
      alertaZeroAZero: result[_alertaZeroAZeroKey] as bool? ?? false,
    );
  }
}
