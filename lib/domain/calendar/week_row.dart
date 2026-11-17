import '../models/tblock.dart';

/// 周视图里一小段的横向位置（0..1 表示占 24 小时的比例）。
class WeekSegment {
  const WeekSegment({
    required this.startMin,
    required this.left,
    required this.width,
    required this.priority,
    required this.isTop,
    required this.title,
  });

  /// 这段对应的原方块开始时间，点它跳时间轴时要用
  final int startMin;
  final double left;
  final double width;
  final Priority priority;
  final bool isTop;
  final String title;

  double get right => left + width;
}

/// 把一天里没完成的方块映射成 24h 条上的分段。
///
/// 只做展示：重叠的段会叠在一起（周视图是概览，不需要分列）。
/// 最短给 0.6% 宽度，否则 5 分钟的方块在小条上根本看不见。
List<WeekSegment> weekSegments(Iterable<TBlock> blocks) {
  const dayMinutes = 24 * 60.0;
  final segments = <WeekSegment>[];
  for (final block in blocks) {
    if (block.done || block.status != BlockStatus.planned) continue;
    final left = (block.startMin / dayMinutes).clamp(0.0, 1.0);
    final rawWidth = (block.durationMin / dayMinutes).clamp(0.0, 1.0);
    final width = rawWidth < 0.006 ? 0.006 : rawWidth;
    segments.add(
      WeekSegment(
        startMin: block.startMin,
        left: left,
        width: (left + width).clamp(0.0, 1.0) - left,
        priority: block.priority,
        isTop: block.priority == Priority.a,
        title: block.title,
      ),
    );
  }
  segments.sort((a, b) => a.left.compareTo(b.left));
  return segments;
}

/// 周视图里每一行显示的日期标签（如「16 周一」）。
String weekDayLabel(DateTime day) {
  const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return '${day.day} ${names[(day.weekday - 1) % 7]}';
}

/// 从 [anchor] 所在周（周一算起）起 7 天。
List<DateTime> weekDays(DateTime anchor) {
  final monday = DateTime(
    anchor.year,
    anchor.month,
    anchor.day,
  ).subtract(Duration(days: (anchor.weekday - 1) % 7));
  return [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
}
