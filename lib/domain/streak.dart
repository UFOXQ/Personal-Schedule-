/// 连续打卡天数：从今天（或昨天）往前数，连续有完成记录的天数。
///
/// 今天还没打卡不该立刻把连击清零，所以允许从昨天起算；
/// 昨天也没有就从今天/昨天断开，连击为 0。
int streakLength(Set<String> dayKeys, DateTime today) {
  int length = 0;
  var cursor = DateTime(today.year, today.month, today.day);

  String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // 今天没记录就从昨天开始数
  if (!dayKeys.contains(key(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!dayKeys.contains(key(cursor))) return 0;
  }

  while (dayKeys.contains(key(cursor))) {
    length++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return length;
}

/// 最近 7 天每天有没有完成记录（从 6 天前到今天），给完成记录页画小圆点。
List<bool> recentWeek(Set<String> dayKeys, DateTime today) {
  String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final day = DateTime(today.year, today.month, today.day);
  return [
    for (var i = 6; i >= 0; i--)
      dayKeys.contains(key(day.subtract(Duration(days: i)))),
  ];
}
