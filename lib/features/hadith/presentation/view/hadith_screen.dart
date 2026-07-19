import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/loading_indicator.dart';
import '../../domain/models/hadith_model.dart';
import '../viewmodel/hadith_viewmodel.dart';

class HadithScreen extends ConsumerWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hadith = ref.watch(dailyHadithProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('হাদিস')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: hadith.when(
          loading: () => const Center(child: LoadingIndicator()),
          error: (_, _) => const _Unavailable(),
          // No verified, permissively-licensed Bangla hadith source has been
          // chosen yet, so hadiths.json is intentionally absent. Showing an
          // honest "coming soon" is correct; inventing or displaying
          // unattributed text as hadith would not be.
          data: (item) => item == null ? const _Unavailable() : _HadithCard(hadith: item),
        ),
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({required this.hadith});

  final HadithModel hadith;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              Text(
                'আজকের হাদিস',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),
              if (hadith.arabic.isNotEmpty) ...[
                Text(
                  hadith.arabic,
                  style: TextStyle(fontFamily: 'Amiri', fontSize: 22.sp, height: 2),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
              ],
              Text(
                hadith.bangla,
                style: TextStyle(fontSize: 15.sp, height: 1.7),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              if (hadith.narrator.isNotEmpty)
                Text(
                  'বর্ণনাকারী: ${hadith.narrator}',
                  style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 6.h),
              // Attribution is mandatory — hadithListProvider drops any entry
              // without a source, so this is always populated here.
              Text(
                '— ${hadith.source} · ${hadith.bookReference}',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📖', style: TextStyle(fontSize: 52.sp)),
            SizedBox(height: 20.h),
            Text(
              'হাদিস শীঘ্রই আসছে',
              style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Text(
              'যাচাইকৃত ও নির্ভরযোগ্য সূত্র থেকে হাদিস যুক্ত করার কাজ চলছে। '
              'সঠিক সনদ ও তথ্যসূত্র নিশ্চিত না হয়ে কোনো হাদিস প্রকাশ করা হবে না।',
              style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary, height: 1.7),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
