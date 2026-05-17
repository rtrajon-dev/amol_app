import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/dua_model.dart';
import '../viewmodel/dua_viewmodel.dart';
import '../widgets/dua_card.dart';
import '../widgets/dua_category_chip.dart';

class DuaScreen extends ConsumerWidget {
  const DuaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final duas = ref.watch(duaListProvider(selectedCategory));

    return Scaffold(
      appBar: AppBar(title: const Text('দোয়া সমূহ')),
      body: Column(
        children: [
          SizedBox(
            height: 50.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: [
                DuaCategoryChip(label: 'সব', isSelected: selectedCategory == null, onTap: () => ref.read(selectedCategoryProvider.notifier).state = null),
                ...DuaCategory.values.map((c) => DuaCategoryChip(
                      label: c.banglaName,
                      isSelected: selectedCategory == c,
                      onTap: () => ref.read(selectedCategoryProvider.notifier).state = c,
                    )),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: duas.length,
              itemBuilder: (_, i) => DuaCard(
                dua: duas[i],
                onTap: () => context.go('/dua/${duas[i].id}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
