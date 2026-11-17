import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/repositories/library_repository.dart';
import 'package:tnt_app/domain/models/tblock.dart';

/// 集合的增改：改完之后条目要整包替换，读回来顺序和字段都对
void main() {
  late TntDatabase db;
  late LibraryRepository repo;

  setUp(() {
    db = TntDatabase.forTesting(NativeDatabase.memory());
    repo = LibraryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('updateCollection 整包替换条目', () async {
    final id = await repo.createCollectionSimple(
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

    var seeds = await repo.collectionSeeds(id);
    expect(seeds.length, 2);
    expect(seeds.first.title, '喂猫');

    await repo.updateCollection(
      id: id,
      name: '早间流程 2',
      items: const [
        CollectionSeedItem(
          title: '喂猫',
          lane: Lane.daily,
          startMin: 420,
          durationMin: 10,
        ),
        CollectionSeedItem(
          title: '散步',
          lane: Lane.habit,
          startMin: 450,
          durationMin: 20,
        ),
        CollectionSeedItem(
          title: '早餐',
          lane: Lane.daily,
          startMin: 480,
          durationMin: 30,
        ),
      ],
    );

    final collections = await repo.collections();
    final row = collections.firstWhere((c) => c.id == id);
    expect(row.name, '早间流程 2');

    seeds = await repo.collectionSeeds(id);
    expect(seeds.length, 3);
    expect(seeds.map((s) => s.title), ['喂猫', '散步', '早餐']);
    expect(seeds[1].lane, Lane.habit);
    expect(seeds[0].startMin, 420);
  });

  test('软删除集合后列表里不再出现', () async {
    final id = await repo.createCollectionSimple(
      name: '临时集合',
      items: const [
        CollectionSeedItem(
          title: '一件事',
          lane: Lane.temp,
          startMin: 600,
          durationMin: 30,
        ),
      ],
    );
    await repo.deleteCollection(id);
    final collections = await repo.collections();
    expect(collections.where((c) => c.id == id), isEmpty);
  });
}
