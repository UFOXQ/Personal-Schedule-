import 'package:flutter_test/flutter_test.dart';

import 'package:tnt_app/domain/models/tblock.dart';
import 'package:tnt_app/domain/reminders.dart';
import 'package:tnt_app/domain/quiet_hours.dart';

TBlock _block(String id, int startMin, {int duration = 30}) => TBlock(
  id: id,
  title: id,
  lane: Lane.daily,
  startMin: startMin,
  durationMin: duration,
  priority: Priority.c,
);

void main() {
  group('免打扰窗口', () {
    test('普通时段（08:00-12:00）', () {
      expect(inQuietWindow(8 * 60, 8 * 60, 12 * 60), isTrue);
      expect(inQuietWindow(11 * 60 + 59, 8 * 60, 12 * 60), isTrue);
      expect(inQuietWindow(12 * 60, 8 * 60, 12 * 60), isFalse); // 止不含
      expect(inQuietWindow(7 * 60 + 59, 8 * 60, 12 * 60), isFalse);
    });

    test('跨零点（22:00-08:00）', () {
      expect(inQuietWindow(22 * 60, 22 * 60, 8 * 60), isTrue);
      expect(inQuietWindow(23 * 60 + 30, 22 * 60, 8 * 60), isTrue);
      expect(inQuietWindow(0, 22 * 60, 8 * 60), isTrue);
      expect(inQuietWindow(7 * 60 + 59, 22 * 60, 8 * 60), isTrue);
      expect(inQuietWindow(8 * 60, 22 * 60, 8 * 60), isFalse);
      expect(inQuietWindow(12 * 60, 22 * 60, 8 * 60), isFalse);
    });

    test('起止相同＝没有免打扰', () {
      expect(inQuietWindow(22 * 60, 22 * 60, 22 * 60), isFalse);
    });
  });

  group('排提醒时应用免打扰/工作日', () {
    final day = DateTime(2026, 11, 16); // 周一
    final saturday = DateTime(2026, 11, 21);
    final now = DateTime(2026, 11, 16, 0, 0);

    test('落在免打扰里的提醒被跳过', () {
      final reminders = planReminders(
        blocks: [
          _block('early', 7 * 60),
          _block('noon', 12 * 60),
        ],
        day: day,
        leadMinutes: 0,
        now: now,
        quietStartMin: 22 * 60,
        quietEndMin: 8 * 60,
      );
      expect(reminders.map((r) => r.blockId), ['noon']);
    });

    test('开始时间和免打扰无关时不传窗口就照常提醒', () {
      final reminders = planReminders(
        blocks: [_block('early', 7 * 60)],
        day: day,
        leadMinutes: 0,
        now: now,
      );
      expect(reminders, hasLength(1));
    });

    test('周末整天不提醒', () {
      final reminders = planReminders(
        blocks: [_block('a', 10 * 60)],
        day: saturday,
        leadMinutes: 0,
        now: DateTime(2026, 11, 21, 0, 0),
        workdaysOnly: true,
      );
      expect(reminders, isEmpty);
    });

    test('工作日照常提醒', () {
      final reminders = planReminders(
        blocks: [_block('a', 10 * 60)],
        day: day,
        leadMinutes: 0,
        now: now,
        workdaysOnly: true,
      );
      expect(reminders, hasLength(1));
    });

    test('提前量把时间挪进免打扰也算跳过', () {
      // 08:03 的方块提前 5 分钟 → 07:58，落在 22:00-08:00 里
      final reminders = planReminders(
        blocks: [_block('edge', 8 * 60 + 3)],
        day: day,
        leadMinutes: 5,
        now: now,
        quietStartMin: 22 * 60,
        quietEndMin: 8 * 60,
      );
      expect(reminders, isEmpty);
    });
  });
}
