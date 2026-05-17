import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সেটিংস')),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
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
          _SettingsSection(title: 'প্রিমিয়াম', items: [
            _SettingsItem(icon: Icons.star_outline, title: 'প্রিমিয়াম সাবস্ক্রিপশন', subtitle: 'সপ্তাহে ৫ টাকা', onTap: () {}, highlight: true),
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
