import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../global_widgets/app_card.dart';

/// A titled group of profile rows, matching the Settings screen's grouping so
/// the two read as one app rather than two.
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Space.xs, bottom: Space.sm),
          child: Text(
            title.toUpperCase(),
            style: AppType.overline
                .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Irreversible actions are coloured so they cannot be tapped by pattern.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final color = destructive ? AppColors.error : theme.colorScheme.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.xs,
      ),
      // A tinted plate keeps every row's icon at the same optical weight,
      // however dense the glyph.
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isLight ? 0.10 : 0.18),
          borderRadius: Radii.smAll,
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      title: Text(
        title,
        style: AppType.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: destructive ? AppColors.error : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: AppType.bodySmall
                    .copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
