import 'package:flutter_test/flutter_test.dart';

import 'package:tnt_app/domain/gesture/swipe_action.dart';

void main() {
  group('横向划动判定', () {
    test('横向够长且明显大于纵向 → 是划动', () {
      expect(isHorizontalSwipe(30, 5), isTrue);
      expect(isHorizontalSwipe(-40, -10), isTrue);
      expect(isHorizontalSwipe(80, 0), isTrue);
    });

    test('位移太小 → 不算', () {
      expect(isHorizontalSwipe(10, 0), isFalse);
      expect(isHorizontalSwipe(-13, 0), isFalse);
    });

    test('纵向为主 → 不算（避免翻页误触）', () {
      expect(isHorizontalSwipe(30, 30), isFalse);
      expect(isHorizontalSwipe(30, 26), isFalse);
      expect(isHorizontalSwipe(30, -25), isFalse);
    });

    test('刚好压线的边界', () {
      // 14 横向、0 纵向：算
      expect(isHorizontalSwipe(14, 0), isTrue);
      // 30 横向、25 纵向：30 > 30 不成立 → 不算
      expect(isHorizontalSwipe(30, 25), isFalse);
      expect(isHorizontalSwipe(31, 25), isTrue);
    });
  });

  group('划动结果', () {
    test('左滑完成、右滑顺延', () {
      expect(swipeActionFor(-100), SwipeAction.complete);
      expect(swipeActionFor(100), SwipeAction.postpone);
    });

    test('不到 72px 什么都不做', () {
      expect(swipeActionFor(-71), SwipeAction.none);
      expect(swipeActionFor(0), SwipeAction.none);
      expect(swipeActionFor(71), SwipeAction.none);
    });

    test('刚好 72px 生效', () {
      expect(swipeActionFor(-72), SwipeAction.complete);
      expect(swipeActionFor(72), SwipeAction.postpone);
    });
  });
}
