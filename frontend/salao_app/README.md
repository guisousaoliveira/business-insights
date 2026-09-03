# Salão App — Flutter (Android/iOS)

O app de celular da Thamires Borges Beauty. **Só mobile**: desde a decisão A10 a
web é um projeto React separado, em `frontend/salao_web`.

Contexto do produto, decisões (A1–A10) e o padrão arquitetural estão no
[CLAUDE.md](../../CLAUDE.md) da raiz do repositório.

## Estrutura

```
lib/
├── main.dart              # MaterialApp, providers globais, rotas
├── settings/              # AppApi, AppStorage, AppRoutes, cores, fontes, enums
├── cubits/                # um Cubit por módulo + BlocSubState por operação
├── models/                # *_model.dart com fromResponse(Map)
├── repositories/          # interface + impl por módulo; demo/ = servidor falso
├── l10n/                  # ARB pt-BR — nenhuma string visível fora daqui
└── ui/
    ├── components/        # o design system (App*), casca em app_scaffold.dart
    ├── dialogs/           # diálogos de domínio usados por mais de uma tela
    └── screens/           # uma pasta por módulo
```

## Como rodar

```bash
flutter pub get
flutter run --dart-define-from-file=env/demo.json
```

`env/demo.json` liga o **modo demo**: um servidor falso em memória por trás das
mesmas interfaces de repository, para o app ser navegável enquanto o FastAPI não
sobe. `env/dev.json`, `env/hml.json` e `env/prod.json` apontam para a API real.

## Portões

```bash
flutter analyze          # sem nenhum aviso
flutter test             # 102 testes
flutter build apk --dart-define-from-file=env/prod.json
```

## Telas

| Tela | O que responde |
|---|---|
| Resumo | entrada do app: saldo do mês, histórico de 6 meses, insights, meta |
| Atendimentos | agendar, finalizar (com baixa de estoque), cancelar |
| Gastos | lançar, marcar pago, pendentes vs pagos |
| Estoque | itens, movimentações e kits de revenda |
| Perfil | dados do salão, custos fixos e tabela de serviços |

A casca é uma só: app bar, barra inferior de 5 destinos e FAB para a ação
primária (`ui/components/app_scaffold.dart`).
