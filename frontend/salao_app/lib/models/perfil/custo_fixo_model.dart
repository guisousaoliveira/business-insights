import '../../settings/app_utils.dart';
import '../response_model.dart';

class CustoFixoModel {
  static const _idKey = 'id';
  static const _descricaoKey = 'descricao';
  static const _valorKey = 'valor';
  static const _diaVencimentoKey = 'dia_vencimento';
  static const _competenciaKey = 'competencia';
  static const _pagoKey = 'pago';
  static const _pagoEmKey = 'pago_em';

  /// Quando o backend não manda dia nenhum. Todo custo fixo tem uma data —
  /// aluguel vence, internet vence — então o campo não é opcional na tela; o
  /// dia 1 é só o palpite para o dado antigo, cadastrado antes deste campo
  /// existir.
  static const diaVencimentoPadrao = 1;

  final String id;
  final String descricao;
  final double valor;

  /// Dia do mês, de 1 a 31. Sem ele um custo fixo é só um número no total:
  /// não dá para avisar que vence amanhã nem para ordenar o mês.
  final int diaVencimento;

  /// `2026-09` — o mês a que o [pago] se refere.
  ///
  /// Custo fixo não se paga uma vez: ele volta todo mês. O que se marca como
  /// pago é a **ocorrência do mês**, não o cadastro — por isso o estado de
  /// pagamento anda junto de uma competência, e não dentro do custo.
  final String competencia;

  final bool pago;
  final DateTime? pagoEm;

  const CustoFixoModel({
    required this.id,
    required this.descricao,
    required this.valor,
    this.diaVencimento = diaVencimentoPadrao,
    this.competencia = '',
    this.pago = false,
    this.pagoEm,
  });

  /// O vencimento desta competência resolvido em data: dia 31 em fevereiro é o
  /// último dia do mês, não o dia 3 de março.
  DateTime? get vencimento {
    final partes = competencia.split('-');
    if (partes.length != 2) return null;

    final ano = int.tryParse(partes.first);
    final mes = int.tryParse(partes.last);
    if (ano == null || mes == null) return null;

    return AppUtils.vencimentoNoMes(diaVencimento, ano, mes);
  }

  /// Passou do dia e ninguém marcou como pago. É o que pinta a linha de
  /// vermelho — e o que o servidor usa para mandar `custo_fixo_vencido`.
  bool get isVencido {
    final data = vencimento;
    if (pago || data == null) return false;

    final agora = DateTime.now();
    return data.isBefore(DateTime(agora.year, agora.month, agora.day));
  }

  factory CustoFixoModel.fromResponse(Map<String, dynamic> map) =>
      CustoFixoModel(
        id: map[_idKey] as String? ?? '',
        descricao: map[_descricaoKey] as String? ?? '',
        valor: (map[_valorKey] as num?)?.toDouble() ?? 0,
        diaVencimento:
            (map[_diaVencimentoKey] as num?)?.toInt() ?? diaVencimentoPadrao,
        competencia: map[_competenciaKey] as String? ?? '',
        pago: map[_pagoKey] as bool? ?? false,
        pagoEm: DateTime.tryParse(map[_pagoEmKey] as String? ?? ''),
      );

  Map<String, dynamic> get toBody => {
        _descricaoKey: descricao,
        _valorKey: valor,
        _diaVencimentoKey: diaVencimento,
      };
}

class GetCustosFixosResponseModel extends ResponseModel {
  static const _totalMensalKey = 'total_mensal';
  static const _totalPagoKey = 'total_pago';
  static const _totalPendenteKey = 'total_pendente';
  static const _custosKey = 'custos';

  final double totalMensal;

  /// Quanto do mês já saiu e quanto ainda vai sair. Vem somado do servidor —
  /// o app não soma lista.
  final double totalPago;
  final double totalPendente;

  final List<CustoFixoModel> custos;

  const GetCustosFixosResponseModel({
    required super.total,
    required super.message,
    required this.totalMensal,
    required this.totalPago,
    required this.totalPendente,
    required this.custos,
  });

  factory GetCustosFixosResponseModel.fromResponse(Map<String, dynamic> map) {
    final result =
        map[ResponseModel.resultKey] as Map<String, dynamic>? ?? const {};

    return GetCustosFixosResponseModel(
      total: ResponseModel.totalFrom(map),
      message: ResponseModel.messageFrom(map),
      totalMensal: (result[_totalMensalKey] as num?)?.toDouble() ?? 0,
      totalPago: (result[_totalPagoKey] as num?)?.toDouble() ?? 0,
      totalPendente: (result[_totalPendenteKey] as num?)?.toDouble() ?? 0,
      custos: (result[_custosKey] as List? ?? const [])
          .map((e) => CustoFixoModel.fromResponse(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
