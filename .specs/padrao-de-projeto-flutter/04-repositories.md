# 04 — Repositories

`lib/repositories/` — **um arquivo por módulo**, contendo a interface **e** a
implementação. Nunca métodos `static`: o cubit chamaria a classe concreta e não
haveria como testar sem bater na rede.

```dart
abstract interface class ProductRepository {
  Future<GetProductsResponseModel> getProducts(GetProductsRequestModel model);
  Future<void> deleteProduct(String id);
}

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl();

  @override
  Future<GetProductsResponseModel> getProducts(GetProductsRequestModel model) async {
    final response = await AppApi.get(
      '${AppApi.getProductsPath}/${model.storeId}',
      queryParameters: model.toQuery,
    );
    return GetProductsResponseModel.fromResponse(response.data);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await AppApi.delete('${AppApi.deleteProductPath}/$id');
  }
}
```

O cubit injeta com default (`repository ?? const ProductRepositoryImpl()`), então
produção continua `BlocProvider(create: (_) => ProductCubit())` e teste vira
`ProductCubit(repository: MockProductRepository())`. Sem container de DI, sem
`get_it`, sem mudança na UI. Ver [14-testes.md](14-testes.md).

## Contrato de um método

1. recebe primitivos ou um `RequestModel`;
2. monta o path e chama `AppApi.<verbo>`;
3. converte **`response.data`** num `ResponseModel` tipado;
4. **não** captura exceções — quem trata é o cubit;
5. **não** conhece estado, UI nem `BuildContext`.

Três linhas úteis por método. Se está ficando grande, a lógica pertence ao cubit ou
ao model.

**Sempre `response.data`**, nunca o `Response` do Dio inteiro — a fábrica recebe
`Map<String, dynamic>` para que o parse seja testável sem HTTP, com um JSON literal.

## Catálogo de formas

```dart
// GET com query inline (poucos parâmetros → dispensa RequestModel)
final response = await AppApi.get(AppApi.getDayOffsPath,
    queryParameters: {'idLoja': storeId, 'data': date});
return GetDayOffsResponseModel.fromResponse(response.data);

// Operação sem retorno útil → Future<void>, sem model de resposta
await AppApi.put('${AppApi.editFlagPath}/$storeId', queryParameters: {'valor': value});

// Resposta que não merece um model
final Map<String, dynamic> result = response.data[ResponseModel.resultkey];
return result.map((k, v) => MapEntry(int.parse(k), v as String));

// Download de binário
final response = await AppApi.get<List<int>>(AppApi.exportProductsPath,
    queryParameters: model.toQuery, responseType: ResponseType.bytes);
return Uint8List.fromList(response.data!);
```

## Regras

- Um método ↔ um endpoint. Compor duas chamadas é papel do cubit.
- Sem `try/catch`, sem `print`, sem `null` para sinalizar erro: **deixe a exceção subir**.
- Sem cache dentro do repository — persistência é `AppStorage`, decidida pelo cubit.
- Repository não formata dado para exibição (isso é `AppUtils`), só traduz JSON → model.
- A interface declara **apenas** os métodos usados.
