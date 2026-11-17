import 'package:flutter_test/flutter_test.dart';

import 'package:tnt_app/domain/calendar/week_row.dart';
import 'package:tnt_app/domain/models/tblock.dart';

TBlock block({
  required String id,
  required int startMin,
  int durationMin = 60,
  Priority priority = Priority.c,
  bool done = false,
  BlockStatus status = BlockStatus.planned,
}) {
  return TBlock(
    id: id,
    title: id,
    lane: Lane.daily,
    startMin: startMin,
    durationMin: durationMin,
    priority: priority,
    done: done,
    status: status,
  );
}

void main() {
  group('weekDays', () {
    test('从周一开始算 7 天', () {
      final days = weekDays(DateTime(2026, 11, 18)); // 周三
      expect(days.length, 7);
      expect(days.first, DateTime(2026, 11, 16)); // 周一
      expect(days.last, DateTime(2026, 11, 22)); // 周日
    });

    test('周日属于当周而不是下一周', () {
      final days = weekDays(DateTime(2026, 11, 22));
      expect(days.first, DateTime(2026, 11, 16));
    });

    test('跨月也算得对', () {
      final days = weekDays(DateTime(2026, 12, 2));
      expect(days.first, DateTime(2026, 11, 30));
      expect(days.last, DateTime(2026, 12, 6));
    });
  });

  test('weekDayLabel 显示日号 + 星期', () {
    expect(weekDayLabel(DateTime(2026, 11, 16)), '16 周一');
    expect(weekDayLabel(DateTime(2026, 11, 22)), '22 周日');
  });

  group('weekSegments', () {
    test('位置按时长换算成 0..1 比例', () {
      final segments = weekSegments([block(id: 'a', startMin: 0, durationMin: 720)]);
      expect(segments.single.left, 0);
      expect(segments.single.width, closeTo(0.5, 0.0001));
    });

    test('跳过已完成和非 planned 的方块', () {
      final segments = weekSegments([
        block(id: 'done', startMin: 60, done: true, status: BlockStatus.done),
        block(id: 'carried', startMin: 120, status: BlockStatus.carried),
        block(id: 'ok', startMin: 180),
      ]);
      expect(segments.map((s) => s.title), ['ok']);
    });

    test('太短的方块给最小宽度，保证能看见', () {
      final segments = weekSegments([block(id: 'tiny', startMin: 600, durationMin: 5)]);
      expect(segments.single.width, greaterThanOrEqualTo(0.006));
    });

    test('按开始时间排序', () {
      final segments = weekSegments([
        block(id: 'late', startMin: 900),
        block(id: 'early', startMin: 120),
      ]);
      expect(segments.map((s) => s.title), ['early', 'late']);
    });

    test('不会超出右边界', () {
      final segments = weekSegments([
        block(id: 'end', startMin: 23 * 60, durationMin: 120),
      ]);
      expect(segments.single.right, lessThanOrEqualTo(1.0));
    });
  });
}
