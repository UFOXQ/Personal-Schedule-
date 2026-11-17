import 'package:flutter_test/flutter_test.dart';

import 'package:tnt_app/domain/layout/gap_suggestions.dart';
import 'package:tnt_app/domain/models/tblock.dart';

TBlock _block(String id, int start, int duration, {bool done = false}) => TBlock(
  id: id,
  title: id,
  lane: Lane.daily,
  startMin: start,
  durationMin: duration,
  priority: Priority.c,
  done: done,
);

void main() {
  group('空档推荐', () {
    test('空白天从 00:00 到 24:00', () {
      expect(
        suggestGapStarts(blocks: const [], durationMin: 30),
        [0],
      );
    });

    test('两块之间/末尾的空档', () {
      final starts = suggestGapStarts(
        blocks: [
          _block('a', 600, 60), // 10:00-11:00
          _block('b', 720, 60), // 12:00-13:00
        ],
        durationMin: 30,
      );
      expect(starts, [0, 660, 780]);
    });

    test('排除正在编辑的自己和已完成的', () {
      final starts = suggestGapStarts(
        blocks: [
          _block('me', 0, 600),
          _block('done', 900, 600, done: true),
          _block('other', 660, 60),
        ],
        durationMin: 30,
        excludeId: 'me',
      );
      // me 被排除、done 不算，剩下的 other 在 11:00-12:00：
      // 00:00 那段和 12:00 之后都空着
      expect(starts, [0, 720]);
    });

    test('当前开始时间已经是最佳空档时不重复给', () {
      final starts = suggestGapStarts(
        blocks: [_block('a', 600, 60)],
        durationMin: 30,
        currentStart: 0,
        limit: 3,
      );
      expect(starts, isNot(contains(0)));
      expect(starts, [660]);
    });

    test('时长不合法时不给建议', () {
      expect(suggestGapStarts(blocks: const [], durationMin: 0), isEmpty);
      expect(suggestGapStarts(blocks: const [], durationMin: -5), isEmpty);
    });

    test('limit 生效', () {
      final starts = suggestGapStarts(
        blocks: [
          _block('a', 60, 30),
          _block('b', 120, 30),
          _block('c', 180, 30),
          _block('d', 240, 30),
        ],
        durationMin: 30,
        limit: 2,
      );
      expect(starts, [0, 90]);
    });
  });
}
