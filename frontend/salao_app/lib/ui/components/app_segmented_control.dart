import 'package:flutter/widgets.dart';

import '../../settings/app_colors.dart';
import '../../settings/app_fonts.dart';
import 'app_tappable.dart';

class AppSegment<T> {
  final T value;
  final String label;

  const AppSegment(this.value, this.label);
}

/// Seletor compacto equivalente ao `TabsList` usado nas rotas mobile React.
class AppSegmentedControl<T> extends StatelessWidget {
  final T value;
  final List<AppSegment<T>> segments;
  final ValueChanged<T> onChanged;

  const AppSegmentedControl({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: segments.map((segment) {
              final selected = segment.value == value;
              return AppTappable(
                onTap: () => onChanged(segment.value),
                minSize: 36,
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.surface : AppColors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    segment.label,
                    style: AppFonts.caption(context).copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.text1 : AppColors.text2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
}
