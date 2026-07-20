import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// A completed amal, one row per (amal, day).
///
/// Un-checking an item deletes its row rather than storing `completed: false`
/// — absence is the only representation of "not done", so a day can never hold
/// two contradictory answers for the same amal.
@DataClassName('AmalLogEntry')
class AmalLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Matches `AmalItemModel.id` (`fajr`, `quran`, …).
  TextColumn get amalId => text().withLength(min: 1, max: 64)();

  /// Local calendar day, `YYYY-MM-DD`. Stored as text, not a timestamp: the
  /// user's "today" is a local-calendar concept, and a UTC instant would put
  /// an evening amal on the wrong day for any user east of Greenwich.
  TextColumn get dayKey => text().withLength(min: 10, max: 10)();

  DateTimeColumn get completedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {amalId, dayKey},
      ];
}

/// One row per completed tasbeeh cycle (count reaching its target).
@DataClassName('TasbeehSessionEntry')
class TasbeehSessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Matches `TasbeehModel.id` (`subhanallah`, `alhamdulillah`, …).
  TextColumn get tasbeehId => text().withLength(min: 1, max: 64)();

  TextColumn get dayKey => text().withLength(min: 10, max: 10)();

  /// Recitations in this cycle — the tasbeeh's target at the time it completed.
  IntColumn get count => integer()();

  DateTimeColumn get recordedAt => dateTime()();
}

/// Device-local store for user-generated data (amal history, tasbeeh counts).
///
/// Deliberately never synced to the server. This data is single-user and
/// single-device, so keeping it here costs nothing, works with no network,
/// and keeps the app usable while signed out.
///
/// Bundled reference content (surahs, names, cities) does NOT belong here —
/// that ships as JSON assets and is refreshed from the content manifest.
@DriftDatabase(tables: [AmalLogs, TasbeehSessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'amol365'));

  @override
  int get schemaVersion => 1;

  // ------------------------------------------------------------------ amal

  /// The amal ids completed on [dayKey].
  Future<Set<String>> completedAmalIds(String dayKey) async {
    final rows = await (select(amalLogs)..where((t) => t.dayKey.equals(dayKey)))
        .get();
    return rows.map((r) => r.amalId).toSet();
  }

  /// Emits the completed amal ids for [dayKey] and again on every change.
  Stream<Set<String>> watchCompletedAmalIds(String dayKey) {
    return (select(amalLogs)..where((t) => t.dayKey.equals(dayKey)))
        .watch()
        .map((rows) => rows.map((r) => r.amalId).toSet());
  }

  Future<void> markAmalCompleted({
    required String amalId,
    required String dayKey,
    required DateTime completedAt,
  }) {
    return into(amalLogs).insert(
      AmalLogsCompanion.insert(
        amalId: amalId,
        dayKey: dayKey,
        completedAt: completedAt,
      ),
      // Re-checking an already-checked item is a no-op, not a crash on the
      // (amalId, dayKey) unique key.
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> clearAmalCompleted({
    required String amalId,
    required String dayKey,
  }) {
    return (delete(amalLogs)
          ..where((t) => t.amalId.equals(amalId) & t.dayKey.equals(dayKey)))
        .go();
  }

  /// Consecutive days, ending today, on which at least one amal was completed.
  ///
  /// Derived from the rows rather than stored as a counter: a stored streak
  /// drifts wrong the first time the app is killed mid-update or the device
  /// changes timezone, and there is no way to detect that it has.
  ///
  /// Today counts if it has any amal, but its absence does not break the
  /// streak — a user checking in at 9pm has not yet lost yesterday's run.
  Future<int> currentStreak(DateTime now) async {
    final query = selectOnly(amalLogs, distinct: true)
      ..addColumns([amalLogs.dayKey])
      ..orderBy([OrderingTerm.desc(amalLogs.dayKey)]);

    final days = (await query.map((r) => r.read(amalLogs.dayKey)!).get()).toSet();
    if (days.isEmpty) return 0;

    final today = DateTime(now.year, now.month, now.day);

    // Anchor on today when it has activity, otherwise on yesterday.
    var cursor = today;
    if (!days.contains(dayKeyFor(cursor))) {
      cursor = today.subtract(const Duration(days: 1));
      if (!days.contains(dayKeyFor(cursor))) return 0;
    }

    var streak = 0;
    while (days.contains(dayKeyFor(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // --------------------------------------------------------------- tasbeeh

  Future<void> recordTasbeehCycle({
    required String tasbeehId,
    required String dayKey,
    required int count,
    required DateTime recordedAt,
  }) {
    return into(tasbeehSessions).insert(
      TasbeehSessionsCompanion.insert(
        tasbeehId: tasbeehId,
        dayKey: dayKey,
        count: count,
        recordedAt: recordedAt,
      ),
    );
  }

  /// Total recitations recorded on [dayKey], across every tasbeeh.
  Future<int> tasbeehTotalForDay(String dayKey) async {
    final total = tasbeehSessions.count.sum();
    final query = selectOnly(tasbeehSessions)
      ..addColumns([total])
      ..where(tasbeehSessions.dayKey.equals(dayKey));

    final row = await query.getSingleOrNull();
    return row?.read(total) ?? 0;
  }
}

/// The local-calendar day key (`YYYY-MM-DD`) for [date].
String dayKeyFor(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}
