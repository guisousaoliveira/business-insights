import 'package:flutter/widgets.dart';

import '../../../../models/atendimentos/atendimento_model.dart';
import '../../../../models/atendimentos/material_atendimento_model.dart';
import '../../../../settings/app_assets.dart';
import '../../../../settings/app_colors.dart';
import '../../../../settings/app_extensions.dart';
import '../../../../settings/app_fonts.dart';
import '../../../../settings/app_utils.dart';
import '../../../components/app_button.dart';
import '../../../components/app_card.dart';
import '../../../components/app_icon.dart';
import '../../../components/app_tag.dart';
import '../../../components/app_tappable.dart';

/// Um atendimento, em cartao — a unidade da tela nas duas cascas.
///
/// Responde a pergunta do app numa linha so: **cobrei X, gastei Y, sobrou Z**.
/// O que estava escondido atras de outra tela (quais servicos, quais materiais)
/// abre no proprio cartao.
class AtendimentoCardWidget extends StatefulWidget {
  final AtendimentoModel atendimento;

  /// Uma escrita em voo. Trava os botoes **deste** cartao para nao mandar a
  /// mesma operacao duas vezes.
  final bool isBusy;

  final VoidCallback? onFinalizar;
  final VoidCallback? onEditar;
  final VoidCallback? onCancelar;

  const AtendimentoCardWidget({
    super.key,
    required this.atendimento,
    this.isBusy = false,
    this.onFinalizar,
    this.onEditar,
    this.onCancelar,
  });

  @override
  State<AtendimentoCardWidget> createState() => _AtendimentoCardWidgetState();
}

class _AtendimentoCardWidgetState extends State<AtendimentoCardWidget> {
  bool _isExpanded = false;

  AtendimentoModel get _atendimento => widget.atendimento;

  bool get _isCancelado => _atendimento.isCancelado;

  /// Cancelado não entra em conta nenhuma do mês: o número continua visível
  /// (ela precisa saber o que deixou de ganhar), mas em cinza, para não ser
  /// lido como dinheiro que entrou.
  Color get _lucroColor {
    if (_isCancelado) return AppColors.text3;
    return _atendimento.saldo >= 0 ? AppColors.success : AppColors.danger;
  }

  bool get _hasDetails =>
      _atendimento.servicos.isNotEmpty || _atendimento.materiais.isNotEmpty;

  void _toggle() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTappable(
              onTap: _hasDetails ? _toggle : null,
              minSize: 0,
              borderRadius: BorderRadius.circular(8),
              child: _buildHeader(context),
            ),
            const SizedBox(height: 11),
            _buildTotals(context),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _isExpanded && _hasDetails
                  ? _buildDetails(context)
                  : const SizedBox(width: double.infinity),
            ),
            _buildActions(context),
          ],
        ),
      );

  Widget _buildHeader(BuildContext context) {
    final resumoServicos = _atendimento.servicos.isEmpty
        ? context.l10n.emptyList
        : _atendimento.servicos.map((servico) => servico.nome).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _atendimento.clienteNome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.rowTitle(context).copyWith(
                  fontSize: 14,
                  color: _isCancelado ? AppColors.text2 : AppColors.text1,
                  decoration: _isCancelado ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AppTag.statusAtendimento(
              _atendimento.status,
              AppUtils.statusAtendimentoToString(_atendimento.status),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          resumoServicos,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.caption(context),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              context.l10n.appointmentAtDate(
                AppUtils.dateToFull(_atendimento.data),
                AppUtils.timeToShort(_atendimento.data),
              ),
              style: AppFonts.captionSmall(context)
                  .copyWith(color: AppColors.primaryDark),
            ),
            if (_hasDetails) ...[
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const AppIcon(
                  AppAssets.chevronDown,
                  size: 14,
                  color: AppColors.text3,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// A linha que responde à pergunta do app. Fundo cinza para se separar do
  /// cartão sem usar cor — a cor aqui é do lucro, e só dele.
  Widget _buildTotals(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _Total(
              label: context.l10n.chargedLabel,
              value: AppUtils.numToMoney(_atendimento.totalServicos),
              color: _isCancelado ? AppColors.text3 : AppColors.text1,
              alignment: CrossAxisAlignment.start,
            ),
            _Total(
              label: context.l10n.costLabel,
              value: AppUtils.numToMoney(_atendimento.totalMateriais),
              color: _isCancelado ? AppColors.text3 : AppColors.text1,
              alignment: CrossAxisAlignment.center,
            ),
            _Total(
              label: context.l10n.profitLabel,
              value: AppUtils.numToMoney(_atendimento.saldo),
              color: _lucroColor,
              alignment: CrossAxisAlignment.end,
            ),
          ],
        ),
      );

  Widget _buildDetails(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_atendimento.servicos.isNotEmpty)
              _DetailSection(
                title: context.l10n.servicesLabel,
                lines: _atendimento.servicos
                    .map(
                      (servico) => _DetailLine(
                        name: servico.nome,
                        value: AppUtils.numToMoney(servico.preco),
                      ),
                    )
                    .toList(),
              ),
            if (_atendimento.materiais.isNotEmpty) ...[
              const SizedBox(height: 10),
              _DetailSection(
                title: context.l10n.materialsUsedLabel,
                lines: _atendimento.materiais.map(_materialLine).toList(),
              ),
            ],
          ],
        ),
      );

  _DetailLine _materialLine(MaterialAtendimentoModel material) {
    final quantidade = AppUtils.quantityToString(material.quantidade);

    return _DetailLine(
      name: '$quantidade× ${material.nome}',
      value: AppUtils.numToMoney(material.preco),
    );
  }

  Widget _buildActions(BuildContext context) {
    // Cancelado não tem ação: o servidor recusa editar e não há o que
    // finalizar. O cartão vira registro, e a frase explica por quê.
    if (_isCancelado) {
      return Padding(
        padding: const EdgeInsets.only(top: 11),
        child: Text(
          context.l10n.canceledAppointmentHint,
          style: AppFonts.captionSmall(context),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 11),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_atendimento.isAgendado && widget.onFinalizar != null)
            AppButton(
              label: context.l10n.finishAppointment,
              icon: AppAssets.check,
              isDense: true,
              isLoading: widget.isBusy,
              onPressed: widget.onFinalizar,
            ),
          if (widget.onEditar != null)
            AppButton(
              label: context.l10n.edit,
              icon: AppAssets.edit,
              type: AppButtonType.outlined,
              isDense: true,
              onPressed: widget.isBusy ? null : widget.onEditar,
            ),
          if (widget.onCancelar != null)
            AppButton(
              label: context.l10n.cancel,
              icon: AppAssets.close,
              type: AppButtonType.text,
              isDense: true,
              onPressed: widget.isBusy ? null : widget.onCancelar,
            ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment alignment;

  const _Total({
    required this.label,
    required this.value,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.sectionLabel(context),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.rowValue(context)
                  .copyWith(fontSize: 14, color: color),
            ),
          ],
        ),
      );
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<_DetailLine> lines;

  const _DetailSection({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(), style: AppFonts.sectionLabel(context)),
          const SizedBox(height: 5),
          ...lines,
        ],
      );
}

class _DetailLine extends StatelessWidget {
  final String name;
  final String value;

  const _DetailLine({required this.name, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.caption(context),
              ),
            ),
            const SizedBox(width: 8),
            Text(value, style: AppFonts.caption(context)),
          ],
        ),
      );
}
