import 'dart:io';

import 'package:drift/drift.dart';

import '../../domain/models/lane.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'tnt_database.g.dart';

// ─────────────────────────────────────────────────────────────
// 方块模板：事件的「原型」，集合与长期计划都引用它
// ─────────────────────────────────────────────────────────────
class BlockTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get lane => text()();
  IntColumn get priority => integer().withDefault(const Constant(2))();
  IntColumn get durationMin => integer().withDefault(const Constant(30))();
  IntColumn get startMin => integer().nullable()();
  DateTimeColumn get deadlineAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────────────────────
// 集合：重复任务整包（吃饭/读书/学习/睡觉/健身），可整包投入某天
// ─────────────────────────────────────────────────────────────
class Collections extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get color => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CollectionItems extends Table {
  TextColumn get id => text()();
  TextColumn get collectionId =>
      text().references(Collections, #id, onDelete: KeyAction.cascade)();
  TextColumn get templateId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get lane => text()();
  IntColumn get startMin => integer()();
  IntColumn get durationMin => integer()();
  IntColumn get priority => integer().withDefault(const Constant(2))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────────────────────
// 长期计划：日期区间内的总体规划（如 11/1–12/31 学英语）
// ─────────────────────────────────────────────────────────────
class Plans extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get startDate => text()(); // yyyy-MM-dd
  TextColumn get endDate => text()(); // yyyy-MM-dd
  IntColumn get weekdaysMask => integer().withDefault(const Constant(127))();
  TextColumn get lane => text()();
  IntColumn get startMin => integer()();
  IntColumn get durationMin => integer()();
  IntColumn get priority => integer().withDefault(const Constant(2))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────────────────────
// 某天时间轴上的一个方块（可来自模板/集合/长期计划/手动）
// ─────────────────────────────────────────────────────────────
/// 用户可自己增删改名排序的泳道
class LaneRows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DayBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  TextColumn get title => text()();
  TextColumn get lane => text()();
  IntColumn get startMin => integer()();
  IntColumn get durationMin => integer()();
  IntColumn get priority => integer()();
  DateTimeColumn get deadlineAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get status => integer().withDefault(const Constant(0))();
  IntColumn get manualOrder => integer().withDefault(const Constant(0))();
  IntColumn get sourceType => integer().withDefault(const Constant(0))();
  TextColumn get sourceId => text().nullable()();
  TextColumn get templateSnapshot => text().nullable()();
  TextColumn get fromBlockId => text().nullable()();
  IntColumn get carryCount => integer().withDefault(const Constant(0))();
  TextColumn get originalDate => text().nullable()();
  TextColumn get instanceGroupId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────────────────────
// 完成记录：打卡历史，从时间轴移除后仍可回看
// ─────────────────────────────────────────────────────────────
class CompletionLogs extends Table {
  TextColumn get id => text()();
  TextColumn get dayBlockId => text()();
  TextColumn get date => text()();
  TextColumn get title => text()();
  TextColumn get lane => text()();
  IntColumn get startMin => integer().withDefault(const Constant(0))();
  IntColumn get durationMin => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────────────────────
// 收件箱：还没排进某一天的念头/任务，随时可以拖到某天或某个合集
// ─────────────────────────────────────────────────────────────
class InboxItems extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  TextColumn get lane => text().withDefault(const Constant('temp'))();
  IntColumn get startMin => integer().nullable()();
  IntColumn get durationMin => integer().withDefault(const Constant(30))();
  IntColumn get priority => integer().withDefault(const Constant(2))();
  TextColumn get day => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    LaneRows,
    BlockTemplates,
    Collections,
    CollectionItems,
    Plans,
    DayBlocks,
    CompletionLogs,
    InboxItems,
  ],
)
class TntDatabase extends _$TntDatabase {
  TntDatabase() : super(_openConnection());

