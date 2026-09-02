// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Thamires Borges Beauty';

  @override
  String get unknownError => 'Ocorreu um erro inesperado.';

  @override
  String get connectionError => 'Sem conexão. Verifique sua internet.';

  @override
  String get unauthorizedError => 'Sessão expirada. Entre novamente.';

  @override
  String get unknownPageError => 'Não encontramos o que você procura.';

  @override
  String get requestError => 'Não foi possível completar a solicitação.';

  @override
  String get responseError => 'Erro no servidor. Tente novamente em instantes.';

  @override
  String get requiredInputError => 'Campo obrigatório.';

  @override
  String get emailError => 'E-mail inválido.';

  @override
  String get passwordTooShortError =>
      'A senha precisa de ao menos 6 caracteres.';

  @override
  String get invalidNumberError => 'Informe um número válido.';

  @override
  String get invalidPhoneError => 'Telefone inválido.';

  @override
  String get invalidDateError => 'Data inválida.';

  @override
  String get positiveValueError => 'O valor precisa ser maior que zero.';

  @override
  String get invalidCredentialsError => 'E-mail ou senha incorretos.';

  @override
  String get sessionExpiredError => 'Sua sessão expirou. Entre novamente.';

  @override
  String get validationError => 'Confira os campos destacados.';

  @override
  String get notFoundError => 'Registro não encontrado.';

  @override
  String get appointmentStatusError =>
      'Esta ação não vale para o status atual do atendimento.';

  @override
  String get insufficientStockError =>
      'Não há saldo em estoque para dar baixa neste item.';

  @override
  String get itemInUseError =>
      'Este item já tem histórico e não pode ser excluído.';

  @override
  String get kitNotAssembledError =>
      'Você não tem kits montados suficientes. Monte antes de vender.';

  @override
  String get expenseAlreadyPaidError => 'Este gasto já está pago.';

  @override
  String get rateLimitError => 'Muitas tentativas. Aguarde um momento.';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get save => 'Salvar';

  @override
  String get delete => 'Excluir';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Adicionar';

  @override
  String get close => 'Fechar';

  @override
  String get emptyList => 'Nada por aqui ainda.';

  @override
  String get loading => 'Carregando…';

  @override
  String get navAppointments => 'Atendimentos';

  @override
  String get navExpenses => 'Gastos';

  @override
  String get navSummary => 'Resumo';

  @override
  String get navStock => 'Estoque';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navAlerts => 'Alertas';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get loginSubtitle => 'Acompanhe o financeiro do seu salão.';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get emailHint => 'voce@exemplo.com';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get signInButton => 'Entrar';

  @override
  String get logout => 'Sair';

  @override
  String get demoModeBanner =>
      'Modo demo — dados de exemplo, nada é salvo de verdade. Entre com qualquer e-mail e senha.';

  @override
  String get appointmentsTitle => 'Atendimentos';

  @override
  String get netBalanceInPeriod => 'Saldo líquido no período';

  @override
  String appointmentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atendimentos',
      one: '1 atendimento',
      zero: 'nenhum atendimento',
    );
    return '$_temp0';
  }

  @override
  String get scheduleButton => 'Agendar';

  @override
  String get statusScheduled => 'Agendado';

  @override
  String get statusFinished => 'Finalizado';

  @override
  String get statusCanceled => 'Cancelado';

  @override
  String get netLabel => 'líquido';

  @override
  String get forecastLabel => 'previsto';

  @override
  String get clientLabel => 'Cliente';

  @override
  String get dateLabel => 'Data';

  @override
  String get statusLabel => 'Status';

  @override
  String get valueLabel => 'Valor';

  @override
  String get finishAppointment => 'Finalizar';

  @override
  String get cancelAppointment => 'Cancelar atendimento';

  @override
  String cancelAppointmentQuestion(String client) {
    return 'Cancelar o atendimento de $client?';
  }

  @override
  String get expensesTitle => 'Gastos';

  @override
  String get pendingLabel => 'Pendente';

  @override
  String get paidThisMonthLabel => 'Pago no mês';

  @override
  String get pendingAndUpcoming => 'Pendentes / próximos';

  @override
  String get alreadyPaid => 'Já pagos';

  @override
  String get newExpenseButton => 'Novo gasto';

  @override
  String dueBy(String date) {
    return 'até $date';
  }

  @override
  String get categoryFixed => 'fixo';

  @override
  String get categoryMaterial => 'material';

  @override
  String get categoryOther => 'outros';

  @override
  String get paymentCash => 'à vista';

  @override
  String get paymentCredit => 'crédito';

  @override
  String get paymentDebit => 'débito';

  @override
  String get paymentPix => 'pix';

  @override
  String get summaryTitle => 'Resumo';

  @override
  String get monthBalance => 'Saldo do mês';

  @override
  String get cameIn => 'Entrou';

  @override
  String get wentOut => 'Saiu';

  @override
  String get periodInsights => 'Insights do período';

  @override
  String get averageTicket => 'Ticket médio';

  @override
  String get profitMargin => 'Margem de lucro';

  @override
  String get vsPreviousMonth => 'Vs. mês anterior';

  @override
  String get mostProfitable => 'Mais lucrativo';

  @override
  String get mostPerformedServices => 'Serviços mais realizados';

  @override
  String get fixedCosts => 'Custos fixos';

  @override
  String get purchasesAndRestock => 'Compras e reposição';

  @override
  String timesPerformed(int count) {
    return '$count×';
  }

  @override
  String get stockTitle => 'Estoque';

  @override
  String get itemsInAlert => 'Itens em alerta';

  @override
  String get stockValue => 'Valor em estoque';

  @override
  String needRestock(int count) {
    return 'Precisam de reposição · $count';
  }

  @override
  String stockOk(int count) {
    return 'Estoque ok · $count';
  }

  @override
  String get resaleKits => 'Kits de revenda';

  @override
  String get newItemButton => 'Novo item';

  @override
  String get stockCritical => 'crítico';

  @override
  String get stockAlert => 'alerta';

  @override
  String get stockNegative => 'negativo';

  @override
  String currentQuantity(String quantity, String unit) {
    return 'Atual: $quantity $unit';
  }

  @override
  String unitCost(String value) {
    return 'Custo un.: $value';
  }

  @override
  String get insufficientStockTitle => 'Falta material no estoque';

  @override
  String get insufficientStockQuestion =>
      'O saldo não cobre tudo que foi usado. Quer registrar mesmo assim?';

  @override
  String get insufficientStockHint =>
      'O estoque vai ficar negativo e entrar na lista de reposição. Corrija quando repor.';

  @override
  String insufficientStockRow(String requested, String available, String unit) {
    return 'Usou $requested · tem $available $unit';
  }

  @override
  String get finishAnyway => 'Registrar mesmo assim';

  @override
  String get assembleKit => 'Montar';

  @override
  String get sellKit => 'Vender';

  @override
  String get assembleKitTitle => 'Montar kit';

  @override
  String get sellKitTitle => 'Vender kit';

  @override
  String assembledQuantity(String count) {
    return 'Montados: $count';
  }

  @override
  String assemblableQuantity(String count) {
    return 'Dá para montar: $count';
  }

  @override
  String get quantityToAssembleLabel => 'Quantos kits montar';

  @override
  String get quantityToSellLabel => 'Quantos kits vender';

  @override
  String get unitPriceLabel => 'Preço unitário';

  @override
  String kitsRevenueLine(String value, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kits vendidos',
      one: '1 kit vendido',
    );
    return '$value do que entrou veio de $_temp0';
  }

  @override
  String get stockHistory => 'Histórico de movimentações';

  @override
  String get stockEntry => 'entrada';

  @override
  String get stockExit => 'saída';

  @override
  String get stockAdjustment => 'ajuste';

  @override
  String get profileTitle => 'Perfil do salão';

  @override
  String get ownerLabel => 'Proprietária';

  @override
  String get monthlyFixedCosts => 'Custos fixos mensais';

  @override
  String get monthlyTotal => 'Total mensal';

  @override
  String get serviceTable => 'Tabela de serviços';

  @override
  String get addAction => '+ Adicionar';

  @override
  String get alertsTitle => 'Alertas';

  @override
  String unreadAlerts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alertas novos',
      one: '1 alerta novo',
      zero: 'nenhum alerta novo',
    );
    return '$_temp0';
  }

  @override
  String get markAllAsRead => 'Marcar todos como lidos';

  @override
  String get descriptionLabel => 'Descrição';

  @override
  String get paymentMethodLabel => 'Forma de pagamento';

  @override
  String get categoryLabel => 'Categoria';

  @override
  String get dueDateLabel => 'Prazo de pagamento';

  @override
  String get whatsappLabel => 'WhatsApp';

  @override
  String get servicesLabel => 'Serviços';

  @override
  String get itemNameLabel => 'Nome do item';

  @override
  String get unitLabel => 'Unidade';

  @override
  String get quantityLabel => 'Quantidade';

  @override
  String get minQuantityLabel => 'Quantidade mínima';

  @override
  String get unitCostLabel => 'Custo unitário';

  @override
  String get reasonLabel => 'Motivo';

  @override
  String get stockEntryTitle => 'Registrar entrada';

  @override
  String get serviceNameLabel => 'Nome do serviço';

  @override
  String get priceLabel => 'Preço';

  @override
  String get salonNameLabel => 'Nome do salão';

  @override
  String get salonFallbackName => 'Meu salão';

  @override
  String get phoneHint => '(11) 90000-0000';

  @override
  String get ownerNameLabel => 'Proprietária';

  @override
  String get materialsUsedLabel => 'Materiais usados';

  @override
  String get newFixedCostTitle => 'Novo custo fixo';

  @override
  String get newServiceTitle => 'Novo serviço';

  @override
  String get consumedLabel => 'Consumido no atendimento';

  @override
  String get logoutQuestion => 'Deseja sair da sua conta?';

  @override
  String get noAlerts => 'Nenhum alerta no momento.';
}
