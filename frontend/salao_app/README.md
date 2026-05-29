# Salão App — POC Flutter

Gestão financeira para empreendedora solo de salão de beleza.

## Stack

| Camada | Tecnologia |
|--------|-----------|
| App mobile | Flutter + Dart |
| Estado | Provider (ChangeNotifier) |
| Banco / Auth | Mock local em memória |
| Backend | Mock local em memória |
| Automações | Sem integração externa |

## Estrutura

```
lib/
├── main.dart                        ← entry point, MultiProvider, tema
├── models/
│   └── atendimento.dart             ← todos os modelos + enums
├── services/
│   └── api_service.dart             ← dados mockados em memória
├── providers/
│   ├── atendimento_provider.dart    ← estado dos atendimentos
│   ├── gasto_provider.dart          ← estado dos gastos
│   └── relatorio_provider.dart      ← estado do relatório mensal
├── screens/
│   ├── login_screen.dart
│   ├── main_nav_screen.dart         ← IndexedStack + NavigationBar
│   ├── home_screen.dart             ← painel mensal (Fase 2)
│   ├── atendimentos_screen.dart     ← lista + formulário (Fase 1)
│   ├── gastos_screen.dart           ← lista + formulário (Fase 1)
│   └── perfil_screen.dart           ← custos fixos + alertas (Fase 1)
└── widgets/
    └── atendimento_tile.dart        ← collapsable central ★
```

## Como rodar

### 1. Instale as dependências
```bash
flutter pub get
```

### 2. Rode o app
```bash
flutter run
```

> Os dados são mockados localmente. Não há necessidade de Supabase nem variáveis de ambiente.

## Fases

| Fase | Funcionalidades | Status |
|------|----------------|--------|
| 1 | Registro de atendimentos, gastos, perfil de custos fixos | ✅ POC |
| 2 | Painel mensal com DRE simplificado | ✅ POC |
| 3 | Calculadora de precificação mínima | 🔜 Próximo |

## Dependências principais

```yaml
intl: ^0.19.0               # pt-BR (moeda e datas)
provider: ^6.1.2            # Gerência de estado
```
