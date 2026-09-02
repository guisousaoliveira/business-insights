/// Material descartável usado num atendimento. Quando tem [itemEstoqueId], a
/// finalização dá baixa no estoque — a regra roda no servidor.
class MaterialAtendimentoModel {
  static const _itemEstoqueIdKey = 'item_estoque_id';
  static const _nomeKey = 'nome';
  static const _quantidadeKey = 'quantidade';
  static const _precoKey = 'preco';

  final String? itemEstoqueId;
  final String nome;
  final double quantidade;
  final double preco;

  const MaterialAtendimentoModel({
    this.itemEstoqueId,
    required this.nome,
    required this.quantidade,
    required this.preco,
  });

  factory MaterialAtendimentoModel.fromResponse(Map<String, dynamic> map) =>
      MaterialAtendimentoModel(
        itemEstoqueId: map[_itemEstoqueIdKey] as String?,
        nome: map[_nomeKey] as String? ?? '',
        quantidade: (map[_quantidadeKey] as num?)?.toDouble() ?? 1,
        preco: (map[_precoKey] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> get toBody => itemEstoqueId != null
      ? {_itemEstoqueIdKey: itemEstoqueId, _quantidadeKey: quantidade}
      : {_nomeKey: nome, _quantidadeKey: quantidade, _precoKey: preco};
}
