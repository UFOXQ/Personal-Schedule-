import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
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

  test('自动收起空泳道：只收起当天没有方块的泳道', () async {
    final notifier = container.read(timelineProvider.notifier);
    var state = container.read(timelineProvider);
    final used = {for (final block in state.blocks) block.lane};
    expect(used, isNotEmpty);

    expect(state.autoHideEmptyLanes, isFalse);
    expect(state.effectiveHiddenLanes, isEmpty);

    notifier.toggleAutoHideEmptyLanes();
    state = container.read(timelineProvider);
    expect(state.autoHideEmptyLanes, isTrue);
    // 有方块的泳道不能被收掉
    for (final lane in used) {
      expect(state.effectiveHiddenLanes.contains(lane), isFalse);
    }
    // 没方块的泳道才是被收起的那些
    final empty = Lane.defaults.where((lane) => !used.contains(lane)).toSet();
    expect(state.effectiveHiddenLanes, empty);

    notifier.toggleAutoHideEmptyLanes();
    expect(container.read(timelineProvider).effectiveHiddenLanes, isEmpty);
  });

  test('自动收起和手动隐藏互不干扰，关掉自动后手动隐藏还在', () async {
    final notifier = container.read(timelineProvider.notifier);
    notifier.toggleLaneHidden(Lane.temp);
    notifier.toggleAutoHideEmptyLanes();
    var state = container.read(timelineProvider);
    expect(state.effectiveHiddenLanes.contains(Lane.temp), isTrue);

    notifier.toggleAutoHideEmptyLanes();
    state = container.read(timelineProvider);
    expect(state.autoHideEmptyLanes, isFalse);
    expect(state.effectiveHiddenLanes, {Lane.temp});
  });
}
