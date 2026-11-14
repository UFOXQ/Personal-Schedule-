import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/data/repositories/day_block_repository.dart';
import 'package:tnt_app/data/repositories/library_repository.dart';
import 'package:tnt_app/features/timeline/timeline_state.dart';

/// 状态层的行为验证（不起 UI）：完成、集合投入、幂等。
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
  late DayBlockRepository dayRepo;
  late LibraryRepository libRepo;

  setUp(() async {
    db = TntDatabase.forTesting(NativeDatabase.memory());
    dayRepo = DayBlockRepository(db);
    libRepo = LibraryRepository(db);
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

  test('首次启动会灌示例数据，并且长期计划当天被物化了一份', () async {
    final state = container.read(timelineProvider);
    expect(state.blocks, isNotEmpty);
    // 学英语来自「计划」物化，不是手写 seed
    final english = state.blocks.where((b) => b.title == '学英语').toList();
    expect(english, hasLength(1));
    expect(english.single.carryCount, 0);

    final plans = await libRepo.plans();
    expect(plans.map((p) => p.title), contains('学英语'));
  });

  test('完成选中方块：当天列表少一条，完成记录多一条', () async {
    final notifier = container.read(timelineProvider.notifier);
    final target = container.read(timelineProvider).blocks.first;
    notifier.select(target.id);
    expect(container.read(timelineProvider).selectedId, target.id);

    final before = container.read(timelineProvider).blocks.length;
    await notifier.completeSelected();

    final after = container.read(timelineProvider);
    expect(after.blocks.length, before - 1);
    expect(after.selectedId, isNull);
    expect(after.blocks.any((b) => b.id == target.id), isFalse);

    final logs = await libRepo.completions();
    expect(logs.single.title, target.title);

    final todayKey = container.read(timelineProvider).dateKey;
    final raw = await dayRepo.loadDay(todayKey, includeDone: true);
    expect(raw.firstWhere((b) => b.id == target.id).done, isTrue);
  });

  test('投入集合：加进当天，重复投入不再叠加', () async {
    final notifier = container.read(timelineProvider.notifier);
    final collections = await libRepo.collections();
    expect(collections, isNotEmpty);
    final id = collections.first.id;

    final before = container.read(timelineProvider).blocks.length;
    final added = await notifier.injectCollection(id);
    expect(added, greaterThan(0));
    expect(container.read(timelineProvider).blocks.length, before + added);

    final again = await notifier.injectCollection(id);
    expect(again, 0, reason: '同一集合同一天只能投一次');
    expect(container.read(timelineProvider).blocks.length, before + added);
  });

  test('重启后不会重复物化计划方块', () async {
    final todayKey = container.read(timelineProvider).dateKey;
    final before = await dayRepo.loadDay(todayKey);

    // 模拟重启：新建一个 container，复用同一个库
    final second = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(second.dispose);
    second.read(timelineProvider.notifier);
    await settle(second);

    final after = await dayRepo.loadDay(todayKey);
    expect(after.length, before.length);
    expect(after.where((b) => b.title == '学英语'), hasLength(1));
  });
}
