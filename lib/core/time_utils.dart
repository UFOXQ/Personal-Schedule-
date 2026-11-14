/// 一天内的时间刻度工具。所有时刻都用「距 0 点的分钟数」表示，避免 DateTime 带来的时区麻烦。
library;

/// 一天的总分钟数
const int kMinutesPerDay = 24 * 60;

/// 方块吸附的最小刻度（分钟）
const int kSnapMinutes = 5;

/// 方块最短时长（分钟）
const int kMinDuration = 10;

/// 吸附到最近的刻度
int snapMinute(num rawMinute, [int step = kSnapMinutes]) {
  final snapped = (rawMinute / step).round() * step;
  return snapped.clamp(0, kMinutesPerDay);
}

/// 把分钟数格式化成 HH:mm
String formatMinute(int minute) {
  final m = minute.clamp(0, kMinutesPerDay - 1);
  final h = m ~/ 60;
  final mm = m % 60;
  return '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
}

/// 把时间段格式化成 09:30 - 10:15
String formatRange(int startMin, int durationMin) =>
    '${formatMinute(startMin)} - ${formatMinute(startMin + durationMin)}';

/// 把时长格式化成「1小时30分」
String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '$m 分';
  if (m == 0) return '$h 小时';
  return '$h 小时 $m 分';
}

/// 判断两个时间段是否重叠（端点相接不算重叠）
bool rangesOverlap(int aStart, int aEnd, int bStart, int bEnd) =>
    aStart < bEnd && bStart < aEnd;
