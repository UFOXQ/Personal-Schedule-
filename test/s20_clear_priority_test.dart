import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/features/timeline/timeline_state.dart';

Future<TntDatabase> _emptyDb() async {
  final db = TntDatabase.forTesting(NativeDatabase.memory());
  return db;
}

Future<void> _settle(ProviderContainer container) async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!container.read(timelineProvider).loading) return;
  }
}

void main() {
  test('清空只清勾选泳道且不动已完成的', () async {
    final db = await _emptyDb();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    await _settle(container);

    final notifier = container.read(timelineProvider.notifier);
    final before = container.read(timelineProvider).blocks;
    final dailyCount = before.where((b) => b.lane == Lane.daily).length;

    final removed = await notifier.clearBlocks(
      lanes: {Lane.daily},
      includeDone: false,
    );

    expect(removed.length, dailyCount);
    final after = container.read(timelineProvider).blocks;
    expect(after.any((b) => b.lane == Lane.daily), isFalse);
    expect(after.any((b) => b.lane == Lane.habit), isTrue);

    // 撤销：全部放回来
    for (final block in removed) {
      await notifier.restoreBlock(block);
    }
    expect(container.read(timelineProvider).blocks.length, before.length);
  });

  test('clearBlocks 在锁定态不做事', () async {
    final db = await _emptyDb();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    await _settle(container);

    final notifier = container.read(timelineProvider.notifier);
    notifier.toggleLock();
    final count = container.read(timelineProvider).blocks.length;
    final removed = await notifier.clearBlocks(
      lanes: {Lane.daily, Lane.habit, Lane.temp},
      includeDone: true,
    );
    expect(removed, isEmpty);
    expect(container.read(timelineProvider).blocks.length, count);
  });

  test('setPriority 直接指定级别', () async {
    final db = await _emptyDb();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    await _settle(container);

    final notifier = container.read(timelineProvider.notifier);
    final target = container.read(timelineProvider).blocks.first;
    notifier.setPriority(target.id, Priority.a);
    final updated =
        container.read(timelineProvider).blocks.firstWhere((b) => b.id == target.id);
    expect(updated.priority, Priority.a);
  });
}
