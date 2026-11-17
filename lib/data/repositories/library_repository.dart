import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/tblock.dart';
import '../db/tnt_database.dart';

/// 往集合里塞一条的种子数据
class CollectionSeedItem {
  const CollectionSeedItem({
    required this.title,
    required this.lane,
    required this.startMin,
    required this.durationMin,
    this.priority = Priority.c,
  });

  final String title;
  final Lane lane;
  final int startMin;
  final int durationMin;
  final Priority priority;
}

/// 模板 / 集合 / 长期计划的读写。S3 把它们「物化」到某天的 DayBlocks。
class LibraryRepository {
  LibraryRepository(this._db);

  final TntDatabase _db;
  static const _uuid = Uuid();

  // ── 模板 ────────────────────────────────────────────────────
  /// 一次性清理老版本灌进库里的示例数据（id 都以 seed- 开头）。
  /// 只动 seed 前缀的行，绝不会碰用户自己建的内容；重复调用安全。
  Future<void> purgeDemoData() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.customStatement(
      "UPDATE day_blocks SET deleted_at = ? WHERE deleted_at IS NULL "
      "AND (id LIKE 'seed-%' OR id LIKE 'plan:seed-%')",
      [now],
    );
    await _db.customStatement(
      "DELETE FROM collection_items WHERE collection_id LIKE 'seed-coll-%'",
    );
    await _db.customStatement(
      "DELETE FROM collections WHERE id LIKE 'seed-coll-%'",
    );
    await _db.customStatement("DELETE FROM plans WHERE id LIKE 'seed-%'");
  }

  Future<List<BlockTemplate>> templates() {
    final q = _db.select(_db.blockTemplates)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.title)]);
    return q.get();
  }

  Future<void> saveTemplate(BlockTemplatesCompanion row) =>
      _db.into(_db.blockTemplates).insertOnConflictUpdate(row);

  Future<void> deleteTemplate(String id) {
    final now = DateTime.now();
    return (_db.update(
      _db.blockTemplates,
    )..where((t) => t.id.equals(id))).write(
      BlockTemplatesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  // ── 集合 ────────────────────────────────────────────────────
  Future<List<Collection>> collections() {
    final q = _db.select(_db.collections)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return q.get();
  }

  Future<List<CollectionItem>> collectionItems(String collectionId) {
    final q = _db.select(_db.collectionItems)
      ..where((t) => t.collectionId.equals(collectionId))
      ..orderBy([(t) => OrderingTerm(expression: t.startMin)]);
    return q.get();
  }

  /// 新建一个集合（整包），返回集合 id
  ///
  /// [id] / [itemIdPrefix] 是给示例数据用的：两台设备各自首次启动时
  /// 会灌同一批示例，只有 id 完全一样，局域网同步才会按 LWW 合并成一份，
  /// 而不是各留一套出现「洗衣服 ×2」。
  Future<String> createCollection({
    required String name,
    List<CollectionItemsCompanion> items = const [],
    int? color,
    String? id,
    String? itemIdPrefix,
  }) async {
    final now = DateTime.now();
    final collectionId = id ?? _uuid.v4();
    await _db.transaction(() async {
      await _db
          .into(_db.collections)
          .insert(
            CollectionsCompanion.insert(
              id: collectionId,
              name: name,
              color: Value(color),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db.batch((batch) {
        var index = 0;
        for (final item in items) {
          batch.insert(
            _db.collectionItems,
            item.copyWith(
              id: Value(
                itemIdPrefix == null
                    ? _uuid.v4()
                    : '$itemIdPrefix-${index++}',
              ),
              collectionId: Value(collectionId),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
        }
      });
    });
    return collectionId;
  }

  /// 建集合的简易入口：直接给条目，内部补齐 id / 时间戳 / 排序。
  Future<String> createCollectionSimple({
    required String name,
    required List<CollectionSeedItem> items,
    int? color,
    String? id,
    String? itemIdPrefix,
  }) {
    return createCollection(
      name: name,
      color: color,
      id: id,
      itemIdPrefix: itemIdPrefix,
      items: [
        for (var i = 0; i < items.length; i++)
          CollectionItemsCompanion.insert(
            id: '',
            collectionId: '',
            title: items[i].title,
            lane: items[i].lane.id,
            startMin: items[i].startMin,
            durationMin: items[i].durationMin,
            priority: Value(items[i].priority.index),
            sortOrder: Value(i),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
      ],
    );
  }

  Future<void> deleteCollection(String id) {
    final now = DateTime.now();
    return (_db.update(_db.collections)..where((t) => t.id.equals(id))).write(
      CollectionsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// 改一个集合：改名字 + 整包替换条目。
  ///
  /// 条目没有墓碑字段，所以这里是硬删再插——集合本身是「模板」，
  /// 改一次就等于换一份，不同步删除是可接受的取舍（README 里有记）。
  Future<void> updateCollection({
    required String id,
    required String name,
    required List<CollectionSeedItem> items,
  }) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.collections)..where((t) => t.id.equals(id))).write(
        CollectionsCompanion(name: Value(name), updatedAt: Value(now)),
      );
      await (_db.delete(
        _db.collectionItems,
      )..where((t) => t.collectionId.equals(id))).go();
      await _db.batch((batch) {
        for (var i = 0; i < items.length; i++) {
          batch.insert(
            _db.collectionItems,
            CollectionItemsCompanion.insert(
              id: _uuid.v4(),
              collectionId: id,
              title: items[i].title,
              lane: items[i].lane.id,
              startMin: items[i].startMin,
              durationMin: items[i].durationMin,
              priority: Value(items[i].priority.index),
              sortOrder: Value(i),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      });
    });
  }

  /// 某集合的条目按「条目模型」返回，方便编辑面板回填
  Future<List<CollectionSeedItem>> collectionSeeds(String collectionId) async {
    final rows = await collectionItems(collectionId);
    return [
      for (final row in rows)
        CollectionSeedItem(
          title: row.title,
          lane: Lane(id: row.lane, name: row.lane),
          startMin: row.startMin,
          durationMin: row.durationMin,
          priority: Priority.byIndex(row.priority),
        ),
    ];
  }

  // ── 长期计划 ────────────────────────────────────────────────
  Future<List<Plan>> plans() {
    final q = _db.select(_db.plans)..where((t) => t.deletedAt.isNull());
    return q.get();
  }

  /// 某天生效的计划（日期区间 + 星期掩码）
  Future<List<Plan>> plansOn(DateTime day) async {
    final all = await (_db.select(
      _db.plans,
    )..where((t) => t.deletedAt.isNull())).get();
    final key = formatDateKey(day);
    final weekdayBit = 1 << (day.weekday - 1); // 周一=bit0
    return [
      for (final p in all)
        if (p.startDate.compareTo(key) <= 0 &&
            p.endDate.compareTo(key) >= 0 &&
            (p.weekdaysMask & weekdayBit) != 0)
          p,
    ];
  }

  Future<void> savePlan(PlansCompanion row) =>
      _db.into(_db.plans).insertOnConflictUpdate(row);

  /// 建计划的简易入口：不用在 UI/状态层构造 Drift 的 Companion
  Future<void> createPlanSimple({
    required String id,
    required String title,
    required String startDate,
    required String endDate,
    required Lane lane,
    required int startMin,
    required int durationMin,
    Priority priority = Priority.c,
    int weekdaysMask = 127,
  }) {
    final now = DateTime.now();
    return savePlan(
      PlansCompanion.insert(
        id: id,
        title: title,
        startDate: startDate,
        endDate: endDate,
        lane: lane.id,
        startMin: startMin,
        durationMin: durationMin,
        priority: Value(priority.index),
        weekdaysMask: Value(weekdaysMask),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> deletePlan(String id) {
    final now = DateTime.now();
    return (_db.update(_db.plans)..where((t) => t.id.equals(id))).write(
      PlansCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// 改计划（编辑面板保存时走这里）
  Future<void> updatePlanSimple({
    required String id,
    required String title,
    required String startDate,
    required String endDate,
    required Lane lane,
    required int startMin,
    required int durationMin,
    required Priority priority,
    required int weekdaysMask,
  }) {
    return (_db.update(_db.plans)..where((t) => t.id.equals(id))).write(
      PlansCompanion(
        title: Value(title),
        startDate: Value(startDate),
        endDate: Value(endDate),
        lane: Value(lane.id),
        startMin: Value(startMin),
        durationMin: Value(durationMin),
        priority: Value(priority.index),
        weekdaysMask: Value(weekdaysMask),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ── 完成记录 ────────────────────────────────────────────────
  Future<void> logCompletion({
    required String dayBlockId,
    required String date,
    required String title,
    required String lane,
    required int startMin,
    required int durationMin,
    String? note,
  }) {
    return _db
        .into(_db.completionLogs)
        .insert(
          CompletionLogsCompanion.insert(
            id: _uuid.v4(),
            dayBlockId: dayBlockId,
            date: date,
            title: title,
            lane: lane,
            startMin: Value(startMin),
            durationMin: Value(durationMin),
            completedAt: DateTime.now(),
            note: Value(note),
          ),
        );
  }

  Future<List<CompletionLog>> completions({int limit = 100}) {
    final q = _db.select(_db.completionLogs)
      ..orderBy([
        (t) => OrderingTerm(expression: t.completedAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    return q.get();
  }

  /// 哪些天有过完成记录（用于连续打卡天数）。
  Future<Set<String>> completionDayKeys() async {
    final q = _db.selectOnly(_db.completionLogs)
      ..addColumns([_db.completionLogs.date])
      ..groupBy([_db.completionLogs.date]);
    final rows = await q.get();
    return {
      for (final row in rows)
        if (row.read(_db.completionLogs.date) != null)
          row.read(_db.completionLogs.date)!,
    };
  }
}

/// yyyy-MM-dd（本地时区）
String formatDateKey(DateTime day) {
  final local = day.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}-$m-$d';
}
