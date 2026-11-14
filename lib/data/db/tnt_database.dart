import 'dart:io';

import 'package:drift/drift.dart';
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
  IntColumn get lane => integer()();
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
  IntColumn get lane => integer()();
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
  IntColumn get lane => integer()();
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
class DayBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()(); // yyyy-MM-dd
  TextColumn get title => text()();
  IntColumn get lane => integer()();
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
  IntColumn get lane => integer()();
  IntColumn get startMin => integer().withDefault(const Constant(0))();
  IntColumn get durationMin => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    BlockTemplates,
    Collections,
    CollectionItems,
    Plans,
    DayBlocks,
    CompletionLogs,
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_day_blocks_date ON day_blocks(date)',
      );
    },
  );
}
