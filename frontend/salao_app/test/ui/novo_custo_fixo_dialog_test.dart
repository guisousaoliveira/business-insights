import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app/cubits/perfil/perfil_cubit.dart';
import 'package:salon_app/l10n/app_localizations.dart';
import 'package:salon_app/models/perfil/custo_fixo_model.dart';
import 'package:salon_app/models/perfil/perfil_model.dart';
import 'package:salon_app/repositories/perfil_repository.dart';
import 'package:salon_app/ui/screens/perfil/dialogs/novo_custo_fixo_dialog.dart';

/// Não faz chamada nenhuma: o que este teste exercita é a **construção** da
/// folha, não o salvamento.
class _RepositoryVazio implements PerfilRepository {
  @override
  Future<GetPerfilResponseModel> getPerfil() async =>
      throw UnimplementedError();

  @override
  Future<void> updatePerfil(PerfilModel model) async {}

  @override
  Future<GetCustosFixosResponseModel> getCustosFixos() async =>
      throw UnimplementedError();

  @override
  Future<void> createCustoFixo(CustoFixoModel model) async {}

  @override
  Future<void> editCustoFixo(CustoFixoModel model) async {}

  @override
  Future<void> deleteCustoFixo(String id) async {}

  @override
  Future<void> pagarCustoFixo({
    required String id,
    required String competencia,
    required bool pago,
  }) async {}
}

Future<void> _pump(WidgetTester tester, CustoFixoModel? custoFixo) =>
    tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) => PerfilCubit(repository: _RepositoryVazio()),
          child: Scaffold(
            body: SingleChildScrollView(
              child: NovoCustoFixoDialog(custoFixo: custoFixo),
            ),
          ),
        ),
      ),
    );

/// Regressão de um erro que chegou à usuária: os rótulos dos dias eram montados
/// no `initState`, e ler o ARB depende do `Localizations` — dependência que o
/// `initState` não pode registrar. Abrir a folha estourava em vermelho.
void main() {
  testWidgets('abre para cadastro sem estourar', (tester) async {
    await _pump(tester, null);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abre para edição com o dia já escolhido', (tester) async {
    await _pump(
      tester,
      const CustoFixoModel(
        id: 'c1',
        descricao: 'Aluguel',
        valor: 1200,
        diaVencimento: 5,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Aluguel'), findsOneWidget);
    expect(find.text('Dia 5'), findsOneWidget);
  });
}
