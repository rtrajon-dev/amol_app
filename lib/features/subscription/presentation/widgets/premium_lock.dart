import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../viewmodel/subscription_viewmodel.dart';

/// FR-S-16 — a premium feature stays VISIBLE with a lock, and opens the
/// subscription flow when tapped.
///
/// Hiding locked features would be simpler and is the wrong call: a user who
/// cannot see what premium contains has no reason to buy it, and after
/// FR-S-09 silences the gate this is one of only two remaining conversion
/// paths (FR-S-10).
class PremiumLock extends ConsumerWidget {
  const PremiumLock({
    super.key,
    required this.child,
    this.label = 'প্রিমিয়াম',
    this.enabled = true,
  });

  final Widget child;
  final String label;

  /// Set false to render [child] untouched (e.g. while loading).
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider);

    if (!enabled || entitlement.isPremium) return child;

    return Stack(
      children: [
        // Dimmed but readable — the user should see what they are missing.
        Opacity(opacity: 0.45, child: IgnorePointer(child: child)),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // `manual=1` — FR-S-10 re-entry, always allowed through the
              // redirect even after the automatic prompt is silenced.
              onTap: () => context.push('${AppRoutes.subscription}?manual=1'),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 14.sp, color: Colors.white),
                      SizedBox(width: 6.w),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline row variant for list items (e.g. a locked amal-tracker entry).
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6.w : 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 11.sp, color: AppColors.accent),
          if (!compact) ...[
            SizedBox(width: 4.w),
            Text(
              'প্রিমিয়াম',
              style: TextStyle(
                fontSize: 10.sp,
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
