import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/loading_indicator.dart';
import '../../domain/models/surah_model.dart';
import '../viewmodel/surah_viewmodel.dart';

class SurahDetailScreen extends ConsumerWidget {
  const SurahDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final number = int.tryParse(id) ?? -1;
    final surah = ref.watch(surahByNumberProvider(number));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          surah.value?.banglaName ?? 'সূরা',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: surah.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (_, _) => _message('সূরা লোড করা যায়নি।'),
        data: (data) {
          // A bad deep link must not crash — show a proper message (FR-G-07).
          if (data == null) return _message('এই সূরাটি পাওয়া যায়নি।');
          if (data.ayahs.isEmpty) return _message('এই সূরার আয়াত এখনো যোগ করা হয়নি।');

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            itemCount: data.ayahs.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) return _Header(surah: data);
              return _AyahTile(ayah: data.ayahs[i - 1], index: i - 1);
            },
          );
        },
      ),
    );
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Text(
            text,
            style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.surah});

  final SurahModel surah;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h, top: 8.h),
      child: Column(
        children: [
          Text(
            surah.arabicName,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 30.sp,
              color: AppColors.primary,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 8.h),
          Text(
            surah.isPassage
                ? surah.passageNote
                : '${surah.transliteration} · ${surah.verseCount} আয়াত · ${surah.revelationBangla}',
            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AyahTile extends StatelessWidget {
  const _AyahTile({required this.ayah, required this.index});

  final AyahModel ayah;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: index.isEven
            ? AppColors.primary.withValues(alpha: 0.04)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${ayah.number}',
                  style: TextStyle(color: Colors.white, fontSize: 11.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            ayah.arabic,
            style: TextStyle(fontFamily: 'Amiri', fontSize: 22.sp, height: 2),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          if (ayah.transliteration.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              ayah.transliteration,
              style: TextStyle(
                fontSize: 13.sp,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          SizedBox(height: 10.h),
          Text(
            ayah.bangla,
            style: TextStyle(fontSize: 14.sp, height: 1.7),
          ),
        ],
      ),
    );
  }
}
