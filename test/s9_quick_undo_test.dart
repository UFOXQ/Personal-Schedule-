import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/data/repositories/day_block_repository.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/features/timeline/timeline_state.dart';

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
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  DayBlockRepository repo() => container.read(dayBlockRepositoryProvider);

  test('一句话添加：加到明天时不动今天列表，但库里有了', () async {
    final notifier = container.read(timelineProvider.notifier);
    final today = container.read(timelineProvider).dateKey;
    final before = container.read(timelineProvider).blocks.length;
    final tomorrow = DateTime.parse(today).add(const Duration(days: 1));
    final key = '${tomorrow.year.toString().padLeft(4, '0')}-'
        '${tomorrow.month.toString().padLeft(2, '0')}-'
        '${tomorrow.day.toString().padLeft(2, '0')}';

    final created = await notifier.addBlock(
      title: '交周报',
      lane: Lane.temp,
      startMin: 630,
      durationMin: 45,
      priority: Priority.a,
      dateKey: key,
    );

    expect(created, isNotNull);
    expect(container.read(timelineProvider).blocks.length, before);
    final nextDay = await repo().loadDay(key);
    final found = nextDay.firstWhere((b) => b.id == created!.id);
    expect(found.title, '交周报');
    expect(found.startMin, 630);
    expect(found.durationMin, 45);
    expect(found.priority, Priority.a);
  });

  test('一句话添加：加到今天就立刻出现在列表并选中', () async {
    final notifier = container.read(timelineProvider.notifier);
    final today = container.read(timelineProvider).dateKey;
    final before = container.read(timelineProvider).blocks.length;

    final created = await notifier.addBlock(
      title: '买牛奶',
      lane: Lane.daily,
      startMin: 1200,
      durationMin: 30,
      priority: Priority.d,
    );

    final state = container.read(timelineProvider);
    expect(state.blocks.length, before + 1);
    expect(state.selectedId, created!.id);
    expect(state.dateKey, today);
  });

  test('撤销删除：原样放回来', () async {
    final notifier = container.read(timelineProvider.notifier);
    final target = container.read(timelineProvider).blocks.first;

    notifier.deleteBlock(target.id);
    expect(
      container.read(timelineProvider).blocks.any((b) => b.id == target.id),
      isFalse,
    );

    await notifier.restoreBlock(target);
    final restored = container
        .read(timelineProvider)
        .blocks
        .firstWhere((b) => b.id == target.id);
    expect(restored.title, target.title);
    expect(restored.startMin, target.startMin);
    expect(restored.durationMin, target.durationMin);
  });

  test('撤销顺延：今天这条回到未完成，明天那份被删', () async {
    final notifier = container.read(timelineProvider.notifier);
    final target = container.read(timelineProvider).blocks.first;
    final today = container.read(timelineProvider).dateKey;

    final createdId = await notifier.carryOverToNextDay(target.id);
    expect(createdId, isNotNull);
    expect(
      container.read(timelineProvider).blocks.any((b) => b.id == target.id),
      isFalse,
    );

    await notifier.undoCarryOver(target, createdId!);
    final back = container
        .read(timelineProvider)
        .blocks
        .firstWhere((b) => b.id == target.id);
    expect(back.status, BlockStatus.planned);

    final tomorrow = DateTime.parse(today).add(const Duration(days: 1));
    final key = '${tomorrow.year.toString().padLeft(4, '0')}-'
        '${tomorrow.month.toString().padLeft(2, '0')}-'
        '${tomorrow.day.toString().padLeft(2, '0')}';
    final nextDay = await repo().loadDay(key);
    expect(nextDay.any((b) => b.id == createdId), isFalse);
  });

  test('集合投到别的日子：今天列表不动，那天有方块', () async {
    final notifier = container.read(timelineProvider.notifier);
    final collections = await container.read(libraryRepositoryProvider).collections();
    expect(collections, isNotEmpty);
    final collectionId = collections.first.id;

    final today = container.read(timelineProvider).dateKey;
    final before = container.read(timelineProvider).blocks.length;
    final dayAfter = DateTime.parse(today).add(const Duration(days: 2));
    final key = '${dayAfter.year.toString().padLeft(4, '0')}-'
        '${dayAfter.month.toString().padLeft(2, '0')}-'
        '${dayAfter.day.toString().padLeft(2, '0')}';

    final created = await notifier.injectCollectionFor(key, collectionId);
    expect(created, greaterThan(0));
    expect(container.read(timelineProvider).blocks.length, before);

    final thatDay = await repo().loadDay(key);
    expect(thatDay.length, created);
    // 再投一次是幂等的
    expect(await notifier.injectCollectionFor(key, collectionId), 0);
  });
}
