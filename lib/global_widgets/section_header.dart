import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';
import '../app/theme/app_typography.dart';

/// Titles a group of content.
///
/// The action is `Flexible`, and the title takes the remaining room, so a long
/// Bangla heading beside a long action label wraps instead of overflowing —
/// which the previous fixed Row did at narrow widths and large font scales.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppType.h2.copyWith(color: theme.colorScheme.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppType.bodySmall
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          Padding(
            padding: const EdgeInsets.only(left: Space.sm),
            child: TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.sm,
                  vertical: Space.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!, style: AppType.label),
            ),
          ),
      ],
    );
  }
}
