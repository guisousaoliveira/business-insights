// ─────────────────────────────────────────────────────────────────────────────
// providers/relatorio_provider.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/atendimento.dart';
import '../services/api_service.dart';

class RelatorioProvider extends ChangeNotifier {
  RelatorioMensal? _relatorio;
  bool _loading = false;
  String? _erro;

  RelatorioMensal? get relatorio => _relatorio;
  bool    get loading            => _loading;
  String? get erro               => _erro;

  Future<void> carregar({int? mes, int? ano}) async {
    _loading = true;
    _erro = null;
    notifyListeners();

    try {
      final json = await ApiService.getRelatorioMensal(mes: mes, ano: ano);
      _relatorio = RelatorioMensal.fromJson(json);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
