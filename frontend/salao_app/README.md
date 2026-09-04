# Salon App — Flutter

App de gestão financeira para salão de beleza. Interface mobile-first, simples e funcional.

## Estrutura do projeto

```
lib/
├── main.dart                    # Entrada do app
├── theme/
│   └── app_theme.dart           # Cores, tipografia, estilos globais
├── models/
│   └── models.dart              # Modelos de dados + dados de exemplo
├── widgets/
│   └── common_widgets.dart      # Componentes reutilizáveis
└── screens/
    ├── home_screen.dart         # BottomNav + IndexedStack
    ├── atendimentos_screen.dart # Lista colapsável de atendimentos
    ├── gastos_screen.dart       # Gastos semanais com checkbox
    ├── resumo_screen.dart       # Resumo financeiro do mês
    └── perfil_screen.dart       # Custos fixos e tabela de serviços
```

## Como rodar

```bash
cd salon_app
flutter pub get
flutter run
```

## Telas

### Atendimentos
- Lista colapsável por cliente
- Mostra serviços realizados, insumos usados e saldo líquido por atendimento
- Banner com total do mês no topo
- FAB para novo atendimento

### Gastos
- Agrupado por semana, colapsável
- Checkbox para marcar como pago
- Tags de prioridade (alta / média / baixa) e forma de pagamento
- Métricas de pendente vs pago no topo

### Resumo
- Saldo real do mês (entrou − saiu)
- Barra visual de proporção
- Breakdown de receita de atendimentos e gastos
- Aviso quando está no zero a zero

### Perfil
- Cadastro de custos fixos (aluguel, internet, etc.)
- Tabela de serviços com preços
- Adicionar e remover itens

## Próximos passos (integração com backend)
1. Substituir dados de exemplo por chamadas ao Supabase REST API
2. Adicionar auth (Supabase Auth)
3. Conectar endpoints de cálculo no FastAPI (`/relatorio/mensal`)
4. Transformar em PWA para rodar no celular sem app store
