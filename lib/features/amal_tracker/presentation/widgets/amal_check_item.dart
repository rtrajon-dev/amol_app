import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/feature_flags.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../subscription/presentation/viewmodel/subscription_viewmodel.dart';
import '../../../subscription/presentation/widgets/premium_lock.dart';
import '../../domain/models/amal_item_model.dart';

class AmalCheckItem extends ConsumerWidget {
  const AmalCheckItem({super.key, required this.item, required this.onToggle});

  final AmalItemModel item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FR-S-16 — the item stays VISIBLE when locked. Tapping it opens the
    // subscription flow rather than doing nothing, which is one of the two
    // conversion paths that survive FR-S-09 silencing the gate.
    //
    // FR-PH-02 — nothing is locked in a phase with no purchasable tier.
    // Leaving the padlock on would advertise an upgrade the user cannot buy
    // and send them to a route that now redirects away.
    final subscriptionEnabled = ref.watch(featureFlagsProvider).subscriptionEnabled;
    final isLocked = subscriptionEnabled &&
        item.isPremium &&
        !ref.watch(entitlementProvider).isPremium;

    void handleTap() {
      if (isLocked) {
        context.push('${AppRoutes.subscription}?manual=1');
        return;
      }
      onToggle();
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        onTap: handleTap,
        leading: GestureDetector(
          onTap: handleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.isCompleted && !isLocked ? AppColors.success : Colors.transparent,
              border: Border.all(
                color: isLocked
                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                    : (item.isCompleted ? AppColors.success : AppColors.textSecondary),
                width: 2,
              ),
            ),
            child: isLocked
                ? Icon(Icons.lock, size: 14.sp, color: AppColors.textSecondary)
                : (item.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null),
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            decoration:
                item.isCompleted && !isLocked ? TextDecoration.lineThrough : null,
            color: item.isCompleted && !isLocked ? AppColors.textSecondary : null,
          ),
        ),
        subtitle: Text(item.subtitle, style: TextStyle(fontSize: 12.sp)),
        trailing: isLocked ? const PremiumBadge() : null,
      ),
    );
  }
}
