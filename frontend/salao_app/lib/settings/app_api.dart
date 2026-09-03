import 'package:dio/dio.dart';

import 'app_globals.dart' as globals;
import 'app_logger.dart';
import 'app_storage.dart';
import 'app_utils.dart';

/// URL base — **nunca fixa no código**.
///
/// ```bash
/// flutter run                                            # default de dev
/// flutter build apk --dart-define-from-file=env/prod.json
/// ```
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/v1',
);

/// Única porta de saída do app para a rede.
///
/// `_dio` é privado: **nenhuma outra camada toca no Dio**. Repositories chamam
/// os wrappers de verbo; cubits e telas não conhecem nem o `AppApi`.
///
/// O app fala **só com o FastAPI** (decisão A1). Não há Supabase aqui — nem
/// PostgREST, nem RPC, nem `anon key`.
class AppApi {
  const AppApi._();

  static final _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 50),
      receiveTimeout: const Duration(seconds: 50),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  )..interceptors.add(AuthDioInterceptor());

  // ── auth ───────────────────────────────────────────────────────────────────
  static const loginPath = '/auth/login';
  static const refreshPath = '/auth/refresh';
  static const logoutPath = '/auth/logout';
  static const getMePath = '/auth/eu';

  // ── atendimentos ───────────────────────────────────────────────────────────
  static const getAtendimentosPath = '/atendimentos';
  static const postAtendimentoPath = '/atendimentos';
  static const editAtendimentoPath = '/atendimentos';
  static const deleteAtendimentoPath = '/atendimentos';

  /// `'$finalizeAtendimentoPath/$id/finalizar'`
  static const finalizeAtendimentoPath = '/atendimentos';
  static const cancelAtendimentoPath = '/atendimentos';

  // ── gastos ─────────────────────────────────────────────────────────────────
  static const getGastosPath = '/gastos';
  static const postGastoPath = '/gastos';
  static const editGastoPath = '/gastos';
  static const payGastoPath = '/gastos';
  static const deleteGastoPath = '/gastos';

  // ── resumo ─────────────────────────────────────────────────────────────────
  static const getResumoMensalPath = '/resumo/mensal';
  static const postPrecificacaoPath = '/precificacao/calcular';

  // ── estoque ────────────────────────────────────────────────────────────────
  static const getEstoqueItensPath = '/estoque/itens';
  static const postEstoqueItemPath = '/estoque/itens';
  static const editEstoqueItemPath = '/estoque/itens';
  static const deleteEstoqueItemPath = '/estoque/itens';

  /// `'$postMovimentacaoPath/$itemId/movimentacoes'`
  static const postMovimentacaoPath = '/estoque/itens';
  static const getMovimentacoesPath = '/estoque/movimentacoes';

  // ── kits ───────────────────────────────────────────────────────────────────
  static const getKitsPath = '/kits';
  static const postKitPath = '/kits';
  static const editKitPath = '/kits';
  static const deleteKitPath = '/kits';
  static const montarKitPath = '/kits';
  static const venderKitPath = '/kits';

  // ── perfil ─────────────────────────────────────────────────────────────────
  static const getPerfilPath = '/perfil';
  static const editPerfilPath = '/perfil';
  static const getCustosFixosPath = '/perfil/custos-fixos';
  static const postCustoFixoPath = '/perfil/custos-fixos';
  static const editCustoFixoPath = '/perfil/custos-fixos';
  static const deleteCustoFixoPath = '/perfil/custos-fixos';
  static const payCustoFixoPath = '/perfil/custos-fixos';

  // ── servicos ───────────────────────────────────────────────────────────────
  static const getServicosPath = '/servicos';
  static const postServicoPath = '/servicos';
  static const editServicoPath = '/servicos';
  static const deleteServicoPath = '/servicos';

  // ── alertas ────────────────────────────────────────────────────────────────
  static const getAlertasPath = '/alertas';

  /// `'$readAlertaPath/$id/lido'`
  static const readAlertaPath = '/alertas';
  static const readAllAlertasPath = '/alertas/lidos';
  static const getAlertaPreferenciasPath = '/alertas/preferencias';
  static const editAlertaPreferenciasPath = '/alertas/preferencias';
  static const postDispositivoPath = '/dispositivos';
  static const deleteDispositivoPath = '/dispositivos';

  // ── Verbos ─────────────────────────────────────────────────────────────────

  static Future<Response<T>> get<T>(
    String path, {
    Object? data,
    FormData? formData,
    Map<String, dynamic>? queryParameters,
    ResponseType? responseType,
  }) async {
    assert(data == null || formData == null);
    await _setTokenHeader();
    _dio.options.contentType = formData != null
        ? Headers.multipartFormDataContentType
        : Headers.jsonContentType;
    _dio.options.responseType = responseType ?? ResponseType.json;
    return _dio.get<T>(
      path,
      data: data ?? formData,
      queryParameters: queryParameters,
    );
  }

  static Future<Response<T>> post<T>(
    String path, {
    Object? data,
    FormData? formData,
    Map<String, dynamic>? queryParameters,
  }) async {
    assert(data == null || formData == null);
    await _setTokenHeader();
    _dio.options.contentType = formData != null
        ? Headers.multipartFormDataContentType
        : Headers.jsonContentType;
    _dio.options.responseType = ResponseType.json;
    return _dio.post<T>(
      path,
      data: data ?? formData,
      queryParameters: queryParameters,
    );
  }

  static Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _setTokenHeader();
    _dio.options.contentType = Headers.jsonContentType;
    _dio.options.responseType = ResponseType.json;
    return _dio.put<T>(path, data: data, queryParameters: queryParameters);
  }

  static Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _setTokenHeader();
    _dio.options.contentType = Headers.jsonContentType;
    _dio.options.responseType = ResponseType.json;
    return _dio.patch<T>(path, data: data, queryParameters: queryParameters);
  }

  static Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _setTokenHeader();
    _dio.options.contentType = Headers.jsonContentType;
    _dio.options.responseType = ResponseType.json;
    return _dio.delete<T>(path, data: data, queryParameters: queryParameters);
  }

  /// Fluxo que precisa de um token diferente do da sessão (o refresh usa o
  /// refresh token, não o bearer). Nunca crie um `Dio` avulso no repository.
  static Future<Response<T>> postWithoutToken<T>(
    String path, {
    Object? data,
  }) async {
    _dio.options.headers.remove('Authorization');
    _dio.options.contentType = Headers.jsonContentType;
    _dio.options.responseType = ResponseType.json;
    return _dio.post<T>(path, data: data);
  }

  /// Chamado no início de **cada** verbo — a UI e os cubits nunca manipulam
  /// header.
  static Future<void> _setTokenHeader() async {
    _dio.options.headers.addAll({
      'Authorization':
          'Bearer ${AppStorage.read<String>(AppStorage.bearerToken) ?? ''}',
      'Accept-Language': globals.l10n?.localeName ?? 'pt-BR',
    });
  }
}

