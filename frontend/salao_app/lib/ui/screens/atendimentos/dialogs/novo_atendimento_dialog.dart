import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cubits/atendimentos/atendimentos_cubit.dart';
import '../../../../cubits/servicos/servicos_cubit.dart';
import '../../../../models/atendimentos/atendimento_model.dart';
import '../../../../models/atendimentos/servico_atendimento_model.dart';
import '../../../../models/dropdown_model.dart';
import '../../../../models/servicos/servico_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../../settings/app_validators.dart';
import '../../../components/app_button.dart';
import '../../../components/app_card.dart';
import '../../../components/app_date_picker.dart';
import '../../../components/app_dropdown.dart';
import '../../../components/app_icon.dart';
import '../../../components/app_input.dart';
import '../../../components/app_tappable.dart';

/// Formulário de agendamento **e** de edição. Devolve `true` quando algo
/// mudou; quem abriu recarrega a lista (padrão de diálogo do capítulo 07).
///
/// É um formulário só porque os campos são os mesmos: cliente, data e
/// serviços. O que muda é o verbo — sem [atendimento] chama `createAtendimento`,
/// com ele chama `editAtendimento`.
class NovoAtendimentoDialog extends StatefulWidget {
  /// O atendimento sendo editado, ou `null` para um novo.
  final AtendimentoModel? atendimento;

  const NovoAtendimentoDialog({super.key, this.atendimento});

  @override
  State<NovoAtendimentoDialog> createState() => _NovoAtendimentoDialogState();
}

class _NovoAtendimentoDialogState extends State<NovoAtendimentoDialog> {
  late final AppInputController _nomeController;
  late final AppInputController _telefoneController;
  late final AppDatePickerController _dataController;
  late final AppDropdownController _servicoController;

  final List<ServicoAtendimentoModel> _servicosEscolhidos = [];

  AtendimentoModel? get _atendimento => widget.atendimento;

  bool get _isEdicao => _atendimento != null;

  @override
  void initState() {
    super.initState();
    _nomeController = AppInputController(
      initialValue: _atendimento?.clienteNome,
    );
    _telefoneController = AppInputController(
      isRequired: false,
      initialValue: _atendimento?.clienteTelefone,
      validator: AppValidators.validatePhone,
    );
    _dataController = AppDatePickerController(
      selectedDate: _atendimento?.data ?? DateTime.now(),
    );
    _servicosEscolhidos.addAll(_atendimento?.servicos ?? const []);
    _servicoController = AppDropdownController(
      isRequired: false,
      onValueSelected: _addServico,
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _dataController.dispose();
    _servicoController.dispose();
    super.dispose();
  }

  /// O catálogo entra como referência (`servicoId`), não como cópia de preço:
  /// quem congela o valor é o servidor, no momento da escrita.
  void _addServico(Object? value) {
    if (value is! ServicoModel) return;
    setState(
      () => _servicosEscolhidos.add(
        ServicoAtendimentoModel(
          servicoId: value.id,
          nome: value.nome,
          preco: value.preco,
        ),
      ),
    );
    _servicoController.selectedValue = null;
  }

  double get _total =>
      _servicosEscolhidos.fold(0.0, (sum, item) => sum + item.preco);

  void _submit() {
    setState(() {
      _nomeController.validate();
      _telefoneController.validate();
      _dataController.validate();
    });

    if (_nomeController.hasError ||
        _telefoneController.hasError ||
        _dataController.hasError ||
        _servicosEscolhidos.isEmpty) {
      return;
    }

    final cubit = BlocProvider.of<AtendimentosCubit>(context);
    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.trim();
    final data = _dataController.selectedDate!;

    if (_isEdicao) {
      cubit.editAtendimento(
        id: _atendimento!.id,
        clienteNome: nome,
        clienteTelefone: telefone,
        data: data,
        servicos: _servicosEscolhidos,
      );
    } else {
      cubit.createAtendimento(
        clienteNome: nome,
        clienteTelefone: telefone,
        data: data,
        servicos: _servicosEscolhidos,
      );
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            controller: _nomeController,
            label: context.l10n.clientLabel,
            autofocus: true,
          ),
          const SizedBox(height: 14),
          AppInput(
            controller: _telefoneController,
            label: context.l10n.whatsappLabel,
            hint: context.l10n.phoneHint,
          ),
          const SizedBox(height: 14),
          AppDatePicker(
            controller: _dataController,
            label: context.l10n.dateLabel,
            withTime: true,
          ),
          const SizedBox(height: 14),
          _buildServicoPicker(context),
          if (_servicosEscolhidos.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildServicosEscolhidos(context),
          ],
          const SizedBox(height: 20),
          AppButton(
            label: _isEdicao
                ? context.l10n.saveChanges
                : context.l10n.scheduleButton,
            isExpanded: true,
            onPressed: _submit,
          ),
        ],
      );

  Widget _buildServicoPicker(BuildContext context) =>
      BlocBuilder<ServicosCubit, ServicosState>(
        buildWhen: (p, c) => p.getServicosSubState != c.getServicosSubState,
        builder: (context, state) {
          final servicos = state.getServicosSubState
                  .value<GetServicosResponseModel>()
                  ?.servicos ??
              const <ServicoModel>[];

          _servicoController.items = servicos
              .map(
                (servico) => DropdownModel(
                  key:
                      '${servico.nome} · ${AppUtils.numToMoney(servico.preco)}',
                  value: servico,
                ),
              )
              .toList();

          return AppDropdown(
            controller: _servicoController,
            label: context.l10n.serviceTable,
            hint: context.l10n.addAction,
          );
        },
      );

  Widget _buildServicosEscolhidos(BuildContext context) => AppCard(
        child: Column(
          children: [
            ...List.generate(
              _servicosEscolhidos.length,
              (index) => AppCardRow(
                isFirst: index == 0,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _servicosEscolhidos[index].nome,
                        style: AppFonts.rowTitle(context),
                      ),
                    ),
                    Text(
                      AppUtils.numToMoney(_servicosEscolhidos[index].preco),
                      style: AppFonts.rowValue(context),
                    ),
                    const SizedBox(width: 4),
                    AppTappable(
                      minSize: 32,
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          setState(() => _servicosEscolhidos.removeAt(index)),
                      child: const AppIcon(AppAssets.close, size: 15),
                    ),
                  ],
                ),
              ),
            ),
            AppCardRow(
              background: AppColors.surface2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.valueLabel,
                    style: AppFonts.rowTitle(context)
                        .copyWith(color: AppColors.text2),
                  ),
                  Text(
                    AppUtils.numToMoney(_total),
                    style: AppFonts.rowValue(context)
                        .copyWith(color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
