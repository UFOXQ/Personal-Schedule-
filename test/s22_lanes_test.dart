import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/repositories/lane_repository.dart';
import 'package:tnt_app/domain/models/lane.dart';

void main() {
  late TntDatabase db;
  late LaneRepository repo;

  setUp(() async {
    db = TntDatabase.forTesting(NativeDatabase.memory());
    repo = LaneRepository(db);
    // onCreate 会塞默认三条，这里先确认
    await db.customSelect('select 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  test('新库自动带上默认三条泳道', () async {
    final lanes = await repo.all();
    expect(lanes.map((lane) => lane.name), ['日常', '打卡', '临时']);
  });

  test('增、改名、排序、删', () async {
    await repo.add('工作');
    var lanes = await repo.all();
    expect(lanes.length, 4);
    expect(lanes.last.name, '工作');

    await repo.rename(lanes.last.id, '深度工作');
    lanes = await repo.all();
    expect(lanes.last.name, '深度工作');

    // 把最后一条挪到最前
    final reordered = [lanes.last, ...lanes.take(lanes.length - 1)];
    await repo.reorder(reordered);
    lanes = await repo.all();
    expect(lanes.first.name, '深度工作');

    await repo.remove(lanes.first.id);
    lanes = await repo.all();
    expect(lanes.length, 3);
    expect(lanes.map((lane) => lane.name), ['日常', '打卡', '临时']);
  });

  test('重置回默认三条', () async {
    await repo.add('A');
    await repo.add('B');
    await repo.rename('daily', '生活');
    expect((await repo.all()).length, 5);

    await repo.resetToDefaults();
    final lanes = await repo.all();
    expect(lanes.length, 3);
    expect(lanes.map((lane) => lane.name), ['日常', '打卡', '临时']);
    expect(lanes.first, Lane.daily);
  });
}
