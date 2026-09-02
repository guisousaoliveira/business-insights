import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Logger do app (S5 da adaptação). **Nenhum `print` no projeto** — o lint
/// `avoid_print` reforça isso.
///
/// Chamado nos dois lugares onde erro nasce: o `catch` do cubit e o
/// `ErrorModel.fromDioException`. Em release, só `warning` e `error` passam.
class AppLogger {
  const AppLogger._();

  static const _name = 'salon_app';

  static void debug(String message) {
    if (!kReleaseMode) _log(message, level: 500);
  }

  static void info(String message) {
    if (!kReleaseMode) _log(message, level: 800);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(message, level: 900, error: error, stackTrace: stackTrace);

  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(message, level: 1000, error: error, stackTrace: stackTrace);

  static void _log(
    String message, {
    required int level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: _name,
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
