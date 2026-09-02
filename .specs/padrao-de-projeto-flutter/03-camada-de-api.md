# 03 — Camada de API (`AppApi`)

`lib/settings/app_api.dart` — uma **única classe estática** com três coisas: a
`baseUrl` por ambiente e a instância única do `Dio`; **todos os paths** como
`static const`; os wrappers de verbo que injetam token e content-type.

## 1. Base URL — nunca fixa no código

```dart
const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.dev.exemplo.com.br/api',   // desenvolvimento
);
```

```bash
flutter run                                                       # dev
flutter build web --dart-define=API_BASE_URL=https://api.exemplo.com.br/api
flutter build web --dart-define-from-file=env/prod.json           # sem repetir flags
```

> URL de produção fixa no código, com a de dev comentada acima, faz o binário
> depender de qual linha estava descomentada no build. Já causou build de
> homologação apontando para produção.

## 2. Instância do Dio

```dart
class AppApi {
  static final _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 50),
      receiveTimeout: const Duration(seconds: 50),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  )..interceptors.add(UnauthorizedDioInterceptor());
}
```

`_dio` é privado: **nenhuma outra camada toca no Dio**. Fluxo que precisa de
configuração diferente (token vindo de link de e-mail, por exemplo) ganha um método
dedicado no `AppApi` — nunca um `Dio` avulso no repository:

```dart
static Future<Response<T>> postWithToken<T>(String path,
    {required String token, Object? data}) async =>
    await _dio.post<T>(path, data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}));
```

## 3. Catálogo de paths

```dart
class AppApi {
  static const loginPath       = '/Autenticacao/login';
  static const getProductsPath = '/Produto/buscar-produtos';
  static const postProductPath = '/Produto/adicionar-produto';
}
```

**Nenhuma string de path solta no código.** Segmentos dinâmicos são concatenados no
repository: `'${AppApi.getProductsPath}/$storeId'`. Convenção: `get*Path`,
`post*Path`, `edit*Path`, `delete*Path`, `export*Path`.

## 4. Token e wrappers de verbo

```dart
static Future<void> _setTokenHeader() async {
  _dio.options.headers = _dio.options.headers..addAll({
    'Authorization': 'Bearer ${AppStorage.read<String>(AppStorage.bearerToken)}',
    'Accept-Language': globals.l10n?.localeName ?? 'pt-BR',
  });
}
```

Chamado no início de **cada** verbo — a UI e os cubits nunca manipulam header. Os
quatro wrappers são idênticos exceto pelo verbo:

```dart
static Future<Response<T>> get<T>(String path, {Object? data, FormData? formData,
    Map<String, dynamic>? queryParameters, ResponseType? responseType}) async {
  assert(data == null || formData == null);   // mutuamente exclusivos
  await _setTokenHeader();
  _dio.options.contentType = formData != null
      ? Headers.multipartFormDataContentType : Headers.jsonContentType;
  _dio.options.responseType = responseType ?? ResponseType.json;
  return await _dio.get<T>(path, data: data ?? formData,
                           queryParameters: queryParameters);
}
```

| Necessidade | Como |
|-------------|------|
| Autenticação | automática, via `_setTokenHeader()` |
| Upload de arquivo | passe `formData:` em vez de `data:` — o content-type muda sozinho |
| Download binário (xlsx/pdf) | `responseType: ResponseType.bytes` |
| Query string | `queryParameters:` |

## 5. Interceptors

**401 → logout** é o mínimo obrigatório. Sessão expirada é tratada em **um lugar
só**; nenhum cubit checa 401.

```dart
class UnauthorizedDioInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) AppUtils.logout();
    super.onError(err, handler);
  }
}
```

**Refresh token**, se o backend suportar, vem **antes** do logout. Use
`QueuedInterceptor` (não `Interceptor`): ele serializa as requisições durante o
refresh, evitando N refreshes simultâneos.

```dart
class AuthDioInterceptor extends QueuedInterceptor {
  bool _refreshing = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || _refreshing) {
      return super.onError(err, handler);
    }
    _refreshing = true;
    try {
      final novoToken = await AuthRepositoryImpl()
          .refresh(AppStorage.read<String>(AppStorage.refreshToken)!);
      await AppStorage.write(AppStorage.bearerToken, novoToken);
      final req = err.requestOptions;
      req.headers['Authorization'] = 'Bearer $novoToken';
      return handler.resolve(await Dio(BaseOptions(baseUrl: _baseUrl)).fetch(req));
    } catch (_) {
      AppUtils.logout();
      return super.onError(err, handler);
    } finally {
      _refreshing = false;
    }
  }
}
```

## 6. Como chamar (sempre pelo repository)

```dart
await AppApi.get('${AppApi.getProductsPath}/$storeId', queryParameters: model.toQuery);
await AppApi.post(AppApi.loginPath, data: model.toBody);
await AppApi.put('${AppApi.editProductPath}/${model.id}', data: model.toBody);
await AppApi.delete('${AppApi.deleteProductPath}/$id');
await AppApi.get(AppApi.exportProductsPath, responseType: ResponseType.bytes);
```

Envelope de resposta diferente? Ajuste `ResponseModel` ([05](05-models.md)) — **não**
o `AppApi`, que só transporta.
