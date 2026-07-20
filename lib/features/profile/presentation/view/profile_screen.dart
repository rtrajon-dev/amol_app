import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/feature_flags.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../../subscription/presentation/viewmodel/subscription_viewmodel.dart';
import '../widgets/profile_section.dart';
import '../widgets/subscription_status_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final entitlement = ref.watch(entitlementProvider);
    final flags = ref.watch(featureFlagsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('প্রোফাইল')),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _AccountHeader(email: auth.user?.email ?? ''),
          SizedBox(height: 20.h),

          // Status and unsubscribe belong to subscribers only — a free user has
          // nothing to check and nothing to cancel. In Phase 1 there is also
          // nothing to sell (FR-PH-01), so the section disappears entirely
          // rather than rendering an empty card.
          if (SubscriptionStatusCard.isVisible(
            entitlement: entitlement,
            canSubscribe: flags.subscriptionEnabled,
          )) ...[
            ProfileSection(
              title: 'সাবস্ক্রিপশন',
              children: [
                SubscriptionStatusCard(
                  entitlement: entitlement,
                  canSubscribe: flags.subscriptionEnabled,
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],

          ProfileSection(
            title: 'অ্যাপ',
            children: [
              ProfileTile(
                icon: Icons.settings_outlined,
                title: 'সেটিংস',
                subtitle: 'নামাজের সময়, আযান, শহর',
                onTap: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          ProfileSection(
            title: 'অ্যাকাউন্ট',
            children: [
              ProfileTile(
                icon: Icons.logout,
                title: 'লগআউট',
                subtitle: 'আমল ও তাসবিহ এই ডিভাইসেই থাকবে',
                onTap: () => _confirmLogout(context, ref),
              ),
              ProfileTile(
                icon: Icons.delete_forever_outlined,
                title: 'অ্যাকাউন্ট মুছে ফেলুন',
                subtitle: 'স্থায়ীভাবে মুছে যাবে',
                destructive: true,
                onTap: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// FR-A-08 — device-local progress survives a logout. Saying so in the
  /// dialog matters: users who fear losing a long streak will not log out, and
  /// then cannot switch accounts.
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
    await ref.read(authProvider.notifier).logout();
  }

  /// Irreversible, and the server requires the password — an unlocked phone
  /// alone must not be able to destroy an account.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('অ্যাকাউন্ট মুছে ফেলুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'এই কাজটি স্থায়ী। আপনার অ্যাকাউন্ট ও সাবস্ক্রিপশন মুছে যাবে '
              'এবং ফিরিয়ে আনা যাবে না।\n\n'
              'নিশ্চিত করতে পাসওয়ার্ড দিন:',
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'পাসওয়ার্ড',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('থাক'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text('মুছে ফেলুন', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    controller.dispose();
    if (password == null || password.isEmpty || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(authProvider.notifier).deleteAccount(password);

    if (!ok) {
      final failure = ref.read(authProvider).failure;
      messenger.showSnackBar(
        SnackBar(content: Text(failure?.message ?? 'মুছে ফেলা যায়নি।')),
      );
    }
    // On success the router redirect handles navigation as auth state flips.
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28.r,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(Icons.person_outline,
              size: 30.sp, color: AppColors.primary),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email.isEmpty ? 'অ্যাকাউন্ট' : email,
                style:
                    TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                'আসসালামু আলাইকুম',
                style: TextStyle(
                    fontSize: 12.sp, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
