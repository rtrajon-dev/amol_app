import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/services/storage_service.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../global_widgets/loading_indicator.dart';
import '../viewmodel/city_viewmodel.dart';
import '../viewmodel/prayer_time_viewmodel.dart';

/// FR-N-01 / FR-N-05 / FR-N-06 — location selection.
///
/// This is the other half of the G-06 fix: the prayer-time screen can now warn
/// that it is guessing, and this is where the user does something about it.
class CitySelectorScreen extends ConsumerStatefulWidget {
  const CitySelectorScreen({super.key});

  @override
  ConsumerState<CitySelectorScreen> createState() => _CitySelectorScreenState();
}

class _CitySelectorScreenState extends ConsumerState<CitySelectorScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(cityListProvider);
    final location = ref.watch(resolvedLocationProvider).value;
    final isAuto =
        StorageService.instance.getString(StorageKeys.locationSource) != 'manual';

    return Scaffold(
      appBar: AppBar(
        title: const Text('শহর নির্বাচন'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'কোঅর্ডিনেট দিয়ে',
            onPressed: _showCoordinateEntry,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            child: Column(
              children: [
                Card(
                  child: RadioListTile<bool>(
                    title: Text('স্বয়ংক্রিয় (জিপিএস)', style: TextStyle(fontSize: 15.sp)),
                    subtitle: Text(
                      'আপনার অবস্থান অনুযায়ী সময়',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    value: true,
                    // ignore: deprecated_member_use
                    groupValue: isAuto,
                    // ignore: deprecated_member_use
                    onChanged: (_) async {
                      await ref.read(locationSettingsProvider).useAutomatic();
                      if (mounted) setState(() {});
                    },
                  ),
                ),
                if (!isAuto && location != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16.sp, color: AppColors.success),
                        SizedBox(width: 6.w),
                        Text(
                          'নির্বাচিত: ${location.name}',
                          style: TextStyle(fontSize: 13.sp, color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'জেলা খুঁজুন (বাংলা বা English)',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: citiesAsync.when(
              loading: () => const LoadingIndicator(),
              error: (_, _) => Center(
                child: Text(
                  'শহরের তালিকা লোড করা যায়নি।',
                  style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
                ),
              ),
              data: (cities) {
                // Rank so an exact city match leads, with division-only
                // matches after it (see CityModel.matchRank).
                final filtered = cities
                    .where((c) => c.matches(_query))
                    .toList()
                  ..sort((a, b) {
                    final rank = (a.matchRank(_query) ?? 99)
                        .compareTo(b.matchRank(_query) ?? 99);
                    return rank != 0 ? rank : a.bangla.compareTo(b.bangla);
                  });

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.w),
                      child: Text(
                        'কোনো জেলা পাওয়া যায়নি।\nবাংলাদেশের বাইরে হলে উপরের 📍 আইকন থেকে '
                        'কোঅর্ডিনেট দিন।',
                        style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary, height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final city = filtered[i];
                    final isSelected = !isAuto && location?.name == city.bangla;

                    return Card(
                      margin: EdgeInsets.only(bottom: 8.h),
                      child: ListTile(
                        leading: Icon(
                          isSelected ? Icons.location_on : Icons.location_city_outlined,
                          color: isSelected ? AppColors.success : AppColors.primary,
                        ),
                        title: Text(city.bangla, style: TextStyle(fontSize: 15.sp)),
                        subtitle: Text(
                          '${city.english} · ${city.division}',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: AppColors.success, size: 20.sp)
                            : null,
                        onTap: () async {
                          await ref.read(locationSettingsProvider).selectCity(city);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${city.bangla} নির্বাচন করা হয়েছে'),
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// FR-N-06 — coordinate entry, for users outside Bangladesh.
  Future<void> _showCoordinateEntry() async {
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final nameController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('কোঅর্ডিনেট দিন'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'স্থানের নাম'),
              ),
              TextField(
                controller: latController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'অক্ষাংশ (latitude)',
                  hintText: '-90 থেকে 90',
                ),
              ),
              TextField(
                controller: lngController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'দ্রাঘিমাংশ (longitude)',
                  hintText: '-180 থেকে 180',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('সংরক্ষণ'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    final lat = double.tryParse(latController.text.trim());
    final lng = double.tryParse(lngController.text.trim());

    if (lat == null || lng == null) {
      _snack('সঠিক সংখ্যা দিন।');
      return;
    }

    final ok = await ref.read(locationSettingsProvider).selectCoordinates(
          latitude: lat,
          longitude: lng,
          name: nameController.text,
        );

    if (!mounted) return;
    if (!ok) {
      _snack('কোঅর্ডিনেট সঠিক নয়। অক্ষাংশ −৯০..৯০, দ্রাঘিমাংশ −১৮০..১৮০।');
      return;
    }

    setState(() {});
    _snack('অবস্থান সংরক্ষণ করা হয়েছে।');
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}
