// ─────────────────────────────────────────────────────────────────────────────
// providers/perfil_provider.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/models.dart'; // Usando os modelos base de CustoFixo e Servico

class PerfilProvider extends ChangeNotifier {
  List<CustoFixo> _fixos = [];
  List<Servico> _servicos = [];
  bool _loading = false;
  String? _erro;

  List<CustoFixo> get fixos => _fixos;
  List<Servico> get servicos => _servicos;
  bool get loading => _loading;
  String? get erro => _erro;

  double get totalFixos => _fixos.fold(0.0, (s, c) => s + c.valor);

  Future<void> carregar() async {
    _loading = true;
    _erro = null;
    notifyListeners();

    try {
      // Quando a API estiver pronta, chamaremos: ApiService.getCustosFixos() e ApiService.getServicos()
      await Future.delayed(const Duration(milliseconds: 300)); // Simulando rede

      // Carrega os dados de exemplo apenas se a lista estiver vazia
      if (_fixos.isEmpty) _fixos = List.from(custosFixosExemplo);
      if (_servicos.isEmpty) _servicos = List.from(servicosExemplo);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> adicionarCustoFixo(String descricao, double valor) async {
    await Future.delayed(const Duration(milliseconds: 250)); // Simula API POST
    _fixos.add(CustoFixo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      descricao: descricao,
      valor: valor,
    ));
    notifyListeners();
  }

  Future<void> removerCustoFixo(String id) async {
    await Future.delayed(const Duration(milliseconds: 250)); // Simula API DELETE
    _fixos.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> adicionarServico(String nome, double preco, List<ProdutoAssociado> produtos) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _servicos.add(Servico(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: nome,
      preco: preco,
      produtosPadrao: produtos,
    ));
    notifyListeners();
  }

  Future<void> removerServico(String id) async {
    await Future.delayed(const Duration(milliseconds: 250)); // Simula API DELETE
    _servicos.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
