import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/network/api_exception.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../subscription/domain/entitlement.dart';
import '../../../subscription/presentation/viewmodel/subscription_viewmodel.dart';
import 'profile_section.dart';

/// BDApps subscription status and the actions a subscriber needs.
///
/// Status and unsubscribe are shown ONLY to a subscriber. There is nothing for
/// a free user to check or cancel, and no phone number is asked for: the
/// entitlement is discovered on every launch from `/auth/me`, which returns
/// what is bound to the account and needs no MSISDN (FR-S-21).
///
/// [canSubscribe] governs the upgrade offer alone. Phase 1 sells nothing
/// (FR-PH-01), so a free user sees no subscription section at all.
class SubscriptionStatusCard extends ConsumerWidget {
  const SubscriptionStatusCard({
    super.key,
    required this.entitlement,
    required this.canSubscribe,
  });

  final Entitlement entitlement;
  final bool canSubscribe;

  /// Whether this card has anything to show. Lets the caller drop the whole
  /// section rather than render an empty card.
  static bool isVisible({
    required Entitlement entitlement,
    required bool canSubscribe,
  }) =>
      entitlement.isPremium || canSubscribe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entitlement.isPremium) {
      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.verified, color: AppColors.accent),
            title: Text(
              'প্রিমিয়াম সক্রিয়',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
            subtitle: Text(_activeSubtitle(), style: TextStyle(fontSize: 12.sp)),
          ),
          ProfileTile(
            icon: Icons.refresh,
            title: 'স্ট্যাটাস চেক করুন',
            onTap: () => _refresh(context, ref),
          ),
          ProfileTile(
            icon: Icons.cancel_outlined,
            title: 'আনসাবস্ক্রাইব',
            subtitle: 'ওয়েবসাইটেও প্রিমিয়াম বন্ধ হবে',
            destructive: true,
            onTap: () => _confirmCancel(context, ref),
          ),
        ],
      );
    }

    // Free user. In Phase 1 the caller hides this section entirely; in a phase
    // that sells something, the upgrade offer is all a free user needs.
    return ProfileTile(
      icon: Icons.star_outline,
      title: 'প্রিমিয়াম সাবস্ক্রিপশন',
      subtitle: 'সপ্তাহে ৫ টাকা',
      onTap: () => context.push('${AppRoutes.subscription}?manual=1'),
    );
  }

  String _activeSubtitle() {
    final masked = entitlement.maskedMsisdn;
    final base =
        masked == null ? 'সাপ্তাহিক ৫ টাকা' : '$masked · সাপ্তাহিক ৫ টাকা';
    // FR-S-15 — say when the answer is old rather than implying it is fresh.
    return entitlement.isStale ? '$base · যাচাই করা যায়নি' : base;
  }

  /// Re-asks the server. Uses the account-bound path, so it needs no phone
  /// number and cannot be used to look up someone else's subscription.
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result =
          await ref.read(subscriptionRepositoryProvider).refreshIfStale();
      ref.read(entitlementProvider.notifier).set(result);
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.isPremium
              ? 'প্রিমিয়াম সক্রিয় আছে।'
              : 'কোনো সক্রিয় সাবস্ক্রিপশন নেই।'),
        ),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// FR-S-20 — cancelling is GLOBAL. Amol365 mobile and web are one BDApps
  /// application, so ending this subscription ends web access too. The dialog
  /// says so plainly; the consequence must never be a surprise.
  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('সাবস্ক্রিপশন বাতিল'),
        content: const Text(
          'আপনি কি সাবস্ক্রিপশন বাতিল করতে চান?\n\n'
          'বাতিল করলে প্রিমিয়াম ফিচারগুলো সাথে সাথে বন্ধ হয়ে যাবে। '
          'এই নম্বর দিয়ে ওয়েবসাইটেও আর প্রিমিয়াম ব্যবহার করা যাবে না।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('থাক'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('বাতিল করুন', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref.read(subscriptionRepositoryProvider).cancel();
      ref.read(entitlementProvider.notifier).set(result);
      messenger.showSnackBar(
        const SnackBar(content: Text('সাবস্ক্রিপশন বাতিল করা হয়েছে।')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
