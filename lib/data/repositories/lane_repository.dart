import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/models/lane.dart';
import '../db/tnt_database.dart';

/// 泳道的读写。泳道是可以让用户自己增删改名的，所以存表而不是写死枚举。
class LaneRepository {
  LaneRepository(this._db);

  final TntDatabase _db;

  static final Random _random = Random();
  static int _seq = 0;

  Future<List<Lane>> all() async {
    final query = _db.select(_db.laneRows)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.createdAt),
        (t) => OrderingTerm(expression: t.id),
      ]);
    final rows = await query.get();
    if (rows.isEmpty) return Lane.defaults;
    return [
      for (final r in rows)
        Lane(id: r.id, name: r.name, sortOrder: r.sortOrder),
    ];
  }

  Future<void> add(String name) async {
    final existing = await all();
    // 时间戳单独用不够：连续两次 add 可能落在同一微秒（尤其是 Windows 上
    // 计时器精度粗），会撞主键。加序号 + 随机后缀兜底。
    final id = 'lane-${DateTime.now().microsecondsSinceEpoch}'
        '-${_seq++}-${_random.nextInt(0x10000).toRadixString(16)}';
    final now = DateTime.now();
    await _db.into(_db.laneRows).insert(
          LaneRowsCompanion.insert(
            id: id,
            name: name.trim(),
            sortOrder: Value(existing.length),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> rename(String id, String name) async {
    await (_db.update(_db.laneRows)..where((t) => t.id.equals(id))).write(
      LaneRowsCompanion(
        name: Value(name.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 按给定顺序把 sortOrder 重排（0,1,2...）
  Future<void> reorder(List<Lane> lanes) async {
    final now = DateTime.now();
    await _db.batch((batch) {
      for (var i = 0; i < lanes.length; i++) {
        batch.update(
          _db.laneRows,
          LaneRowsCompanion(
            sortOrder: Value(i),
            updatedAt: Value(now),
          ),
          where: (t) => t.id.equals(lanes[i].id),
        );
      }
    });
  }

  Future<void> remove(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.laneRows)..where((t) => t.id.equals(id))).write(
      LaneRowsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// 重置回「日常 / 打卡 / 临时」
  Future<void> resetToDefaults() async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db.delete(_db.laneRows).go();
      for (final lane in Lane.defaults) {
        await _db.into(_db.laneRows).insert(
              LaneRowsCompanion.insert(
                id: lane.id,
                name: lane.name,
                sortOrder: Value(lane.sortOrder),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
  }
}
