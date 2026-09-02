import '../../settings/app_enums.dart';
import '../../settings/app_utils.dart';
import '../response_model.dart';

/// Material que o serviço consome por padrão — é o que pré-preenche a tela de
/// finalizar atendimento, para a usuária não ter que lembrar o que gastou.
class ProdutoPadraoModel {
  static const _itemEstoqueIdKey = 'item_estoque_id';
  static const _nomeKey = 'nome';
  static const _quantidadeKey = 'quantidade';
  static const _unidadeKey = 'unidade';

  final String itemEstoqueId;
  final String nome;
  final double quantidade;
  final UnidadeEstoque unidade;

  const ProdutoPadraoModel({
    required this.itemEstoqueId,
    required this.nome,
    required this.quantidade,
    required this.unidade,
  });

  factory ProdutoPadraoModel.fromResponse(Map<String, dynamic> map) =>
      ProdutoPadraoModel(
        itemEstoqueId: map[_itemEstoqueIdKey] as String? ?? '',
        nome: map[_nomeKey] as String? ?? '',
        quantidade: (map[_quantidadeKey] as num?)?.toDouble() ?? 1,
        unidade: AppUtils.decodeUnidadeEstoque(map[_unidadeKey] as String?),
      );

  Map<String, dynamic> get toBody => {
        _itemEstoqueIdKey: itemEstoqueId,
        _quantidadeKey: quantidade,
      };
}

class ServicoModel {
  static const _idKey = 'id';
  static const _nomeKey = 'nome';
  static const _precoKey = 'preco';
  static const _produtosPadraoKey = 'produtos_padrao';

  final String id;
  final String nome;
  final double preco;
  final List<ProdutoPadraoModel> produtosPadrao;

  const ServicoModel({
    required this.id,
    required this.nome,
    required this.preco,
    this.produtosPadrao = const [],
  });

  factory ServicoModel.fromResponse(Map<String, dynamic> map) => ServicoModel(
        id: map[_idKey] as String? ?? '',
        nome: map[_nomeKey] as String? ?? '',
        preco: (map[_precoKey] as num?)?.toDouble() ?? 0,
        produtosPadrao: (map[_produtosPadraoKey] as List? ?? const [])
            .map((e) =>
                ProdutoPadraoModel.fromResponse(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> get toBody => {
        _nomeKey: nome,
        _precoKey: preco,
        _produtosPadraoKey: produtosPadrao.map((e) => e.toBody).toList(),
      };
}

class GetServicosResponseModel extends ResponseModel {
  static const _servicosKey = 'servicos';

  final List<ServicoModel> servicos;

  const GetServicosResponseModel({
    required super.total,
    required super.message,
    required this.servicos,
  });

  factory GetServicosResponseModel.fromResponse(Map<String, dynamic> map) {
    final result =
        map[ResponseModel.resultKey] as Map<String, dynamic>? ?? const {};

    return GetServicosResponseModel(
      total: ResponseModel.totalFrom(map),
      message: ResponseModel.messageFrom(map),
      servicos: (result[_servicosKey] as List? ?? const [])
          .map((e) => ServicoModel.fromResponse(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
