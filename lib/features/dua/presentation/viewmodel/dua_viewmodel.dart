import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/dua_model.dart';

class SelectedCategoryNotifier extends Notifier<DuaCategory?> {
  @override
  DuaCategory? build() => null;

  void select(DuaCategory? category) => state = category;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, DuaCategory?>(
        SelectedCategoryNotifier.new);

final duaListProvider = Provider.family<List<DuaModel>, DuaCategory?>((ref, category) {
  // TODO: load from JSON asset (lib/assets/data/duas.json)
  return _sampleDuas.where((d) => category == null || d.category == category).toList();
});

final _sampleDuas = <DuaModel>[
  const DuaModel(
    id: '1',
    arabic: 'بِسْمِ اللّٰهِ',
    transliteration: 'Bismillah',
    bangla: 'আল্লাহর নামে শুরু করছি',
    source: 'বুখারি',
    category: DuaCategory.food,
  ),
  const DuaModel(
    id: '2',
    arabic: 'اَللّٰهُمَّ أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلّٰهِ',
    transliteration: 'Allahumma asbahna wa asbahal mulku lillah',
    bangla: 'হে আল্লাহ, আমরা সকালে উঠেছি এবং রাজত্ব আল্লাহর জন্য',
    source: 'আবু দাউদ',
    category: DuaCategory.morningAzkar,
  ),
];
