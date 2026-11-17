import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/domain/layout/timeline_layout.dart';
import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/features/settings/interaction_modes.dart';

TBlock _block({
  String id = 'b1',
  int startMin = 600,
  int durationMin = 60,
  Lane lane = Lane.daily,
}) {
  return TBlock(
    id: id,
    title: '测试',
    lane: lane,
    startMin: startMin,
    durationMin: durationMin,
    priority: Priority.c,
  );
}

TimelineLayout _layout(List<TBlock> blocks) {
  return TimelineLayout.compute(
    viewport: const Size(900, 700),
    pxPerMin: 1.5,
    blocks: blocks,
    showTopInLane: false,
    now: DateTime(2026, 11, 16, 12),
  );
}

void main() {
  group('把手命中区域', () {
    test('上方箭头在方块外侧也算命中', () {
      final layout = _layout([_block()]);
      final placed = layout.placed.first;
      final r = placed.rect;
      final above = Offset(r.center.dx, r.top - 10);
      expect(TimelineLayout.isOnTopHandle(placed, above), isTrue);
      expect(TimelineLayout.isOnBottomHandle(placed, above), isFalse);
    });

    test('下方箭头在方块外侧也算命中', () {
      final layout = _layout([_block()]);
      final placed = layout.placed.first;
      final r = placed.rect;
      final below = Offset(r.center.dx, r.bottom + 10);
      expect(TimelineLayout.isOnBottomHandle(placed, below), isTrue);
      expect(TimelineLayout.isOnTopHandle(placed, below), isFalse);
    });

    test('方块正中间不落在任何把手上', () {
      final layout = _layout([_block()]);
      final placed = layout.placed.first;
      expect(TimelineLayout.isOnTopHandle(placed, placed.rect.center), isFalse);
      expect(
        TimelineLayout.isOnBottomHandle(placed, placed.rect.center),
        isFalse,
      );
    });

    test('很矮的方块：上下把手上半/下半各占一份，互不重叠', () {
      final layout = _layout([_block(durationMin: 10)]);
      final placed = layout.placed.first;
      final r = placed.rect;
      expect(r.height, lessThan(34));
      final upper = Offset(r.center.dx, r.center.dy - 2);
      final lower = Offset(r.center.dx, r.center.dy + 2);
      expect(TimelineLayout.isOnTopHandle(placed, upper), isTrue);
      expect(TimelineLayout.isOnBottomHandle(placed, lower), isTrue);
      expect(TimelineLayout.isOnTopHandle(placed, lower), isFalse);
    });

    test('容差命中：点歪 8px 也能抓到很窄的方块', () {
      final layout = _layout([_block(durationMin: 10)]);
      final placed = layout.placed.first;
      final near = Offset(placed.rect.left - 8, placed.rect.center.dy);
      expect(layout.hitTest(near), isNull);
      expect(layout.hitTest(near, slop: 10)?.block.id, 'b1');
    });
  });

  group('交互方式设置', () {
    test('默认两种新建方式都开', () {
      const modes = InteractionModes();
      expect(modes.create, CreateMode.both);
      expect(modes.priorityPicker, PriorityPickerMode.menu);
      expect(modes.allowLongPressCreate, isTrue);
      expect(modes.allowDoubleTapCreate, isTrue);
    });

    test('只允许长按时双击禁用', () {
      const modes = InteractionModes(create: CreateMode.longPress);
      expect(modes.allowLongPressCreate, isTrue);
      expect(modes.allowDoubleTapCreate, isFalse);
    });

    test('只允许双击时长按禁用', () {
      const modes = InteractionModes(create: CreateMode.doubleTap);
      expect(modes.allowLongPressCreate, isFalse);
      expect(modes.allowDoubleTapCreate, isTrue);
    });
  });
}
