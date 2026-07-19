import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/services/content_service.dart';
import '../../domain/models/allah_name_model.dart';

/// Loads the 99 names from bundled JSON (FR-C-01 — no network involved).
final namesOfAllahProvider = FutureProvider<List<AllahNameModel>>((ref) async {
  final rows = await ContentService.instance.loadList(ContentFiles.namesOfAllah);
  return rows.map(AllahNameModel.fromJson).toList()
    ..sort((a, b) => a.number.compareTo(b.number));
});
