import '../../settings/app_enums.dart';
import '../../settings/app_utils.dart';

class CreateEstoqueItemRequestModel {
  final String nome;
  final UnidadeEstoque unidade;
  final CategoriaEstoque categoria;
  final double quantidadeAtual;
  final double quantidadeMinima;
  final double custoUnitario;

  const CreateEstoqueItemRequestModel({
    required this.nome,
    required this.unidade,
    required this.categoria,
    required this.quantidadeAtual,
    required this.quantidadeMinima,
    required this.custoUnitario,
  });

  Map<String, dynamic> get toBody => {
        'nome': nome,
        'unidade': unidade.name,
        'categoria': AppUtils.categoriaEstoqueToApi(categoria),
        'quantidade_atual': quantidadeAtual,
        'quantidade_minima': quantidadeMinima,
        'custo_unitario': custoUnitario,
      };
}
