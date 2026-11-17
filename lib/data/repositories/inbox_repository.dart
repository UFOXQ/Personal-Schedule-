import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/tblock.dart';
import '../db/tnt_database.dart';

/// 收件箱：还没排进某一天的任务。
///
/// 组合台的「待安排」就是它 —— 关掉页面也不会丢，
/// 拖进合集、点一下放到今天时再从这里删掉。
class InboxRepository {
  InboxRepository(this._db);

  final TntDatabase _db;
  static const _uuid = Uuid();

  Future<List<InboxItem>> items() {
    final query = _db.select(_db.inboxItems)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.get();
  }

  Future<int> count() async {
    final query = _db.select(_db.inboxItems)
      ..where((t) => t.deletedAt.isNull());
    final rows = await query.get();
    return rows.length;
  }

  Future<InboxItem> add({
    required String title,
    String? note,
    Lane lane = Lane.temp,
    int? startMin,
    int durationMin = 30,
    Priority priority = Priority.c,
    String? day,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final companion = InboxItemsCompanion.insert(
      id: id,
      title: title,
      note: Value(note),
      lane: Value(lane.id),
      startMin: Value(startMin),
      durationMin: Value(durationMin),
      priority: Value(priority.index),
      day: Value(day),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.inboxItems).insert(companion);
    return (await (_db.select(_db.inboxItems)..where((t) => t.id.equals(id)))
        .getSingle());
  }

  /// 软删除：同步时墓碑要能传过去
  Future<void> remove(String id) async {
    await (_db.update(_db.inboxItems)..where((t) => t.id.equals(id))).write(
      InboxItemsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateTitle(String id, String title) async {
    await (_db.update(_db.inboxItems)..where((t) => t.id.equals(id))).write(
      InboxItemsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
