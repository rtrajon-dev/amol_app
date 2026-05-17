import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/ramadan_model.dart';

class RamadanScreen extends StatelessWidget {
  const RamadanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('রমজান স্পেশাল')),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _buildSehriIftarCard(),
          SizedBox(height: 16.h),
          _buildRamadanAmalList(),
        ],
      ),
    );
  }

  Widget _buildSehriIftarCard() {
    return Card(
      color: AppColors.primaryDark,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.nightlight, color: Colors.white70, size: 28),
                  SizedBox(height: 6.h),
                  Text('সেহরি', style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
                  Text('৪:১৫ AM', style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(width: 1, height: 60.h, color: Colors.white30),
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.wb_twilight, color: Colors.white70, size: 28),
                  SizedBox(height: 6.h),
                  Text('ইফতার', style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
                  Text('৬:৪৫ PM', style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRamadanAmalList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('রমজানের আমল', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 12.h),
        ...RamadanAmalItem.defaultList.map((item) => CheckboxListTile(
              title: Text(item.title, style: TextStyle(fontSize: 14.sp)),
              value: item.isCompleted,
              activeColor: AppColors.primary,
              onChanged: (_) {/* TODO: toggle */},
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )),
        // TODO: wire to state management
      ],
    );
  }
}
