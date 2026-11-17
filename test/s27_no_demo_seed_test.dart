import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/repositories/day_block_repository.dart';
import 'package:tnt_app/data/providers.dart';
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

  setUp(() {
    db = TntDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer newContainer() => ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );

  test('首次启动是空的：没有方块、没有合集、没有计划', () async {
    final container = newContainer();
    addTearDown(container.dispose);
    container.read(timelineProvider.notifier);
    await settle(container);

    expect(container.read(timelineProvider).blocks, isEmpty);
    final lib = container.read(libraryRepositoryProvider);
    expect(await lib.collections(), isEmpty);
    expect(await lib.plans(), isEmpty);
    expect(await lib.templates(), isEmpty);
  });

  test('清空时间轴后重开也不会把方块灌回来', () async {
    final first = newContainer();
    addTearDown(first.dispose);
    final notifier = first.read(timelineProvider.notifier);
    await settle(first);

    notifier.addBlockAt(lane: Lane.daily, startMin: 10 * 60);
    notifier.addBlockAt(lane: Lane.habit, startMin: 11 * 60);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(first.read(timelineProvider).blocks, hasLength(2));

    await notifier.clearBlocks(
      lanes: {Lane.daily, Lane.habit, Lane.temp},
      includeDone: true,
    );
    expect(first.read(timelineProvider).blocks, isEmpty);

    // 模拟用户切到别的页面再回来 / 重启 App：重新建容器走一遍 _load
    final second = newContainer();
    addTearDown(second.dispose);
    second.read(timelineProvider.notifier);
    await settle(second);
    expect(
      second.read(timelineProvider).blocks,
      isEmpty,
      reason: '清空之后 _load 不能再判定成「首次启动」把示例塞回来',
    );
  });

  test('老版本遗留的 seed- 样例会被自动清掉，用户自己的方块不动', () async {
    final repo = DayBlockRepository(db);
    final today = DateTime.now();
    await repo.upsert(
      TBlock(
        id: 'seed-cat',
        title: '喂猫',
        lane: Lane.habit,
        startMin: 430,
        durationMin: 15,
        priority: Priority.c,
        done: false,
        status: BlockStatus.planned,
      ),
      _key(today),
    );
    await repo.upsert(
      TBlock(
        id: 'mine',
        title: '我自己的事',
        lane: Lane.daily,
        startMin: 600,
        durationMin: 30,
        priority: Priority.a,
        done: false,
        status: BlockStatus.planned,
      ),
      _key(today),
    );

    final container = newContainer();
    addTearDown(container.dispose);
    container.read(timelineProvider.notifier);
    await settle(container);

    final ids = container.read(timelineProvider).blocks.map((b) => b.id).toSet();
    expect(ids.contains('seed-cat'), isFalse);
    expect(ids.contains('mine'), isTrue);
    expect(
      container.read(timelineProvider).blocks.single.title,
      '我自己的事',
      reason: '不能误删用户数据（也不能拿中文标题当条件，这里按 id 判）',
    );
  });
}

String _key(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
