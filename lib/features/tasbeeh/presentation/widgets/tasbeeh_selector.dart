import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/models/tasbeeh_model.dart';

/// Horizontal dhikr picker.
///
/// Bangla labels rather than Arabic: this is navigation, and the user is
/// choosing from a list they already know by its Bangla name. The Arabic is
/// shown large once selected, where it can be read properly.
class TasbeehSelector extends StatelessWidget {
  const TasbeehSelector({
    super.key,
    required this.presets,
    required this.selected,
    required this.onSelect,
  });

  final List<TasbeehModel> presets;
  final TasbeehModel selected;
  final ValueChanged<TasbeehModel> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.lg),
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
        itemBuilder: (_, i) {
          final item = presets[i];
          final isSelected = item.id == selected.id;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(item);
            },
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.curve,
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isLight
                        ? AppColors.surfaceLight
                        : AppColors.surfaceDark),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isLight
                          ? AppColors.borderLight
                          : AppColors.borderDark),
                ),
              ),
              child: Center(
                child: Text(
                  item.bangla,
                  style: AppType.labelSmall.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
