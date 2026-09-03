// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'GlowApp';

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
  String get appointmentsSubtitle => 'Agenda, valores e lucro de cada cliente';

  @override
  String appointmentAtDate(String date, String time) {
    return '$date às $time';
  }

  @override
  String get chargedLabel => 'Cobrado';

  @override
  String get costLabel => 'Custo';

  @override
  String get profitLabel => 'Lucro';

  @override
  String get filterThisMonth => 'Este mês';

  @override
  String get filterLastMonth => 'Mês passado';

  @override
  String get filterLastThreeMonths => 'Últimos 3 meses';

  @override
  String get filterAllPeriod => 'Todo o período';

  @override
  String get filterAllStatus => 'Todos os status';

  @override
  String get periodLabel => 'Período';

  @override
  String get noAppointmentsInFilter => 'Nenhum atendimento com esses filtros.';

  @override
  String get editAppointmentTitle => 'Editar atendimento';

  @override
  String get saveChanges => 'Salvar alterações';

  @override
  String get canceledAppointmentHint =>
      'Atendimento cancelado — fora das contas do mês.';

  @override
  String get expensesTitle => 'Gastos';

  @override
  String expensesSubtitle(String month) {
    return 'Materiais, custos fixos e outras contas de $month';
  }

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
  String helloUser(String name) {
    return 'Olá, $name';
  }

  @override
  String get userFallbackName => 'Thamires';

  @override
  String summaryOfPeriod(String period) {
    return 'Resumo de $period';
  }

  @override
  String get monthProfit => 'Lucro do mês';

  @override
  String get monthLoss => 'Prejuízo do mês';

  @override
  String get noPreviousComparison => 'Sem comparação com o mês anterior';

  @override
  String get revenueLabel => 'Faturamento';

  @override
  String get expensesLabel => 'Gastos';

  @override
  String get appointmentsLabel => 'Atendimentos';

  @override
  String get finalizedInMonth => 'finalizados no mês';

  @override
  String get revenuesAndExpenses => 'Receitas e despesas';

  @override
  String get lastSixMonths => 'Últimos 6 meses';

  @override
  String get revenuesLabel => 'Receitas';

  @override
  String get mostProfitableService => 'Serviço mais lucrativo';

  @override
  String profitableServiceDetail(int count, String value) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atendimentos',
      one: '1 atendimento',
    );
    return '$_temp0 • lucro de $value';
  }

  @override
  String mostProfitableInsight(String service) {
    return '$service foi o serviço mais lucrativo do mês.';
  }

  @override
  String get forYouToKnow => 'Para você saber';

  @override
  String get generatedFromYourNumbers => 'Gerado a partir dos seus números';

  @override
  String restockProductsInsight(int count) {
    return '$count produtos precisam de reposição.';
  }

  @override
  String revenueGoalInsight(String percent, String value) {
    return 'Você alcançou $percent% da meta de faturamento de $value.';
  }

  @override
  String get upcomingExpenses => 'Próximos gastos a vencer';

  @override
  String get viewAll => 'Ver todos';

  @override
  String dueOn(String date) {
    return 'Vence em $date';
  }

  @override
  String get overdueLabel => 'Vencido';

  @override
  String get stockToRestock => 'Estoque para repor';

  @override
  String get viewStock => 'Ver estoque';

  @override
  String get scheduleAppointmentLong => 'Agendar atendimento';

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
  String get stockSubtitle => 'Saldo, custo médio e kits para revenda';

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
  String get profileTitle => 'Perfil';

  @override
  String get profileSubtitle => 'Dados do salão, custos fixos e serviços';

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
  String alertsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avisos não lidos',
      one: '1 aviso não lido',
      zero: 'nenhum aviso não lido',
    );
    return '$_temp0';
  }

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
  String get editFixedCostTitle => 'Editar custo fixo';

  @override
  String get dueDayLabel => 'Vence todo dia';

  @override
  String dueDayOption(int day) {
    return 'Dia $day';
  }

  @override
  String dueDayShort(int day) {
    return 'vence dia $day';
  }

  @override
  String overdueDayShort(int day) {
    return 'venceu dia $day';
  }

  @override
  String paidOnShort(String date) {
    return 'pago em $date';
  }

  @override
  String get fixedCostPaidTooltip => 'Marcar como pago neste mês';

  @override
  String get monthlyPending => 'Falta pagar';

  @override
  String deleteFixedCostQuestion(String description) {
    return 'Excluir $description dos custos fixos?';
  }

  @override
  String get newServiceTitle => 'Novo serviço';

  @override
  String get editServiceTitle => 'Editar serviço';

  @override
  String deleteServiceQuestion(String name) {
    return 'Excluir $name da tabela de preços?';
  }

  @override
  String get defaultProductsLabel => 'Materiais que este serviço consome';

  @override
  String get defaultProductsHint =>
      'Toda vez que este serviço for realizado, esta é a baixa que aparece pronta na finalização.';

  @override
  String get noDefaultProducts => 'Nenhum material vinculado.';

  @override
  String get linkProductAction => 'Vincular material';

  @override
  String get stockItemLabel => 'Item do estoque';

  @override
  String materialsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count materiais',
      one: '1 material',
      zero: 'sem materiais',
    );
    return '$_temp0';
  }

  @override
  String quantityWithUnit(String quantity, String unit) {
    return '$quantity $unit';
  }

  @override
  String get confirmConsumptionTitle => 'Confirmar consumo';

  @override
  String get confirmConsumptionHint =>
      'Veio pronto do serviço. Ajuste o que saiu a mais ou a menos antes de finalizar.';

  @override
  String get addMaterialAction => 'Adicionar material';

  @override
  String get noStockItemsToLink =>
      'Cadastre um item no estoque para poder vincular.';

  @override
  String get consumedLabel => 'Consumido no atendimento';

  @override
  String get logoutQuestion => 'Deseja sair da sua conta?';

  @override
  String get noAlerts => 'Nenhum alerta no momento.';
}
