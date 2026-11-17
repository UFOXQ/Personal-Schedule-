import 'package:drift/drift.dart';

import '../../domain/models/carry_over.dart';
import '../../domain/models/tblock.dart';
import '../db/tnt_database.dart';

/// 某天时间轴方块的仓库。所有写操作都带 updatedAt，删除是软删除（tombstone），
/// 为后面 S7 的局域网同步留好字段。
class DayBlockRepository {
  DayBlockRepository(this._db);

  final TntDatabase _db;

  /// 当天的方块流。默认不含已完成 / 已顺延 / 已丢弃的（它们在别处体现）。
  Stream<List<TBlock>> watchDay(String date) {
    final query = _db.select(_db.dayBlocks)
      ..where(
        (t) =>
            t.date.equals(date) &
            t.deletedAt.isNull() &
            t.status.equals(BlockStatus.planned.index),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.startMin),
        (t) => OrderingTerm(expression: t.manualOrder),
      ]);
    return query.watch().map(_toBlocks);
  }

  Future<List<TBlock>> loadDay(String date, {bool includeDone = false}) async {
    final query = _db.select(_db.dayBlocks)
      ..where((t) {
        final alive = t.date.equals(date) & t.deletedAt.isNull();
        return includeDone
            ? alive
            : alive & t.status.equals(BlockStatus.planned.index);
      })
      ..orderBy([(t) => OrderingTerm(expression: t.startMin)]);
    return _toBlocks(await query.get());
  }

  /// 今天之前还没做完的方块（顺延弹窗的数据源）
  Future<List<CarryOver>> unfinishedBefore(String dateKey) async {
    final query = _db.select(_db.dayBlocks)
      ..where(
        (t) =>
            t.date.isSmallerThanValue(dateKey) &
            t.deletedAt.isNull() &
            t.done.equals(false) &
            t.status.equals(BlockStatus.planned.index),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.date),
        (t) => OrderingTerm(expression: t.startMin),
      ]);
    final rows = await query.get();
    return [
      for (final row in rows) CarryOver(date: row.date, block: _toBlock(row)),
    ];
  }

  /// 全局搜索：标题或备注里包含 [query]，按日期倒序、同一天按开始时间。
  ///
  /// 只搜没被软删除的行；已完成 / 顺延的也搜得到（历史记录也要能找回来）。
  Future<List<({String date, TBlock block})>> search(
    String query, {
    int limit = 80,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final pattern = '%$q%';
    final rows = await (_db.select(_db.dayBlocks)
          ..where(
            (t) =>
                t.deletedAt.isNull() &
                (t.title.like(pattern) | t.note.like(pattern)),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.startMin),
          ])
          ..limit(limit))
        .get();
    return [for (final row in rows) (date: row.date, block: _toBlock(row))];
  }

  /// 周视图用：一次取回区间内所有未完成方块，按日期分组。
  Future<Map<String, List<TBlock>>> blocksInRange(
    String startKey,
    String endKey,
  ) async {
    final query = _db.select(_db.dayBlocks)
      ..where(
        (t) =>
            t.date.isBetweenValues(startKey, endKey) &
            t.deletedAt.isNull() &
            t.status.equals(BlockStatus.planned.index),
      )
      ..orderBy([(t) => OrderingTerm(expression: t.startMin)]);
    final rows = await query.get();
    final grouped = <String, List<TBlock>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.date, () => <TBlock>[]).add(_toBlock(row));
    }
    return grouped;
  }

  /// 日历月视图用：区间内每天还剩多少条（不含已完成的）
  Future<Map<String, int>> countByDateRange(
    String startKey,
    String endKey,
  ) async {
    final count = _db.dayBlocks.id.count();
    final query = _db.selectOnly(_db.dayBlocks)
      ..addColumns([_db.dayBlocks.date, count])
      ..where(
        _db.dayBlocks.date.isBetweenValues(startKey, endKey) &
            _db.dayBlocks.deletedAt.isNull() &
            _db.dayBlocks.status.equals(BlockStatus.planned.index),
      )
      ..groupBy([_db.dayBlocks.date]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(_db.dayBlocks.date)!: row.read(count) ?? 0,
    };
  }

  Future<void> upsert(TBlock block, String date) {
    return _db
        .into(_db.dayBlocks)
        .insertOnConflictUpdate(_toCompanion(block, date));
  }

  Future<void> upsertAll(Iterable<TBlock> blocks, String date) async {
    final rows = [for (final b in blocks) _toCompanion(b, date)];
    if (rows.isEmpty) return;
    await _db.batch((batch) {
      for (final row in rows) {
        batch.insert(_db.dayBlocks, row, onConflict: DoUpdate((_) => row));
      }
    });
  }

  /// 改状态：done / carried / dropped，顺带更新 updatedAt
  Future<void> setStatus(String id, BlockStatus status) {
    final now = DateTime.now();
    return (_db.update(_db.dayBlocks)..where((t) => t.id.equals(id))).write(
      DayBlocksCompanion(
        status: Value(status.index),
        done: Value(status == BlockStatus.done),
        updatedAt: Value(now),
      ),
    );
  }

  /// 软删除：保留墓碑，同步时能传播「这条没了」
  Future<void> softDelete(String id) {
    final now = DateTime.now();
    return (_db.update(_db.dayBlocks)..where((t) => t.id.equals(id))).write(
      DayBlocksCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<int> countDay(String date) async {
    final count = _db.dayBlocks.id.count();
    final query = _db.selectOnly(_db.dayBlocks)
      ..addColumns([count])
      ..where(
        _db.dayBlocks.date.equals(date) & _db.dayBlocks.deletedAt.isNull(),
      );
    return (await query.getSingle()).read(count) ?? 0;
  }

  /// 全库还有多少条方块（用来判断是不是第一次启动，避免删空后又被灌示例）
  Future<int> countAll() async {
    final count = _db.dayBlocks.id.count();
    final query = _db.selectOnly(_db.dayBlocks)
      ..addColumns([count])
      ..where(_db.dayBlocks.deletedAt.isNull());
    return (await query.getSingle()).read(count) ?? 0;
  }

  List<TBlock> _toBlocks(List<DayBlock> rows) => [
    for (final row in rows) _toBlock(row),
  ];

  TBlock _toBlock(DayBlock r) {
    return TBlock(
      id: r.id,
      title: r.title,
      lane: Lane(id: r.lane, name: r.lane),
      startMin: r.startMin,
      durationMin: r.durationMin,
      priority:
          Priority.values[r.priority.clamp(0, Priority.values.length - 1)],
      deadline: r.deadlineAt,
      done: r.done,
      note: r.note ?? '',
      sourceType: BlockSource.byIndex(r.sourceType),
      sourceId: r.sourceId,
      instanceGroupId: r.instanceGroupId,
      fromBlockId: r.fromBlockId,
      carryCount: r.carryCount,
      originalDate: r.originalDate,
      status: BlockStatus.byIndex(r.status),
    );
  }

  DayBlocksCompanion _toCompanion(TBlock b, String date) {
    final now = DateTime.now();
    return DayBlocksCompanion(
      id: Value(b.id),
      date: Value(date),
      title: Value(b.title),
      lane: Value(b.lane.id),
      startMin: Value(b.startMin),
      durationMin: Value(b.durationMin),
      priority: Value(b.priority.index),
      deadlineAt: Value(b.deadline),
      note: Value(b.note.isEmpty ? null : b.note),
      done: Value(b.done),
      status: Value(b.status.index),
      sourceType: Value(b.sourceType.index),
      sourceId: Value(b.sourceId),
      instanceGroupId: Value(b.instanceGroupId),
      fromBlockId: Value(b.fromBlockId),
      carryCount: Value(b.carryCount),
      originalDate: Value(b.originalDate),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }
}
