import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/services/content_service.dart';
import '../../domain/models/surah_model.dart';

/// All bundled surahs and passages, in the order they appear in the JSON.
final surahListProvider = FutureProvider<List<SurahModel>>((ref) async {
  final rows = await ContentService.instance.loadList(ContentFiles.surahs);
  return rows.map(SurahModel.fromJson).toList();
});

/// A single surah by its `number`. Returns null when absent, so the detail
/// screen can show a proper message instead of crashing on a bad deep link.
final surahByNumberProvider =
    FutureProvider.family<SurahModel?, int>((ref, number) async {
  final all = await ref.watch(surahListProvider.future);
  for (final surah in all) {
    if (surah.number == number) return surah;
  }
  return null;
});
