class ServicoRankingModel {
  static const _nomeKey = 'nome';
  static const _quantidadeKey = 'quantidade';
  static const _totalReceitaKey = 'total_receita';

  final String nome;
  final int quantidade;
  final double totalReceita;

  const ServicoRankingModel({
    required this.nome,
    required this.quantidade,
    required this.totalReceita,
  });

  factory ServicoRankingModel.fromResponse(Map<String, dynamic> map) =>
      ServicoRankingModel(
        nome: map[_nomeKey] as String? ?? '',
        quantidade: (map[_quantidadeKey] as num?)?.toInt() ?? 0,
        totalReceita: (map[_totalReceitaKey] as num?)?.toDouble() ?? 0,
      );
}
