import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/domain/layout/timeline_layout.dart';
import 'package:tnt_app/domain/models/tblock.dart';

TBlock _block(
  String id,
  Lane lane,
  int startMin, {
  int durationMin = 30,
  Priority priority = Priority.c,
}) {
  return TBlock(
    id: id,
    title: id,
    lane: lane,
    startMin: startMin,
    durationMin: durationMin,
    priority: priority,
  );
}

void main() {
  const viewport = Size(390, 700);

  test('隐藏泳道后该泳道不出现、方块也不参与布局', () {
    final blocks = [
      _block('daily-1', Lane.daily, 600),
      _block('habit-1', Lane.habit, 660),
      _block('temp-1', Lane.temp, 720),
    ];

    final full = TimelineLayout.compute(
      viewport: viewport,
      pxPerMin: 1.5,
      blocks: blocks,
      showTopInLane: true,
      now: DateTime(2026, 11, 15, 9),
    );
    expect(full.lanes.length, 3);
    expect(full.placed.length, 3);

    final withoutTemp = TimelineLayout.compute(
      viewport: viewport,
      pxPerMin: 1.5,
      blocks: blocks,
      showTopInLane: true,
      now: DateTime(2026, 11, 15, 9),
      hiddenLanes: {Lane.temp},
    );
    expect(withoutTemp.lanes, [Lane.daily, Lane.habit]);
    expect(withoutTemp.placed.length, 2);
    expect(
      withoutTemp.placed.every((p) => p.block.lane != Lane.temp),
      isTrue,
    );
    // 剩下的两条泳道平分宽度，比三条时更宽
    expect(withoutTemp.laneWidth, greaterThan(full.laneWidth));
    // 隐藏的泳道查不到范围
    expect(withoutTemp.laneRectAt(Lane.temp), Rect.zero);
  });

  test('隐藏全部泳道也不崩，laneAtX 返回 null', () {
    final layout = TimelineLayout.compute(
      viewport: viewport,
      pxPerMin: 1.5,
      blocks: [_block('a', Lane.daily, 600)],
      showTopInLane: true,
      now: DateTime(2026, 11, 15, 9),
      hiddenLanes: {Lane.daily, Lane.habit, Lane.temp},
    );
    expect(layout.lanes, isEmpty);
    expect(layout.placed, isEmpty);
    expect(layout.laneAtX(120), isNull);
    expect(layout.laneWidth, 0);
  });

  test('换道判定只看可见泳道', () {
    final layout = TimelineLayout.compute(
      viewport: viewport,
      pxPerMin: 1.5,
      blocks: [
        _block('a', Lane.daily, 600),
        _block('b', Lane.habit, 660),
      ],
      showTopInLane: true,
      now: DateTime(2026, 11, 15, 9),
      hiddenLanes: {Lane.temp},
    );
    final dailyRect = layout.laneRectAt(Lane.daily);
    final habitRect = layout.laneRectAt(Lane.habit);
    expect(layout.laneAtX(dailyRect.center.dx), Lane.daily);
    expect(layout.laneAtX(habitRect.center.dx), Lane.habit);
  });
}
