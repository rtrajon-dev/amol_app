import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';

class DuaDetailScreen extends StatelessWidget {
  const DuaDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('দোয়া'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {/* TODO: share */},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            onPressed: () {/* TODO: toggle favorite */},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                'আরবি টেক্সট এখানে দেখাবে',
                style: TextStyle(fontFamily: 'Amiri', fontSize: 26.sp, height: 2),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20.h),
            Text('উচ্চারণ', style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            SizedBox(height: 6.h),
            Text('Transliteration এখানে', style: TextStyle(fontSize: 16.sp, fontStyle: FontStyle.italic)),
            SizedBox(height: 20.h),
            Text('অর্থ', style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            SizedBox(height: 6.h),
            Text('বাংলা অর্থ এখানে দেখাবে', style: TextStyle(fontSize: 16.sp, height: 1.6)),
            SizedBox(height: 20.h),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: 'দোয়া কপি করা হয়েছে'));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('কপি হয়েছে')));
              },
              icon: const Icon(Icons.copy),
              label: const Text('কপি করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
