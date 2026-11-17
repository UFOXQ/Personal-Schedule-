import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/repositories/inbox_repository.dart';
import 'package:tnt_app/domain/models/tblock.dart';

void main() {
  late TntDatabase db;
  late InboxRepository repo;

  setUp(() {
    db = TntDatabase.forTesting(NativeDatabase.memory());
    repo = InboxRepository(db);
  });

  tearDown(() async => db.close());

  test('加一条：字段都存下来，没给时间的就是 null', () async {
    await repo.add(
      title: '写周报',
      lane: Lane.temp,
      startMin: 14 * 60,
      durationMin: 60,
      priority: Priority.a,
    );
    await repo.add(title: '拉伸', lane: Lane.habit, priority: Priority.d);

    final rows = await repo.items();
    expect(rows.length, 2);
    expect(rows.first.title, '写周报');
    expect(rows.first.startMin, 14 * 60);
    expect(rows.first.durationMin, 60);
    expect(rows.first.priority, Priority.a.index);
    expect(rows.last.startMin, isNull);
    expect(rows.last.lane, Lane.habit.id);
  });

  test('删掉之后列表里没有，但墓碑还在（同步要看）', () async {
    final item = await repo.add(title: '临时念头');
    await repo.remove(item.id);

    expect(await repo.items(), isEmpty);
    expect(await repo.count(), 0);
    final all = await db.select(db.inboxItems).get();
    expect(all.length, 1);
    expect(all.single.deletedAt, isNotNull);
  });

  test('可以带日期：拖进合集/放到指定的那天用', () async {
    await repo.add(title: '下周体检', day: '2026-11-20');
    final rows = await repo.items();
    expect(rows.single.day, '2026-11-20');
  });
}
