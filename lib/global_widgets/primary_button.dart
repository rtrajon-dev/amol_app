import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme/app_colors.dart';
import '../app/theme/app_tokens.dart';
import '../app/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

/// The app's button.
///
/// Three things it does that a bare `ElevatedButton` does not:
///
///  - **Keeps its width while loading.** Swapping a label for a spinner
///    normally collapses the button and shifts everything under it; the label
///    stays laid out and is hidden by opacity instead.
///  - **Fires haptics.** A tap that confirms itself physically feels
///    responsive on a slow device even before the screen reacts.
///  - **Blocks double-fire.** Disabled while loading, so an impatient second
///    tap on a laggy handset cannot start a second subscribe or registration.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.icon,
    this.variant = AppButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final IconData? icon;
  final AppButtonVariant variant;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final (background, foreground, border) = switch (variant) {
      AppButtonVariant.primary => (
          theme.colorScheme.primary,
          theme.colorScheme.onPrimary,
          null,
        ),
      AppButtonVariant.secondary => (
          isLight ? AppColors.primary50 : AppColors.surfaceDarkRaised,
          theme.colorScheme.primary,
          null,
        ),
      AppButtonVariant.ghost => (
          Colors.transparent,
          theme.colorScheme.primary,
          isLight ? AppColors.borderLight : AppColors.borderDark,
        ),
      AppButtonVariant.danger => (
          isLight ? AppColors.errorSurface : AppColors.surfaceDarkRaised,
          AppColors.error,
          null,
        ),
    };

    final disabledBackground =
        isLight ? AppColors.neutral200 : AppColors.neutral800;
    final disabledForeground =
        isLight ? AppColors.neutral400 : AppColors.neutral600;

    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: Radii.mdAll,
          // Glow only on an enabled primary in light mode. On a secondary or
          // ghost it would imply a prominence they do not have.
          boxShadow:
              _enabled && variant == AppButtonVariant.primary && isLight
                  ? Shadows.glow(background)
                  : Shadows.none,
        ),
        child: Material(
          color: _enabled ? background : disabledBackground,
          borderRadius: Radii.mdAll,
          child: InkWell(
            onTap: _enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onPressed!();
                  }
                : null,
            borderRadius: Radii.mdAll,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: Radii.mdAll,
                border: border == null ? null : Border.all(color: border),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Still laid out while loading, so the button holds its
                    // size and nothing below it jumps.
                    Opacity(
                      opacity: isLoading ? 0 : 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              size: 19,
                              color:
                                  _enabled ? foreground : disabledForeground,
                            ),
                            const SizedBox(width: Space.sm),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.h3.copyWith(
                                color: _enabled
                                    ? foreground
                                    : disabledForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: foreground,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
