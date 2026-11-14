import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/materialize.dart';
import 'package:tnt_app/data/repositories/day_block_repository.dart';
import 'package:tnt_app/data/repositories/library_repository.dart';
import 'package:tnt_app/domain/materialize.dart';
import 'package:tnt_app/domain/models/tblock.dart';

TBlock _block(
  String id, {
  String title = '方块',
  int startMin = 600,
  int durationMin = 30,
  bool done = false,
  BlockStatus status = BlockStatus.planned,
  int carryCount = 0,
}) {
  return TBlock(
    id: id,
    title: title,
    lane: Lane.daily,
    startMin: startMin,
    durationMin: durationMin,
    done: done,
    status: status,
    carryCount: carryCount,
  );
}

Plan _plan({String id = 'p1', String title = '学英语'}) => Plan(
  id: id,
  title: title,
  startDate: '2026-11-01',
  endDate: '2026-12-31',
  weekdaysMask: 127,
  lane: Lane.habit.index,
  startMin: 540,
  durationMin: 60,
  priority: Priority.b.index,
  createdAt: DateTime(2026, 11, 1),
  updatedAt: DateTime(2026, 11, 1),
);

CollectionItem _item(int startMin, String title) => CollectionItem(
  id: 'i$startMin',
  collectionId: 'c1',
  title: title,
  lane: Lane.daily.index,
  startMin: startMin,
  durationMin: 30,
  priority: Priority.c.index,
  sortOrder: 0,
  createdAt: DateTime(2026, 11, 1),
  updatedAt: DateTime(2026, 11, 1),
);