  /// 仅用于测试的内存库
  TntDatabase.forTesting(super.e);

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      // 放应用私有目录，不污染「文档」；
      // Windows: %APPDATA%\com.tnt\tnt_app\tnt.sqlite
      // Android: /data/data/com.tnt.tnt_app/files/tnt.sqlite
      final dir = await getApplicationSupportDirectory();
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File(p.join(dir.path, 'tnt.sqlite'));
      stderr.writeln('TNT db=${file.path}');
      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_day_blocks_date ON day_blocks(date)',
      );
      await _seedLanes();
    },
    onUpgrade: (m, from, to) async {
      // v1 → v2：多了「收件箱」这张表，老库直接补建，不动已有数据
      if (from < 2) {
        await m.createTable(inboxItems);
      }
      // v2 → v3：泳道可自定义，`lane` 从 int 下标改成 text id，并补一张 lanes 表
      if (from < 3) {
        await m.createTable(laneRows);
        await _migrateLaneColumns();
      }
    },
  );

  /// 给新库塞三条默认泳道（id 与老版本的 0/1/2 对应）
  Future<void> _seedLanes() async {
    final now = DateTime.now();
    for (final lane in Lane.defaults) {
      await into(laneRows).insert(
        LaneRowsCompanion.insert(
          id: lane.id,
          name: lane.name,
          sortOrder: Value(lane.sortOrder),
          createdAt: now,
          updatedAt: now,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  /// 把 5 张表里的 `lane INTEGER` 换成 `lane TEXT`（旧值 0/1/2 → daily/habit/temp）
  Future<void> _migrateLaneColumns() async {
    // 迁移必须可重入：上一次中途失败会留下 `xxx_v2` 表，老版本因此卡在
    // 「collection_items_v2 already exists」，之后每次启动都退化到内存模式
    // （看起来像数据全丢）。这里先清残骸，再逐表判断是否已经迁过。
    const tables = <String>[
      'day_blocks',
      'plans',
      'collection_items',
      'block_templates',
      'completion_logs',
      'inbox_items',
    ];
    for (final table in tables) {
      await customStatement('DROP TABLE IF EXISTS ${table}_v2');
    }

    const legacy = "CASE lane WHEN 0 THEN 'daily' WHEN 1 THEN 'habit' "
        "WHEN 2 THEN 'temp' ELSE 'daily' END";

    Future<bool> migrated(String table) async {
      final info = await customSelect('PRAGMA table_info($table)').get();
      for (final row in info) {
        if (row.data['name'] == 'lane') {
          final type = (row.data['type'] as String? ?? '').toUpperCase();
          return type.contains('TEXT');
        }
      }
      return true;
    }

    final statements = <String>[];
    if (!await migrated('day_blocks')) {
      statements.addAll(<String>[
        'ALTER TABLE day_blocks RENAME TO day_blocks_v2',
        'CREATE TABLE day_blocks ('
            'id TEXT NOT NULL PRIMARY KEY, date TEXT NOT NULL, '
            'title TEXT NOT NULL, lane TEXT NOT NULL, '
            'start_min INTEGER NOT NULL, duration_min INTEGER NOT NULL, '
            'priority INTEGER NOT NULL, deadline_at INTEGER, note TEXT, '
            'done INTEGER NOT NULL DEFAULT 0, status INTEGER NOT NULL DEFAULT 0, '
            'manual_order INTEGER NOT NULL DEFAULT 0, '
            'source_type INTEGER NOT NULL DEFAULT 0, '
            'source_id TEXT, template_snapshot TEXT, from_block_id TEXT, '
            'carry_count INTEGER NOT NULL DEFAULT 0, original_date TEXT, '
            'instance_group_id TEXT, created_at INTEGER NOT NULL, '
            'updated_at INTEGER NOT NULL, deleted_at INTEGER)',
        'INSERT INTO day_blocks SELECT id, date, title, $legacy, '
            'start_min, duration_min, priority, deadline_at, note, done, status, '
            'manual_order, source_type, source_id, template_snapshot, '
            'from_block_id, carry_count, original_date, instance_group_id, '
            'created_at, updated_at, deleted_at FROM day_blocks_v2',
        'DROP TABLE day_blocks_v2',
        'CREATE INDEX IF NOT EXISTS idx_day_blocks_date ON day_blocks(date)',
      ]);
    }
    if (!await migrated('plans')) {
      statements.addAll(<String>[
        'ALTER TABLE plans RENAME TO plans_v2',
        'CREATE TABLE plans ('
            'id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, '
            'start_date TEXT NOT NULL, end_date TEXT NOT NULL, '
            'weekdays_mask INTEGER NOT NULL DEFAULT 127, lane TEXT NOT NULL, '
            'start_min INTEGER NOT NULL, duration_min INTEGER NOT NULL, '
            'priority INTEGER NOT NULL DEFAULT 2, note TEXT, '
            'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
            'deleted_at INTEGER)',
        'INSERT INTO plans SELECT id, title, start_date, end_date, '
            'weekdays_mask, $legacy, start_min, duration_min, priority, note, '
            'created_at, updated_at, deleted_at FROM plans_v2',
        'DROP TABLE plans_v2',
      ]);
    }
    if (!await migrated('collection_items')) {
      statements.addAll(<String>[
        'ALTER TABLE collection_items RENAME TO collection_items_v2',
        'CREATE TABLE collection_items ('
            'id TEXT NOT NULL PRIMARY KEY, '
            'collection_id TEXT NOT NULL REFERENCES collections(id) '
            'ON DELETE CASCADE, template_id TEXT, title TEXT NOT NULL, '
            'lane TEXT NOT NULL, start_min INTEGER NOT NULL, '
            'duration_min INTEGER NOT NULL, priority INTEGER NOT NULL DEFAULT 2, '
            'sort_order INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL, '
            'updated_at INTEGER NOT NULL, deleted_at INTEGER)',
        'INSERT INTO collection_items SELECT id, collection_id, template_id, '
            'title, $legacy, start_min, duration_min, priority, sort_order, '
            'created_at, updated_at, deleted_at FROM collection_items_v2',
        'DROP TABLE collection_items_v2',
      ]);
    }
    if (!await migrated('block_templates')) {
      statements.addAll(<String>[
        'ALTER TABLE block_templates RENAME TO block_templates_v2',
        'CREATE TABLE block_templates ('
            'id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, '
            'lane TEXT NOT NULL, priority INTEGER NOT NULL DEFAULT 2, '
            'duration_min INTEGER NOT NULL DEFAULT 30, start_min INTEGER, '
            'deadline_at INTEGER, note TEXT, created_at INTEGER NOT NULL, '
            'updated_at INTEGER NOT NULL, deleted_at INTEGER)',
        'INSERT INTO block_templates SELECT id, title, $legacy, priority, '
            'duration_min, start_min, deadline_at, note, created_at, updated_at, '
            'deleted_at FROM block_templates_v2',
        'DROP TABLE block_templates_v2',
      ]);
    }
    if (!await migrated('completion_logs')) {
      statements.addAll(<String>[
        'ALTER TABLE completion_logs RENAME TO completion_logs_v2',
        'CREATE TABLE completion_logs ('
            'id TEXT NOT NULL PRIMARY KEY, day_block_id TEXT NOT NULL, '
            'date TEXT NOT NULL, title TEXT NOT NULL, lane TEXT NOT NULL, '
            'start_min INTEGER NOT NULL DEFAULT 0, '
            'duration_min INTEGER NOT NULL DEFAULT 0, '
            'completed_at INTEGER NOT NULL, note TEXT)',
        'INSERT INTO completion_logs SELECT id, day_block_id, date, title, '
            '$legacy, start_min, duration_min, completed_at, note '
            'FROM completion_logs_v2',
        'DROP TABLE completion_logs_v2',
      ]);
    }
    if (!await migrated('inbox_items')) {
      statements.addAll(<String>[
        'ALTER TABLE inbox_items RENAME TO inbox_items_v2',
        'CREATE TABLE inbox_items ('
            'id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, note TEXT, '
            "lane TEXT NOT NULL DEFAULT 'temp', start_min INTEGER, "
            'duration_min INTEGER NOT NULL DEFAULT 30, '
            'priority INTEGER NOT NULL DEFAULT 2, day TEXT, '
            'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
            'deleted_at INTEGER)',
        'INSERT INTO inbox_items SELECT id, title, note, '
            "$legacy, start_min, duration_min, priority, day, created_at, "
            "updated_at, deleted_at FROM inbox_items_v2",
        'DROP TABLE inbox_items_v2',
      ]);
    }

    for (final statement in statements) {
      await customStatement(statement);
    }
  }
}
