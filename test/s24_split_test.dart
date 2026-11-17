import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/domain/layout/timeline_layout.dart';
import 'package:tnt_app/domain/models/tblock.dart';

TBlock _block(String id, int start, int duration) => TBlock(
  id: id,
  title: id,
  lane: Lane.daily,
  startMin: start,
  durationMin: duration,
  priority: Priority.c,
);

void main() {
  const viewport = Size(600, 800);
  const pxPerMin = 1.0;

  TimelineLayout layoutOf(List<TBlock> blocks) => TimelineLayout.compute(
    viewport: viewport,
    pxPerMin: pxPerMin,
    blocks: blocks,
    showTopInLane: true,
    now: DateTime(2026, 11, 16, 12),
    hiddenLanes: {Lane.habit, Lane.temp},
  );

  test('只重叠的那一段分列，不重叠的铺满整条泳道', () {
    // A 10:00–11:00，B 10:30–11:45：只有 10:30–11:00 这半小时重叠
    final layout = layoutOf([_block('A', 600, 60), _block('B', 630, 75)]);
    final laneWidth = layout.laneRectAt(Lane.daily).width;
    final full = laneWidth - TimelineLayout.blockGap;
    final half = laneWidth / 2 - TimelineLayout.blockGap;
    final a = layout.placed.firstWhere((p) => p.block.id == 'A');
    final b = layout.placed.firstWhere((p) => p.block.id == 'B');

    expect(a.segments, isNotNull, reason: '有重叠的方块应该被切成多段');
    expect(b.segments, isNotNull);
    expect(a.segments!.length, 2);
    expect(b.segments!.length, 2);

    // 10:00–10:30 只有 A，占满整条泳道
    final aAlone = a.segments!.first;
    expect(aAlone.width, closeTo(full, 1.5));
    expect(aAlone.top, closeTo(600 * pxPerMin, 0.5));

    // 10:30–11:00 两个都重叠，各占一半
    final aOverlap = a.segments![1];
    final bOverlap = b.segments!.first;
    expect(aOverlap.width, closeTo(half, 1.5));
    expect(bOverlap.width, closeTo(half, 1.5));
    expect(aOverlap.left < bOverlap.left, isTrue, reason: '先开始的在左列');

    // 11:00–11:45 只剩 B，铺满
    final bAlone = b.segments![1];
    expect(bAlone.width, closeTo(full, 1.5));
  });

  test('不重叠的方块还是一整块', () {
    final layout = layoutOf([_block('A', 600, 30), _block('B', 700, 30)]);
    expect(layout.placed.length, 2);
    for (final p in layout.placed) {
      expect(p.segments, isNull);
    }
  });

  test('三方重叠：重叠段三等分，其余段占满', () {
    // 10:00–10:20 A、10:10–10:40 B、10:20–10:50 C
    final layout = layoutOf([
      _block('A', 600, 20),
      _block('B', 610, 30),
      _block('C', 620, 30),
    ]);
    final laneWidth = layout.laneRectAt(Lane.daily).width;
    final full = laneWidth - TimelineLayout.blockGap;
    final half = laneWidth / 2 - TimelineLayout.blockGap;
    final placed = {for (final p in layout.placed) p.block.id: p};

    // A 在 10:00–10:10 独占
    expect(placed['A']!.segments!.first.width, closeTo(full, 1.5));
    // 10:10–10:20 A、B 两段
    expect(placed['A']!.segments![1].width, closeTo(half, 1.5));
    expect(placed['B']!.segments!.first.width, closeTo(half, 1.5));
    // 10:20–10:40 B、C 两段（A 已结束）
    expect(placed['B']!.segments!.last.width, closeTo(half, 1.5));
    expect(placed['C']!.segments!.first.width, closeTo(half, 1.5));
    // C 在 10:40–10:50 独占
    expect(placed['C']!.segments!.last.width, closeTo(full, 1.5));
  });
}
