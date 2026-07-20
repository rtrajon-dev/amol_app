// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AmalLogsTable extends AmalLogs
    with TableInfo<$AmalLogsTable, AmalLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AmalLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _amalIdMeta = const VerificationMeta('amalId');
  @override
  late final GeneratedColumn<String> amalId = GeneratedColumn<String>(
    'amal_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, amalId, dayKey, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'amal_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AmalLogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amal_id')) {
      context.handle(
        _amalIdMeta,
        amalId.isAcceptableOrUnknown(data['amal_id']!, _amalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_amalIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {amalId, dayKey},
  ];
  @override
  AmalLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AmalLogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amal_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $AmalLogsTable createAlias(String alias) {
    return $AmalLogsTable(attachedDatabase, alias);
  }
}

class AmalLogEntry extends DataClass implements Insertable<AmalLogEntry> {
  final int id;

  /// Matches `AmalItemModel.id` (`fajr`, `quran`, …).
  final String amalId;

  /// Local calendar day, `YYYY-MM-DD`. Stored as text, not a timestamp: the
  /// user's "today" is a local-calendar concept, and a UTC instant would put
  /// an evening amal on the wrong day for any user east of Greenwich.
  final String dayKey;
  final DateTime completedAt;
  const AmalLogEntry({
    required this.id,
    required this.amalId,
    required this.dayKey,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amal_id'] = Variable<String>(amalId);
    map['day_key'] = Variable<String>(dayKey);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  AmalLogsCompanion toCompanion(bool nullToAbsent) {
    return AmalLogsCompanion(
      id: Value(id),
      amalId: Value(amalId),
      dayKey: Value(dayKey),
      completedAt: Value(completedAt),
    );
  }

  factory AmalLogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AmalLogEntry(
      id: serializer.fromJson<int>(json['id']),
      amalId: serializer.fromJson<String>(json['amalId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amalId': serializer.toJson<String>(amalId),
      'dayKey': serializer.toJson<String>(dayKey),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  AmalLogEntry copyWith({
    int? id,
    String? amalId,
    String? dayKey,
    DateTime? completedAt,
  }) => AmalLogEntry(
    id: id ?? this.id,
    amalId: amalId ?? this.amalId,
    dayKey: dayKey ?? this.dayKey,
    completedAt: completedAt ?? this.completedAt,
  );
  AmalLogEntry copyWithCompanion(AmalLogsCompanion data) {
    return AmalLogEntry(
      id: data.id.present ? data.id.value : this.id,
      amalId: data.amalId.present ? data.amalId.value : this.amalId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AmalLogEntry(')
          ..write('id: $id, ')
          ..write('amalId: $amalId, ')
          ..write('dayKey: $dayKey, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, amalId, dayKey, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AmalLogEntry &&
          other.id == this.id &&
          other.amalId == this.amalId &&
          other.dayKey == this.dayKey &&
          other.completedAt == this.completedAt);
}

class AmalLogsCompanion extends UpdateCompanion<AmalLogEntry> {
  final Value<int> id;
  final Value<String> amalId;
  final Value<String> dayKey;
  final Value<DateTime> completedAt;
  const AmalLogsCompanion({
    this.id = const Value.absent(),
    this.amalId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  AmalLogsCompanion.insert({
    this.id = const Value.absent(),
    required String amalId,
    required String dayKey,
    required DateTime completedAt,
  }) : amalId = Value(amalId),
       dayKey = Value(dayKey),
       completedAt = Value(completedAt);
  static Insertable<AmalLogEntry> custom({
    Expression<int>? id,
    Expression<String>? amalId,
    Expression<String>? dayKey,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amalId != null) 'amal_id': amalId,
      if (dayKey != null) 'day_key': dayKey,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  AmalLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? amalId,
    Value<String>? dayKey,
    Value<DateTime>? completedAt,
  }) {
    return AmalLogsCompanion(
      id: id ?? this.id,
      amalId: amalId ?? this.amalId,
      dayKey: dayKey ?? this.dayKey,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amalId.present) {
      map['amal_id'] = Variable<String>(amalId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AmalLogsCompanion(')
          ..write('id: $id, ')
          ..write('amalId: $amalId, ')
          ..write('dayKey: $dayKey, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $RamadanLogsTable extends RamadanLogs
    with TableInfo<$RamadanLogsTable, RamadanLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RamadanLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, itemId, dayKey, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ramadan_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RamadanLogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {itemId, dayKey},
  ];
  @override
  RamadanLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RamadanLogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $RamadanLogsTable createAlias(String alias) {
    return $RamadanLogsTable(attachedDatabase, alias);
  }
}

class RamadanLogEntry extends DataClass implements Insertable<RamadanLogEntry> {
  final int id;

  /// Matches `RamadanAmalItem.id` (`tarawih`, `laylat_qadr`, …).
  final String itemId;

  /// Local calendar day, `YYYY-MM-DD`, as in [AmalLogs].
  final String dayKey;
  final DateTime completedAt;
  const RamadanLogEntry({
    required this.id,
    required this.itemId,
    required this.dayKey,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<String>(itemId);
    map['day_key'] = Variable<String>(dayKey);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  RamadanLogsCompanion toCompanion(bool nullToAbsent) {
    return RamadanLogsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      dayKey: Value(dayKey),
      completedAt: Value(completedAt),
    );
  }

  factory RamadanLogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RamadanLogEntry(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<String>(itemId),
      'dayKey': serializer.toJson<String>(dayKey),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  RamadanLogEntry copyWith({
    int? id,
    String? itemId,
    String? dayKey,
    DateTime? completedAt,
  }) => RamadanLogEntry(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    dayKey: dayKey ?? this.dayKey,
    completedAt: completedAt ?? this.completedAt,
  );
  RamadanLogEntry copyWithCompanion(RamadanLogsCompanion data) {
    return RamadanLogEntry(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RamadanLogEntry(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('dayKey: $dayKey, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, dayKey, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RamadanLogEntry &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.dayKey == this.dayKey &&
          other.completedAt == this.completedAt);
}

class RamadanLogsCompanion extends UpdateCompanion<RamadanLogEntry> {
  final Value<int> id;
  final Value<String> itemId;
  final Value<String> dayKey;
  final Value<DateTime> completedAt;
  const RamadanLogsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  RamadanLogsCompanion.insert({
    this.id = const Value.absent(),
    required String itemId,
    required String dayKey,
    required DateTime completedAt,
  }) : itemId = Value(itemId),
       dayKey = Value(dayKey),
       completedAt = Value(completedAt);
  static Insertable<RamadanLogEntry> custom({
    Expression<int>? id,
    Expression<String>? itemId,
    Expression<String>? dayKey,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (dayKey != null) 'day_key': dayKey,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  RamadanLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? itemId,
    Value<String>? dayKey,
    Value<DateTime>? completedAt,
  }) {
    return RamadanLogsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      dayKey: dayKey ?? this.dayKey,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RamadanLogsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('dayKey: $dayKey, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $TasbeehSessionsTable extends TasbeehSessions
    with TableInfo<$TasbeehSessionsTable, TasbeehSessionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasbeehSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tasbeehIdMeta = const VerificationMeta(
    'tasbeehId',
  );
  @override
  late final GeneratedColumn<String> tasbeehId = GeneratedColumn<String>(
    'tasbeeh_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tasbeehId,
    dayKey,
    count,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasbeeh_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TasbeehSessionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tasbeeh_id')) {
      context.handle(
        _tasbeehIdMeta,
        tasbeehId.isAcceptableOrUnknown(data['tasbeeh_id']!, _tasbeehIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tasbeehIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TasbeehSessionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TasbeehSessionEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tasbeehId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tasbeeh_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $TasbeehSessionsTable createAlias(String alias) {
    return $TasbeehSessionsTable(attachedDatabase, alias);
  }
}

class TasbeehSessionEntry extends DataClass
    implements Insertable<TasbeehSessionEntry> {
  final int id;

  /// Matches `TasbeehModel.id` (`subhanallah`, `alhamdulillah`, …).
  final String tasbeehId;
  final String dayKey;

  /// Recitations in this cycle — the tasbeeh's target at the time it completed.
  final int count;
  final DateTime recordedAt;
  const TasbeehSessionEntry({
    required this.id,
    required this.tasbeehId,
    required this.dayKey,
    required this.count,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tasbeeh_id'] = Variable<String>(tasbeehId);
    map['day_key'] = Variable<String>(dayKey);
    map['count'] = Variable<int>(count);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  TasbeehSessionsCompanion toCompanion(bool nullToAbsent) {
    return TasbeehSessionsCompanion(
      id: Value(id),
      tasbeehId: Value(tasbeehId),
      dayKey: Value(dayKey),
      count: Value(count),
      recordedAt: Value(recordedAt),
    );
  }

  factory TasbeehSessionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TasbeehSessionEntry(
      id: serializer.fromJson<int>(json['id']),
      tasbeehId: serializer.fromJson<String>(json['tasbeehId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      count: serializer.fromJson<int>(json['count']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tasbeehId': serializer.toJson<String>(tasbeehId),
      'dayKey': serializer.toJson<String>(dayKey),
      'count': serializer.toJson<int>(count),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  TasbeehSessionEntry copyWith({
    int? id,
    String? tasbeehId,
    String? dayKey,
    int? count,
    DateTime? recordedAt,
  }) => TasbeehSessionEntry(
    id: id ?? this.id,
    tasbeehId: tasbeehId ?? this.tasbeehId,
    dayKey: dayKey ?? this.dayKey,
    count: count ?? this.count,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  TasbeehSessionEntry copyWithCompanion(TasbeehSessionsCompanion data) {
    return TasbeehSessionEntry(
      id: data.id.present ? data.id.value : this.id,
      tasbeehId: data.tasbeehId.present ? data.tasbeehId.value : this.tasbeehId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      count: data.count.present ? data.count.value : this.count,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TasbeehSessionEntry(')
          ..write('id: $id, ')
          ..write('tasbeehId: $tasbeehId, ')
          ..write('dayKey: $dayKey, ')
          ..write('count: $count, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tasbeehId, dayKey, count, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TasbeehSessionEntry &&
          other.id == this.id &&
          other.tasbeehId == this.tasbeehId &&
          other.dayKey == this.dayKey &&
          other.count == this.count &&
          other.recordedAt == this.recordedAt);
}

class TasbeehSessionsCompanion extends UpdateCompanion<TasbeehSessionEntry> {
  final Value<int> id;
  final Value<String> tasbeehId;
  final Value<String> dayKey;
  final Value<int> count;
  final Value<DateTime> recordedAt;
  const TasbeehSessionsCompanion({
    this.id = const Value.absent(),
    this.tasbeehId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.count = const Value.absent(),
    this.recordedAt = const Value.absent(),
  });
  TasbeehSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String tasbeehId,
    required String dayKey,
    required int count,
    required DateTime recordedAt,
  }) : tasbeehId = Value(tasbeehId),
       dayKey = Value(dayKey),
       count = Value(count),
       recordedAt = Value(recordedAt);
  static Insertable<TasbeehSessionEntry> custom({
    Expression<int>? id,
    Expression<String>? tasbeehId,
    Expression<String>? dayKey,
    Expression<int>? count,
    Expression<DateTime>? recordedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tasbeehId != null) 'tasbeeh_id': tasbeehId,
      if (dayKey != null) 'day_key': dayKey,
      if (count != null) 'count': count,
      if (recordedAt != null) 'recorded_at': recordedAt,
    });
  }

  TasbeehSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? tasbeehId,
    Value<String>? dayKey,
    Value<int>? count,
    Value<DateTime>? recordedAt,
  }) {
    return TasbeehSessionsCompanion(
      id: id ?? this.id,
      tasbeehId: tasbeehId ?? this.tasbeehId,
      dayKey: dayKey ?? this.dayKey,
      count: count ?? this.count,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tasbeehId.present) {
      map['tasbeeh_id'] = Variable<String>(tasbeehId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasbeehSessionsCompanion(')
          ..write('id: $id, ')
          ..write('tasbeehId: $tasbeehId, ')
          ..write('dayKey: $dayKey, ')
          ..write('count: $count, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AmalLogsTable amalLogs = $AmalLogsTable(this);
  late final $RamadanLogsTable ramadanLogs = $RamadanLogsTable(this);
  late final $TasbeehSessionsTable tasbeehSessions = $TasbeehSessionsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    amalLogs,
    ramadanLogs,
    tasbeehSessions,
  ];
}

typedef $$AmalLogsTableCreateCompanionBuilder =
    AmalLogsCompanion Function({
      Value<int> id,
      required String amalId,
      required String dayKey,
      required DateTime completedAt,
    });
typedef $$AmalLogsTableUpdateCompanionBuilder =
    AmalLogsCompanion Function({
      Value<int> id,
      Value<String> amalId,
      Value<String> dayKey,
      Value<DateTime> completedAt,
    });

class $$AmalLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AmalLogsTable> {
  $$AmalLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amalId => $composableBuilder(
    column: $table.amalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AmalLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AmalLogsTable> {
  $$AmalLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amalId => $composableBuilder(
    column: $table.amalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AmalLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AmalLogsTable> {
  $$AmalLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get amalId =>
      $composableBuilder(column: $table.amalId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$AmalLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AmalLogsTable,
          AmalLogEntry,
          $$AmalLogsTableFilterComposer,
          $$AmalLogsTableOrderingComposer,
          $$AmalLogsTableAnnotationComposer,
          $$AmalLogsTableCreateCompanionBuilder,
          $$AmalLogsTableUpdateCompanionBuilder,
          (
            AmalLogEntry,
            BaseReferences<_$AppDatabase, $AmalLogsTable, AmalLogEntry>,
          ),
          AmalLogEntry,
          PrefetchHooks Function()
        > {
  $$AmalLogsTableTableManager(_$AppDatabase db, $AmalLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AmalLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AmalLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AmalLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> amalId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
              }) => AmalLogsCompanion(
                id: id,
                amalId: amalId,
                dayKey: dayKey,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String amalId,
                required String dayKey,
                required DateTime completedAt,
              }) => AmalLogsCompanion.insert(
                id: id,
                amalId: amalId,
                dayKey: dayKey,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AmalLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AmalLogsTable,
      AmalLogEntry,
      $$AmalLogsTableFilterComposer,
      $$AmalLogsTableOrderingComposer,
      $$AmalLogsTableAnnotationComposer,
      $$AmalLogsTableCreateCompanionBuilder,
      $$AmalLogsTableUpdateCompanionBuilder,
      (
        AmalLogEntry,
        BaseReferences<_$AppDatabase, $AmalLogsTable, AmalLogEntry>,
      ),
      AmalLogEntry,
      PrefetchHooks Function()
    >;
typedef $$RamadanLogsTableCreateCompanionBuilder =
    RamadanLogsCompanion Function({
      Value<int> id,
      required String itemId,
      required String dayKey,
      required DateTime completedAt,
    });
typedef $$RamadanLogsTableUpdateCompanionBuilder =
    RamadanLogsCompanion Function({
      Value<int> id,
      Value<String> itemId,
      Value<String> dayKey,
      Value<DateTime> completedAt,
    });

class $$RamadanLogsTableFilterComposer
    extends Composer<_$AppDatabase, $RamadanLogsTable> {
  $$RamadanLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RamadanLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $RamadanLogsTable> {
  $$RamadanLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RamadanLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RamadanLogsTable> {
  $$RamadanLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$RamadanLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RamadanLogsTable,
          RamadanLogEntry,
          $$RamadanLogsTableFilterComposer,
          $$RamadanLogsTableOrderingComposer,
          $$RamadanLogsTableAnnotationComposer,
          $$RamadanLogsTableCreateCompanionBuilder,
          $$RamadanLogsTableUpdateCompanionBuilder,
          (
            RamadanLogEntry,
            BaseReferences<_$AppDatabase, $RamadanLogsTable, RamadanLogEntry>,
          ),
          RamadanLogEntry,
          PrefetchHooks Function()
        > {
  $$RamadanLogsTableTableManager(_$AppDatabase db, $RamadanLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RamadanLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RamadanLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RamadanLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
              }) => RamadanLogsCompanion(
                id: id,
                itemId: itemId,
                dayKey: dayKey,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemId,
                required String dayKey,
                required DateTime completedAt,
              }) => RamadanLogsCompanion.insert(
                id: id,
                itemId: itemId,
                dayKey: dayKey,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RamadanLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RamadanLogsTable,
      RamadanLogEntry,
      $$RamadanLogsTableFilterComposer,
      $$RamadanLogsTableOrderingComposer,
      $$RamadanLogsTableAnnotationComposer,
      $$RamadanLogsTableCreateCompanionBuilder,
      $$RamadanLogsTableUpdateCompanionBuilder,
      (
        RamadanLogEntry,
        BaseReferences<_$AppDatabase, $RamadanLogsTable, RamadanLogEntry>,
      ),
      RamadanLogEntry,
      PrefetchHooks Function()
    >;
typedef $$TasbeehSessionsTableCreateCompanionBuilder =
    TasbeehSessionsCompanion Function({
      Value<int> id,
      required String tasbeehId,
      required String dayKey,
      required int count,
      required DateTime recordedAt,
    });
typedef $$TasbeehSessionsTableUpdateCompanionBuilder =
    TasbeehSessionsCompanion Function({
      Value<int> id,
      Value<String> tasbeehId,
      Value<String> dayKey,
      Value<int> count,
      Value<DateTime> recordedAt,
    });

class $$TasbeehSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $TasbeehSessionsTable> {
  $$TasbeehSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tasbeehId => $composableBuilder(
    column: $table.tasbeehId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasbeehSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TasbeehSessionsTable> {
  $$TasbeehSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tasbeehId => $composableBuilder(
    column: $table.tasbeehId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasbeehSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasbeehSessionsTable> {
  $$TasbeehSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tasbeehId =>
      $composableBuilder(column: $table.tasbeehId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );
}

class $$TasbeehSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasbeehSessionsTable,
          TasbeehSessionEntry,
          $$TasbeehSessionsTableFilterComposer,
          $$TasbeehSessionsTableOrderingComposer,
          $$TasbeehSessionsTableAnnotationComposer,
          $$TasbeehSessionsTableCreateCompanionBuilder,
          $$TasbeehSessionsTableUpdateCompanionBuilder,
          (
            TasbeehSessionEntry,
            BaseReferences<
              _$AppDatabase,
              $TasbeehSessionsTable,
              TasbeehSessionEntry
            >,
          ),
          TasbeehSessionEntry,
          PrefetchHooks Function()
        > {
  $$TasbeehSessionsTableTableManager(
    _$AppDatabase db,
    $TasbeehSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasbeehSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasbeehSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasbeehSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tasbeehId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
              }) => TasbeehSessionsCompanion(
                id: id,
                tasbeehId: tasbeehId,
                dayKey: dayKey,
                count: count,
                recordedAt: recordedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tasbeehId,
                required String dayKey,
                required int count,
                required DateTime recordedAt,
              }) => TasbeehSessionsCompanion.insert(
                id: id,
                tasbeehId: tasbeehId,
                dayKey: dayKey,
                count: count,
                recordedAt: recordedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasbeehSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasbeehSessionsTable,
      TasbeehSessionEntry,
      $$TasbeehSessionsTableFilterComposer,
      $$TasbeehSessionsTableOrderingComposer,
      $$TasbeehSessionsTableAnnotationComposer,
      $$TasbeehSessionsTableCreateCompanionBuilder,
      $$TasbeehSessionsTableUpdateCompanionBuilder,
      (
        TasbeehSessionEntry,
        BaseReferences<
          _$AppDatabase,
          $TasbeehSessionsTable,
          TasbeehSessionEntry
        >,
      ),
      TasbeehSessionEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AmalLogsTableTableManager get amalLogs =>
      $$AmalLogsTableTableManager(_db, _db.amalLogs);
  $$RamadanLogsTableTableManager get ramadanLogs =>
      $$RamadanLogsTableTableManager(_db, _db.ramadanLogs);
  $$TasbeehSessionsTableTableManager get tasbeehSessions =>
      $$TasbeehSessionsTableTableManager(_db, _db.tasbeehSessions);
}
