class ServicoRankingModel {
  static const _nomeKey = 'nome';
  static const _quantidadeKey = 'quantidade';
  static const _totalReceitaKey = 'total_receita';
  static const _lucroKey = 'lucro';

  final String nome;
  final int quantidade;
  final double totalReceita;
  final double lucro;

  const ServicoRankingModel({
    required this.nome,
    required this.quantidade,
    required this.totalReceita,
    this.lucro = 0,
  });

  factory ServicoRankingModel.fromResponse(Map<String, dynamic> map) =>
      ServicoRankingModel(
        nome: map[_nomeKey] as String? ?? '',
        quantidade: (map[_quantidadeKey] as num?)?.toInt() ?? 0,
        totalReceita: (map[_totalReceitaKey] as num?)?.toDouble() ?? 0,
        // Compatibilidade durante a implantação do contrato novo: enquanto o
        // backend ainda não mandar lucro, a receita mantém o ranking visível.
        lucro: (map[_lucroKey] as num?)?.toDouble() ??
            (map[_totalReceitaKey] as num?)?.toDouble() ??
            0,
      );
}
