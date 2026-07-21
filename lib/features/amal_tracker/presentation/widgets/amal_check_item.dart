import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/feature_flags.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../subscription/presentation/viewmodel/subscription_viewmodel.dart';
import '../../../subscription/presentation/widgets/premium_lock.dart';
import '../../domain/models/amal_item_model.dart';

/// A single amal row.
///
/// The checkbox is a filled circle rather than a Material checkbox: this is a
/// list the user taps five to nine times a day, and a large, unambiguous
/// target that animates on completion is worth more here than platform
/// convention. Haptics fire on the tap so it confirms itself before the frame
/// even lands, which matters on a slow device.
class AmalCheckItem extends ConsumerWidget {
  const AmalCheckItem({super.key, required this.item, required this.onToggle});

  final AmalItemModel item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    // FR-S-16 — the item stays VISIBLE when locked. Tapping it opens the
    // subscription flow rather than doing nothing.
    //
    // FR-PH-02 — nothing is locked in a phase with no purchasable tier.
    final subscriptionEnabled =
        ref.watch(featureFlagsProvider).subscriptionEnabled;
    final isLocked = subscriptionEnabled &&
        item.isPremium &&
        !ref.watch(entitlementProvider).isPremium;

    final done = item.isCompleted && !isLocked;

    void handleTap() {
      if (isLocked) {
        context.push('${AppRoutes.subscription}?manual=1');
        return;
      }
      // Heavier than a selection click: completing an amal is an achievement,
      // and the feedback should feel like one.
      HapticFeedback.mediumImpact();
      onToggle();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Material(
        color: done
            ? AppColors.success.withValues(alpha: isLight ? 0.06 : 0.12)
            : (isLight ? AppColors.surfaceLight : AppColors.surfaceDark),
        borderRadius: Radii.lgAll,
        child: InkWell(
          onTap: handleTap,
          borderRadius: Radii.lgAll,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: Radii.lgAll,
              border: Border.all(
                color: done
                    ? AppColors.success.withValues(alpha: 0.35)
                    : (isLight
                        ? AppColors.borderLight
                        : AppColors.borderDark),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Row(
                children: [
                  _CheckCircle(done: done, isLocked: isLocked),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppType.bodyLarge.copyWith(
                            color: done
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                            decorationColor:
                                theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: AppType.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(width: Space.sm),
                    const PremiumBadge(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done, required this.isLocked});

  final bool done;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: Motion.normal,
      curve: Motion.curve,
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.success : Colors.transparent,
        border: Border.all(
          color: isLocked
              ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
              : (done
                  ? AppColors.success
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          width: 2,
        ),
      ),
      child: isLocked
          ? Icon(
              Icons.lock_outline_rounded,
              size: 15,
              color: theme.colorScheme.onSurfaceVariant,
            )
          : AnimatedScale(
              // Scales in rather than appearing, so a tap reads as an action
              // that landed.
              scale: done ? 1 : 0,
              duration: Motion.normal,
              curve: Curves.easeOutBack,
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 18),
            ),
    );
  }
}
