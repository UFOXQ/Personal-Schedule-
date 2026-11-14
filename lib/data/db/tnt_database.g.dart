// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tnt_database.dart';

// ignore_for_file: type=lint
class $BlockTemplatesTable extends BlockTemplates
    with TableInfo<$BlockTemplatesTable, BlockTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlockTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _laneMeta = const VerificationMeta('lane');
  @override
  late final GeneratedColumn<int> lane = GeneratedColumn<int>(
    'lane',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _startMinMeta = const VerificationMeta(
    'startMin',
  );
  @override
  late final GeneratedColumn<int> startMin = GeneratedColumn<int>(
    'start_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deadlineAtMeta = const VerificationMeta(
    'deadlineAt',
  );
  @override
  late final GeneratedColumn<DateTime> deadlineAt = GeneratedColumn<DateTime>(
    'deadline_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    lane,
    priority,
    durationMin,
    startMin,
    deadlineAt,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'block_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlockTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('lane')) {
      context.handle(
        _laneMeta,
        lane.isAcceptableOrUnknown(data['lane']!, _laneMeta),
      );
    } else if (isInserting) {
      context.missing(_laneMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    }
    if (data.containsKey('start_min')) {
      context.handle(
        _startMinMeta,
        startMin.isAcceptableOrUnknown(data['start_min']!, _startMinMeta),
      );
    }
    if (data.containsKey('deadline_at')) {
      context.handle(
        _deadlineAtMeta,
        deadlineAt.isAcceptableOrUnknown(data['deadline_at']!, _deadlineAtMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlockTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlockTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      lane: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lane'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      )!,
      startMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_min'],
      ),
      deadlineAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deadline_at'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $BlockTemplatesTable createAlias(String alias) {
    return $BlockTemplatesTable(attachedDatabase, alias);
  }
}

class BlockTemplate extends DataClass implements Insertable<BlockTemplate> {
  final String id;
  final String title;
  final int lane;
  final int priority;
  final int durationMin;
  final int? startMin;
  final DateTime? deadlineAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const BlockTemplate({
    required this.id,
    required this.title,
    required this.lane,
    required this.priority,
    required this.durationMin,
    this.startMin,
    this.deadlineAt,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['lane'] = Variable<int>(lane);
    map['priority'] = Variable<int>(priority);
    map['duration_min'] = Variable<int>(durationMin);
    if (!nullToAbsent || startMin != null) {
      map['start_min'] = Variable<int>(startMin);
    }
    if (!nullToAbsent || deadlineAt != null) {
      map['deadline_at'] = Variable<DateTime>(deadlineAt);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  BlockTemplatesCompanion toCompanion(bool nullToAbsent) {
    return BlockTemplatesCompanion(
      id: Value(id),
      title: Value(title),
      lane: Value(lane),
      priority: Value(priority),
      durationMin: Value(durationMin),
      startMin: startMin == null && nullToAbsent
          ? const Value.absent()
          : Value(startMin),
      deadlineAt: deadlineAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deadlineAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory BlockTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlockTemplate(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      lane: serializer.fromJson<int>(json['lane']),
      priority: serializer.fromJson<int>(json['priority']),
      durationMin: serializer.fromJson<int>(json['durationMin']),
      startMin: serializer.fromJson<int?>(json['startMin']),
      deadlineAt: serializer.fromJson<DateTime?>(json['deadlineAt']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'lane': serializer.toJson<int>(lane),
      'priority': serializer.toJson<int>(priority),
      'durationMin': serializer.toJson<int>(durationMin),
      'startMin': serializer.toJson<int?>(startMin),
      'deadlineAt': serializer.toJson<DateTime?>(deadlineAt),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  BlockTemplate copyWith({
    String? id,
    String? title,
    int? lane,
    int? priority,
    int? durationMin,
    Value<int?> startMin = const Value.absent(),
    Value<DateTime?> deadlineAt = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => BlockTemplate(
    id: id ?? this.id,
    title: title ?? this.title,
    lane: lane ?? this.lane,
    priority: priority ?? this.priority,
    durationMin: durationMin ?? this.durationMin,
    startMin: startMin.present ? startMin.value : this.startMin,
    deadlineAt: deadlineAt.present ? deadlineAt.value : this.deadlineAt,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  BlockTemplate copyWithCompanion(BlockTemplatesCompanion data) {
    return BlockTemplate(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      lane: data.lane.present ? data.lane.value : this.lane,
      priority: data.priority.present ? data.priority.value : this.priority,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      startMin: data.startMin.present ? data.startMin.value : this.startMin,
      deadlineAt: data.deadlineAt.present
          ? data.deadlineAt.value
          : this.deadlineAt,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlockTemplate(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('lane: $lane, ')
          ..write('priority: $priority, ')
          ..write('durationMin: $durationMin, ')
          ..write('startMin: $startMin, ')
          ..write('deadlineAt: $deadlineAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    lane,
    priority,
    durationMin,
    startMin,
    deadlineAt,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlockTemplate &&
          other.id == this.id &&
          other.title == this.title &&
          other.lane == this.lane &&
          other.priority == this.priority &&
          other.durationMin == this.durationMin &&
          other.startMin == this.startMin &&
          other.deadlineAt == this.deadlineAt &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class BlockTemplatesCompanion extends UpdateCompanion<BlockTemplate> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> lane;
  final Value<int> priority;
  final Value<int> durationMin;
  final Value<int?> startMin;
  final Value<DateTime?> deadlineAt;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const BlockTemplatesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.lane = const Value.absent(),
    this.priority = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.startMin = const Value.absent(),
    this.deadlineAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlockTemplatesCompanion.insert({
    required String id,
    required String title,
    required int lane,
    this.priority = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.startMin = const Value.absent(),
    this.deadlineAt = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       lane = Value(lane),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BlockTemplate> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? lane,
    Expression<int>? priority,
    Expression<int>? durationMin,
    Expression<int>? startMin,
    Expression<DateTime>? deadlineAt,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (lane != null) 'lane': lane,
      if (priority != null) 'priority': priority,
      if (durationMin != null) 'duration_min': durationMin,
      if (startMin != null) 'start_min': startMin,
      if (deadlineAt != null) 'deadline_at': deadlineAt,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BlockTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? lane,
    Value<int>? priority,
    Value<int>? durationMin,
    Value<int?>? startMin,
    Value<DateTime?>? deadlineAt,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return BlockTemplatesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      lane: lane ?? this.lane,
      priority: priority ?? this.priority,
      durationMin: durationMin ?? this.durationMin,
      startMin: startMin ?? this.startMin,
      deadlineAt: deadlineAt ?? this.deadlineAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (lane.present) {
      map['lane'] = Variable<int>(lane.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (startMin.present) {
      map['start_min'] = Variable<int>(startMin.value);
    }
    if (deadlineAt.present) {
      map['deadline_at'] = Variable<DateTime>(deadlineAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlockTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('lane: $lane, ')
          ..write('priority: $priority, ')
          ..write('durationMin: $durationMin, ')
          ..write('startMin: $startMin, ')
          ..write('deadlineAt: $deadlineAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, Collection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Collection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Collection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Collection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }
}

class Collection extends DataClass implements Insertable<Collection> {
  final String id;
  final String name;
  final int? color;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Collection({
    required this.id,
    required this.name,
    this.color,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      id: Value(id),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Collection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Collection(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int?>(json['color']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int?>(color),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Collection copyWith({
    String? id,
    String? name,
    Value<int?> color = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Collection(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Collection copyWithCompanion(CollectionsCompanion data) {
    return Collection(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Collection(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, color, note, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Collection &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CollectionsCompanion extends UpdateCompanion<Collection> {
  final Value<String> id;
  final Value<String> name;
  final Value<int?> color;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionsCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Collection> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int?>? color,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionItemsTable extends CollectionItems
    with TableInfo<$CollectionItemsTable, CollectionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES collections (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _laneMeta = const VerificationMeta('lane');
  @override
  late final GeneratedColumn<int> lane = GeneratedColumn<int>(
    'lane',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinMeta = const VerificationMeta(
    'startMin',
  );
  @override
  late final GeneratedColumn<int> startMin = GeneratedColumn<int>(
    'start_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    collectionId,
    templateId,
    title,
    lane,
    startMin,
    durationMin,
    priority,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('lane')) {
      context.handle(
        _laneMeta,
        lane.isAcceptableOrUnknown(data['lane']!, _laneMeta),
      );
    } else if (isInserting) {
      context.missing(_laneMeta);
    }
    if (data.containsKey('start_min')) {
      context.handle(
        _startMinMeta,
        startMin.isAcceptableOrUnknown(data['start_min']!, _startMinMeta),
      );
    } else if (isInserting) {
      context.missing(_startMinMeta);
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      lane: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lane'],
      )!,
      startMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_min'],
      )!,
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CollectionItemsTable createAlias(String alias) {
    return $CollectionItemsTable(attachedDatabase, alias);
  }
}

class CollectionItem extends DataClass implements Insertable<CollectionItem> {
  final String id;
  final String collectionId;
  final String? templateId;
  final String title;
  final int lane;
  final int startMin;
  final int durationMin;
  final int priority;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CollectionItem({
    required this.id,
    required this.collectionId,
    this.templateId,
    required this.title,
    required this.lane,
    required this.startMin,
    required this.durationMin,
    required this.priority,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['collection_id'] = Variable<String>(collectionId);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    map['title'] = Variable<String>(title);
    map['lane'] = Variable<int>(lane);
    map['start_min'] = Variable<int>(startMin);
    map['duration_min'] = Variable<int>(durationMin);
    map['priority'] = Variable<int>(priority);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CollectionItemsCompanion toCompanion(bool nullToAbsent) {
    return CollectionItemsCompanion(
      id: Value(id),
      collectionId: Value(collectionId),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      title: Value(title),
      lane: Value(lane),
      startMin: Value(startMin),
      durationMin: Value(durationMin),
      priority: Value(priority),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CollectionItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionItem(
      id: serializer.fromJson<String>(json['id']),
      collectionId: serializer.fromJson<String>(json['collectionId']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      title: serializer.fromJson<String>(json['title']),
      lane: serializer.fromJson<int>(json['lane']),
      startMin: serializer.fromJson<int>(json['startMin']),
      durationMin: serializer.fromJson<int>(json['durationMin']),
      priority: serializer.fromJson<int>(json['priority']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'collectionId': serializer.toJson<String>(collectionId),
      'templateId': serializer.toJson<String?>(templateId),
      'title': serializer.toJson<String>(title),
      'lane': serializer.toJson<int>(lane),
      'startMin': serializer.toJson<int>(startMin),
      'durationMin': serializer.toJson<int>(durationMin),
      'priority': serializer.toJson<int>(priority),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CollectionItem copyWith({
    String? id,
    String? collectionId,
    Value<String?> templateId = const Value.absent(),
    String? title,
    int? lane,
    int? startMin,
    int? durationMin,
    int? priority,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CollectionItem(
    id: id ?? this.id,
    collectionId: collectionId ?? this.collectionId,
    templateId: templateId.present ? templateId.value : this.templateId,
    title: title ?? this.title,
    lane: lane ?? this.lane,
    startMin: startMin ?? this.startMin,
    durationMin: durationMin ?? this.durationMin,
    priority: priority ?? this.priority,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CollectionItem copyWithCompanion(CollectionItemsCompanion data) {
    return CollectionItem(
      id: data.id.present ? data.id.value : this.id,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      title: data.title.present ? data.title.value : this.title,
      lane: data.lane.present ? data.lane.value : this.lane,
      startMin: data.startMin.present ? data.startMin.value : this.startMin,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      priority: data.priority.present ? data.priority.value : this.priority,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItem(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('lane: $lane, ')
          ..write('startMin: $startMin, ')
          ..write('durationMin: $durationMin, ')
          ..write('priority: $priority, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    collectionId,
    templateId,
    title,
    lane,
    startMin,
    durationMin,
    priority,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionItem &&
          other.id == this.id &&
          other.collectionId == this.collectionId &&
          other.templateId == this.templateId &&
          other.title == this.title &&
          other.lane == this.lane &&
          other.startMin == this.startMin &&
          other.durationMin == this.durationMin &&
          other.priority == this.priority &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CollectionItemsCompanion extends UpdateCompanion<CollectionItem> {
  final Value<String> id;
  final Value<String> collectionId;
  final Value<String?> templateId;
  final Value<String> title;
  final Value<int> lane;
  final Value<int> startMin;
  final Value<int> durationMin;
  final Value<int> priority;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CollectionItemsCompanion({
    this.id = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.templateId = const Value.absent(),
    this.title = const Value.absent(),
    this.lane = const Value.absent(),
    this.startMin = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.priority = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionItemsCompanion.insert({
    required String id,
    required String collectionId,
    this.templateId = const Value.absent(),
    required String title,
    required int lane,
    required int startMin,
    required int durationMin,
    this.priority = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       collectionId = Value(collectionId),
       title = Value(title),
       lane = Value(lane),
       startMin = Value(startMin),
       durationMin = Value(durationMin),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CollectionItem> custom({
    Expression<String>? id,
    Expression<String>? collectionId,
    Expression<String>? templateId,
    Expression<String>? title,
    Expression<int>? lane,
    Expression<int>? startMin,
    Expression<int>? durationMin,
    Expression<int>? priority,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectionId != null) 'collection_id': collectionId,
      if (templateId != null) 'template_id': templateId,
      if (title != null) 'title': title,
      if (lane != null) 'lane': lane,
      if (startMin != null) 'start_min': startMin,
      if (durationMin != null) 'duration_min': durationMin,
      if (priority != null) 'priority': priority,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? collectionId,
    Value<String?>? templateId,
    Value<String>? title,
    Value<int>? lane,
    Value<int>? startMin,
    Value<int>? durationMin,
    Value<int>? priority,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CollectionItemsCompanion(
      id: id ?? this.id,
      collectionId: collectionId ?? this.collectionId,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      lane: lane ?? this.lane,
      startMin: startMin ?? this.startMin,
      durationMin: durationMin ?? this.durationMin,
      priority: priority ?? this.priority,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (lane.present) {
      map['lane'] = Variable<int>(lane.value);
    }
    if (startMin.present) {
      map['start_min'] = Variable<int>(startMin.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItemsCompanion(')
          ..write('id: $id, ')
          ..write('collectionId: $collectionId, ')
          ..write('templateId: $templateId, ')
          ..write('title: $title, ')
          ..write('lane: $lane, ')
          ..write('startMin: $startMin, ')
          ..write('durationMin: $durationMin, ')
          ..write('priority: $priority, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlansTable extends Plans with TableInfo<$PlansTable, Plan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdaysMaskMeta = const VerificationMeta(
    'weekdaysMask',
  );
  @override
  late final GeneratedColumn<int> weekdaysMask = GeneratedColumn<int>(
    'weekdays_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(127),
  );
  static const VerificationMeta _laneMeta = const VerificationMeta('lane');
  @override
  late final GeneratedColumn<int> lane = GeneratedColumn<int>(
    'lane',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinMeta = const VerificationMeta(
    'startMin',
  );
  @override
  late final GeneratedColumn<int> startMin = GeneratedColumn<int>(
    'start_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    startDate,
    endDate,
    weekdaysMask,
    lane,
    startMin,
    durationMin,
    priority,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Plan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('weekdays_mask')) {
      context.handle(
        _weekdaysMaskMeta,
        weekdaysMask.isAcceptableOrUnknown(
          data['weekdays_mask']!,
          _weekdaysMaskMeta,
        ),
      );
    }
    if (data.containsKey('lane')) {
      context.handle(
        _laneMeta,
        lane.isAcceptableOrUnknown(data['lane']!, _laneMeta),
      );
    } else if (isInserting) {
      context.missing(_laneMeta);
    }
    if (data.containsKey('start_min')) {
      context.handle(
        _startMinMeta,
        startMin.isAcceptableOrUnknown(data['start_min']!, _startMinMeta),
      );
    } else if (isInserting) {
      context.missing(_startMinMeta);
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Plan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      weekdaysMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekdays_mask'],
      )!,
      lane: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lane'],
      )!,
      startMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_min'],
      )!,
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $PlansTable createAlias(String alias) {
    return $PlansTable(attachedDatabase, alias);
  }
}

class Plan extends DataClass implements Insertable<Plan> {
  final String id;
  final String title;
  final String startDate;
  final String endDate;
  final int weekdaysMask;
  final int lane;
  final int startMin;
  final int durationMin;
  final int priority;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Plan({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.weekdaysMask,
    required this.lane,
    required this.startMin,
    required this.durationMin,
    required this.priority,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['weekdays_mask'] = Variable<int>(weekdaysMask);
    map['lane'] = Variable<int>(lane);
    map['start_min'] = Variable<int>(startMin);
    map['duration_min'] = Variable<int>(durationMin);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PlansCompanion toCompanion(bool nullToAbsent) {
    return PlansCompanion(
      id: Value(id),
      title: Value(title),
      startDate: Value(startDate),
      endDate: Value(endDate),
      weekdaysMask: Value(weekdaysMask),
      lane: Value(lane),
      startMin: Value(startMin),
      durationMin: Value(durationMin),
      priority: Value(priority),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Plan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plan(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      weekdaysMask: serializer.fromJson<int>(json['weekdaysMask']),
      lane: serializer.fromJson<int>(json['lane']),
      startMin: serializer.fromJson<int>(json['startMin']),
      durationMin: serializer.fromJson<int>(json['durationMin']),
      priority: serializer.fromJson<int>(json['priority']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'weekdaysMask': serializer.toJson<int>(weekdaysMask),
      'lane': serializer.toJson<int>(lane),
      'startMin': serializer.toJson<int>(startMin),
      'durationMin': serializer.toJson<int>(durationMin),
      'priority': serializer.toJson<int>(priority),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Plan copyWith({
    String? id,
    String? title,
    String? startDate,
    String? endDate,
    int? weekdaysMask,
    int? lane,
    int? startMin,
    int? durationMin,
    int? priority,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Plan(
    id: id ?? this.id,
    title: title ?? this.title,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    weekdaysMask: weekdaysMask ?? this.weekdaysMask,
    lane: lane ?? this.lane,
    startMin: startMin ?? this.startMin,
    durationMin: durationMin ?? this.durationMin,
    priority: priority ?? this.priority,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Plan copyWithCompanion(PlansCompanion data) {
    return Plan(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      weekdaysMask: data.weekdaysMask.present
          ? data.weekdaysMask.value
          : this.weekdaysMask,
      lane: data.lane.present ? data.lane.value : this.lane,
      startMin: data.startMin.present ? data.startMin.value : this.startMin,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      priority: data.priority.present ? data.priority.value : this.priority,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plan(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('weekdaysMask: $weekdaysMask, ')
          ..write('lane: $lane, ')
          ..write('startMin: $startMin, ')
          ..write('durationMin: $durationMin, ')
          ..write('priority: $priority, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    startDate,
    endDate,
    weekdaysMask,
    lane,
    startMin,
    durationMin,
    priority,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plan &&
          other.id == this.id &&
          other.title == this.title &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.weekdaysMask == this.weekdaysMask &&
          other.lane == this.lane &&
          other.startMin == this.startMin &&
          other.durationMin == this.durationMin &&
          other.priority == this.priority &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PlansCompanion extends UpdateCompanion<Plan> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<int> weekdaysMask;
  final Value<int> lane;
  final Value<int> startMin;
  final Value<int> durationMin;
  final Value<int> priority;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const PlansCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.weekdaysMask = const Value.absent(),
    this.lane = const Value.absent(),
    this.startMin = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.priority = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlansCompanion.insert({
    required String id,
    required String title,
    required String startDate,
    required String endDate,
    this.weekdaysMask = const Value.absent(),
    required int lane,
    required int startMin,
    required int durationMin,
    this.priority = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       startDate = Value(startDate),
       endDate = Value(endDate),
       lane = Value(lane),
       startMin = Value(startMin),
       durationMin = Value(durationMin),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Plan> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? weekdaysMask,
    Expression<int>? lane,
    Expression<int>? startMin,
    Expression<int>? durationMin,
    Expression<int>? priority,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (weekdaysMask != null) 'weekdays_mask': weekdaysMask,
      if (lane != null) 'lane': lane,
      if (startMin != null) 'start_min': startMin,
      if (durationMin != null) 'duration_min': durationMin,
      if (priority != null) 'priority': priority,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlansCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<int>? weekdaysMask,
    Value<int>? lane,
    Value<int>? startMin,
    Value<int>? durationMin,
    Value<int>? priority,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return PlansCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      weekdaysMask: weekdaysMask ?? this.weekdaysMask,
      lane: lane ?? this.lane,
      startMin: startMin ?? this.startMin,
      durationMin: durationMin ?? this.durationMin,
      priority: priority ?? this.priority,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (weekdaysMask.present) {
      map['weekdays_mask'] = Variable<int>(weekdaysMask.value);
    }
    if (lane.present) {
      map['lane'] = Variable<int>(lane.value);
    }
    if (startMin.present) {
      map['start_min'] = Variable<int>(startMin.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlansCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('weekdaysMask: $weekdaysMask, ')
          ..write('lane: $lane, ')
          ..write('startMin: $startMin, ')
          ..write('durationMin: $durationMin, ')
          ..write('priority: $priority, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayBlocksTable extends DayBlocks
    with TableInfo<$DayBlocksTable, DayBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _laneMeta = const VerificationMeta('lane');
  @override
  late final GeneratedColumn<int> lane = GeneratedColumn<int>(
    'lane',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinMeta = const VerificationMeta(
    'startMin',
  );
  @override
  late final GeneratedColumn<int> startMin = GeneratedColumn<int>(
    'start_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deadlineAtMeta = const VerificationMeta(
    'deadlineAt',
  );
  @override
  late final GeneratedColumn<DateTime> deadlineAt = GeneratedColumn<DateTime>(
    'deadline_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _manualOrderMeta = const VerificationMeta(
    'manualOrder',
  );
  @override
  late final GeneratedColumn<int> manualOrder = GeneratedColumn<int>(
    'manual_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<int> sourceType = GeneratedColumn<int>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateSnapshotMeta = const VerificationMeta(
    'templateSnapshot',
  );
  @override
  late final GeneratedColumn<String> templateSnapshot = GeneratedColumn<String>(
    'template_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromBlockIdMeta = const VerificationMeta(
    'fromBlockId',
  );
  @override
  late final GeneratedColumn<String> fromBlockId = GeneratedColumn<String>(
    'from_block_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carryCountMeta = const VerificationMeta(
    'carryCount',
  );
  @override
  late final GeneratedColumn<int> carryCount = GeneratedColumn<int>(
    'carry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _originalDateMeta = const VerificationMeta(
    'originalDate',
  );
  @override
  late final GeneratedColumn<String> originalDate = GeneratedColumn<String>(
    'original_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instanceGroupIdMeta = const VerificationMeta(
    'instanceGroupId',
  );
  @override
  late final GeneratedColumn<String> instanceGroupId = GeneratedColumn<String>(
    'instance_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    title,
    lane,
    startMin,
    durationMin,
    priority,
    deadlineAt,
    note,
    done,
    status,
    manualOrder,
    sourceType,
    sourceId,
    templateSnapshot,
    fromBlockId,
    carryCount,
    originalDate,
    instanceGroupId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayBlock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('lane')) {
      context.handle(
        _laneMeta,
        lane.isAcceptableOrUnknown(data['lane']!, _laneMeta),
      );
    } else if (isInserting) {
      context.missing(_laneMeta);
    }
    if (data.containsKey('start_min')) {
      context.handle(
        _startMinMeta,
        startMin.isAcceptableOrUnknown(data['start_min']!, _startMinMeta),
      );
    } else if (isInserting) {
      context.missing(_startMinMeta);
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('deadline_at')) {
      context.handle(
        _deadlineAtMeta,
        deadlineAt.isAcceptableOrUnknown(data['deadline_at']!, _deadlineAtMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('manual_order')) {
      context.handle(
        _manualOrderMeta,
        manualOrder.isAcceptableOrUnknown(
          data['manual_order']!,
          _manualOrderMeta,
        ),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('template_snapshot')) {
      context.handle(
        _templateSnapshotMeta,
        templateSnapshot.isAcceptableOrUnknown(
          data['template_snapshot']!,
          _templateSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('from_block_id')) {
      context.handle(
        _fromBlockIdMeta,
        fromBlockId.isAcceptableOrUnknown(
          data['from_block_id']!,
          _fromBlockIdMeta,
        ),
      );
    }
    if (data.containsKey('carry_count')) {
      context.handle(
        _carryCountMeta,
        carryCount.isAcceptableOrUnknown(data['carry_count']!, _carryCountMeta),
      );
    }
    if (data.containsKey('original_date')) {
      context.handle(
        _originalDateMeta,
        originalDate.isAcceptableOrUnknown(
          data['original_date']!,
          _originalDateMeta,
        ),
      );
    }
    if (data.containsKey('instance_group_id')) {
      context.handle(
        _instanceGroupIdMeta,
        instanceGroupId.isAcceptableOrUnknown(
          data['instance_group_id']!,
          _instanceGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayBlock(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      lane: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lane'],
      )!,
      startMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_min'],
      )!,
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      deadlineAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deadline_at'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      manualOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}manual_order'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      templateSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_snapshot'],
      ),
      fromBlockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_block_id'],
      ),
      carryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carry_count'],
      )!,
      originalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_date'],
      ),
      instanceGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_group_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $DayBlocksTable createAlias(String alias) {
    return $DayBlocksTable(attachedDatabase, alias);
  }
}

class DayBlock extends DataClass implements Insertable<DayBlock> {
  final String id;
  final String date;
  final String title;
  final int lane;
  final int startMin;
  final int durationMin;
  final int priority;
  final DateTime? deadlineAt;
  final String? note;
  final bool done;
  final int status;
  final int manualOrder;
  final int sourceType;
  final String? sourceId;
  final String? templateSnapshot;
  final String? fromBlockId;
  final int carryCount;
  final String? originalDate;
  final String? instanceGroupId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const DayBlock({
    required this.id,
    required this.date,
    required this.title,
    required this.lane,
    required this.startMin,
    required this.durationMin,
    required this.priority,
    this.deadlineAt,
    this.note,
    required this.done,
    required this.status,
    required this.manualOrder,
    required this.sourceType,
    this.sourceId,
    this.templateSnapshot,
    this.fromBlockId,
    required this.carryCount,
    this.originalDate,
    this.instanceGroupId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['title'] = Variable<String>(title);
    map['lane'] = Variable<int>(lane);
    map['start_min'] = Variable<int>(startMin);
    map['duration_min'] = Variable<int>(durationMin);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || deadlineAt != null) {
      map['deadline_at'] = Variable<DateTime>(deadlineAt);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['done'] = Variable<bool>(done);
    map['status'] = Variable<int>(status);
    map['manual_order'] = Variable<int>(manualOrder);
    map['source_type'] = Variable<int>(sourceType);
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || templateSnapshot != null) {
      map['template_snapshot'] = Variable<String>(templateSnapshot);
    }
    if (!nullToAbsent || fromBlockId != null) {
      map['from_block_id'] = Variable<String>(fromBlockId);
    }
    map['carry_count'] = Variable<int>(carryCount);
    if (!nullToAbsent || originalDate != null) {
      map['original_date'] = Variable<String>(originalDate);
    }
    if (!nullToAbsent || instanceGroupId != null) {
      map['instance_group_id'] = Variable<String>(instanceGroupId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  DayBlocksCompanion toCompanion(bool nullToAbsent) {
    return DayBlocksCompanion(
      id: Value(id),
      date: Value(date),
      title: Value(title),
      lane: Value(lane),
      startMin: Value(startMin),
      durationMin: Value(durationMin),
      priority: Value(priority),
      deadlineAt: deadlineAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deadlineAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      done: Value(done),
      status: Value(status),
      manualOrder: Value(manualOrder),
      sourceType: Value(sourceType),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      templateSnapshot: templateSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(templateSnapshot),
      fromBlockId: fromBlockId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromBlockId),
      carryCount: Value(carryCount),
      originalDate: originalDate == null && nullToAbsent
          ? const Value.absent()
          : Value(originalDate),
      instanceGroupId: instanceGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(instanceGroupId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory DayBlock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayBlock(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      title: serializer.fromJson<String>(json['title']),
      lane: serializer.fromJson<int>(json['lane']),
      startMin: serializer.fromJson<int>(json['startMin']),
      durationMin: serializer.fromJson<int>(json['durationMin']),
      priority: serializer.fromJson<int>(json['priority']),
      deadlineAt: serializer.fromJson<DateTime?>(json['deadlineAt']),
      note: serializer.fromJson<String?>(json['note']),
      done: serializer.fromJson<bool>(json['done']),
      status: serializer.fromJson<int>(json['status']),
      manualOrder: serializer.fromJson<int>(json['manualOrder']),
      sourceType: serializer.fromJson<int>(json['sourceType']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      templateSnapshot: serializer.fromJson<String?>(json['templateSnapshot']),
      fromBlockId: serializer.fromJson<String?>(json['fromBlockId']),
      carryCount: serializer.fromJson<int>(json['carryCount']),
      originalDate: serializer.fromJson<String?>(json['originalDate']),
      instanceGroupId: serializer.fromJson<String?>(json['instanceGroupId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'title': serializer.toJson<String>(title),
      'lane': serializer.toJson<int>(lane),
      'startMin': serializer.toJson<int>(startMin),
      'durationMin': serializer.toJson<int>(durationMin),
      'priority': serializer.toJson<int>(priority),
      'deadlineAt': serializer.toJson<DateTime?>(deadlineAt),
      'note': serializer.toJson<String?>(note),
      'done': serializer.toJson<bool>(done),
      'status': serializer.toJson<int>(status),
      'manualOrder': serializer.toJson<int>(manualOrder),
      'sourceType': serializer.toJson<int>(sourceType),
      'sourceId': serializer.toJson<String?>(sourceId),
      'templateSnapshot': serializer.toJson<String?>(templateSnapshot),
      'fromBlockId': serializer.toJson<String?>(fromBlockId),
      'carryCount': serializer.toJson<int>(carryCount),
      'originalDate': serializer.toJson<String?>(originalDate),
      'instanceGroupId': serializer.toJson<String?>(instanceGroupId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  DayBlock copyWith({
    String? id,
    String? date,
    String? title,
    int? lane,
    int? startMin,
    int? durationMin,
    int? priority,
    Value<DateTime?> deadlineAt = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? done,
    int? status,
    int? manualOrder,
    int? sourceType,
    Value<String?> sourceId = const Value.absent(),
    Value<String?> templateSnapshot = const Value.absent(),
    Value<String?> fromBlockId = const Value.absent(),
    int? carryCount,
    Value<String?> originalDate = const Value.absent(),
    Value<String?> instanceGroupId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => DayBlock(
    id: id ?? this.id,
    date: date ?? this.date,
    title: title ?? this.title,
    lane: lane ?? this.lane,
    startMin: startMin ?? this.startMin,
    durationMin: durationMin ?? this.durationMin,
    priority: priority ?? this.priority,
    deadlineAt: deadlineAt.present ? deadlineAt.value : this.deadlineAt,
    note: note.present ? note.value : this.note,
    done: done ?? this.done,
    status: status ?? this.status,
    manualOrder: manualOrder ?? this.manualOrder,
    sourceType: sourceType ?? this.sourceType,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    templateSnapshot: templateSnapshot.present
        ? templateSnapshot.value
        : this.templateSnapshot,
    fromBlockId: fromBlockId.present ? fromBlockId.value : this.fromBlockId,
    carryCount: carryCount ?? this.carryCount,
    originalDate: originalDate.present ? originalDate.value : this.originalDate,
    instanceGroupId: instanceGroupId.present
        ? instanceGroupId.value
        : this.instanceGroupId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  DayBlock copyWithCompanion(DayBlocksCompanion data) {
    return DayBlock(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      title: data.title.present ? data.title.value : this.title,
      lane: data.lane.present ? data.lane.value : this.lane,
      startMin: data.startMin.present ? data.startMin.value : this.startMin,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      priority: data.priority.present ? data.priority.value : this.priority,
      deadlineAt: data.deadlineAt.present
          ? data.deadlineAt.value
          : this.deadlineAt,
      note: data.note.present ? data.note.value : this.note,
      done: data.done.present ? data.done.value : this.done,
      status: data.status.present ? data.status.value : this.status,
      manualOrder: data.manualOrder.present
          ? data.manualOrder.value
          : this.manualOrder,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      templateSnapshot: data.templateSnapshot.present
          ? data.templateSnapshot.value
          : this.templateSnapshot,
      fromBlockId: data.fromBlockId.present
          ? data.fromBlockId.value
          : this.fromBlockId,
      carryCount: data.carryCount.present
          ? data.carryCount.value
          : this.carryCount,
      originalDate: data.originalDate.present
          ? data.originalDate.value
          : this.originalDate,
      instanceGroupId: data.instanceGroupId.present
          ? data.instanceGroupId.value
          : this.instanceGroupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayBlock(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('title: $title, ')
          ..write('lane: $lane, ')
          ..write('startMin: $startMin, ')
          ..write('durationMin: $durationMin, ')
          ..write('priority: $priority, ')
          ..write('deadlineAt: $deadlineAt, ')
          ..write('note: $note, ')
          ..write('done: $done, ')
          ..write('status: $status, ')
          ..write('manualOrder: $manualOrder, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('templateSnapshot: $templateSnapshot, ')
          ..write('fromBlockId: $fromBlockId, ')
          ..write('carryCount: $carryCount, ')
          ..write('originalDate: $originalDate, ')
          ..write('instanceGroupId: $instanceGroupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    date,
    title,
    lane,
    startMin,
    durationMin,
    priority,
    deadlineAt,
    note,
    done,
    status,
    manualOrder,
    sourceType,
    sourceId,
    templateSnapshot,
    fromBlockId,
    carryCount,
    originalDate,
    instanceGroupId,
    createdAt,
    updatedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayBlock &&
          other.id == this.id &&
          other.date == this.date &&
          other.title == this.title &&
          other.lane == this.lane &&
          other.startMin == this.startMin &&
          other.durationMin == this.durationMin &&
          other.priority == this.priority &&
          other.deadlineAt == this.deadlineAt &&
          other.note == this.note &&
          other.done == this.done &&
          other.status == this.status &&
          other.manualOrder == this.manualOrder &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.templateSnapshot == this.templateSnapshot &&
          other.fromBlockId == this.fromBlockId &&
          other.carryCount == this.carryCount &&
          other.originalDate == this.originalDate &&
          other.instanceGroupId == this.instanceGroupId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class DayBlocksCompanion extends UpdateCompanion<DayBlock> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> title;
  final Value<int> lane;
  final Value<int> startMin;
  final Value<int> durationMin;
  final Value<int> priority;
  final Value<DateTime?> deadlineAt;
  final Value<String?> note;
  final Value<bool> done;
  final Value<int> status;
  final Value<int> manualOrder;
  final Value<int> sourceType;
  final Value<String?> sourceId;
  final Value<String?> templateSnapshot;
  final Value<String?> fromBlockId;
  final Value<int> carryCount;
  final Value<String?> originalDate;
  final Value<String?> instanceGroupId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const DayBlocksCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.title = const Value.absent(),
    this.lane = const Value.absent(),
    this.startMin = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.priority = const Value.absent(),
    this.deadlineAt = const Value.absent(),
    this.note = const Value.absent(),
    this.done = const Value.absent(),
    this.status = const Value.absent(),
    this.manualOrder = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.templateSnapshot = const Value.absent(),
    this.fromBlockId = const Value.absent(),
    this.carryCount = const Value.absent(),
    this.originalDate = const Value.absent(),
    this.instanceGroupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayBlocksCompanion.insert({
    required String id,
    required String date,
    required String title,
    required int lane,
    required int startMin,
    required int durationMin,
    required int priority,
    this.deadlineAt = const Value.absent(),
    this.note = const Value.absent(),
    this.done = const Value.absent(),
    this.status = const Value.absent(),
    this.manualOrder = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.templateSnapshot = const Value.absent(),
    this.fromBlockId = const Value.absent(),
    this.carryCount = const Value.absent(),
    this.originalDate = const Value.absent(),
    this.instanceGroupId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       title = Value(title),
       lane = Value(lane),
       startMin = Value(startMin),
       durationMin = Value(durationMin),
       priority = Value(priority),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DayBlock> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? title,
    Expression<int>? lane,
    Expression<int>? startMin,
    Expression<int>? durationMin,
    Expression<int>? priority,
    Expression<DateTime>? deadlineAt,
    Expression<String>? note,
    Expression<bool>? done,
    Expression<int>? status,
    Expression<int>? manualOrder,
    Expression<int>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? templateSnapshot,
    Expression<String>? fromBlockId,
    Expression<int>? carryCount,
    Expression<String>? originalDate,
    Expression<String>? instanceGroupId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (title != null) 'title': title,
      if (lane != null) 'lane': lane,
      if (startMin != null) 'start_min': startMin,
      if (durationMin != null) 'duration_min': durationMin,
      if (priority != null) 'priority': priority,
      if (deadlineAt != null) 'deadline_at': deadlineAt,
      if (note != null) 'note': note,
      if (done != null) 'done': done,
      if (status != null) 'status': status,
      if (manualOrder != null) 'manual_order': manualOrder,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (templateSnapshot != null) 'template_snapshot': templateSnapshot,
      if (fromBlockId != null) 'from_block_id': fromBlockId,
      if (carryCount != null) 'carry_count': carryCount,
      if (originalDate != null) 'original_date': originalDate,
      if (instanceGroupId != null) 'instance_group_id': instanceGroupId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayBlocksCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String>? title,
    Value<int>? lane,
    Value<int>? startMin,
    Value<int>? durationMin,
    Value<int>? priority,
    Value<DateTime?>? deadlineAt,
    Value<String?>? note,
    Value<bool>? done,
    Value<int>? status,
    Value<int>? manualOrder,
    Value<int>? sourceType,
    Value<String?>? sourceId,
    Value<String?>? templateSnapshot,
    Value<String?>? fromBlockId,
    Value<int>? carryCount,
    Value<String?>? originalDate,
    Value<String?>? instanceGroupId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return DayBlocksCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      lane: lane ?? this.lane,
      startMin: startMin ?? this.startMin,
      durationMin: durationMin ?? this.durationMin,
      priority: priority ?? this.priority,
      deadlineAt: deadlineAt ?? this.deadlineAt,
      note: note ?? this.note,
      done: done ?? this.done,
      status: status ?? this.status,
      manualOrder: manualOrder ?? this.manualOrder,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      templateSnapshot: templateSnapshot ?? this.templateSnapshot,
      fromBlockId: fromBlockId ?? this.fromBlockId,
      carryCount: carryCount ?? this.carryCount,
      originalDate: originalDate ?? this.originalDate,
      instanceGroupId: instanceGroupId ?? this.instanceGroupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (lane.present) {
      map['lane'] = Variable<int>(lane.value);
    }
    if (startMin.present) {
      map['start_min'] = Variable<int>(startMin.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (deadlineAt.present) {
      map['deadline_at'] = Variable<DateTime>(deadlineAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (manualOrder.present) {
      map['manual_order'] = Variable<int>(manualOrder.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<int>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (templateSnapshot.present) {
      map['template_snapshot'] = Variable<String>(templateSnapshot.value);
    }
    if (fromBlockId.present) {
      map['from_block_id'] = Variable<String>(fromBlockId.value);
    }
    if (carryCount.present) {
      map['carry_count'] = Variable<int>(carryCount.value);
    }
    if (originalDate.present) {
      map['original_date'] = Variable<String>(originalDate.value);
    }
    if (instanceGroupId.present) {
      map['instance_group_id'] = Variable<String>(instanceGroupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayBlocksCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('title: $title, ')
          ..write('lane: $lane, ')
          ..write('startMin: $startMin, ')
          ..write('durationMin: $durationMin, ')
          ..write('priority: $priority, ')
          ..write('deadlineAt: $deadlineAt, ')
          ..write('note: $note, ')
          ..write('done: $done, ')
          ..write('status: $status, ')
          ..write('manualOrder: $manualOrder, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('templateSnapshot: $templateSnapshot, ')
          ..write('fromBlockId: $fromBlockId, ')
          ..write('carryCount: $carryCount, ')
          ..write('originalDate: $originalDate, ')
          ..write('instanceGroupId: $instanceGroupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompletionLogsTable extends CompletionLogs
    with TableInfo<$CompletionLogsTable, CompletionLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletionLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayBlockIdMeta = const VerificationMeta(
    'dayBlockId',
  );
  @override
  late final GeneratedColumn<String> dayBlockId = GeneratedColumn<String>(
    'day_block_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _laneMeta = const VerificationMeta('lane');
  @override
  late final GeneratedColumn<int> lane = GeneratedColumn<int>(
    'lane',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMinMeta = const VerificationMeta(
    'startMin',
  );
  @override
  late final GeneratedColumn<int> startMin = GeneratedColumn<int>(
    'start_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayBlockId,
    date,
    title,
    lane,
    startMin,
    durationMin,
    completedAt,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completion_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletionLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day_block_id')) {
      context.handle(
        _dayBlockIdMeta,
        dayBlockId.isAcceptableOrUnknown(
          data['day_block_id']!,
          _dayBlockIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayBlockIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('lane')) {
      context.handle(
        _laneMeta,
        lane.isAcceptableOrUnknown(data['lane']!, _laneMeta),
      );
    } else if (isInserting) {
      context.missing(_laneMeta);
    }
    if (data.containsKey('start_min')) {
      context.handle(
        _startMinMeta,
        startMin.isAcceptableOrUnknown(data['start_min']!, _startMinMeta),
      );
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
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
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompletionLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletionLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dayBlockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_block_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      lane: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lane'],
      )!,
      startMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_min'],
      )!,
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $CompletionLogsTable createAlias(String alias) {
    return $CompletionLogsTable(attachedDatabase, alias);
  }
}

class CompletionLog extends DataClass implements Insertable<CompletionLog> {
  final String id;
  final String dayBlockId;
  final String date;
  final String title;
  final int lane;
  final int startMin;
  final int durationMin;
  final DateTime completedAt;
  final String? note;
  const CompletionLog({
    required this.id,
    required this.dayBlockId,
    required this.date,
    required this.title,
    required this.lane,
    required this.startMin,
    required this.durationMin,
    required this.completedAt,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day_block_id'] = Variable<String>(dayBlockId);
    map['date'] = Variable<String>(date);
    map['title'] = Variable<String>(title);
    map['lane'] = Variable<int>(lane);
    map['start_min'] = Variable<int>(startMin);
    map['duration_min'] = Variable<int>(durationMin);
    map['completed_at'] = Variable<DateTime>(completedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  CompletionLogsCompanion toCompanion(bool nullToAbsent) {
    return CompletionLogsCompanion(
      id: Value(id),
      dayBlockId: Value(dayBlockId),
      date: Value(date),
      title: Value(title),
      lane: Value(lane),
      startMin: Value(startMin),
      durationMin: Value(durationMin),
      completedAt: Value(completedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory CompletionLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletionLog(
      id: serializer.fromJson<String>(json['id']),
      dayBlockId: serializer.fromJson<String>(json['dayBlockId']),
      date: serializer.fromJson<String>(json['date']),
      title: serializer.fromJson<String>(json['title']),
      lane: serializer.fromJson<int>(json['lane']),
      startMin: serializer.fromJson<int>(json['startMin']),
      durationMin: serializer.fromJson<int>(json['durationMin']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dayBlockId': serializer.toJson<String>(dayBlockId),
      'date': serializer.toJson<String>(date),
      'title': serializer.toJson<String>(title),
      'lane': serializer.toJson<int>(lane),
      'startMin': serializer.toJson<int>(startMin),
      'durationMin': serializer.toJson<int>(durationMin),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  CompletionLog copyWith({
    String? id,
    String? dayBlockId,
    String? date,
    String? title,
    int? lane,
    int? startMin,
    int? durationMin,
    DateTime? completedAt,
    Value<String?> note = const Value.absent(),
  }) => CompletionLog(
    id: id ?? this.id,
    dayBlockId: dayBlockId ?? this.dayBlockId,
    date: date ?? this.date,
    title: title ?? this.title,
    lane: lane ?? this.lane,
    startMin: startMin ?? this.startMin,
    durationMin: durationMin ?? this.durationMin,
    completedAt: completedAt ?? this.completedAt,
    note: note.present ? note.value : this.note,
  );
  CompletionLog copyWithCompanion(CompletionLogsCompanion data) {
    return CompletionLog(
      id: data.id.present ? data.id.value : this.id,
      dayBlockId: data.dayBlockId.present
          ? data.dayBlockId.value
          : this.dayBlockId,
      date: data.date.present ? data.date.value : this.date,
      title: data.title.present ? data.title.value : this.title,
      lane: data.lane.present ? data.lane.value : this.lane,
      startMin: data.startMin.present ? data.startMin.value : this.startMin,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletionLog(')
          ..write('id: $id, ')
          ..write('dayBlockId: $dayBlockId, ')
          ..write('date: $date, ')
          ..write('title: $title, ')
          ..write('lane: $lane, ')
          ..write('startMin: $startMin, ')
          ..write('durationMin: $durationMin, ')
          ..write('completedAt: $completedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dayBlockId,
    date,
    title,
    lane,
    startMin,
    durationMin,
    completedAt,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletionLog &&
          other.id == this.id &&
          other.dayBlockId == this.dayBlockId &&
          other.date == this.date &&
          other.title == this.title &&
          other.lane == this.lane &&
          other.startMin == this.startMin &&
          other.durationMin == this.durationMin &&
          other.completedAt == this.completedAt &&
          other.note == this.note);
}

class CompletionLogsCompanion extends UpdateCompanion<CompletionLog> {
  final Value<String> id;
  final Value<String> dayBlockId;
  final Value<String> date;
  final Value<String> title;
  final Value<int> lane;
  final Value<int> startMin;
  final Value<int> durationMin;
  final Value<DateTime> completedAt;
  final Value<String?> note;
  final Value<int> rowid;
  const CompletionLogsCompanion({
    this.id = const Value.absent(),
    this.dayBlockId = const Value.absent(),
    this.date = const Value.absent(),
    this.title = const Value.absent(),
    this.lane = const Value.absent(),
    this.startMin = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompletionLogsCompanion.insert({
    required String id,
    required String dayBlockId,
    required String date,
    required String title,
    required int lane,
    this.startMin = const Value.absent(),
    this.durationMin = const Value.absent(),
    required DateTime completedAt,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dayBlockId = Value(dayBlockId),
       date = Value(date),
       title = Value(title),
       lane = Value(lane),
       completedAt = Value(completedAt);
  static Insertable<CompletionLog> custom({
    Expression<String>? id,
    Expression<String>? dayBlockId,
    Expression<String>? date,
    Expression<String>? title,
    Expression<int>? lane,
    Expression<int>? startMin,
    Expression<int>? durationMin,
    Expression<DateTime>? completedAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayBlockId != null) 'day_block_id': dayBlockId,
      if (date != null) 'date': date,
      if (title != null) 'title': title,
      if (lane != null) 'lane': lane,
      if (startMin != null) 'start_min': startMin,
      if (durationMin != null) 'duration_min': durationMin,
      if (completedAt != null) 'completed_at': completedAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompletionLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? dayBlockId,
    Value<String>? date,
    Value<String>? title,
    Value<int>? lane,
    Value<int>? startMin,
    Value<int>? durationMin,
    Value<DateTime>? completedAt,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return CompletionLogsCompanion(
      id: id ?? this.id,
      dayBlockId: dayBlockId ?? this.dayBlockId,
      date: date ?? this.date,
      title: title ?? this.title,
      lane: lane ?? this.lane,
      startMin: startMin ?? this.startMin,
      durationMin: durationMin ?? this.durationMin,
      completedAt: completedAt ?? this.completedAt,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dayBlockId.present) {
      map['day_block_id'] = Variable<String>(dayBlockId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (lane.present) {
      map['lane'] = Variable<int>(lane.value);
    }
    if (startMin.present) {
      map['start_min'] = Variable<int>(startMin.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletionLogsCompanion(')
          ..write('id: $id, ')
          ..write('dayBlockId: $dayBlockId, ')
          ..write('date: $date, ')
          ..write('title: $title, ')
          ..write('lane: $lane, ')
          ..write('startMin: $startMin, ')
          ..write('durationMin: $durationMin, ')
          ..write('completedAt: $completedAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TntDatabase extends GeneratedDatabase {
  _$TntDatabase(QueryExecutor e) : super(e);
  $TntDatabaseManager get managers => $TntDatabaseManager(this);
  late final $BlockTemplatesTable blockTemplates = $BlockTemplatesTable(this);
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $CollectionItemsTable collectionItems = $CollectionItemsTable(
    this,
  );
  late final $PlansTable plans = $PlansTable(this);
  late final $DayBlocksTable dayBlocks = $DayBlocksTable(this);
  late final $CompletionLogsTable completionLogs = $CompletionLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    blockTemplates,
    collections,
    collectionItems,
    plans,
    dayBlocks,
    completionLogs,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'collections',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('collection_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$BlockTemplatesTableCreateCompanionBuilder =
    BlockTemplatesCompanion Function({
      required String id,
      required String title,
      required int lane,
      Value<int> priority,
      Value<int> durationMin,
      Value<int?> startMin,
      Value<DateTime?> deadlineAt,
      Value<String?> note,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$BlockTemplatesTableUpdateCompanionBuilder =
    BlockTemplatesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int> lane,
      Value<int> priority,
      Value<int> durationMin,
      Value<int?> startMin,
      Value<DateTime?> deadlineAt,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$BlockTemplatesTableFilterComposer
    extends Composer<_$TntDatabase, $BlockTemplatesTable> {
  $$BlockTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lane => $composableBuilder(
    column: $table.lane,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deadlineAt => $composableBuilder(
    column: $table.deadlineAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BlockTemplatesTableOrderingComposer
    extends Composer<_$TntDatabase, $BlockTemplatesTable> {
  $$BlockTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lane => $composableBuilder(
    column: $table.lane,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deadlineAt => $composableBuilder(
    column: $table.deadlineAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BlockTemplatesTableAnnotationComposer
    extends Composer<_$TntDatabase, $BlockTemplatesTable> {
  $$BlockTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get lane =>
      $composableBuilder(column: $table.lane, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startMin =>
      $composableBuilder(column: $table.startMin, builder: (column) => column);

  GeneratedColumn<DateTime> get deadlineAt => $composableBuilder(
    column: $table.deadlineAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$BlockTemplatesTableTableManager
    extends
        RootTableManager<
          _$TntDatabase,
          $BlockTemplatesTable,
          BlockTemplate,
          $$BlockTemplatesTableFilterComposer,
          $$BlockTemplatesTableOrderingComposer,
          $$BlockTemplatesTableAnnotationComposer,
          $$BlockTemplatesTableCreateCompanionBuilder,
          $$BlockTemplatesTableUpdateCompanionBuilder,
          (
            BlockTemplate,
            BaseReferences<_$TntDatabase, $BlockTemplatesTable, BlockTemplate>,
          ),
          BlockTemplate,
          PrefetchHooks Function()
        > {
  $$BlockTemplatesTableTableManager(
    _$TntDatabase db,
    $BlockTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlockTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlockTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlockTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> lane = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> durationMin = const Value.absent(),
                Value<int?> startMin = const Value.absent(),
                Value<DateTime?> deadlineAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlockTemplatesCompanion(
                id: id,
                title: title,
                lane: lane,
                priority: priority,
                durationMin: durationMin,
                startMin: startMin,
                deadlineAt: deadlineAt,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int lane,
                Value<int> priority = const Value.absent(),
                Value<int> durationMin = const Value.absent(),
                Value<int?> startMin = const Value.absent(),
                Value<DateTime?> deadlineAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlockTemplatesCompanion.insert(
                id: id,
                title: title,
                lane: lane,
                priority: priority,
                durationMin: durationMin,
                startMin: startMin,
                deadlineAt: deadlineAt,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BlockTemplatesTable, BlockTemplate>(table),
                  BaseReferences<
                    _$TntDatabase,
                    $BlockTemplatesTable,
                    BlockTemplate
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BlockTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$TntDatabase,
      $BlockTemplatesTable,
      BlockTemplate,
      $$BlockTemplatesTableFilterComposer,
      $$BlockTemplatesTableOrderingComposer,
      $$BlockTemplatesTableAnnotationComposer,
      $$BlockTemplatesTableCreateCompanionBuilder,
      $$BlockTemplatesTableUpdateCompanionBuilder,
      (
        BlockTemplate,
        BaseReferences<_$TntDatabase, $BlockTemplatesTable, BlockTemplate>,
      ),
      BlockTemplate,
      PrefetchHooks Function()
    >;
typedef $$CollectionsTableCreateCompanionBuilder =
    CollectionsCompanion Function({
      required String id,
      required String name,
      Value<int?> color,
      Value<String?> note,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$CollectionsTableUpdateCompanionBuilder =
    CollectionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int?> color,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$CollectionsTableReferences
    extends BaseReferences<_$TntDatabase, $CollectionsTable, Collection> {
  $$CollectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CollectionItemsTable, List<CollectionItem>>
  _collectionItemsRefsTable(_$TntDatabase db) => MultiTypedResultKey.fromTable(
    db.collectionItems,
    aliasName: 'collections__id__collection_items__collection_id',
  );

  $$CollectionItemsTableProcessedTableManager get collectionItemsRefs {
    final manager = $$CollectionItemsTableTableManager(
      $_db,
      $_db.collectionItems,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectionItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CollectionsTableFilterComposer
    extends Composer<_$TntDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> collectionItemsRefs(
    Expression<bool> Function($$CollectionItemsTableFilterComposer f) f,
  ) {
    final $$CollectionItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableFilterComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$TntDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$TntDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> collectionItemsRefs<T extends Object>(
    Expression<T> Function($$CollectionItemsTableAnnotationComposer a) f,
  ) {
    final $$CollectionItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionItems,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.collectionItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionsTableTableManager
    extends
        RootTableManager<
          _$TntDatabase,
          $CollectionsTable,
          Collection,
          $$CollectionsTableFilterComposer,
          $$CollectionsTableOrderingComposer,
          $$CollectionsTableAnnotationComposer,
          $$CollectionsTableCreateCompanionBuilder,
          $$CollectionsTableUpdateCompanionBuilder,
          (Collection, $$CollectionsTableReferences),
          Collection,
          PrefetchHooks Function({bool collectionItemsRefs})
        > {
  $$CollectionsTableTableManager(_$TntDatabase db, $CollectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion(
                id: id,
                name: name,
                color: color,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int?> color = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion.insert(
                id: id,
                name: name,
                color: color,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionsTable, Collection>(table),
                  $$CollectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (collectionItemsRefs) db.collectionItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (collectionItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      Collection,
                      $CollectionsTable,
                      CollectionItem,
                      $CollectionItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CollectionsTableReferences
                          ._collectionItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CollectionsTableReferences(
                            db,
                            table,
                            p0,
                          ).collectionItemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'collection_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$TntDatabase,
      $CollectionsTable,
      Collection,
      $$CollectionsTableFilterComposer,
      $$CollectionsTableOrderingComposer,
      $$CollectionsTableAnnotationComposer,
      $$CollectionsTableCreateCompanionBuilder,
      $$CollectionsTableUpdateCompanionBuilder,
      (Collection, $$CollectionsTableReferences),
      Collection,
      PrefetchHooks Function({bool collectionItemsRefs})
    >;
typedef $$CollectionItemsTableCreateCompanionBuilder =
    CollectionItemsCompanion Function({
      required String id,
      required String collectionId,
      Value<String?> templateId,
      required String title,
      required int lane,
      required int startMin,
      required int durationMin,
      Value<int> priority,
      Value<int> sortOrder,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CollectionItemsTableUpdateCompanionBuilder =
    CollectionItemsCompanion Function({
      Value<String> id,
      Value<String> collectionId,
      Value<String?> templateId,
      Value<String> title,
      Value<int> lane,
      Value<int> startMin,
      Value<int> durationMin,
      Value<int> priority,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CollectionItemsTableReferences
    extends
        BaseReferences<_$TntDatabase, $CollectionItemsTable, CollectionItem> {
  $$CollectionItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CollectionsTable _collectionIdTable(_$TntDatabase db) => db
      .collections
      .createAlias('collection_items__collection_id__collections__id');

  $$CollectionsTableProcessedTableManager get collectionId {
    final $_column = $_itemColumn<String>('collection_id')!;

    final manager = $$CollectionsTableTableManager(
      $_db,
      $_db.collections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CollectionItemsTableFilterComposer
    extends Composer<_$TntDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lane => $composableBuilder(
    column: $table.lane,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CollectionsTableFilterComposer get collectionId {
    final $$CollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableFilterComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionItemsTableOrderingComposer
    extends Composer<_$TntDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lane => $composableBuilder(
    column: $table.lane,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CollectionsTableOrderingComposer get collectionId {
    final $$CollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionItemsTableAnnotationComposer
    extends Composer<_$TntDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get lane =>
      $composableBuilder(column: $table.lane, builder: (column) => column);

  GeneratedColumn<int> get startMin =>
      $composableBuilder(column: $table.startMin, builder: (column) => column);

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CollectionsTableAnnotationComposer get collectionId {
    final $$CollectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionItemsTableTableManager
    extends
        RootTableManager<
          _$TntDatabase,
          $CollectionItemsTable,
          CollectionItem,
          $$CollectionItemsTableFilterComposer,
          $$CollectionItemsTableOrderingComposer,
          $$CollectionItemsTableAnnotationComposer,
          $$CollectionItemsTableCreateCompanionBuilder,
          $$CollectionItemsTableUpdateCompanionBuilder,
          (CollectionItem, $$CollectionItemsTableReferences),
          CollectionItem,
          PrefetchHooks Function({bool collectionId})
        > {
  $$CollectionItemsTableTableManager(
    _$TntDatabase db,
    $CollectionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> collectionId = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> lane = const Value.absent(),
                Value<int> startMin = const Value.absent(),
                Value<int> durationMin = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion(
                id: id,
                collectionId: collectionId,
                templateId: templateId,
                title: title,
                lane: lane,
                startMin: startMin,
                durationMin: durationMin,
                priority: priority,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String collectionId,
                Value<String?> templateId = const Value.absent(),
                required String title,
                required int lane,
                required int startMin,
                required int durationMin,
                Value<int> priority = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion.insert(
                id: id,
                collectionId: collectionId,
                templateId: templateId,
                title: title,
                lane: lane,
                startMin: startMin,
                durationMin: durationMin,
                priority: priority,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionItemsTable, CollectionItem>(table),
                  $$CollectionItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (collectionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.collectionId,
                        referencedTable: $$CollectionItemsTableReferences
                            ._collectionIdTable(db),
                        referencedColumn: $$CollectionItemsTableReferences
                            ._collectionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CollectionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$TntDatabase,
      $CollectionItemsTable,
      CollectionItem,
      $$CollectionItemsTableFilterComposer,
      $$CollectionItemsTableOrderingComposer,
      $$CollectionItemsTableAnnotationComposer,
      $$CollectionItemsTableCreateCompanionBuilder,
      $$CollectionItemsTableUpdateCompanionBuilder,
      (CollectionItem, $$CollectionItemsTableReferences),
      CollectionItem,
      PrefetchHooks Function({bool collectionId})
    >;
typedef $$PlansTableCreateCompanionBuilder = PlansCompanion Function({
  required String id,
  required String title,
  required String startDate,
  required String endDate,
  Value<int> weekdaysMask,
  required int lane,
  required int startMin,
  required int durationMin,
  Value<int> priority,
  Value<String?> note,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$PlansTableUpdateCompanionBuilder = PlansCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> startDate,
  Value<String> endDate,
  Value<int> weekdaysMask,
  Value<int> lane,
  Value<int> startMin,
  Value<int> durationMin,
  Value<int> priority,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$PlansTableFilterComposer extends Composer<_$TntDatabase, $PlansTable> {
  $$PlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekdaysMask => $composableBuilder(
    column: $table.weekdaysMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lane => $composableBuilder(
    column: $table.lane,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlansTableOrderingComposer
    extends Composer<_$TntDatabase, $PlansTable> {
  $$PlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekdaysMask => $composableBuilder(
    column: $table.weekdaysMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lane => $composableBuilder(
    column: $table.lane,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlansTableAnnotationComposer
    extends Composer<_$TntDatabase, $PlansTable> {
  $$PlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get weekdaysMask => $composableBuilder(
    column: $table.weekdaysMask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lane =>
      $composableBuilder(column: $table.lane, builder: (column) => column);

  GeneratedColumn<int> get startMin =>
      $composableBuilder(column: $table.startMin, builder: (column) => column);

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PlansTableTableManager
    extends
        RootTableManager<
          _$TntDatabase,
          $PlansTable,
          Plan,
          $$PlansTableFilterComposer,
          $$PlansTableOrderingComposer,
          $$PlansTableAnnotationComposer,
          $$PlansTableCreateCompanionBuilder,
          $$PlansTableUpdateCompanionBuilder,
          (Plan, BaseReferences<_$TntDatabase, $PlansTable, Plan>),
          Plan,
          PrefetchHooks Function()
        > {
  $$PlansTableTableManager(_$TntDatabase db, $PlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<int> weekdaysMask = const Value.absent(),
                Value<int> lane = const Value.absent(),
                Value<int> startMin = const Value.absent(),
                Value<int> durationMin = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion(
                id: id,
                title: title,
                startDate: startDate,
                endDate: endDate,
                weekdaysMask: weekdaysMask,
                lane: lane,
                startMin: startMin,
                durationMin: durationMin,
                priority: priority,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String startDate,
                required String endDate,
                Value<int> weekdaysMask = const Value.absent(),
                required int lane,
                required int startMin,
                required int durationMin,
                Value<int> priority = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlansCompanion.insert(
                id: id,
                title: title,
                startDate: startDate,
                endDate: endDate,
                weekdaysMask: weekdaysMask,
                lane: lane,
                startMin: startMin,
                durationMin: durationMin,
                priority: priority,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlansTable, Plan>(table),
                  BaseReferences<_$TntDatabase, $PlansTable, Plan>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlansTableProcessedTableManager =
    ProcessedTableManager<
      _$TntDatabase,
      $PlansTable,
      Plan,
      $$PlansTableFilterComposer,
      $$PlansTableOrderingComposer,
      $$PlansTableAnnotationComposer,
      $$PlansTableCreateCompanionBuilder,
      $$PlansTableUpdateCompanionBuilder,
      (Plan, BaseReferences<_$TntDatabase, $PlansTable, Plan>),
      Plan,
      PrefetchHooks Function()
    >;
typedef $$DayBlocksTableCreateCompanionBuilder = DayBlocksCompanion Function({
  required String id,
  required String date,
  required String title,
  required int lane,
  required int startMin,
  required int durationMin,
  required int priority,
  Value<DateTime?> deadlineAt,
  Value<String?> note,
  Value<bool> done,
  Value<int> status,
  Value<int> manualOrder,
  Value<int> sourceType,
  Value<String?> sourceId,
  Value<String?> templateSnapshot,
  Value<String?> fromBlockId,
  Value<int> carryCount,
  Value<String?> originalDate,
  Value<String?> instanceGroupId,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$DayBlocksTableUpdateCompanionBuilder = DayBlocksCompanion Function({
  Value<String> id,
  Value<String> date,
  Value<String> title,
  Value<int> lane,
  Value<int> startMin,
  Value<int> durationMin,
  Value<int> priority,
  Value<DateTime?> deadlineAt,
  Value<String?> note,
  Value<bool> done,
  Value<int> status,
  Value<int> manualOrder,
  Value<int> sourceType,
  Value<String?> sourceId,
  Value<String?> templateSnapshot,
  Value<String?> fromBlockId,
  Value<int> carryCount,
  Value<String?> originalDate,
  Value<String?> instanceGroupId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$DayBlocksTableFilterComposer
    extends Composer<_$TntDatabase, $DayBlocksTable> {
  $$DayBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lane => $composableBuilder(
    column: $table.lane,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deadlineAt => $composableBuilder(
    column: $table.deadlineAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get manualOrder => $composableBuilder(
    column: $table.manualOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateSnapshot => $composableBuilder(
    column: $table.templateSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromBlockId => $composableBuilder(
    column: $table.fromBlockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carryCount => $composableBuilder(
    column: $table.carryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalDate => $composableBuilder(
    column: $table.originalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instanceGroupId => $composableBuilder(
    column: $table.instanceGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayBlocksTableOrderingComposer
    extends Composer<_$TntDatabase, $DayBlocksTable> {
  $$DayBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lane => $composableBuilder(
    column: $table.lane,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deadlineAt => $composableBuilder(
    column: $table.deadlineAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get manualOrder => $composableBuilder(
    column: $table.manualOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateSnapshot => $composableBuilder(
    column: $table.templateSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromBlockId => $composableBuilder(
    column: $table.fromBlockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carryCount => $composableBuilder(
    column: $table.carryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalDate => $composableBuilder(
    column: $table.originalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instanceGroupId => $composableBuilder(
    column: $table.instanceGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayBlocksTableAnnotationComposer
    extends Composer<_$TntDatabase, $DayBlocksTable> {
  $$DayBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get lane =>
      $composableBuilder(column: $table.lane, builder: (column) => column);

  GeneratedColumn<int> get startMin =>
      $composableBuilder(column: $table.startMin, builder: (column) => column);

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get deadlineAt => $composableBuilder(
    column: $table.deadlineAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get manualOrder => $composableBuilder(
    column: $table.manualOrder,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get templateSnapshot => $composableBuilder(
    column: $table.templateSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fromBlockId => $composableBuilder(
    column: $table.fromBlockId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get carryCount => $composableBuilder(
    column: $table.carryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalDate => $composableBuilder(
    column: $table.originalDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get instanceGroupId => $composableBuilder(
    column: $table.instanceGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DayBlocksTableTableManager
    extends
        RootTableManager<
          _$TntDatabase,
          $DayBlocksTable,
          DayBlock,
          $$DayBlocksTableFilterComposer,
          $$DayBlocksTableOrderingComposer,
          $$DayBlocksTableAnnotationComposer,
          $$DayBlocksTableCreateCompanionBuilder,
          $$DayBlocksTableUpdateCompanionBuilder,
          (DayBlock, BaseReferences<_$TntDatabase, $DayBlocksTable, DayBlock>),
          DayBlock,
          PrefetchHooks Function()
        > {
  $$DayBlocksTableTableManager(_$TntDatabase db, $DayBlocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> lane = const Value.absent(),
                Value<int> startMin = const Value.absent(),
                Value<int> durationMin = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime?> deadlineAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> manualOrder = const Value.absent(),
                Value<int> sourceType = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> templateSnapshot = const Value.absent(),
                Value<String?> fromBlockId = const Value.absent(),
                Value<int> carryCount = const Value.absent(),
                Value<String?> originalDate = const Value.absent(),
                Value<String?> instanceGroupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayBlocksCompanion(
                id: id,
                date: date,
                title: title,
                lane: lane,
                startMin: startMin,
                durationMin: durationMin,
                priority: priority,
                deadlineAt: deadlineAt,
                note: note,
                done: done,
                status: status,
                manualOrder: manualOrder,
                sourceType: sourceType,
                sourceId: sourceId,
                templateSnapshot: templateSnapshot,
                fromBlockId: fromBlockId,
                carryCount: carryCount,
                originalDate: originalDate,
                instanceGroupId: instanceGroupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required String title,
                required int lane,
                required int startMin,
                required int durationMin,
                required int priority,
                Value<DateTime?> deadlineAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> manualOrder = const Value.absent(),
                Value<int> sourceType = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> templateSnapshot = const Value.absent(),
                Value<String?> fromBlockId = const Value.absent(),
                Value<int> carryCount = const Value.absent(),
                Value<String?> originalDate = const Value.absent(),
                Value<String?> instanceGroupId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayBlocksCompanion.insert(
                id: id,
                date: date,
                title: title,
                lane: lane,
                startMin: startMin,
                durationMin: durationMin,
                priority: priority,
                deadlineAt: deadlineAt,
                note: note,
                done: done,
                status: status,
                manualOrder: manualOrder,
                sourceType: sourceType,
                sourceId: sourceId,
                templateSnapshot: templateSnapshot,
                fromBlockId: fromBlockId,
                carryCount: carryCount,
                originalDate: originalDate,
                instanceGroupId: instanceGroupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DayBlocksTable, DayBlock>(table),
                  BaseReferences<_$TntDatabase, $DayBlocksTable, DayBlock>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayBlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$TntDatabase,
      $DayBlocksTable,
      DayBlock,
      $$DayBlocksTableFilterComposer,
      $$DayBlocksTableOrderingComposer,
      $$DayBlocksTableAnnotationComposer,
      $$DayBlocksTableCreateCompanionBuilder,
      $$DayBlocksTableUpdateCompanionBuilder,
      (DayBlock, BaseReferences<_$TntDatabase, $DayBlocksTable, DayBlock>),
      DayBlock,
      PrefetchHooks Function()
    >;
typedef $$CompletionLogsTableCreateCompanionBuilder =
    CompletionLogsCompanion Function({
      required String id,
      required String dayBlockId,
      required String date,
      required String title,
      required int lane,
      Value<int> startMin,
      Value<int> durationMin,
      required DateTime completedAt,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$CompletionLogsTableUpdateCompanionBuilder =
    CompletionLogsCompanion Function({
      Value<String> id,
      Value<String> dayBlockId,
      Value<String> date,
      Value<String> title,
      Value<int> lane,
      Value<int> startMin,
      Value<int> durationMin,
      Value<DateTime> completedAt,
      Value<String?> note,
      Value<int> rowid,
    });

class $$CompletionLogsTableFilterComposer
    extends Composer<_$TntDatabase, $CompletionLogsTable> {
  $$CompletionLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayBlockId => $composableBuilder(
    column: $table.dayBlockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lane => $composableBuilder(
    column: $table.lane,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompletionLogsTableOrderingComposer
    extends Composer<_$TntDatabase, $CompletionLogsTable> {
  $$CompletionLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayBlockId => $composableBuilder(
    column: $table.dayBlockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lane => $composableBuilder(
    column: $table.lane,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMin => $composableBuilder(
    column: $table.startMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompletionLogsTableAnnotationComposer
    extends Composer<_$TntDatabase, $CompletionLogsTable> {
  $$CompletionLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dayBlockId => $composableBuilder(
    column: $table.dayBlockId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get lane =>
      $composableBuilder(column: $table.lane, builder: (column) => column);

  GeneratedColumn<int> get startMin =>
      $composableBuilder(column: $table.startMin, builder: (column) => column);

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$CompletionLogsTableTableManager
    extends
        RootTableManager<
          _$TntDatabase,
          $CompletionLogsTable,
          CompletionLog,
          $$CompletionLogsTableFilterComposer,
          $$CompletionLogsTableOrderingComposer,
          $$CompletionLogsTableAnnotationComposer,
          $$CompletionLogsTableCreateCompanionBuilder,
          $$CompletionLogsTableUpdateCompanionBuilder,
          (
            CompletionLog,
            BaseReferences<_$TntDatabase, $CompletionLogsTable, CompletionLog>,
          ),
          CompletionLog,
          PrefetchHooks Function()
        > {
  $$CompletionLogsTableTableManager(
    _$TntDatabase db,
    $CompletionLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletionLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletionLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletionLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> dayBlockId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> lane = const Value.absent(),
                Value<int> startMin = const Value.absent(),
                Value<int> durationMin = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletionLogsCompanion(
                id: id,
                dayBlockId: dayBlockId,
                date: date,
                title: title,
                lane: lane,
                startMin: startMin,
                durationMin: durationMin,
                completedAt: completedAt,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String dayBlockId,
                required String date,
                required String title,
                required int lane,
                Value<int> startMin = const Value.absent(),
                Value<int> durationMin = const Value.absent(),
                required DateTime completedAt,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletionLogsCompanion.insert(
                id: id,
                dayBlockId: dayBlockId,
                date: date,
                title: title,
                lane: lane,
                startMin: startMin,
                durationMin: durationMin,
                completedAt: completedAt,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CompletionLogsTable, CompletionLog>(table),
                  BaseReferences<
                    _$TntDatabase,
                    $CompletionLogsTable,
                    CompletionLog
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CompletionLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$TntDatabase,
      $CompletionLogsTable,
      CompletionLog,
      $$CompletionLogsTableFilterComposer,
      $$CompletionLogsTableOrderingComposer,
      $$CompletionLogsTableAnnotationComposer,
      $$CompletionLogsTableCreateCompanionBuilder,
      $$CompletionLogsTableUpdateCompanionBuilder,
      (
        CompletionLog,
        BaseReferences<_$TntDatabase, $CompletionLogsTable, CompletionLog>,
      ),
      CompletionLog,
      PrefetchHooks Function()
    >;

class $TntDatabaseManager {
  final _$TntDatabase _db;
  $TntDatabaseManager(this._db);
  $$BlockTemplatesTableTableManager get blockTemplates =>
      $$BlockTemplatesTableTableManager(_db, _db.blockTemplates);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$CollectionItemsTableTableManager get collectionItems =>
      $$CollectionItemsTableTableManager(_db, _db.collectionItems);
  $$PlansTableTableManager get plans =>
      $$PlansTableTableManager(_db, _db.plans);
  $$DayBlocksTableTableManager get dayBlocks =>
      $$DayBlocksTableTableManager(_db, _db.dayBlocks);
  $$CompletionLogsTableTableManager get completionLogs =>
      $$CompletionLogsTableTableManager(_db, _db.completionLogs);
}
