/// 月视图的纯计算：只算格子，不碰 Flutter，方便单测。
library;

/// 该月第一天（时分秒归零）
DateTime firstOfMonth(DateTime day) => DateTime(day.year, day.month, 1);

/// 加/减月份，自动落到当月 1 号
DateTime addMonths(DateTime month, int delta) =>
    DateTime(month.year, month.month + delta, 1);

/// 该月天数（DateTime 的 day=0 表示上个月最后一天）
int daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

/// 周一 = 0 … 周日 = 6
int mondayIndex(DateTime day) => day.weekday - 1;

/// 6×7 的月视图格子；不在本月的格子是 null。
///
/// 固定 6 行，切换月份时高度不跳。
List<DateTime?> monthCells(DateTime month) {
  final first = firstOfMonth(month);
  final lead = mondayIndex(first);
  final total = daysInMonth(month);
  final cells = <DateTime?>[];
  for (var i = 0; i < lead; i++) {
    cells.add(null);
  }
  for (var d = 1; d <= total; d++) {
    cells.add(DateTime(month.year, month.month, d));
  }
  while (cells.length < 42) {
    cells.add(null);
  }
  return cells;
}

/// 「2026 年 11 月」
String monthLabel(DateTime month) => '${month.year} 年 ${month.month} 月';

/// 「11 月 13 日 · 周五」
String dayLabel(DateTime day) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return '${day.month} 月 ${day.day} 日 · 周${weekdays[mondayIndex(day)]}';
}

const List<String> kMondayFirstWeekdayLabels = [
  '一',
  '二',
  '三',
  '四',
  '五',
  '六',
  '日',
];
