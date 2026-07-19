import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/network/api_exception.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../../subscription/presentation/viewmodel/subscription_viewmodel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('লগআউট'),
        content: const Text(
          'আপনি কি লগআউট করতে চান?\n\n'
          'আপনার আমল, তাসবিহ ও স্ট্রিক এই ডিভাইসেই থাকবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('লগআউট', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    // FR-A-08 — device-local progress is preserved, not wiped. The router
    // redirect handles navigation once the auth state flips.
    await ref.read(authProvider.notifier).logout();
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final entitlement = ref.watch(entitlementProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস')),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _SettingsSection(title: 'অ্যাকাউন্ট', items: [
            _SettingsItem(
              icon: Icons.person_outline,
              title: auth.user?.label ?? 'অ্যাকাউন্ট',
              subtitle: auth.user?.email ?? 'লগইন করা আছে',
              onTap: () {},
            ),
            _SettingsItem(
              icon: Icons.logout,
              title: 'লগআউট',
              subtitle: 'এই ডিভাইস থেকে বের হন',
              onTap: () => _confirmLogout(context, ref),
            ),
          ]),
          SizedBox(height: 16.h),
          _SettingsSection(title: 'নামাজ', items: [
            _SettingsItem(icon: Icons.location_on_outlined, title: 'শহর নির্বাচন', subtitle: 'ঢাকা', onTap: () {}),
            _SettingsItem(icon: Icons.calculate_outlined, title: 'হিসাব পদ্ধতি', subtitle: 'কারাচি (হানাফি)', onTap: () {}),
            _SettingsItem(icon: Icons.notifications_outlined, title: 'আযান নোটিফিকেশন', subtitle: 'চালু', onTap: () {}),
          ]),
          SizedBox(height: 16.h),
          _SettingsSection(title: 'অ্যাপ', items: [
            _SettingsItem(icon: Icons.dark_mode_outlined, title: 'ডার্ক মোড', subtitle: 'সিস্টেম', onTap: () {}),
            _SettingsItem(icon: Icons.language, title: 'ভাষা', subtitle: 'বাংলা', onTap: () {}),
            _SettingsItem(icon: Icons.text_fields, title: 'আরবি ফন্ট সাইজ', subtitle: 'মাঝারি', onTap: () {}),
          ]),
          SizedBox(height: 16.h),
          // FR-S-10 — one of only two conversion paths once the automatic
          // gate is silenced. Always visible to free users.
          _SettingsSection(title: 'প্রিমিয়াম', items: [
            if (entitlement.isPremium) ...[
              _SettingsItem(
                icon: Icons.verified,
                title: 'প্রিমিয়াম সক্রিয়',
                subtitle: entitlement.maskedMsisdn == null
                    ? 'সাপ্তাহিক ৫ টাকা'
                    : '${entitlement.maskedMsisdn} · সাপ্তাহিক ৫ টাকা',
                onTap: () {},
                highlight: true,
              ),
              _SettingsItem(
                icon: Icons.cancel_outlined,
                title: 'সাবস্ক্রিপশন বাতিল করুন',
                subtitle: 'আনসাবস্ক্রাইব',
                onTap: () => _confirmCancel(context, ref),
              ),
            ] else
              _SettingsItem(
                icon: Icons.star_outline,
                title: 'প্রিমিয়াম সাবস্ক্রিপশন',
                subtitle: 'সপ্তাহে ৫ টাকা',
                highlight: true,
                onTap: () => context.push('${AppRoutes.subscription}?manual=1'),
              ),
          ]),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});
  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(title, style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ),
        Card(child: Column(children: items)),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({required this.icon, required this.title, required this.subtitle, required this.onTap, this.highlight = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: highlight ? AppColors.accent : AppColors.primary),
      title: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: highlight ? AppColors.accent : null)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12.sp)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
