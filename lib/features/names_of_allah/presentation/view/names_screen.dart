import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/loading_indicator.dart';
import '../../domain/models/allah_name_model.dart';
import '../viewmodel/names_viewmodel.dart';

class NamesScreen extends ConsumerWidget {
  const NamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = ref.watch(namesOfAllahProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('আল্লাহর ৯৯ নাম')),
      body: names.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (_, _) => _Message(
          emoji: '⚠️',
          text: 'নামসমূহ লোড করা যায়নি।',
        ),
        data: (items) {
          if (items.isEmpty) {
            return _Message(emoji: '📄', text: 'কোনো তথ্য পাওয়া যায়নি।');
          }
          return GridView.builder(
            padding: EdgeInsets.all(16.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1.1,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _NameCard(
              name: items[i],
              onTap: () => _showDetail(context, items[i]),
            ),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, AllahNameModel name) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name.arabic,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 34.sp,
                color: AppColors.primary,
                height: 1.8,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 12.h),
            Text(
              name.transliteration,
              style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 16.h),
            Text(
              name.bangla,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              name.meaning,
              style: TextStyle(fontSize: 15.sp, height: 1.6, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  const _NameCard({required this.name, required this.onTap});

  final AllahNameModel name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${name.number}',
                style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
              ),
              SizedBox(height: 4.h),
              Flexible(
                child: FittedBox(
                  child: Text(
                    name.arabic,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 24.sp,
                      color: AppColors.primary,
                      height: 1.7,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                name.bangla,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 44.sp)),
            SizedBox(height: 16.h),
            Text(
              text,
              style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
