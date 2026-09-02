# 01 — Estrutura de pastas

```
lib/
├── main.dart                  # bootstrap: storage → runApp → MultiBlocProvider
├── cubits/                    # um subdiretório por módulo
│   ├── bloc_substate.dart     # BlocSubState — compartilhado por TODOS os estados
│   └── <modulo>/<modulo>_cubit.dart + <modulo>_state.dart
├── models/                    # espelha os módulos de cubits/
│   ├── response_model.dart    # envelope base da API
│   ├── error_model.dart       # erro normalizado
│   ├── dropdown_model.dart    # models transversais ficam na raiz
│   └── <modulo>/<acao>_request_model.dart + <acao>_response_model.dart
├── repositories/              # um arquivo por módulo: interface E implementação
│   └── <modulo>_repository.dart
├── settings/                  # infra e constantes; sem lógica de tela
│   ├── app_api.dart           # Dio + rotas + interceptors
│   ├── app_storage.dart       # Hive + SharedPreferences
│   ├── app_routes.dart        # navigatorKey + rotas + push/pop
│   ├── app_globals.dart       # getters globais (isLogged, l10n)
│   ├── app_enums.dart         # TODOS os enums
│   ├── app_utils.dart         # helpers puros: format, decode enum, logout
│   ├── app_constants.dart     # listas de opções — SEMPRE funções, não campos
│   ├── app_validators.dart · app_error_codes.dart
│   ├── app_colors.dart · app_fonts.dart · app_assets.dart
│   └── app_media_querys.dart  # DeviceType + breakpoints
├── l10n/                      # ARB (app_pt.arb, …)
└── ui/
    ├── components/            # design system: App* reutilizáveis
    │   ├── app_scaffold.dart · app_button.dart · app_input.dart · app_dropdown.dart
    │   ├── app_table.dart · app_dialog.dart · app_snackbar.dart
    │   └── app_sub_state_builder.dart   # helper loading/dado/erro/vazio
    └── screens/<modulo>/<nome>_screen.dart + widgets/ + dialogs/

test/                          # espelha lib/ — ver 14-testes.md
```

## Regras

1. **Mesmo nome de módulo** em `cubits/`, `models/`, `repositories/` e `ui/screens/`.
   Achar código é mecânico.
2. **Grafo de dependências** — nunca aponte uma seta para cima:

   ```
   ui/screens ──► ui/components ──► settings
        └──► cubits ──► repositories ──► models ──► settings
   ```

   `settings/` não importa `ui/` nem `cubits/` (exceção tolerada:
   `app_constants.dart`, que monta opções para a UI). `repositories/` só importa
   `models/` e `settings/app_api.dart`. `models/` só importa `settings/`.
   Camada baixa que precisa avisar a de cima (interceptor 401 deslogando) usa
   `AppUtils.logout()` + `AppRoutes.navigatorKey` — é para isso que o
   `navigatorKey` global existe.
3. **Widget usado por 2+ módulos** → `ui/components/` com prefixo `App`. Por 1 só →
   `ui/screens/<modulo>/widgets/`.
4. **Um arquivo por classe pública**, `snake_case` do nome da classe. Três exceções:
   `Controller` + `Widget` de um componente; interface + `Impl` de um repository;
   estado do cubit via `part`.
5. **Módulo com mais de ~8 operações deve ser dividido** — por entidade, não por tela.
   Um estado com 19 sub-estados é sintoma de um módulo que virou três.
