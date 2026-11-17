import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/data/repositories/day_block_repository.dart';
import 'package:tnt_app/domain/calendar/week_row.dart';
import 'package:tnt_app/domain/models/day_jump.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/features/timeline/timeline_state.dart';

import 'support/seed_helper.dart';

/// 跨天拖拽（moveToDate）+ 周视图色块跳时刻要用到的领域数据。
Future<void> settle(ProviderContainer container) async {
  for (var i = 0; i < 200; i++) {
    if (!container.read(timelineProvider).loading) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('时间轴一直没有加载完');
}

void main() {
  group('周视图分段', () {
    test('分段带上原开始时间，点它才知道跳哪儿', () {
      const block = TBlock(
        id: 'a',
        title: '交周报',
        lane: Lane.temp,
        startMin: 630,
        durationMin: 60,
        priority: Priority.a,
      );
      final segments = weekSegments(const [block]);
      expect(segments.single.startMin, 630);
    });

    test('DayJump 的 minute 可以为空（只跳到某天）', () {
      const jump = (date: '2026-11-16', minute: null) as DayJump;
      expect(jump.date, '2026-11-16');
      expect(jump.minute, isNull);
    });
  });

  group('moveToDate', () {
    late TntDatabase db;
    late ProviderContainer container;
    late DayBlockRepository repo;

    setUp(() async {
      db = TntDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      container.read(timelineProvider.notifier);
      await settle(container);
    await seedTimeline(container);
      repo = DayBlockRepository(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('方块整条挪到另一天，今天列表里就没了', () async {
      final notifier = container.read(timelineProvider.notifier);
      final todayKey = container.read(timelineProvider).dateKey;
      final block = container.read(timelineProvider).blocks.first;

      final moved = await notifier.moveToDate(block.id, '2026-11-20');
      expect(moved, isTrue);
      expect(
        container.read(timelineProvider).blocks.map((b) => b.id),
        isNot(contains(block.id)),
      );

      final target = await repo.loadDay(
        '2026-11-20',
        includeDone: true,
      );
      final row = target.firstWhere((b) => b.id == block.id);
      expect(row.title, block.title);
      expect(row.startMin, block.startMin);

      // 原日期只剩软删除/移动后的其他行
      final source = await repo.loadDay(todayKey, includeDone: true);
      expect(source.map((b) => b.id), isNot(contains(block.id)));
    });

    test('挪到同一天 / 锁定态都不做事', () async {
      final notifier = container.read(timelineProvider.notifier);
      final todayKey = container.read(timelineProvider).dateKey;
      final block = container.read(timelineProvider).blocks.first;

      expect(await notifier.moveToDate(block.id, todayKey), isFalse);

      notifier.toggleLock();
      expect(await notifier.moveToDate(block.id, '2026-11-21'), isFalse);
    });
  });
}
