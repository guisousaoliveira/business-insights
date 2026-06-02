// ─────────────────────────────────────────────────────────────────────────────
// providers/estoque_provider.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/models.dart';

class EstoqueProvider extends ChangeNotifier {
  List<ItemEstoque> _itens = [];
  List<MovimentacaoEstoque> _movimentacoes = [];
  bool _loading = false;
  String? _erro;

  List<ItemEstoque> get itens => _itens;
  List<MovimentacaoEstoque> get movimentacoes => _movimentacoes;
  bool get loading => _loading;
  String? get erro => _erro;

  List<KitRevenda> _kits = [];
  List<KitRevenda> get kits => _kits;

  Future<void> adicionarKit(KitRevenda kit) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _kits.add(kit);
    notifyListeners();
  }

  // Filtros derivados
  List<ItemEstoque> get emAlerta => _itens.where((i) => i.emAlerta && i.ativo).toList()..sort((a, b) => a.status.index.compareTo(b.status.index));

  List<ItemEstoque> get emOk => _itens.where((i) => !i.emAlerta && i.ativo).toList();

  int get totalAlertas => emAlerta.length;

  double get valorTotalEstoque => _itens.where((i) => i.ativo).fold(0.0, (s, i) => s + i.quantidadeAtual * i.custoUnitario);

  Future<void> carregar() async {
    _loading = true;
    _erro = null;
    notifyListeners();

    try {
      // Futuramente: ApiService.getEstoque() e ApiService.getMovimentacoes()
      await Future.delayed(const Duration(milliseconds: 300));

      if (_itens.isEmpty) _itens = List.from(estoqueExemplo);
      if (_movimentacoes.isEmpty) _movimentacoes = List.from(movimentacoesExemplo);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> registrarEntrada(ItemEstoque item, double quantidade) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simula API

    final idx = _itens.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      // Atualiza o item
      _itens[idx] = _itens[idx].copyWith(
        quantidadeAtual: _itens[idx].quantidadeAtual + quantidade,
      );

      // Registra no histórico
      _movimentacoes.insert(
          0,
          MovimentacaoEstoque(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            itemId: item.id,
            tipo: TipoMovimentacao.entrada,
            quantidade: quantidade,
            motivo: 'Entrada manual',
            criadoEm: DateTime.now(),
          ));

      notifyListeners();
    }
  }

  Future<void> adicionarItem(ItemEstoque novoItem) async {
    await Future.delayed(const Duration(milliseconds: 250)); // Simula API
    _itens.add(novoItem);
    notifyListeners();
  }

  Future<void> registrarSaidaList(List<Map<String, dynamic>> materiais, String atendimentoNome) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simula API

    final agora = DateTime.now();

    for (var mat in materiais) {
      final nomeProduto = mat['nome'];
      final quantidadeGasta = mat['quantidade'] ?? 1.0; // Pega a qtd gasta

      // Encontra o item no estoque pelo nome
      final idx = _itens.indexWhere((i) => i.nome == nomeProduto);
      if (idx != -1) {
        // Deduz a quantidade
        _itens[idx] = _itens[idx].copyWith(
          quantidadeAtual: (_itens[idx].quantidadeAtual - quantidadeGasta).clamp(0.0, double.infinity),
        );

        // Registra a saída no Histórico
        _movimentacoes.insert(
            0,
            MovimentacaoEstoque(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              itemId: _itens[idx].id,
              tipo: TipoMovimentacao.saida,
              quantidade: quantidadeGasta,
              motivo: 'Atendimento: $atendimentoNome',
              criadoEm: agora,
            ));
      }
    }
    notifyListeners();
  }
}
