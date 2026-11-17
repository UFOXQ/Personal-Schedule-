import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/repositories/day_block_repository.dart';
import 'package:tnt_app/data/repositories/library_repository.dart';
import 'package:tnt_app/domain/models/tblock.dart';

TBlock _block(
  String id, {
  String title = '测试方块',
  Lane lane = Lane.daily,
  int startMin = 600,
  int durationMin = 30,
  Priority priority = Priority.c,
  bool done = false,
}) {
  return TBlock(
    id: id,
    title: title,
    lane: lane,
    startMin: startMin,
    durationMin: durationMin,
    priority: priority,
    done: done,
  );
}

void main() {
  late TntDatabase db;
  late DayBlockRepository dayRepo;
  late LibraryRepository libRepo;

  setUp(() {
    db = TntDatabase.forTesting(NativeDatabase.memory());
    dayRepo = DayBlockRepository(db);
    libRepo = LibraryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DayBlockRepository', () {
    test('写入后能按开始时间读回来', () async {
      await dayRepo.upsertAll([
        _block('b2', title: '午饭', startMin: 765, durationMin: 45),
        _block('b1', title: '早餐', startMin: 460, durationMin: 30),
      ], '2026-11-13');

      final blocks = await dayRepo.loadDay('2026-11-13');
      expect(blocks.map((b) => b.title).toList(), ['早餐', '午饭']);
      expect(blocks.first.startMin, 460);
      expect(blocks.last.durationMin, 45);
      expect(await dayRepo.countDay('2026-11-13'), 2);
    });

    test('同 id 再写是更新而不是新增', () async {
      await dayRepo.upsert(_block('b1', title: '早餐'), '2026-11-13');
      await dayRepo.upsert(
        _block('b1', title: '早餐', startMin: 500, durationMin: 40),
        '2026-11-13',
      );

      final blocks = await dayRepo.loadDay('2026-11-13');
      expect(blocks, hasLength(1));
      expect(blocks.single.startMin, 500);
      expect(blocks.single.durationMin, 40);
    });

    test('软删除后查不到，但墓碑还在库里', () async {
      await dayRepo.upsert(_block('b1', title: '喂猫'), '2026-11-13');
      await dayRepo.softDelete('b1');

      expect(await dayRepo.loadDay('2026-11-13'), isEmpty);
      expect(await dayRepo.countDay('2026-11-13'), 0);

      final raw = await db.select(db.dayBlocks).get();
      expect(raw, hasLength(1));
      expect(raw.single.deletedAt, isNotNull);
    });

    test('不同日期互不干扰', () async {
      await dayRepo.upsert(_block('b1', title: '今天'), '2026-11-13');
      await dayRepo.upsert(_block('b2', title: '明天'), '2026-11-14');

      expect((await dayRepo.loadDay('2026-11-13')).single.title, '今天');
      expect((await dayRepo.loadDay('2026-11-14')).single.title, '明天');
    });
  });

  group('LibraryRepository.plansOn', () {
    PlansCompanion plan({
      required String id,
      required String startDate,
      required String endDate,
      int mask = 127,
    }) {
      final now = DateTime.now();
      return PlansCompanion(
        id: Value(id),
        title: const Value('学英语'),
        startDate: Value(startDate),
        endDate: Value(endDate),
        weekdaysMask: Value(mask),
        lane: const Value('habit'),
        startMin: const Value(540),
        durationMin: const Value(60),
        priority: const Value(2),
        createdAt: Value(now),
        updatedAt: Value(now),
      );
    }

    test('区间内命中，区间外不命中', () async {
      await libRepo.savePlan(
        plan(id: 'p1', startDate: '2026-11-01', endDate: '2026-12-31'),
      );

      final hit = await libRepo.plansOn(DateTime(2026, 11, 13));
      expect(hit.map((p) => p.id), ['p1']);

      final miss = await libRepo.plansOn(DateTime(2027, 1, 5));
      expect(miss, isEmpty);
    });

    test('星期掩码生效：只在周一排的计划，周五不出现', () async {
      await libRepo.savePlan(
        plan(
          id: 'monday',
          startDate: '2026-01-01',
          endDate: '2026-12-31',
          mask: 1 << (DateTime.monday - 1),
        ),
      );

      // 2026-11-09 是周一，2026-11-13 是周五
      expect((await libRepo.plansOn(DateTime(2026, 11, 9))).map((p) => p.id), [
        'monday',
      ]);
      expect(await libRepo.plansOn(DateTime(2026, 11, 13)), isEmpty);
    });
  });

  test('formatDateKey 补零', () {
    expect(formatDateKey(DateTime(2026, 1, 5)), '2026-01-05');
    expect(formatDateKey(DateTime(2026, 12, 31)), '2026-12-31');
  });
}
