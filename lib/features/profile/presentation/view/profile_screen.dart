import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/feature_flags.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/services/push_service.dart';
import '../../../../app/services/storage_service.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/theme_mode_provider.dart';
import '../../../../app/utils/prayer_time_utils.dart';
import '../../../../global_widgets/option_picker.dart';
import '../../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../../prayer_time/presentation/viewmodel/prayer_time_viewmodel.dart';
import '../../../subscription/presentation/viewmodel/subscription_viewmodel.dart';
import '../widgets/profile_section.dart';
import '../widgets/subscription_status_card.dart';

/// The single place a user manages anything.
///
/// Settings used to be a separate screen, and roughly half of it duplicated
/// this one: both showed the account and email, both offered logout, both
/// carried subscription status and cancel. Two screens disagreeing about the
/// same three things is how a user ends up unsure which one is authoritative —
/// and Settings had no entry point of its own, so it was reached *through*
/// Profile anyway.
///
/// Section order follows how often a row is actually touched: subscription and
/// prayer configuration are why someone opens this screen; account actions are
/// rare and destructive, so they sit last where they cannot be hit by accident.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final entitlement = ref.watch(entitlementProvider);
    final flags = ref.watch(featureFlagsProvider);
    final themeMode = ref.watch(themeModeProvider);

    final locationName =
        StorageService.instance.getString(StorageKeys.locationName);
    final methodKey = PrayerTimeUtils.readMethodKey();
    final isHanafi = PrayerTimeUtils.readMadhab().name == 'hanafi';

    return Scaffold(
      appBar: AppBar(title: const Text('প্রোফাইল')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.lg,
          Space.lg,
          Space.xxxl,
        ),
        children: [
          _AccountHeader(
            email: auth.user?.email ?? '',
            msisdn: auth.user?.msisdn,
            isPremium: entitlement.isPremium,
          ),
          const SizedBox(height: Space.xxl),

          // Subscribers only, or a phase that can actually sell (FR-PH-02).
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
            const SizedBox(height: Space.xl),
          ],

          ProfileSection(
            title: 'নামাজ',
            children: [
              ProfileTile(
                icon: Icons.location_on_outlined,
                title: 'শহর নির্বাচন',
                subtitle: locationName.isEmpty
                    ? 'স্বয়ংক্রিয় (জিপিএস)'
                    : locationName,
                onTap: () => context.push(AppRoutes.citySelector),
              ),
              ProfileTile(
                icon: Icons.calculate_outlined,
                title: 'হিসাব পদ্ধতি',
                subtitle: PrayerTimeUtils.methods[methodKey] ?? 'কারাচি',
                onTap: () => _pickCalculationMethod(context, ref, methodKey),
              ),
              ProfileTile(
                icon: Icons.balance_outlined,
                title: 'মাযহাব',
                subtitle: isHanafi ? 'হানাফি' : 'শাফেয়ী',
                onTap: () => _pickMadhab(context, ref, isHanafi),
              ),
              ProfileTile(
                icon: Icons.notifications_outlined,
                title: 'আযান নোটিফিকেশন',
                subtitle: 'ওয়াক্ত অনুযায়ী চালু/বন্ধ',
                onTap: () => context.push(AppRoutes.azanSettings),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),

          // FR-PH-09 — no Phase 1 surface may mention hadith. This row
          // previously showed unconditionally: it advertised a withheld
          // feature, labelled it "প্রিমিয়াম ফিচার" in a phase selling
          // nothing, and led to a route that redirects away.
          if (flags.hadithEnabled) ...[
            ProfileSection(
              title: 'নোটিফিকেশন',
              children: [
                ProfileTile(
                  icon: Icons.auto_stories_outlined,
                  title: 'প্রতিদিনের হাদিস',
                  subtitle: entitlement.isPremium
                      ? (StorageService.instance
                              .getBool(StorageKeys.pushHadithEnabled)
                          ? 'চালু'
                          : 'বন্ধ')
                      : 'প্রিমিয়াম ফিচার',
                  onTap: () =>
                      _toggleHadithPush(context, ref, entitlement.isPremium),
                ),
              ],
            ),
            const SizedBox(height: Space.xl),
          ],

          ProfileSection(
            title: 'অ্যাপ',
            children: [
              ProfileTile(
                icon: Icons.dark_mode_outlined,
                title: 'থিম',
                subtitle: ThemeModeNotifier.labelFor(themeMode),
                onTap: () => _pickThemeMode(context, ref, themeMode),
              ),
              // Bangla-only by design (C-02), so this states the fact rather
              // than opening a picker with one option in it.
              ProfileTile(
                icon: Icons.language,
                title: 'ভাষা',
                subtitle: 'বাংলা',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('এই সংস্করণে শুধু বাংলা সমর্থিত।'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),

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

  // ------------------------------------------------------------------ prayer

  /// FR-N-11 — the method was configurable in every layer except the UI:
  /// `PrayerTimeUtils` read it, `StorageKeys.calculationMethod` stored it, and
  /// the row that should have set it had an empty `onTap`. So every user was
  /// silently on Karachi with no way to change it.
  Future<void> _pickCalculationMethod(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    const descriptions = {
      'karachi': 'দক্ষিণ এশিয়ায় প্রচলিত',
      'muslim_world_league': 'ইউরোপ ও আমেরিকায় প্রচলিত',
      'umm_al_qura': 'সৌদি আরব',
      'egyptian': 'মিশর ও আফ্রিকা',
      'moon_sighting_committee': 'চাঁদ দেখা কমিটি',
    };

    final chosen = await showOptionPicker<String>(
      context: context,
      title: 'হিসাব পদ্ধতি',
      current: current,
      options: [
        for (final entry in PrayerTimeUtils.methods.entries)
          PickerOption(
            value: entry.key,
            label: entry.value,
            description: descriptions[entry.key],
          ),
      ],
    );

    if (chosen == null || chosen == current) return;

    await StorageService.instance
        .setString(StorageKeys.calculationMethod, chosen);
    // FR-N-15 — times must recompute, and the azan already scheduled against
    // the old method has to be replaced or the alarms disagree with the screen.
    _invalidatePrayerTimes(ref);
  }

  /// FR-N-12 — affects Asr only.
  Future<void> _pickMadhab(
    BuildContext context,
    WidgetRef ref,
    bool isHanafi,
  ) async {
    final chosen = await showOptionPicker<String>(
      context: context,
      title: 'মাযহাব',
      current: isHanafi ? 'hanafi' : 'shafi',
      options: const [
        PickerOption(
          value: 'hanafi',
          label: 'হানাফি',
          description: 'আসরের সময় দেরিতে',
        ),
        PickerOption(
          value: 'shafi',
          label: 'শাফেয়ী',
          description: 'আসরের সময় আগে',
        ),
      ],
    );

    if (chosen == null) return;

    await StorageService.instance.setString(StorageKeys.madhab, chosen);
    _invalidatePrayerTimes(ref);
  }

  void _invalidatePrayerTimes(WidgetRef ref) {
    ref.invalidate(prayerTimesProvider);
    ref.invalidate(nextPrayerProvider);
    ref.read(azanSchedulerProvider).rescheduleAll();
  }

  // --------------------------------------------------------------------- app

  Future<void> _pickThemeMode(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final chosen = await showOptionPicker<ThemeMode>(
      context: context,
      title: 'থিম',
      current: current,
      options: [
        for (final mode in ThemeMode.values)
          PickerOption(value: mode, label: ThemeModeNotifier.labelFor(mode)),
      ],
    );

    if (chosen != null) {
      await ref.read(themeModeProvider.notifier).set(chosen);
    }
  }

  /// FR-P-02 / FR-P-03 — permission is requested HERE, at the moment the user
  /// asks for the feature, never at startup. Asking on first launch before any
  /// value is demonstrated is how apps get permanently denied.
  Future<void> _toggleHadithPush(
    BuildContext context,
    WidgetRef ref,
    bool isPremium,
  ) async {
    if (!isPremium) {
      context.push('${AppRoutes.subscription}?manual=1');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final storage = StorageService.instance;

    if (storage.getBool(StorageKeys.pushHadithEnabled)) {
      await storage.setBool(StorageKeys.pushHadithEnabled, false);
      messenger.showSnackBar(
        const SnackBar(content: Text('প্রতিদিনের হাদিস বন্ধ করা হয়েছে।')),
      );
      return;
    }

    final granted = await PushService.instance.requestPermission();
    if (!granted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'নোটিফিকেশনের অনুমতি প্রয়োজন। ফোনের সেটিংস থেকে অনুমতি দিন।',
          ),
        ),
      );
      return;
    }

    await storage.setBool(StorageKeys.pushHadithEnabled, true);
    messenger.showSnackBar(
      const SnackBar(content: Text('প্রতিদিনের হাদিস চালু করা হয়েছে।')),
    );
  }

  // ----------------------------------------------------------------- account

  /// FR-A-08 — device-local progress survives a logout. Saying so matters:
  /// users who fear losing a long streak will not log out, and then cannot
  /// switch accounts.
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
            const SizedBox(height: Space.md),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'পাসওয়ার্ড'),
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
  const _AccountHeader({
    required this.email,
    required this.isPremium,
    this.msisdn,
  });

  final String email;
  final String? msisdn;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient:
                isLight ? AppColors.heroGradient : AppColors.heroGradientDark,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 28,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: Space.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email.isEmpty ? 'অ্যাকাউন্ট' : email,
                style: AppType.h3.copyWith(color: theme.colorScheme.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
              if (msisdn != null && msisdn!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  PrayerTimeUtils.toBanglaDigits(msisdn!),
                  style: AppType.bodySmall
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              if (isPremium) ...[
                const SizedBox(height: Space.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent500.withValues(alpha: 0.14),
                    borderRadius: Radii.smAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: AppColors.accent700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'প্রিমিয়াম',
                        style: AppType.labelSmall
                            .copyWith(color: AppColors.accent700),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
