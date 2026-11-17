import '../models/tblock.dart';

/// 拖到屏幕左右边缘时，应该把哪条被收起的泳道临时放出来。
///
/// 规则很简单：靠左边就露出「最左的隐藏泳道」，靠右边露出「最右的」，
/// 每次只露一条，已经露过的跳过；中间区域返回 null。
Lane? edgeRevealTarget({
  required double x,
  required double viewportWidth,
  required Set<Lane> hiddenLanes,
  required Set<Lane> alreadyRevealed,
  double edgeZone = 34,
}) {
  if (hiddenLanes.isEmpty) return null;
  if (viewportWidth <= edgeZone * 2) return null;

  final atLeft = x <= edgeZone;
  final atRight = x >= viewportWidth - edgeZone;
  if (!atLeft && !atRight) return null;

  final candidates = Lane.defaults
      .where(
        (lane) =>
            hiddenLanes.contains(lane) && !alreadyRevealed.contains(lane),
      )
      .toList();
  if (candidates.isEmpty) return null;
  return atLeft ? candidates.first : candidates.last;
}
