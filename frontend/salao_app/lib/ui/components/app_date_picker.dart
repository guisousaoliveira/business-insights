import 'package:flutter/material.dart'
    show
        DatePickerThemeData,
        Theme,
        TimeOfDay,
        TimePickerThemeData,
        showDatePicker,
        showTimePicker;
import 'package:flutter/widgets.dart';

import '../../settings/app_assets.dart';
import '../../settings/app_colors.dart';
import '../../settings/app_fonts.dart';
import '../../settings/app_globals.dart' as globals;
import '../../settings/app_utils.dart';
import 'app_icon.dart';
import 'app_tappable.dart';

/// Seleção de data com a mesma ergonomia dos outros campos: rótulo em cima,
/// erro embaixo, `validate()` no controller.
class AppDatePickerController {
  DateTime? selectedDate;
  final bool isRequired;
  final DateTime? firstDate;
  final DateTime? lastDate;

  String? _error;
  bool _isDisposed = false;

  void Function()? onValueChangedSetState;

  AppDatePickerController({
    this.selectedDate,
    this.isRequired = true,
    this.firstDate,
    this.lastDate,
  });

  String? get error => _error;
  bool get hasError => _error != null;

  void select(DateTime? date) {
    if (_isDisposed) return;
    selectedDate = date;
    _error = null;
    onValueChangedSetState?.call();
  }

  void validate() {
    if (_isDisposed) return;
    _error = isRequired && selectedDate == null
        ? globals.l10n?.requiredInputError
        : null;
  }

  void dispose() => _isDisposed = true;
}

class AppDatePicker extends StatefulWidget {
  final AppDatePickerController controller;
  final String label;
  final String? hint;

  /// Encadeia o relógio na sequência do calendário. Um atendimento acontece a
  /// uma hora, não num dia: sem isso todo agendamento nasce meia-noite e o
  /// cartao mostra `00:00` para todo mundo.
  final bool withTime;

  const AppDatePicker({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.withTime = false,
  });

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  @override
  void initState() {
    super.initState();
    widget.controller.onValueChangedSetState = () {
      if (mounted) setState(() {});
    };
  }

  Future<void> _pick() async {
    final controller = widget.controller;
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate ?? now,
      firstDate: controller.firstDate ?? DateTime(now.year - 2),
      lastDate: controller.lastDate ?? DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: const DatePickerThemeData(
            backgroundColor: AppColors.surface,
            headerBackgroundColor: AppColors.primary,
            headerForegroundColor: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null || !mounted) return;

    if (!widget.withTime) {
      controller.select(picked);
      return;
    }

    final current = controller.selectedDate ?? now;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );

    // Cancelar o relógio não desfaz a data: fica a hora que já estava.
    controller.select(
      DateTime(
        picked.year,
        picked.month,
        picked.day,
        time?.hour ?? current.hour,
        time?.minute ?? current.minute,
      ),
    );
  }

  String _format(DateTime date) => widget.withTime
      ? globals.l10n?.appointmentAtDate(
            AppUtils.dateToFull(date),
            AppUtils.timeToShort(date),
          ) ??
          AppUtils.dateToFull(date)
      : AppUtils.dateToFull(date);
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final date = controller.selectedDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: AppFonts.captionSmall(context).copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.text2,
          ),
        ),
        const SizedBox(height: 5),
        AppTappable(
          onTap: _pick,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    controller.hasError ? AppColors.danger : AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null ? _format(date) : (widget.hint ?? ''),
                    style: AppFonts.input(context).copyWith(
                      color: date != null ? AppColors.text1 : AppColors.text3,
                    ),
                  ),
                ),
                const AppIcon(AppAssets.atendimentos, size: 16),
              ],
            ),
          ),
        ),
        if (controller.hasError) ...[
          const SizedBox(height: 4),
          Text(
            controller.error!,
            style: AppFonts.captionSmall(context)
                .copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}
