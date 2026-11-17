import 'package:flutter_test/flutter_test.dart';
import 'package:tnt_app/domain/layout/lane_reveal.dart';
import 'package:tnt_app/domain/models/tblock.dart';

void main() {
  group('拖到边缘临时展开泳道', () {
    test('靠左边露出最左的隐藏泳道', () {
      final lane = edgeRevealTarget(
        x: 12,
        viewportWidth: 400,
        hiddenLanes: {Lane.daily, Lane.temp},
        alreadyRevealed: const <Lane>{},
      );
      expect(lane, Lane.daily);
    });

    test('靠右边露出最右的隐藏泳道', () {
      final lane = edgeRevealTarget(
        x: 392,
        viewportWidth: 400,
        hiddenLanes: {Lane.daily, Lane.temp},
        alreadyRevealed: const <Lane>{},
      );
      expect(lane, Lane.temp);
    });

    test('已经露出来的不会再露，露完了返回 null', () {
      final first = edgeRevealTarget(
        x: 8,
        viewportWidth: 400,
        hiddenLanes: {Lane.daily, Lane.temp},
        alreadyRevealed: {Lane.daily},
      );
      expect(first, Lane.temp);
      final second = edgeRevealTarget(
        x: 8,
        viewportWidth: 400,
        hiddenLanes: {Lane.daily, Lane.temp},
        alreadyRevealed: {Lane.daily, Lane.temp},
      );
      expect(second, isNull);
    });

    test('中间区域 / 没有隐藏泳道 / 屏幕太窄都不触发', () {
      expect(
        edgeRevealTarget(
          x: 200,
          viewportWidth: 400,
          hiddenLanes: {Lane.temp},
          alreadyRevealed: const <Lane>{},
        ),
        isNull,
      );
      expect(
        edgeRevealTarget(
          x: 4,
          viewportWidth: 400,
          hiddenLanes: const <Lane>{},
          alreadyRevealed: const <Lane>{},
        ),
        isNull,
      );
      expect(
        edgeRevealTarget(
          x: 4,
          viewportWidth: 50,
          hiddenLanes: {Lane.temp},
          alreadyRevealed: const <Lane>{},
        ),
        isNull,
      );
    });
  });
}
