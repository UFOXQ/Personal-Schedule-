/// 横向划动的判定（纯函数，方便单测）。
enum SwipeAction { none, complete, postpone }

/// 手指按在方块上后，位移是否算「横向划动」。
///
/// 要求横向够长、且明显大于纵向，避免竖着翻页时误触发。
bool isHorizontalSwipe(
  double dx,
  double dy, {
  double threshold = 14,
  double ratio = 1.2,
}) {
  return dx.abs() >= threshold && dx.abs() > dy.abs() * ratio;
}

/// 划得够远了该干什么：左划完成、右划顺延，不够远什么都不做。
SwipeAction swipeActionFor(double dx, {double commit = 72}) {
  if (dx.abs() < commit) return SwipeAction.none;
  return dx < 0 ? SwipeAction.complete : SwipeAction.postpone;
}
