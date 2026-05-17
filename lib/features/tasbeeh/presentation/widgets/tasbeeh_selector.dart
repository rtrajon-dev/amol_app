import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/tasbeeh_model.dart';

class TasbeehSelector extends StatelessWidget {
  const TasbeehSelector({super.key, required this.presets, required this.selected, required this.onSelect});

  final List<TasbeehModel> presets;
  final TasbeehModel selected;
  final ValueChanged<TasbeehModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: presets.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final item = presets[i];
          final isSelected = item.bangla == selected.bangla;
          return ChoiceChip(
            label: Text(item.bangla, style: TextStyle(fontSize: 12.sp)),
            selected: isSelected,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: isSelected ? Colors.white : null),
            onSelected: (_) => onSelect(item),
          );
        },
      ),
    );
  }
}
