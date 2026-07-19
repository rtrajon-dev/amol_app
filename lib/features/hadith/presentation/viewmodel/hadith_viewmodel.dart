import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/services/content_service.dart';
import '../../domain/models/hadith_model.dart';

/// Hadiths bundled with the app.
///
/// Currently EMPTY by design: no verified, permissively-licensed Bangla hadith
/// source has been chosen yet (see docs/CONTENT.md). The loader and schema are
/// in place, so filling `hadiths.json` is the only remaining step.
///
/// Entries without full attribution are dropped rather than displayed —
/// showing unattributed text as a hadith is worse than showing nothing.
final hadithListProvider = FutureProvider<List<HadithModel>>((ref) async {
  final rows = await ContentService.instance.loadList(ContentFiles.hadiths);
  return rows
      .map(HadithModel.fromJson)
      .where((h) => h.isAttributed)
      .toList();
});

/// Hadith of the day — a stable daily rotation, not a random pick, so every
/// user sees the same one and it does not change on rebuild.
final dailyHadithProvider = FutureProvider<HadithModel?>((ref) async {
  final all = await ref.watch(hadithListProvider.future);
  if (all.isEmpty) return null;

  final now = DateTime.now();
  final dayNumber = DateTime(now.year, now.month, now.day)
      .difference(DateTime(2024, 1, 1))
      .inDays;

  return all[dayNumber.abs() % all.length];
});
