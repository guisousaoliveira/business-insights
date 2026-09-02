import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app/l10n/app_localizations.dart';
import 'package:salon_app/models/atendimentos/atendimento_model.dart';
import 'package:salon_app/models/atendimentos/material_atendimento_model.dart';
import 'package:salon_app/models/atendimentos/servico_atendimento_model.dart';
import 'package:salon_app/settings/app_enums.dart';
import 'package:salon_app/ui/screens/atendimentos/widgets/atendimento_card_widget.dart';

AtendimentoModel _atendimento({
  required StatusAtendimento status,
  double saldo = 130,
}) =>
    AtendimentoModel(
      id: 'a1',
      clienteNome: 'Marina Souza',
      clienteTelefone: '11999998888',
      data: DateTime(2026, 9, 13, 13),
      status: status,
      servicos: const [
        ServicoAtendimentoModel(nome: 'Extensão de cílios', preco: 180),
      ],
      materiais: const [
        MaterialAtendimentoModel(nome: 'Cola', quantidade: 2, preco: 50),
      ],
      totalServicos: 180,
      totalMateriais: 50,
      saldo: saldo,
    );

Future<void> _pump(WidgetTester tester, AtendimentoModel atendimento) =>
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
        home: Scaffold(
          body: SingleChildScrollView(
            child: AtendimentoCardWidget(
              atendimento: atendimento,
              onFinalizar: () {},
              onEditar: () {},
              onCancelar: () {},
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('mostra cobrado, custo e lucro sem precisar abrir nada',
      (tester) async {
    await _pump(tester, _atendimento(status: StatusAtendimento.agendado));
    await tester.pumpAndSettle();

    expect(find.text('Marina Souza'), findsOneWidget);
    expect(find.text('COBRADO'), findsOneWidget);
    expect(find.text('CUSTO'), findsOneWidget);
    expect(find.text('LUCRO'), findsOneWidget);
    expect(find.text('13/09/2026 às 13:00'), findsOneWidget);
  });

  testWidgets('o detalhe abre no próprio cartão, sem trocar de tela',
      (tester) async {
    await _pump(tester, _atendimento(status: StatusAtendimento.finalizado));
    await tester.pumpAndSettle();

    expect(find.text('MATERIAIS USADOS'), findsNothing);

    await tester.tap(find.text('Marina Souza'));
    await tester.pumpAndSettle();

    expect(find.text('MATERIAIS USADOS'), findsOneWidget);
    expect(find.text('2× Cola'), findsOneWidget);
  });

  testWidgets('agendado oferece finalizar; finalizado não', (tester) async {
    await _pump(tester, _atendimento(status: StatusAtendimento.agendado));
    await tester.pumpAndSettle();
    expect(find.text('Finalizar'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);

    await _pump(tester, _atendimento(status: StatusAtendimento.finalizado));
    await tester.pumpAndSettle();
    expect(find.text('Finalizar'), findsNothing);
    expect(find.text('Editar'), findsOneWidget);
  });

  testWidgets('cancelado não tem ação nenhuma, e explica por quê',
      (tester) async {
    await _pump(tester, _atendimento(status: StatusAtendimento.cancelado));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar'), findsNothing);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Cancelar'), findsNothing);
    expect(
      find.text('Atendimento cancelado — fora das contas do mês.'),
      findsOneWidget,
    );
  });
}
