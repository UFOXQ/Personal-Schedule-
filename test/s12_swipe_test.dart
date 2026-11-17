import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/features/timeline/timeline_state.dart';

import 'support/seed_helper.dart';

Future<void> settle(ProviderContainer container) async {
  for (var i = 0; i < 200; i++) {
    if (!container.read(timelineProvider).loading) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('时间轴一直没有加载完');
}

void main() {
  late TntDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = TntDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    container.read(timelineProvider.notifier);
    await settle(container);
    await seedTimeline(container);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('左滑完成 / 右滑顺延（状态层）', () {
    test('completeBlock 把指定方块从今天移除并写完成记录', () async {
      final notifier = container.read(timelineProvider.notifier);
      final before = container.read(timelineProvider).blocks;
      final target = before.first;

      await notifier.completeBlock(target.id);
      final after = container.read(timelineProvider).blocks;

      expect(after.length, before.length - 1);
      expect(after.any((b) => b.id == target.id), isFalse);

      final logs = await container
          .read(libraryRepositoryProvider)
          .completions(limit: 5);
      expect(logs.any((l) => l.dayBlockId == target.id), isTrue);
    });

    test('锁定时 completeBlock 不生效', () async {
      final notifier = container.read(timelineProvider.notifier);
      notifier.toggleLock();
      final before = container.read(timelineProvider).blocks;
      await notifier.completeBlock(before.first.id);
      expect(container.read(timelineProvider).blocks.length, before.length);
    });

    test('右滑顺延：今天少一条、明天多一条，并且能撤销', () async {
      final notifier = container.read(timelineProvider.notifier);
      final before = container.read(timelineProvider).blocks;
      final target = before.first;

      final createdId = await notifier.carryOverToNextDay(target.id);
      expect(createdId, isNotNull);
      expect(container.read(timelineProvider).blocks.length, before.length - 1);

      await notifier.undoCarryOver(target, createdId!);
      final back = container.read(timelineProvider).blocks;
      expect(back.any((b) => b.id == target.id), isTrue);
      expect(back.any((b) => b.id == createdId), isFalse);
    });

    test('顺延不存在的 id 返回 null', () async {
      final notifier = container.read(timelineProvider.notifier);
      expect(await notifier.carryOverToNextDay('not-exist'), isNull);
    });
  });
}
