import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/data/repositories/library_repository.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/features/settings/ui_scale.dart';

void main() {
  test('界面大小档位与标签', () {
    expect(UiScale.options.length, 4);
    expect(UiScale.labelOf(0.9), '小');
    expect(UiScale.labelOf(1.0), '标准');
    expect(UiScale.labelOf(1.15), '大');
    expect(UiScale.labelOf(1.3), '特大');
  });

  group('组合台：把草稿收进合集', () {
    late TntDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = TntDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
    });

    test('追加一条不会丢掉原来的条目', () async {
      final repo = container.read(libraryRepositoryProvider);
      final id = await repo.createCollectionSimple(
        name: '晨间',
        items: const [
          CollectionSeedItem(
            title: '喂猫',
            lane: Lane.daily,
            startMin: 430,
            durationMin: 15,
            priority: Priority.d,
          ),
        ],
      );

      final before = await repo.collectionSeeds(id);
      expect(before.length, 1);

      // 组合台拖进来一条，就是「读出来 + 追加 + 整包写回」
      await repo.updateCollection(
        id: id,
        name: '晨间',
        items: [
          ...before,
          const CollectionSeedItem(
            title: '回邮件',
            lane: Lane.temp,
            startMin: 600,
            durationMin: 30,
            priority: Priority.b,
          ),
        ],
      );

      final after = await repo.collectionSeeds(id);
      expect(after.length, 2);
      expect(after.map((e) => e.title), ['喂猫', '回邮件']);
      expect(after.last.lane, Lane.temp);
      expect(after.last.startMin, 600);
    });

    test('同一合集可以反复追加，顺序保持', () async {
      final repo = container.read(libraryRepositoryProvider);
      final id = await repo.createCollectionSimple(
        name: '晚间',
        items: const [
          CollectionSeedItem(
            title: '晚饭',
            lane: Lane.daily,
            startMin: 1110,
            durationMin: 45,
            priority: Priority.c,
          ),
        ],
      );

      for (final title in ['洗澡', '复盘']) {
        final current = await repo.collectionSeeds(id);
        await repo.updateCollection(
          id: id,
          name: '晚间',
          items: [
            ...current,
            CollectionSeedItem(
              title: title,
              lane: Lane.daily,
              startMin: 1170,
              durationMin: 30,
              priority: Priority.c,
            ),
          ],
        );
      }

      final rows = await repo.collectionSeeds(id);
      expect(rows.map((e) => e.title), ['晚饭', '洗澡', '复盘']);
    });
  });
}