/// Sessão expirada é tratada em **um lugar só**: nenhum cubit checa 401.
///
/// Tenta o refresh **antes** do logout. É `QueuedInterceptor` (não
/// `Interceptor`) para serializar as requisições durante o refresh — senão N
/// chamadas simultâneas disparam N refreshes e as N-1 últimas falham.
class AuthDioInterceptor extends QueuedInterceptor {
  bool _refreshing = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || _refreshing) {
      return super.onError(err, handler);
    }

    final refreshToken = AppStorage.read<String>(AppStorage.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      await AppUtils.logout();
      return super.onError(err, handler);
    }

    _refreshing = true;
    try {
      final response = await AppApi.postWithoutToken(
        AppApi.refreshPath,
        data: {'refresh_token': refreshToken},
      );

      final result = (response.data as Map)['result'] as Map;
      await AppStorage.write(AppStorage.bearerToken, result['token'] as String);
      await AppStorage.write(
        AppStorage.refreshToken,
        result['refresh_token'] as String,
      );

      final request = err.requestOptions;
      request.headers['Authorization'] = 'Bearer ${result['token']}';
      return handler.resolve(
        await Dio(BaseOptions(baseUrl: _baseUrl)).fetch(request),
      );
    } catch (e, s) {
      AppLogger.warning('Refresh falhou; derrubando a sessão', e, s);
      await AppUtils.logout();
      return super.onError(err, handler);
    } finally {
      _refreshing = false;
    }
  }
}
