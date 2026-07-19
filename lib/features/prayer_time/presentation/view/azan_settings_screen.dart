import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/services/notification_service.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/models/prayer_time_model.dart';
import '../viewmodel/prayer_time_viewmodel.dart';

/// FR-N-29 — azan notification settings: per-prayer toggles, pre-reminder,
/// and the permission/battery work that decides whether any of it actually
/// fires on the user's phone.
class AzanSettingsScreen extends ConsumerStatefulWidget {
  const AzanSettingsScreen({super.key});

  @override
  ConsumerState<AzanSettingsScreen> createState() => _AzanSettingsScreenState();
}

class _AzanSettingsScreenState extends ConsumerState<AzanSettingsScreen> {
  final Map<PrayerSlot, bool> _enabled = AzanPreferences.read();
  late int _preReminder = AzanPreferences.preReminderMinutes();

  bool _notificationsAllowed = false;
  bool _batteryExempt = false;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final allowed = await NotificationService.instance.hasNotificationPermission();
    final pending = await NotificationService.instance.pending();

    var exempt = false;
    try {
      exempt = await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _notificationsAllowed = allowed;
      _batteryExempt = exempt;
      _pendingCount = pending.length;
    });
  }

  /// FR-N-25 — permission is requested HERE, when the user turns a prayer on,
  /// not at app startup.
  Future<bool> _ensurePermissions() async {
    if (!_notificationsAllowed) {
      final granted =
          await NotificationService.instance.requestNotificationPermission();
      if (!granted) {
        if (mounted) _snack('নোটিফিকেশনের অনুমতি প্রয়োজন।');
        return false;
      }
    }
    // Exact alarms — silently best-effort; scheduling falls back to inexact
    // if this is refused rather than failing outright.
    await NotificationService.instance.requestExactAlarmPermission();
    return true;
  }

  Future<void> _apply() async {
    await AzanPreferences.write(_enabled);
    await AzanPreferences.setPreReminderMinutes(_preReminder);
    // FR-N-15 / FR-N-26 — any change reschedules the whole rolling window.
    await ref.read(azanSchedulerProvider).rescheduleAll();
    await _refreshStatus();
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final anyEnabled = _enabled.entries.any((e) => e.value);

    return Scaffold(
      appBar: AppBar(title: const Text('আযান নোটিফিকেশন')),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          if (!_notificationsAllowed) ...[
            _Warning(
              icon: Icons.notifications_off_outlined,
              text: 'নোটিফিকেশন বন্ধ আছে। আযান পেতে অনুমতি দিন।',
              actionLabel: 'অনুমতি দিন',
              onAction: () async {
                await _ensurePermissions();
                await _refreshStatus();
              },
            ),
            SizedBox(height: 16.h),
          ],

          // The single biggest cause of "azan never arrives" in this market.
          if (anyEnabled && !_batteryExempt) ...[
            _Warning(
              icon: Icons.battery_alert_outlined,
              text: 'ব্যাটারি সেভিং চালু থাকলে আযান সময়মতো নাও আসতে পারে।',
              actionLabel: 'ঠিক করুন',
              onAction: _showBatteryGuidance,
            ),
            SizedBox(height: 16.h),
          ],

          Text(
            'কোন কোন ওয়াক্তে আযান',
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Card(
            child: Column(
              children: [
                for (final slot in PrayerSlot.values)
                  if (slot.isNotifiable) // FR-N-23 — sunrise is not a prayer
                    SwitchListTile(
                      title: Text(slot.bangla, style: TextStyle(fontSize: 15.sp)),
                      value: _enabled[slot] ?? false,
                      onChanged: (value) async {
                        if (value && !await _ensurePermissions()) return;
                        setState(() => _enabled[slot] = value);
                        await _apply();
                      },
                    ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // FR-N-24 — optional pre-prayer reminder.
          Text(
            'আগাম রিমাইন্ডার',
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.h),
          Card(
            child: Column(
              children: [
                for (final minutes in [0, 5, 10, 15, 30])
                  RadioListTile<int>(
                    title: Text(
                      minutes == 0 ? 'বন্ধ' : '$minutes মিনিট আগে',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    value: minutes,
                    // ignore: deprecated_member_use
                    groupValue: _preReminder,
                    // ignore: deprecated_member_use
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => _preReminder = value);
                      await _apply();
                    },
                  ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Lets the user prove to themselves that azan works, instead of
          // waiting until the next prayer to find out it does not.
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: Text('পরীক্ষা করুন', style: TextStyle(fontSize: 15.sp)),
                  subtitle: Text(
                    '৫ সেকেন্ড পর একটি পরীক্ষামূলক নোটিফিকেশন আসবে',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  onTap: () async {
                    if (!await _ensurePermissions()) return;
                    await NotificationService.instance.sendTestNotification();
                    if (mounted) _snack('৫ সেকেন্ড অপেক্ষা করুন...');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text('নির্ধারিত আযান', style: TextStyle(fontSize: 15.sp)),
                  subtitle: Text(
                    '$_pendingCount টি নোটিফিকেশন সিডিউল করা আছে',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      await _apply();
                      if (mounted) _snack('আবার সিডিউল করা হয়েছে।');
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Device-specific guidance. Generic advice does not help here — each OEM
  /// buries the setting somewhere different, and users cannot find it.
  Future<void> _showBatteryGuidance() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (status.isGranted) {
        await _refreshStatus();
        if (mounted) _snack('ব্যাটারি অপটিমাইজেশন বন্ধ করা হয়েছে ✅');
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _BatteryGuidanceSheet(),
    );
    await _refreshStatus();
  }
}

class _BatteryGuidanceSheet extends StatelessWidget {
  const _BatteryGuidanceSheet();

  static const _devices = [
    (
      'Xiaomi / Redmi / POCO',
      'Settings → Apps → Manage apps → Amol365 → Battery saver → "No restrictions"\n'
          'এবং Autostart চালু করুন',
    ),
    (
      'Realme / OPPO',
      'Settings → Battery → App Battery Management → Amol365 → '
          '"Allow background running" চালু করুন',
    ),
    (
      'Vivo',
      'Settings → Battery → Background power consumption management → '
          'Amol365 → "Allow high background power consumption"',
    ),
    (
      'Samsung',
      'Settings → Apps → Amol365 → Battery → "Unrestricted" নির্বাচন করুন',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'আযান সময়মতো পেতে',
                style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                'অনেক ফোনে ব্যাটারি সেভিং চালু থাকলে অ্যাপ বন্ধ করে দেওয়া হয়, '
                'ফলে আযান আসে না। আপনার ফোন অনুযায়ী নিচের ধাপগুলো করুন।',
                style: TextStyle(fontSize: 14.sp, height: 1.6, color: AppColors.textSecondary),
              ),
              SizedBox(height: 20.h),
              for (final device in _devices) ...[
                Text(
                  device.$1,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                SizedBox(height: 6.h),
                Text(
                  device.$2,
                  style: TextStyle(fontSize: 13.sp, height: 1.7),
                ),
                SizedBox(height: 16.h),
              ],
              Center(
                child: TextButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings),
                  label: Text('অ্যাপ সেটিংস খুলুন', style: TextStyle(fontSize: 14.sp)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.warning, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.sp, height: 1.5),
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel, style: TextStyle(fontSize: 13.sp)),
          ),
        ],
      ),
    );
  }
}
