import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/features/timeline/timeline_state.dart';

Future<void> settle(ProviderContainer container) async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (!container.read(timelineProvider).loading) return;
  }
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('晚间小结：全部留到明天后今天清空、明天多出来', () async {
    final db = TntDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    await settle(container);
    final notifier = container.read(timelineProvider.notifier);
    final state = container.read(timelineProvider);
    final today = state.dateKey;
    final before = state.blocks.length;
    expect(before, greaterThan(0));

    final moved = await notifier.carryAllUnfinished();

    expect(moved, before);
    expect(container.read(timelineProvider).blocks, isEmpty);

    final rows = await db.customSelect('select * from day_blocks').get();
    final carried = rows.where(
      (row) => row.data['status'] == BlockStatus.carried.index,
    );
    expect(carried.length, before);

    // 明天确实有对应份
    final nextKey = today.replaceFirst(
      RegExp(r'\d\d$'),
      (int.parse(today.substring(8, 10)) + 1).toString().padLeft(2, '0'),
    );
    final nextRows =
        await (db.select(db.dayBlocks)
              ..where((t) => t.date.equals(nextKey))
              ..where((t) => t.fromBlockId.isNotNull()))
            .get();
    expect(nextRows.length, before);
  });

  test('晚间小结：全部丢掉后今天清空、状态是 dropped', () async {
    final db = TntDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    await settle(container);
    final notifier = container.read(timelineProvider.notifier);
    final before = container.read(timelineProvider).blocks.length;

    final dropped = await notifier.dropAllUnfinished();

    expect(dropped, before);
    expect(container.read(timelineProvider).blocks, isEmpty);
    final rows = await db.customSelect(
      'select count(*) c from day_blocks where status = ${BlockStatus.dropped.index}',
    ).getSingle();
    expect(rows.data['c'], before);
  });

  test('晚间小结：锁定状态下不生效', () async {
    final db = TntDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    await settle(container);
    final notifier = container.read(timelineProvider.notifier);
    final before = container.read(timelineProvider).blocks.length;
    notifier.toggleLock();

    expect(await notifier.carryAllUnfinished(), 0);
    expect(await notifier.dropAllUnfinished(), 0);
    expect(container.read(timelineProvider).blocks.length, before);
  });
}
