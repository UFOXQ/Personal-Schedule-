import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/data/repositories/day_block_repository.dart';
import 'package:tnt_app/data/repositories/library_repository.dart';
import 'package:tnt_app/domain/calendar/day_overview.dart';
import 'package:tnt_app/domain/calendar/month_grid.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/features/timeline/timeline_state.dart';

TBlock _block(
  String id, {
  String title = '方块',
  Lane lane = Lane.daily,
  int startMin = 600,
  int durationMin = 30,
  Priority priority = Priority.c,
  BlockStatus status = BlockStatus.planned,
  bool done = false,
}) {
  return TBlock(
    id: id,
    title: title,
    lane: lane,
    startMin: startMin,
    durationMin: durationMin,
    priority: priority,
    status: status,
    done: done,
  );
}

Future<void> _settleTimeline(ProviderContainer container) async {
  for (var i = 0; i < 200; i++) {
    if (!container.read(timelineProvider).loading) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('时间轴没有加载完');
}

void main() {
  group('月视图格子', () {
    test('2026 年 11 月 1 日是周日，前面空 6 格', () {
      final cells = monthCells(DateTime(2026, 11));
      expect(cells.length, 42);
      expect(cells.take(6).every((c) => c == null), isTrue);
      expect(cells[6]!.day, 1);
      expect(cells[6]!.month, 11);
      // 30 天：最后一格是 11/30
      expect(cells[35]!.day, 30);
      expect(cells[36], isNull);
    });

    test('月份天数和闰年', () {
      expect(daysInMonth(DateTime(2026, 2)), 28);
      expect(daysInMonth(DateTime(2028, 2)), 29);
      expect(daysInMonth(DateTime(2026, 11)), 30);
      expect(daysInMonth(DateTime(2026, 12)), 31);
    });

    test('加减月份会归到 1 号并跨年', () {
      expect(addMonths(DateTime(2026, 11, 13), 1), DateTime(2026, 12, 1));
      expect(addMonths(DateTime(2026, 1, 5), -1), DateTime(2025, 12, 1));
      expect(addMonths(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
    });

    test('周一为 0 的星期序号', () {
      expect(mondayIndex(DateTime(2026, 11, 9)), 0); // 周一
      expect(mondayIndex(DateTime(2026, 11, 13)), 4); // 周五
      expect(mondayIndex(DateTime(2026, 11, 15)), 6); // 周日
    });

    test('标签文案', () {
      expect(monthLabel(DateTime(2026, 11)), '2026 年 11 月');
      expect(dayLabel(DateTime(2026, 11, 13)), '11 月 13 日 · 周五');
    });
  });

  group('当天概览', () {
    final now = DateTime(2026, 11, 13, 10);
    test('合计时长 / 泳道计数 / 顶置项', () {
      final overview = DayOverview(
        dateKey: '2026-11-13',
        now: now,
        blocks: [
          _block('a', title: '喂猫', startMin: 430, durationMin: 15),
          _block(
            'b',
            title: '交周报',
            lane: Lane.temp,
            startMin: 630,
            durationMin: 60,
            priority: Priority.a,
          ),
          _block('c', title: '阅读', lane: Lane.habit, startMin: 840),
        ],
      );

      expect(overview.totalMinutes, 105);
      expect(overview.laneCounts[Lane.daily], 1);
      expect(overview.laneCounts[Lane.habit], 1);
      expect(overview.laneCounts[Lane.temp], 1);
      expect(overview.sorted.first.title, '喂猫');
      expect(overview.top.single.title, '交周报'); // A 级
    });

    test('空档只报 30 分钟以上的', () {
      final overview = DayOverview(
        dateKey: '2026-11-13',
        now: now,
        blocks: [
          _block('a', startMin: 540, durationMin: 60), // 9:00-10:00
          _block('b', startMin: 615, durationMin: 45), // 10:15-11:00（空档 15 分钟）
          _block('c', startMin: 780, durationMin: 60), // 13:00-14:00
        ],
      );
      expect(overview.gaps, [(0, 540), (660, 780)]);
    });

    test('空的一天', () {
      final overview = DayOverview(
        dateKey: '2026-11-13',
        now: now,
        blocks: const [],
      );
      expect(overview.isEmpty, isTrue);
      expect(overview.totalMinutes, 0);
      expect(overview.gaps, isEmpty);
    });
  });

  group('仓库', () {
    late TntDatabase db;
    late DayBlockRepository repo;
    late LibraryRepository lib;

    setUp(() {
      db = TntDatabase.forTesting(NativeDatabase.memory());
      repo = DayBlockRepository(db);
      lib = LibraryRepository(db);
    });

    tearDown(() => db.close());

    test('区间统计只算没完成的方块', () async {
      await repo.upsertAll([_block('a'), _block('b')], '2026-11-01');
      await repo.upsert(_block('c'), '2026-11-02');
      await repo.setStatus('c', BlockStatus.done);
      await repo.upsert(_block('d'), '2026-11-02');
      await repo.setStatus('d', BlockStatus.dropped);
      await repo.upsert(_block('e'), '2026-11-10');
      await repo.upsert(_block('f'), '2026-12-01'); // 区间外

      final counts = await repo.countByDateRange('2026-11-01', '2026-11-30');
      expect(counts['2026-11-01'], 2);
      expect(counts.containsKey('2026-11-02'), isFalse);
      expect(counts['2026-11-10'], 1);
      expect(counts.containsKey('2026-12-01'), isFalse);
    });

    test('计划改了之后能读回新值，删除是软删除', () async {
      await lib.createPlanSimple(
        id: 'p1',
        title: '学英语',
        startDate: '2026-11-01',
        endDate: '2026-12-31',
        lane: Lane.habit,
        startMin: 540,
        durationMin: 60,
        priority: Priority.b,
      );
      await lib.updatePlanSimple(
        id: 'p1',
        title: '学英语（听力）',
        startDate: '2026-11-01',
        endDate: '2026-12-31',
        lane: Lane.habit,
        startMin: 570,
        durationMin: 45,
        priority: Priority.a,
        weekdaysMask: 31,
      );
      final plan = (await lib.plans()).single;
      expect(plan.title, '学英语（听力）');
      expect(plan.startMin, 570);
      expect(plan.durationMin, 45);
      expect(plan.priority, Priority.a.index);
      expect(plan.weekdaysMask, 31);

      // 只在国内工作日生效
      expect((await lib.plansOn(DateTime(2026, 11, 13))), hasLength(1));
      expect((await lib.plansOn(DateTime(2026, 11, 14))), isEmpty);

      await lib.deletePlan('p1');
      expect(await lib.plans(), isEmpty);
      expect(await lib.plansOn(DateTime(2026, 11, 13)), isEmpty);
    });
  });

  group('时间轴日期跳转', () {
    late TntDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = TntDatabase.forTesting(NativeDatabase.memory());
      final today = DateTime.now();
      final dayRepo = DayBlockRepository(db);
      // 今天是唯一有数据的一天；昨天留一条没做完的
      await dayRepo.upsert(
        _block('today', title: '今天的活'),
        formatDateKey(today),
      );
      final yesterday = today.subtract(const Duration(days: 1));
      await dayRepo.upsert(
        _block('old', title: '昨天没做完'),
        formatDateKey(yesterday),
      );

      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      container.read(timelineProvider.notifier);
      await _settleTimeline(container);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('翻到昨天：换成昨天的数据，且不弹顺延窗', () async {
      final notifier = container.read(timelineProvider.notifier);
      final todayKey = container.read(timelineProvider).dateKey;
      await notifier.shiftDay(-1);
      await _settleTimeline(container);

      final state = container.read(timelineProvider);
      expect(state.dateKey, isNot(todayKey));
      expect(state.blocks.map((b) => b.title), ['昨天没做完']);
      expect(state.carryOvers, isEmpty, reason: '看历史日期不该被顺延弹窗拦住');

      await notifier.goToday();
      await _settleTimeline(container);
      expect(container.read(timelineProvider).dateKey, todayKey);
      expect(
        container.read(timelineProvider).blocks.map((b) => b.title),
        contains('今天的活'),
      );
    });

    test('跳到空白日期是空的，不会把种子数据倒进去', () async {
      final notifier = container.read(timelineProvider.notifier);
      await notifier.goToDate('2026-01-05');
      await _settleTimeline(container);

      final state = container.read(timelineProvider);
      expect(state.dateKey, '2026-01-05');
      expect(state.blocks, isEmpty);
      expect(await DayBlockRepository(db).countAll(), 2);
    });
  });
}
