import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_logger.dart';

/// Wrapper estático único sobre `SharedPreferences` (decisão A4 / S2).
///
/// Mantém a fachada do padrão — `read` síncrono, `write` assíncrono, chaves
/// centralizadas, falha silenciosa se não inicializado — mas sem Hive e sem
/// drift: funciona igual em web e mobile, sem code-gen e sem banco local.
///
/// **Serve para sessão e cache leve.** Não é offline-first: escrita sem rede
/// falha no repository e a UI mostra o erro.
class AppStorage {
  const AppStorage._();

  static bool _isInitializing = false;
  static bool _isInitialized = false;
  static late final SharedPreferences sharedPreferences;

  // ── CHAVES: todas declaradas aqui, nunca strings soltas ────────────────────
  static const bearerToken = 'bearerToken';
  static const refreshToken = 'refreshToken';
  static const userInfoKey = 'user_info';
  static const salonInfoKey = 'salon_info';

  /// Mês/ano selecionado na tela de Resumo, preservado entre navegações.
  static const selectedPeriodKey = 'selected_period';

  /// Id do item de estoque que a tela de detalhe deve abrir (passagem entre
  /// telas que sobrevive a F5 na web — ver 07 do padrão).
  static const selectedStockItemKey = 'selected_stock_item';

  static Future<void> initialize() async {
    if (_isInitializing || _isInitialized) return;
    _isInitializing = true;
    try {
      sharedPreferences = await SharedPreferences.getInstance();
    } catch (e, s) {
      _isInitialized = false;
      _isInitializing = false;
      AppLogger.error('Falha ao inicializar o AppStorage', e, s);
      rethrow;
    }
    _isInitialized = true;
    _isInitializing = false;
  }

  /// Leitura **síncrona** — pode ser usada em `initState`, em getters globais e
  /// no route guard. Devolve `null` se a chave não existe ou se o storage não
  /// foi inicializado.
  static T? read<T>(String key) {
    if (!_isInitialized) return null;
    final raw = sharedPreferences.getString(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map[_valueKey] as T?;
    } catch (e, s) {
      AppLogger.warning('Valor ilegível no storage para a chave "$key"', e, s);
      return null;
    }
  }

  /// Aceita primitivos, `List` e `Map` de primitivos — o que `jsonEncode`
  /// serializa. Objetos passam pelo `toStorage` do model, como manda o padrão.
  static Future<void> write<T>(String key, T value) async {
    if (!_isInitialized) return;
    await sharedPreferences.setString(key, jsonEncode({_valueKey: value}));
  }

  static Future<void> delete(String key) async {
    if (!_isInitialized) return;
    await sharedPreferences.remove(key);
  }

  static Future<void> clear() async {
    if (!_isInitialized) return;
    await sharedPreferences.clear();
  }

  /// Embrulhar em `{'value': x}` distingue "chave ausente" de "valor nulo" e
  /// uniformiza o tipo gravado — é o mesmo truque do padrão base com o Hive.
  static const _valueKey = 'value';
}
