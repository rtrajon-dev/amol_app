import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/loading_indicator.dart';
import '../viewmodel/surah_viewmodel.dart';

class SurahScreen extends ConsumerWidget {
  const SurahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahs = ref.watch(surahListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('সূরা সমূহ')),
      body: surahs.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (_, _) => Center(
          child: Text(
            'সূরা লোড করা যায়নি।',
            style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'কোনো সূরা পাওয়া যায়নি।',
                style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final surah = items[i];
              return Card(
                margin: EdgeInsets.only(bottom: 10.h),
                child: ListTile(
                  leading: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${surah.number}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    surah.banglaName,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    // A passage is labelled as such rather than implying a
                    // complete surah (e.g. Ayat al-Kursi).
                    surah.isPassage
                        ? surah.passageNote
                        : '${surah.verseCount} আয়াত · ${surah.revelationBangla}',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  trailing: Text(
                    surah.arabicName,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: () => context.go('/surah/${surah.number}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
