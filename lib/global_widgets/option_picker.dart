import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';
import '../app/theme/app_typography.dart';

/// One choice in [showOptionPicker].
class PickerOption<T> {
  const PickerOption({
    required this.value,
    required this.label,
    this.description,
  });

  final T value;
  final String label;

  /// Optional second line. Worth using when the label alone does not tell a
  /// non-expert what they are choosing — "কারাচি" means nothing without
  /// "দক্ষিণ এশিয়ায় প্রচলিত".
  final String? description;
}

/// A bottom-sheet single-choice picker.
///
/// One implementation for theme, calculation method and madhab, so the three
/// behave identically. A sheet rather than a dialog because the list can grow
/// past a dialog's comfortable height, and a sheet is reachable by thumb on a
/// tall phone where a centred dialog's options are not.
///
/// Returns null when dismissed, which callers must treat as "no change" rather
/// than as a value.
Future<T?> showOptionPicker<T>({
  required BuildContext context,
  required String title,
  required List<PickerOption<T>> options,
  required T current,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);

      return SafeArea(
        child: ConstrainedBox(
          // Never taller than 80% of the screen, so the sheet always reads as
          // a sheet and the user can see there is something behind it.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xl,
                  0,
                  Space.xl,
                  Space.md,
                ),
                child: Text(
                  title,
                  style:
                      AppType.h2.copyWith(color: theme.colorScheme.onSurface),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: Space.md),
                  itemCount: options.length,
                  itemBuilder: (_, i) {
                    final option = options[i];
                    final isSelected = option.value == current;

                    return ListTile(
                      onTap: () => Navigator.pop(sheetContext, option.value),
                      title: Text(
                        option.label,
                        style: AppType.bodyLarge.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      subtitle: option.description == null
                          ? null
                          : Text(
                              option.description!,
                              style: AppType.bodySmall.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                      // A check on the selected row rather than a radio on
                      // every row: the list is read far more often than it is
                      // changed, and one mark is quicker to scan than N empty
                      // circles.
                      trailing: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
