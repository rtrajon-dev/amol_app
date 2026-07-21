import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../app/theme/app_tokens.dart';
import '../app/theme/app_typography.dart';
import 'primary_button.dart';

/// Empty and error states.
///
/// Exists so failure never renders as a bare exception string. Every one of
/// these says what happened in Bangla and offers the next action — an error
/// screen with nothing to tap is a dead end, and on a prayer app the user's
/// only recourse then is to uninstall.
class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tone = AppStateTone.neutral,
  });

  /// Something went wrong, with a retry.
  const AppStateView.error({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  })  : icon = Icons.cloud_off_rounded,
        tone = AppStateTone.error;

  /// Nothing here yet — not a failure.
  const AppStateView.empty({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : tone = AppStateTone.neutral;

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppStateTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final accent = switch (tone) {
      AppStateTone.error => AppColors.error,
      AppStateTone.neutral => theme.colorScheme.primary,
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isLight ? 0.09 : 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: accent),
            ),
            const SizedBox(height: Space.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppType.h2.copyWith(color: theme.colorScheme.onSurface),
            ),
            if (message != null) ...[
              const SizedBox(height: Space.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppType.body
                    .copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Space.xl),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                width: 200,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum AppStateTone { neutral, error }
