import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// No description provided for @appName.
  ///
  /// In pt, this message translates to:
  /// **'Thamires Borges Beauty'**
  String get appName;

  /// No description provided for @unknownError.
  ///
  /// In pt, this message translates to:
  /// **'Ocorreu um erro inesperado.'**
  String get unknownError;

  /// No description provided for @connectionError.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão. Verifique sua internet.'**
  String get connectionError;

  /// No description provided for @unauthorizedError.
  ///
  /// In pt, this message translates to:
  /// **'Sessão expirada. Entre novamente.'**
  String get unauthorizedError;

  /// No description provided for @unknownPageError.
  ///
  /// In pt, this message translates to:
  /// **'Não encontramos o que você procura.'**
  String get unknownPageError;

  /// No description provided for @requestError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível completar a solicitação.'**
  String get requestError;

  /// No description provided for @responseError.
  ///
  /// In pt, this message translates to:
  /// **'Erro no servidor. Tente novamente em instantes.'**
  String get responseError;

  /// No description provided for @requiredInputError.
  ///
  /// In pt, this message translates to:
  /// **'Campo obrigatório.'**
  String get requiredInputError;

  /// No description provided for @emailError.
  ///
  /// In pt, this message translates to:
  /// **'E-mail inválido.'**
  String get emailError;

  /// No description provided for @passwordTooShortError.
  ///
  /// In pt, this message translates to:
  /// **'A senha precisa de ao menos 6 caracteres.'**
  String get passwordTooShortError;

  /// No description provided for @invalidNumberError.
  ///
  /// In pt, this message translates to:
  /// **'Informe um número válido.'**
  String get invalidNumberError;

  /// No description provided for @invalidPhoneError.
  ///
  /// In pt, this message translates to:
  /// **'Telefone inválido.'**
  String get invalidPhoneError;

  /// No description provided for @invalidDateError.
  ///
  /// In pt, this message translates to:
  /// **'Data inválida.'**
  String get invalidDateError;

  /// No description provided for @positiveValueError.
  ///
  /// In pt, this message translates to:
  /// **'O valor precisa ser maior que zero.'**
  String get positiveValueError;

  /// No description provided for @invalidCredentialsError.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou senha incorretos.'**
  String get invalidCredentialsError;

  /// No description provided for @sessionExpiredError.
  ///
  /// In pt, this message translates to:
  /// **'Sua sessão expirou. Entre novamente.'**
  String get sessionExpiredError;

  /// No description provided for @validationError.
  ///
  /// In pt, this message translates to:
  /// **'Confira os campos destacados.'**
  String get validationError;

  /// No description provided for @notFoundError.
  ///
  /// In pt, this message translates to:
  /// **'Registro não encontrado.'**
  String get notFoundError;

  /// No description provided for @appointmentStatusError.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não vale para o status atual do atendimento.'**
  String get appointmentStatusError;

  /// No description provided for @insufficientStockError.
  ///
  /// In pt, this message translates to:
  /// **'Não há saldo em estoque para dar baixa neste item.'**
  String get insufficientStockError;

  /// No description provided for @itemInUseError.
  ///
  /// In pt, this message translates to:
  /// **'Este item já tem histórico e não pode ser excluído.'**
  String get itemInUseError;

  /// No description provided for @kitNotAssembledError.
  ///
  /// In pt, this message translates to:
  /// **'Você não tem kits montados suficientes. Monte antes de vender.'**
  String get kitNotAssembledError;

  /// No description provided for @expenseAlreadyPaidError.
  ///
  /// In pt, this message translates to:
  /// **'Este gasto já está pago.'**
  String get expenseAlreadyPaidError;

  /// No description provided for @rateLimitError.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Aguarde um momento.'**
  String get rateLimitError;

  /// No description provided for @retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get add;

  /// No description provided for @close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get close;

  /// No description provided for @emptyList.
  ///
  /// In pt, this message translates to:
  /// **'Nada por aqui ainda.'**
  String get emptyList;

  /// No description provided for @loading.
  ///
  /// In pt, this message translates to:
  /// **'Carregando…'**
  String get loading;

  /// No description provided for @navAppointments.
  ///
  /// In pt, this message translates to:
  /// **'Atendimentos'**
  String get navAppointments;

  /// No description provided for @navExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Gastos'**
  String get navExpenses;

  /// No description provided for @navSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get navSummary;

  /// No description provided for @navStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque'**
  String get navStock;

  /// No description provided for @navProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @navAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get navAlerts;

  /// No description provided for @loginTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Acompanhe o financeiro do seu salão.'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In pt, this message translates to:
  /// **'voce@exemplo.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get signInButton;

  /// No description provided for @logout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get logout;

  /// No description provided for @demoModeBanner.
  ///
  /// In pt, this message translates to:
  /// **'Modo demo — dados de exemplo, nada é salvo de verdade. Entre com qualquer e-mail e senha.'**
  String get demoModeBanner;

  /// No description provided for @appointmentsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atendimentos'**
  String get appointmentsTitle;

  /// No description provided for @netBalanceInPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Saldo líquido no período'**
  String get netBalanceInPeriod;

  /// No description provided for @appointmentsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{nenhum atendimento} =1{1 atendimento} other{{count} atendimentos}}'**
  String appointmentsCount(int count);

  /// No description provided for @scheduleButton.
  ///
  /// In pt, this message translates to:
  /// **'Agendar'**
  String get scheduleButton;

  /// No description provided for @statusScheduled.
  ///
  /// In pt, this message translates to:
  /// **'Agendado'**
  String get statusScheduled;

  /// No description provided for @statusFinished.
  ///
  /// In pt, this message translates to:
  /// **'Finalizado'**
  String get statusFinished;

  /// No description provided for @statusCanceled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelado'**
  String get statusCanceled;

  /// No description provided for @netLabel.
  ///
  /// In pt, this message translates to:
  /// **'líquido'**
  String get netLabel;

  /// No description provided for @forecastLabel.
  ///
  /// In pt, this message translates to:
  /// **'previsto'**
  String get forecastLabel;

  /// No description provided for @clientLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cliente'**
  String get clientLabel;

  /// No description provided for @dateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get dateLabel;

  /// No description provided for @statusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @valueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get valueLabel;

  /// No description provided for @finishAppointment.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar'**
  String get finishAppointment;

  /// No description provided for @cancelAppointment.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar atendimento'**
  String get cancelAppointment;

  /// No description provided for @cancelAppointmentQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar o atendimento de {client}?'**
  String cancelAppointmentQuestion(String client);

  /// No description provided for @expensesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gastos'**
  String get expensesTitle;

  /// No description provided for @pendingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get pendingLabel;

  /// No description provided for @paidThisMonthLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pago no mês'**
  String get paidThisMonthLabel;

  /// No description provided for @pendingAndUpcoming.
  ///
  /// In pt, this message translates to:
  /// **'Pendentes / próximos'**
  String get pendingAndUpcoming;

  /// No description provided for @alreadyPaid.
  ///
  /// In pt, this message translates to:
  /// **'Já pagos'**
  String get alreadyPaid;

  /// No description provided for @newExpenseButton.
  ///
  /// In pt, this message translates to:
  /// **'Novo gasto'**
  String get newExpenseButton;

  /// No description provided for @dueBy.
  ///
  /// In pt, this message translates to:
  /// **'até {date}'**
  String dueBy(String date);

  /// No description provided for @categoryFixed.
  ///
  /// In pt, this message translates to:
  /// **'fixo'**
  String get categoryFixed;

  /// No description provided for @categoryMaterial.
  ///
  /// In pt, this message translates to:
  /// **'material'**
  String get categoryMaterial;

  /// No description provided for @categoryOther.
  ///
  /// In pt, this message translates to:
  /// **'outros'**
  String get categoryOther;

  /// No description provided for @paymentCash.
  ///
  /// In pt, this message translates to:
  /// **'à vista'**
  String get paymentCash;

  /// No description provided for @paymentCredit.
  ///
  /// In pt, this message translates to:
  /// **'crédito'**
  String get paymentCredit;

  /// No description provided for @paymentDebit.
  ///
  /// In pt, this message translates to:
  /// **'débito'**
  String get paymentDebit;

  /// No description provided for @paymentPix.
  ///
  /// In pt, this message translates to:
  /// **'pix'**
  String get paymentPix;

  /// No description provided for @summaryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get summaryTitle;

  /// No description provided for @helloUser.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}'**
  String helloUser(String name);

  /// No description provided for @userFallbackName.
  ///
  /// In pt, this message translates to:
  /// **'Thamires'**
  String get userFallbackName;

  /// No description provided for @summaryOfPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Resumo de {period}'**
  String summaryOfPeriod(String period);

  /// No description provided for @monthProfit.
  ///
  /// In pt, this message translates to:
  /// **'Lucro do mês'**
  String get monthProfit;

  /// No description provided for @monthLoss.
  ///
  /// In pt, this message translates to:
  /// **'Prejuízo do mês'**
  String get monthLoss;

  /// No description provided for @noPreviousComparison.
  ///
  /// In pt, this message translates to:
  /// **'Sem comparação com o mês anterior'**
  String get noPreviousComparison;

  /// No description provided for @revenueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Faturamento'**
  String get revenueLabel;

  /// No description provided for @expensesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Gastos'**
  String get expensesLabel;

  /// No description provided for @appointmentsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Atendimentos'**
  String get appointmentsLabel;

  /// No description provided for @finalizedInMonth.
  ///
  /// In pt, this message translates to:
  /// **'finalizados no mês'**
  String get finalizedInMonth;

  /// No description provided for @revenuesAndExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Receitas e despesas'**
  String get revenuesAndExpenses;

  /// No description provided for @lastSixMonths.
  ///
  /// In pt, this message translates to:
  /// **'Últimos 6 meses'**
  String get lastSixMonths;

  /// No description provided for @revenuesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Receitas'**
  String get revenuesLabel;

  /// No description provided for @mostProfitableService.
  ///
  /// In pt, this message translates to:
  /// **'Serviço mais lucrativo'**
  String get mostProfitableService;

  /// No description provided for @profitableServiceDetail.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 atendimento} other{{count} atendimentos}} • lucro de {value}'**
  String profitableServiceDetail(int count, String value);

  /// No description provided for @mostProfitableInsight.
  ///
  /// In pt, this message translates to:
  /// **'{service} foi o serviço mais lucrativo do mês.'**
  String mostProfitableInsight(String service);

  /// No description provided for @forYouToKnow.
  ///
  /// In pt, this message translates to:
  /// **'Para você saber'**
  String get forYouToKnow;

  /// No description provided for @generatedFromYourNumbers.
  ///
  /// In pt, this message translates to:
  /// **'Gerado a partir dos seus números'**
  String get generatedFromYourNumbers;

  /// No description provided for @restockProductsInsight.
  ///
  /// In pt, this message translates to:
  /// **'{count} produtos precisam de reposição.'**
  String restockProductsInsight(int count);

  /// No description provided for @revenueGoalInsight.
  ///
  /// In pt, this message translates to:
  /// **'Você alcançou {percent}% da meta de faturamento de {value}.'**
  String revenueGoalInsight(String percent, String value);

  /// No description provided for @upcomingExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Próximos gastos a vencer'**
  String get upcomingExpenses;

  /// No description provided for @viewAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todos'**
  String get viewAll;

  /// No description provided for @dueOn.
  ///
  /// In pt, this message translates to:
  /// **'Vence em {date}'**
  String dueOn(String date);

  /// No description provided for @overdueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vencido'**
  String get overdueLabel;

  /// No description provided for @stockToRestock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque para repor'**
  String get stockToRestock;

  /// No description provided for @viewStock.
  ///
  /// In pt, this message translates to:
  /// **'Ver estoque'**
  String get viewStock;

  /// No description provided for @scheduleAppointmentLong.
  ///
  /// In pt, this message translates to:
  /// **'Agendar atendimento'**
  String get scheduleAppointmentLong;

  /// No description provided for @monthBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo do mês'**
  String get monthBalance;

  /// No description provided for @cameIn.
  ///
  /// In pt, this message translates to:
  /// **'Entrou'**
  String get cameIn;

  /// No description provided for @wentOut.
  ///
  /// In pt, this message translates to:
  /// **'Saiu'**
  String get wentOut;

  /// No description provided for @periodInsights.
  ///
  /// In pt, this message translates to:
  /// **'Insights do período'**
  String get periodInsights;

  /// No description provided for @averageTicket.
  ///
  /// In pt, this message translates to:
  /// **'Ticket médio'**
  String get averageTicket;

  /// No description provided for @profitMargin.
  ///
  /// In pt, this message translates to:
  /// **'Margem de lucro'**
  String get profitMargin;

  /// No description provided for @vsPreviousMonth.
  ///
  /// In pt, this message translates to:
  /// **'Vs. mês anterior'**
  String get vsPreviousMonth;

  /// No description provided for @mostProfitable.
  ///
  /// In pt, this message translates to:
  /// **'Mais lucrativo'**
  String get mostProfitable;

  /// No description provided for @mostPerformedServices.
  ///
  /// In pt, this message translates to:
  /// **'Serviços mais realizados'**
  String get mostPerformedServices;

  /// No description provided for @fixedCosts.
  ///
  /// In pt, this message translates to:
  /// **'Custos fixos'**
  String get fixedCosts;

  /// No description provided for @purchasesAndRestock.
  ///
  /// In pt, this message translates to:
  /// **'Compras e reposição'**
  String get purchasesAndRestock;

  /// No description provided for @timesPerformed.
  ///
  /// In pt, this message translates to:
  /// **'{count}×'**
  String timesPerformed(int count);

  /// No description provided for @stockTitle.
  ///
  /// In pt, this message translates to:
  /// **'Estoque'**
  String get stockTitle;

  /// No description provided for @itemsInAlert.
  ///
  /// In pt, this message translates to:
  /// **'Itens em alerta'**
  String get itemsInAlert;

  /// No description provided for @stockValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor em estoque'**
  String get stockValue;

  /// No description provided for @needRestock.
  ///
  /// In pt, this message translates to:
  /// **'Precisam de reposição · {count}'**
  String needRestock(int count);

  /// No description provided for @stockOk.
  ///
  /// In pt, this message translates to:
  /// **'Estoque ok · {count}'**
  String stockOk(int count);

  /// No description provided for @resaleKits.
  ///
  /// In pt, this message translates to:
  /// **'Kits de revenda'**
  String get resaleKits;

  /// No description provided for @newItemButton.
  ///
  /// In pt, this message translates to:
  /// **'Novo item'**
  String get newItemButton;

  /// No description provided for @stockCritical.
  ///
  /// In pt, this message translates to:
  /// **'crítico'**
  String get stockCritical;

  /// No description provided for @stockAlert.
  ///
  /// In pt, this message translates to:
  /// **'alerta'**
  String get stockAlert;

  /// No description provided for @stockNegative.
  ///
  /// In pt, this message translates to:
  /// **'negativo'**
  String get stockNegative;

  /// No description provided for @currentQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Atual: {quantity} {unit}'**
  String currentQuantity(String quantity, String unit);

  /// No description provided for @unitCost.
  ///
  /// In pt, this message translates to:
  /// **'Custo un.: {value}'**
  String unitCost(String value);

  /// No description provided for @insufficientStockTitle.
  ///
  /// In pt, this message translates to:
  /// **'Falta material no estoque'**
  String get insufficientStockTitle;

  /// No description provided for @insufficientStockQuestion.
  ///
  /// In pt, this message translates to:
  /// **'O saldo não cobre tudo que foi usado. Quer registrar mesmo assim?'**
  String get insufficientStockQuestion;

  /// No description provided for @insufficientStockHint.
  ///
  /// In pt, this message translates to:
  /// **'O estoque vai ficar negativo e entrar na lista de reposição. Corrija quando repor.'**
  String get insufficientStockHint;

  /// No description provided for @insufficientStockRow.
  ///
  /// In pt, this message translates to:
  /// **'Usou {requested} · tem {available} {unit}'**
  String insufficientStockRow(String requested, String available, String unit);

  /// No description provided for @finishAnyway.
  ///
  /// In pt, this message translates to:
  /// **'Registrar mesmo assim'**
  String get finishAnyway;

  /// No description provided for @assembleKit.
  ///
  /// In pt, this message translates to:
  /// **'Montar'**
  String get assembleKit;

  /// No description provided for @sellKit.
  ///
  /// In pt, this message translates to:
  /// **'Vender'**
  String get sellKit;

  /// No description provided for @assembleKitTitle.
  ///
  /// In pt, this message translates to:
  /// **'Montar kit'**
  String get assembleKitTitle;

  /// No description provided for @sellKitTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vender kit'**
  String get sellKitTitle;

  /// No description provided for @assembledQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Montados: {count}'**
  String assembledQuantity(String count);

  /// No description provided for @assemblableQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Dá para montar: {count}'**
  String assemblableQuantity(String count);

  /// No description provided for @quantityToAssembleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantos kits montar'**
  String get quantityToAssembleLabel;

  /// No description provided for @quantityToSellLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantos kits vender'**
  String get quantityToSellLabel;

  /// No description provided for @unitPriceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço unitário'**
  String get unitPriceLabel;

  /// No description provided for @kitsRevenueLine.
  ///
  /// In pt, this message translates to:
  /// **'{value} do que entrou veio de {count, plural, =1{1 kit vendido} other{{count} kits vendidos}}'**
  String kitsRevenueLine(String value, int count);

  /// No description provided for @stockHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de movimentações'**
  String get stockHistory;

  /// No description provided for @stockEntry.
  ///
  /// In pt, this message translates to:
  /// **'entrada'**
  String get stockEntry;

  /// No description provided for @stockExit.
  ///
  /// In pt, this message translates to:
  /// **'saída'**
  String get stockExit;

  /// No description provided for @stockAdjustment.
  ///
  /// In pt, this message translates to:
  /// **'ajuste'**
  String get stockAdjustment;

  /// No description provided for @profileTitle.
  ///
  /// In pt, this message translates to:
  /// **'Perfil do salão'**
  String get profileTitle;

  /// No description provided for @ownerLabel.
  ///
  /// In pt, this message translates to:
  /// **'Proprietária'**
  String get ownerLabel;

  /// No description provided for @monthlyFixedCosts.
  ///
  /// In pt, this message translates to:
  /// **'Custos fixos mensais'**
  String get monthlyFixedCosts;

  /// No description provided for @monthlyTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total mensal'**
  String get monthlyTotal;

  /// No description provided for @serviceTable.
  ///
  /// In pt, this message translates to:
  /// **'Tabela de serviços'**
  String get serviceTable;

  /// No description provided for @addAction.
  ///
  /// In pt, this message translates to:
  /// **'+ Adicionar'**
  String get addAction;

  /// No description provided for @alertsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get alertsTitle;

  /// No description provided for @unreadAlerts.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{nenhum alerta novo} =1{1 alerta novo} other{{count} alertas novos}}'**
  String unreadAlerts(int count);

  /// No description provided for @markAllAsRead.
  ///
  /// In pt, this message translates to:
  /// **'Marcar todos como lidos'**
  String get markAllAsRead;

  /// No description provided for @descriptionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get descriptionLabel;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In pt, this message translates to:
  /// **'Forma de pagamento'**
  String get paymentMethodLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get categoryLabel;

  /// No description provided for @dueDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Prazo de pagamento'**
  String get dueDateLabel;

  /// No description provided for @whatsappLabel.
  ///
  /// In pt, this message translates to:
  /// **'WhatsApp'**
  String get whatsappLabel;

  /// No description provided for @servicesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Serviços'**
  String get servicesLabel;

  /// No description provided for @itemNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do item'**
  String get itemNameLabel;

  /// No description provided for @unitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Unidade'**
  String get unitLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get quantityLabel;

  /// No description provided for @minQuantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade mínima'**
  String get minQuantityLabel;

  /// No description provided for @unitCostLabel.
  ///
  /// In pt, this message translates to:
  /// **'Custo unitário'**
  String get unitCostLabel;

  /// No description provided for @reasonLabel.
  ///
  /// In pt, this message translates to:
  /// **'Motivo'**
  String get reasonLabel;

  /// No description provided for @stockEntryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registrar entrada'**
  String get stockEntryTitle;

  /// No description provided for @serviceNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do serviço'**
  String get serviceNameLabel;

  /// No description provided for @priceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço'**
  String get priceLabel;

  /// No description provided for @salonNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do salão'**
  String get salonNameLabel;

  /// No description provided for @salonFallbackName.
  ///
  /// In pt, this message translates to:
  /// **'Meu salão'**
  String get salonFallbackName;

  /// No description provided for @phoneHint.
  ///
  /// In pt, this message translates to:
  /// **'(11) 90000-0000'**
  String get phoneHint;

  /// No description provided for @ownerNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Proprietária'**
  String get ownerNameLabel;

  /// No description provided for @materialsUsedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Materiais usados'**
  String get materialsUsedLabel;

  /// No description provided for @newFixedCostTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo custo fixo'**
  String get newFixedCostTitle;

  /// No description provided for @newServiceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo serviço'**
  String get newServiceTitle;

  /// No description provided for @consumedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Consumido no atendimento'**
  String get consumedLabel;

  /// No description provided for @logoutQuestion.
  ///
  /// In pt, this message translates to:
  /// **'Deseja sair da sua conta?'**
  String get logoutQuestion;

  /// No description provided for @noAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum alerta no momento.'**
  String get noAlerts;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
