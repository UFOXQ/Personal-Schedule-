import 'package:flutter_test/flutter_test.dart';

import 'package:tnt_app/domain/streak.dart';

String key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  final today = DateTime(2026, 11, 15);

  group('streakLength', () {
    test('空集合是 0', () {
      expect(streakLength(const <String>{}, today), 0);
    });

    test('今天打了卡 → 至少 1', () {
      expect(streakLength({key(today)}, today), 1);
    });

    test('今天没打、昨天打了 → 从昨天算', () {
      final days = {
        key(today.subtract(const Duration(days: 1))),
        key(today.subtract(const Duration(days: 2))),
      };
      expect(streakLength(days, today), 2);
    });

    test('今天和昨天都没有 → 0', () {
      final days = {key(today.subtract(const Duration(days: 2)))};
      expect(streakLength(days, today), 0);
    });

    test('连续三天', () {
      final days = {
        key(today),
        key(today.subtract(const Duration(days: 1))),
        key(today.subtract(const Duration(days: 2))),
      };
      expect(streakLength(days, today), 3);
    });

    test('中间断一天就停', () {
      final days = {
        key(today),
        key(today.subtract(const Duration(days: 1))),
        key(today.subtract(const Duration(days: 3))),
      };
      expect(streakLength(days, today), 2);
    });

    test('跨月也算得对', () {
      final first = DateTime(2026, 12, 1);
      final days = {
        key(first),
        key(first.subtract(const Duration(days: 1))),
        key(first.subtract(const Duration(days: 2))),
      };
      expect(streakLength(days, first), 3);
    });
  });

  group('recentWeek', () {
    test('返回 7 天，最后一位是今天', () {
      final week = recentWeek({key(today)}, today);
      expect(week.length, 7);
      expect(week.last, isTrue);
      expect(week.take(6).every((v) => v == false), isTrue);
    });

    test('六天前的记录也在第一位', () {
      final week = recentWeek({
        key(today.subtract(const Duration(days: 6))),
      }, today);
      expect(week.first, isTrue);
    });
  });
}
