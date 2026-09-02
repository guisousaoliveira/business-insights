/// Serviço prestado num atendimento, com o preço **congelado** no momento do
/// atendimento: mudar a tabela de preços no perfil não pode reescrever o
/// histórico financeiro.
class ServicoAtendimentoModel {
  static const _servicoIdKey = 'servico_id';
  static const _nomeKey = 'nome';
  static const _precoKey = 'preco';

  final String? servicoId;
  final String nome;
  final double preco;

  const ServicoAtendimentoModel({
    this.servicoId,
    required this.nome,
    required this.preco,
  });

  factory ServicoAtendimentoModel.fromResponse(Map<String, dynamic> map) =>
      ServicoAtendimentoModel(
        servicoId: map[_servicoIdKey] as String?,
        nome: map[_nomeKey] as String? ?? '',
        preco: (map[_precoKey] as num?)?.toDouble() ?? 0,
      );

  /// Serviço do catálogo manda só o id — o preço é do servidor. Serviço avulso
  /// manda nome e preço.
  Map<String, dynamic> get toBody => servicoId != null
      ? {_servicoIdKey: servicoId}
      : {_nomeKey: nome, _precoKey: preco};
}
