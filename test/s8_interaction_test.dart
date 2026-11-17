import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/data/db/tnt_database.dart';
import 'package:tnt_app/data/providers.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/features/timeline/timeline_state.dart';

/// P0 交互改造的状态层验证：锁定守卫、编辑字段语义、顺延/复制。
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

  test('锁定后所有写操作都不生效', () async {
    final notifier = container.read(timelineProvider.notifier);
    final before = container.read(timelineProvider).blocks.toList();
    final target = before.first;

    notifier.toggleLock();
    expect(container.read(timelineProvider).locked, isTrue);
    expect(container.read(timelineProvider).canEdit, isFalse);

    notifier.moveBlock(target.id, startMin: 60, lane: Lane.temp);
    notifier.resizeBlock(target.id, durationMin: 90);
    notifier.cyclePriority(target.id);
    notifier.deleteBlock(target.id);
    final added = notifier.addBlockAt(lane: Lane.daily, startMin: 600);
    notifier.select(target.id);
    await notifier.completeSelected();

    final after = container.read(timelineProvider).blocks;
    expect(added, isNull);
    expect(after, hasLength(before.length));
    final kept = after.firstWhere((b) => b.id == target.id);
    expect(kept.startMin, target.startMin);
    expect(kept.durationMin, target.durationMin);
    expect(kept.priority, target.priority);
    expect(kept.lane, target.lane);

    // 解锁后恢复可编辑
    notifier.toggleLock();
    expect(container.read(timelineProvider).canEdit, isTrue);
  });

  test('updateBlock 只改传进来的字段，死线不传就保留', () async {
    final notifier = container.read(timelineProvider.notifier);
    // 找一条本来就带死线的（示例数据里「交周报」「回复邮件」都有）
    final target = container
        .read(timelineProvider)
        .blocks
        .firstWhere((b) => b.deadline != null);
    notifier.updateBlock(
      target.id,
      title: '改过名字',
      startMin: 700,
      durationMin: 45,
    );
    var updated = container
        .read(timelineProvider)
        .blocks
        .firstWhere((b) => b.id == target.id);
    expect(updated.title, '改过名字');
    expect(updated.startMin, 700);
    expect(updated.durationMin, 45);
    expect(updated.deadline, isNotNull);
    expect(updated.priority, target.priority);
    expect(updated.lane, target.lane);

    // 显式传 null 才是清除死线
    notifier.updateBlock(target.id, deadline: null);
    updated = container
        .read(timelineProvider)
        .blocks
        .firstWhere((b) => b.id == target.id);
    expect(updated.deadline, isNull);
    expect(updated.title, '改过名字');

    // 空标题不覆盖
    notifier.updateBlock(target.id, title: '   ');
    updated = container
        .read(timelineProvider)
        .blocks
        .firstWhere((b) => b.id == target.id);
    expect(updated.title, '改过名字');
  });

  test('顺延到明天：今天少一条，明天多一条且带 fromBlockId', () async {
    final notifier = container.read(timelineProvider.notifier);
    final target = container.read(timelineProvider).blocks.first;
    final todayKey = container.read(timelineProvider).dateKey;

    await notifier.carryOverToNextDay(target.id);

    final state = container.read(timelineProvider);
    expect(state.blocks.any((b) => b.id == target.id), isFalse);
    final tomorrow = DateTime.parse(todayKey).add(const Duration(days: 1));
    final tomorrowKey =
        '${tomorrow.year.toString().padLeft(4, '0')}-'
        '${tomorrow.month.toString().padLeft(2, '0')}-'
        '${tomorrow.day.toString().padLeft(2, '0')}';
    await notifier.goToDate(tomorrowKey);
    await settle(container);
    final carried = container
        .read(timelineProvider)
        .blocks
        .where((b) => b.fromBlockId == target.id)
        .toList();
    expect(carried, hasLength(1));
    expect(carried.single.startMin, target.startMin);
    expect(carried.single.carryCount, target.carryCount + 1);
  });

  test('复制到明天：今天这条还在', () async {
    final notifier = container.read(timelineProvider.notifier);
    final target = container.read(timelineProvider).blocks.first;
    final countBefore = container.read(timelineProvider).blocks.length;

    await notifier.duplicateToNextDay(target.id);

    final state = container.read(timelineProvider);
    expect(state.blocks, hasLength(countBefore));
    expect(state.blocks.any((b) => b.id == target.id), isTrue);
  });
}
