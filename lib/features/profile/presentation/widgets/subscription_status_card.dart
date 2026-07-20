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

/// BDApps subscription status, plus the two actions a subscriber needs:
/// find their subscription, and end it.
///
/// [canSubscribe] separates *management* from *sales*. Phase 1 sells nothing
/// (FR-PH-01), but a user who subscribed through the Amol365 **web** app is
/// premium here too under one shared MSISDN (FR-S-19) and must still be able
/// to see and cancel that subscription. So the status check stays available
/// while every path that would take money is withheld.
class SubscriptionStatusCard extends ConsumerWidget {
  const SubscriptionStatusCard({
    super.key,
    required this.entitlement,
    required this.canSubscribe,
  });

  final Entitlement entitlement;
  final bool canSubscribe;

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
            subtitle: Text(
              _activeSubtitle(),
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
          ProfileTile(
            icon: Icons.refresh,
            title: 'স্ট্যাটাস রিফ্রেশ করুন',
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

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.person_outline, color: AppColors.textSecondary),
          title: Text(
            'ফ্রি ব্যবহারকারী',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            canSubscribe
                ? 'প্রিমিয়ামে আপগ্রেড করুন'
                : 'সব ফিচার এখন ফ্রি',
            style: TextStyle(fontSize: 12.sp),
          ),
        ),
        // FR-S-19 — a web subscriber arriving on a fresh install has no cached
        // entitlement, so without this there is no way for them to find the
        // subscription they are already paying for.
        ProfileTile(
          icon: Icons.search,
          title: 'সাবস্ক্রিপশন চেক করুন',
          subtitle: 'অন্য নম্বর বা ওয়েবসাইটে সাবস্ক্রাইব করে থাকলে',
          onTap: () => _checkStatus(context, ref),
        ),
        if (canSubscribe)
          ProfileTile(
            icon: Icons.star_outline,
            title: 'প্রিমিয়াম সাবস্ক্রিপশন',
            subtitle: 'সপ্তাহে ৫ টাকা',
            onTap: () => context.push('${AppRoutes.subscription}?manual=1'),
          ),
      ],
    );
  }

  String _activeSubtitle() {
    final masked = entitlement.maskedMsisdn;
    final base = masked == null ? 'সাপ্তাহিক ৫ টাকা' : '$masked · সাপ্তাহিক ৫ টাকা';
    // FR-S-15 — say when the answer is old rather than implying it is fresh.
    return entitlement.isStale ? '$base · যাচাই করা যায়নি' : base;
  }

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

  /// Status lookup only. Deliberately never continues into the OTP subscribe
  /// flow — that would make this a purchase path, which Phase 1 withholds.
  Future<void> _checkStatus(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    final msisdn = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('সাবস্ক্রিপশন চেক'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'যে নম্বর দিয়ে সাবস্ক্রাইব করেছিলেন সেটি দিন। '
              'কোনো চার্জ কাটা হবে না।',
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'মোবাইল নম্বর',
                hintText: '01XXXXXXXXX',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('চেক করুন'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (msisdn == null || msisdn.trim().isEmpty || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(subscriptionRepositoryProvider)
          .checkStatus(msisdn.trim());
      ref.read(entitlementProvider.notifier).set(result);

      messenger.showSnackBar(
        SnackBar(
          content: Text(result.isPremium
              ? 'প্রিমিয়াম সাবস্ক্রিপশন পাওয়া গেছে।'
              : 'এই নম্বরে কোনো সক্রিয় সাবস্ক্রিপশন নেই।'),
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