void main() {
  group('物化键', () {
    test('计划键带日期，天内唯一', () {
      expect(planInstanceKey('p1', '2026-11-13'), 'plan:p1@2026-11-13');
      expect(planInstanceKey('p1', '2026-11-14'), 'plan:p1@2026-11-14');
    });

    test('集合键带序号，避免同集合同一天重复叠两份', () {
      expect(
        collectionInstanceKey('c1', '2026-11-13', 0),
        'collection:c1@2026-11-13#0',
      );
      expect(
        collectionInstanceKey('c1', '2026-11-13', 1),
        'collection:c1@2026-11-13#1',
      );
    });

    test('已有键时不再物化', () {
      final blocks = [
        _block('a').copyWith(instanceGroupId: 'plan:p1@2026-11-13'),
      ];
      final keys = existingInstanceKeys(blocks);
      expect(needsMaterialize('plan:p1@2026-11-13', keys), isFalse);
      expect(needsMaterialize('plan:p1@2026-11-14', keys), isTrue);
    });
  });

  group('顺延', () {
    test('保留时段与来源，次数 +1，状态回到 planned', () {
      final source = _block('old', title: '交周报', startMin: 630).copyWith(
        carryCount: 2,
        originalDate: '2026-11-11',
        priority: Priority.a,
      );
      final moved = carryOverBlock(
        source,
        newId: 'new',
        sourceDateKey: '2026-11-12',
      );

      expect(moved.id, 'new');
      expect(moved.title, '交周报');
      expect(moved.startMin, 630);
      expect(moved.priority, Priority.a);
      expect(moved.fromBlockId, 'old');
      expect(moved.carryCount, 3);
      // 已经记过原始日期就不再覆盖
      expect(moved.originalDate, '2026-11-11');
      expect(moved.status, BlockStatus.planned);
      expect(moved.done, isFalse);
    });

    test('首次顺延会把来源日期记成 originalDate', () {
      final moved = carryOverBlock(
        _block('old'),
        newId: 'new',
        sourceDateKey: '2026-11-12',
      );
      expect(moved.originalDate, '2026-11-12');
      expect(moved.carryCount, 1);
      expect(moved.isCarried, isTrue);
    });

    test('只有 planned 且未完成的才需要问', () {
      expect(needsCarryPrompt(_block('a')), isTrue);
      expect(
        needsCarryPrompt(_block('a', done: true, status: BlockStatus.done)),
        isFalse,
      );
      expect(
        needsCarryPrompt(_block('a', status: BlockStatus.carried)),
        isFalse,
      );
      expect(
        needsCarryPrompt(_block('a', status: BlockStatus.dropped)),
        isFalse,
      );
    });
  });

  group('物化产物', () {
    test('计划生成一个方块，第二次给空', () {
      final first = blocksFromPlan(_plan(), '2026-11-13', {});
      expect(first, hasLength(1));
      expect(first.single.title, '学英语');
      expect(first.single.startMin, 540);
      expect(first.single.priority, Priority.b);
      expect(first.single.sourceType, BlockSource.plan);
      expect(first.single.instanceGroupId, 'plan:p1@2026-11-13');

      final second = blocksFromPlan(
        _plan(),
        '2026-11-13',
        existingInstanceKeys(first),
      );
      expect(second, isEmpty);
    });

    test('集合展开成多条，各自带幂等键', () {
      final blocks = blocksFromCollection('c1', [
        _item(430, '喂猫'),
        _item(460, '早餐'),
      ], '2026-11-13');

      expect(blocks.map((b) => b.title), ['喂猫', '早餐']);
      expect(blocks.map((b) => b.instanceGroupId), [
        'collection:c1@2026-11-13#0',
        'collection:c1@2026-11-13#1',
      ]);
      expect(
        blocks.every((b) => b.sourceType == BlockSource.collection),
        isTrue,
      );
    });
  });

  group('仓库：状态与顺延数据', () {
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

    test('标成 done 之后当天不再返回', () async {
      await dayRepo.upsert(_block('b1', title: '早餐'), '2026-11-13');
      await dayRepo.setStatus('b1', BlockStatus.done);

      expect(await dayRepo.loadDay('2026-11-13'), isEmpty);
      // 但连已完成一起看还在（记录页要能对上号）
      final all = await dayRepo.loadDay('2026-11-13', includeDone: true);
      expect(all.single.done, isTrue);
      expect(all.single.status, BlockStatus.done);
    });

    test('unfinishedBefore 只捞以前没做完的 planned 方块', () async {
      await dayRepo.upsertAll([
        _block('old1', title: '昨天没做完'),
        _block('old2', title: '昨天做完了', done: true),
      ], '2026-11-12');
      await dayRepo.setStatus('old2', BlockStatus.done);
      await dayRepo.upsert(_block('old3', title: '已顺延'), '2026-11-12');
      await dayRepo.setStatus('old3', BlockStatus.carried);
      await dayRepo.upsert(_block('today', title: '今天'), '2026-11-13');

      final pending = await dayRepo.unfinishedBefore('2026-11-13');
      expect(pending.map((c) => c.block.title), ['昨天没做完']);
      expect(pending.single.date, '2026-11-12');
      expect(needsCarryPrompt(pending.single.block), isTrue);
    });

    test('顺延后的新方块落在今天，原方块变 carried', () async {
      await dayRepo.upsert(_block('old', title: '交周报'), '2026-11-12');
      final pending = await dayRepo.unfinishedBefore('2026-11-13');
      final moved = carryOverBlock(
        pending.single.block,
        newId: 'new',
        sourceDateKey: pending.single.date,
      );

      await dayRepo.upsert(moved, '2026-11-13');
      await dayRepo.setStatus('old', BlockStatus.carried);

      final today = await dayRepo.loadDay('2026-11-13');
      expect(today.single.title, '交周报');
      expect(today.single.fromBlockId, 'old');
      expect(today.single.carryCount, 1);
      expect(today.single.originalDate, '2026-11-12');

      // 原方块已被标 carried，不该再被捞出来；只有新的那一份还算未完成
      final nextDay = await dayRepo.unfinishedBefore('2026-11-14');
      expect(nextDay.map((c) => c.block.id), ['new']);
      expect(nextDay.single.date, '2026-11-13');
      expect(await dayRepo.countAll(), 2);
    });

    test('写完完成记录能在记录页读回来', () async {
      await dayRepo.upsert(_block('b1', title: '健身'), '2026-11-13');
      await dayRepo.setStatus('b1', BlockStatus.done);
      await libRepo.logCompletion(
        dayBlockId: 'b1',
        date: '2026-11-13',
        title: '健身',
        lane: Lane.daily.index,
        startMin: 990,
        durationMin: 60,
      );

      final logs = await libRepo.completions();
      expect(logs.single.title, '健身');
      expect(logs.single.date, '2026-11-13');
      expect(logs.single.startMin, 990);
    });

    test('集合建好之后能读回条目，投入到某天不重复叠两份', () async {
      final id = await libRepo.createCollectionSimple(
        name: '早间流程',
        items: const [
          CollectionSeedItem(
            title: '喂猫',
            lane: Lane.daily,
            startMin: 430,
            durationMin: 15,
          ),
          CollectionSeedItem(
            title: '早餐',
            lane: Lane.daily,
            startMin: 460,
            durationMin: 30,
          ),
        ],
      );
      final items = await libRepo.collectionItems(id);
      expect(items.map((i) => i.title), ['喂猫', '早餐']);

      final blocks = blocksFromCollection(id, items, '2026-11-13');
      await dayRepo.upsertAll(blocks, '2026-11-13');
      expect(await dayRepo.countDay('2026-11-13'), 2);
    });
  });
}
