import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/core/time_utils.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/data/repositories/day_block_repository.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/features/timeline/timeline_state.dart';

import 'support/seed_helper.dart';

/// 全局搜索 + 「方块不许越过 24:00」的夹紧逻辑。
Future<void> settle(ProviderContainer container) async {
  for (var i = 0; i < 200; i++) {
    if (!container.read(timelineProvider).loading) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('时间轴一直没有加载完');
}

void main() {
  group('纯函数夹紧', () {
    test('开始时间放不下时长就往前夹', () {
      expect(clampStartMinute(1439, 30), 1410);
      expect(clampStartMinute(-20, 30), 0);
      expect(clampStartMinute(600, 30), 600);
    });

    test('时长不会顶出 24:00', () {
      expect(clampDuration(1410, 60), 30);
      expect(clampDuration(0, 2000), 1440);
      expect(clampDuration(600, 1), kMinDuration);
    });
  });

  group('仓库与状态层', () {
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

    test('按标题和备注都能搜到，完成的也搜得到', () async {
      await repo.upsert(
        const TBlock(
          id: 'search-title',
          title: '交周报',
          lane: Lane.temp,
          startMin: 630,
          durationMin: 60,
          priority: Priority.a,
        ),
        '2026-11-10',
      );
      await repo.upsert(
        const TBlock(
          id: 'search-note',
          title: '复诊',
          note: '记得带上次的化验单',
          lane: Lane.temp,
          startMin: 600,
          durationMin: 30,
          priority: Priority.b,
        ),
        '2026-11-12',
      );
      await repo.upsert(
        const TBlock(
          id: 'search-done',
          title: '交周报（上周）',
          lane: Lane.temp,
          startMin: 630,
          durationMin: 60,
          priority: Priority.a,
          done: true,
          status: BlockStatus.done,
        ),
        '2026-11-09',
      );

      final byTitle = await repo.search('周报');
      expect(byTitle.map((h) => h.block.id), contains('search-title'));
      expect(byTitle.map((h) => h.block.id), contains('search-done'));

      final byNote = await repo.search('化验单');
      expect(byNote.single.block.id, 'search-note');

      // 日期倒序
      expect(byTitle.first.date.compareTo(byTitle.last.date), greaterThan(0));

      expect(await repo.search('   '), isEmpty);
      expect(await repo.search('根本不存在的词'), isEmpty);
    });

    test('软删除的行不会再被搜到', () async {
      await repo.upsert(
        const TBlock(
          id: 'gone',
          title: '要删掉的',
          lane: Lane.daily,
          startMin: 100,
          durationMin: 30,
          priority: Priority.c,
        ),
        '2026-11-12',
      );
      expect(await repo.search('要删掉'), hasLength(1));
      await repo.softDelete('gone');
      expect(await repo.search('要删掉'), isEmpty);
    });

    test('拖动和拉长都不会越过 24:00', () async {
      final notifier = container.read(timelineProvider.notifier);
      final today = container.read(timelineProvider).blocks.first;

      notifier.moveBlock(today.id, startMin: 1439, lane: today.lane);
      var moved = container
          .read(timelineProvider)
          .blocks
          .firstWhere((b) => b.id == today.id);
      expect(moved.startMin, kMinutesPerDay - today.durationMin);

      notifier.resizeBlock(today.id, durationMin: 1440);
      final resized = container
          .read(timelineProvider)
          .blocks
          .firstWhere((b) => b.id == today.id);
      expect(
        resized.startMin + resized.durationMin,
        lessThanOrEqualTo(kMinutesPerDay),
      );
    });

    test('updateBlock 把时间推到更晚时会连时长一起夹', () async {
      final notifier = container.read(timelineProvider.notifier);
      final target = container.read(timelineProvider).blocks.first;

      notifier.updateBlock(
        target.id,
        startMin: 1430,
        durationMin: 120,
      );
      final updated = container
          .read(timelineProvider)
          .blocks
          .firstWhere((b) => b.id == target.id);
      expect(updated.startMin, 1430);
      expect(updated.durationMin, kMinutesPerDay - 1430);
    });
  });
}
