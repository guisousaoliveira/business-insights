class ResumoHistoricoModel {
  static const _anoKey = 'ano';
  static const _mesKey = 'mes';
  static const _receitasKey = 'receitas';
  static const _despesasKey = 'despesas';

  final int ano;
  final int mes;
  final double receitas;
  final double despesas;

  const ResumoHistoricoModel({
    required this.ano,
    required this.mes,
    required this.receitas,
    required this.despesas,
  });

  factory ResumoHistoricoModel.fromResponse(Map<String, dynamic> map) =>
      ResumoHistoricoModel(
        ano: (map[_anoKey] as num?)?.toInt() ?? 0,
        mes: (map[_mesKey] as num?)?.toInt() ?? 0,
        receitas: (map[_receitasKey] as num?)?.toDouble() ?? 0,
        despesas: (map[_despesasKey] as num?)?.toDouble() ?? 0,
      );
}
