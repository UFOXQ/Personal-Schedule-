import '../domain/models/tblock.dart';
import '../core/time_utils.dart';

/// 一句话快速添加的解析结果。
class QuickDraft {
  const QuickDraft({
    required this.day,
    required this.startMin,
    required this.durationMin,
    required this.title,
    required this.priority,
    required this.lane,
  });

  final DateTime day;
  final int startMin;
  final int durationMin;
  final String title;
  final Priority priority;
  final Lane lane;

  /// 供界面预览：`11/16 10:30 - 11:00 · A 级 · 临时`
  String get preview =>
      '${day.month}/${day.day} ${formatRange(startMin, durationMin)}'
      ' · ${priority.label} 级 · ${lane.name}';
}

/// 数字：阿拉伯数字，或中文数字（一、两、十二、二十三）
/// 注意这里用非捕获组，调用处各自加捕获组，避免组号错位。
const String _numPat = r'(?:\d{1,2}|[零一二两三四五六七八九十]{1,3})';

final RegExp _timePattern =
    RegExp('($_numPat)\\s*[:：点時时]\\s*($_numPat)?\\s*(半|一刻|三刻)?');
final RegExp _durationPattern = RegExp(
  '($_numPat)(?:\\.\\d+)?\\s*(?:个)?\\s*(小时|钟头|h|min|分钟|分)',
  caseSensitive: false,
);
/// `半小时`、`一个半小时`、`1.5 小时`
final RegExp _halfHourPattern = RegExp('($_numPat)?\\s*个?\\s*半\\s*(?:小时|钟头)');
/// `一刻钟`、`三刻钟`
final RegExp _quarterPattern = RegExp('([一两三1-3])?\\s*刻钟?');
/// 时段词：决定上午/下午
final RegExp _periodPattern =
    RegExp('凌晨|清晨|早晨|早上|上午|中午|下午|傍晚|晚上|晚间|夜里|夜晚');
final RegExp _datePattern = RegExp(r'(\d{1,2})\s*[/\-月]\s*(\d{1,2})\s*日?');
final RegExp _priorityLevelPattern = RegExp(r'([ABCDabcd])\s*级');
final RegExp _priorityLoosePattern = RegExp(r'(?:^|\s)([ABCD])(?=\s|$|[,，。、])');

const Map<String, int> _cnDigits = {
  '零': 0,
  '一': 1,
  '二': 2,
  '两': 2,
  '三': 3,
  '四': 4,
  '五': 5,
  '六': 6,
  '七': 7,
  '八': 8,
  '九': 9,
};

/// 解析 `3`、`三`、`十二`、`二十三` 这类数字。
int? _parseNum(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return null;
  final direct = int.tryParse(text);
  if (direct != null) return direct;
  if (text == '十') return 10;
  if (text.contains('十')) {
    final parts = text.split('十');
    final tensPart = parts.first;
    final onesPart = parts.length > 1 ? parts[1] : '';
    final tens = tensPart.isEmpty ? 1 : _cnDigits[tensPart];
    final ones = onesPart.isEmpty ? 0 : _cnDigits[onesPart];
    if (tens == null || ones == null) return null;
    return tens * 10 + ones;
  }
  if (text.length == 1) return _cnDigits[text];
  return null;
}

int? _periodOffset(String word) => switch (word) {
      '凌晨' || '清晨' || '早晨' || '早上' || '上午' => 0,
      '中午' || '下午' || '傍晚' || '晚上' || '晚间' || '夜里' || '夜晚' =>
        12 * 60,
      _ => null,
    };

final Map<String, int> _relativeDays = {
  '今天': 0,
  '今晚': 0,
  '今早': 0,
  '明天': 1,
  '明早': 1,
  '明晚': 1,
  '后天': 2,
  '大后天': 3,
};

final Map<String, Lane> _laneWords = {
  '日常': Lane.daily,
  '琐事': Lane.daily,
  '打卡': Lane.habit,
  '习惯': Lane.habit,
  '临时': Lane.temp,
};

/// 把「明天 10:30 交周报 45分 A」这类输入解析成一个待建方块。
///
/// 规则（都能省略，省略就走默认值）：
/// - 日期：今天/今晚/明天/明晚/后天，或 `11/20`；默认今天
/// - 时间：`10:30`、`10点`、`10点半`；默认「下一个半点」
/// - 时长：`45分`、`1.5小时`；默认 30 分钟
/// - 优先级：单独一个 `A`/`B`/`C`/`D`（可带「级」）；默认 C
/// - 泳道：出现 日常/打卡/临时 字样就用它；默认临时
/// - 剩下的文字就是标题；标题为空时用「新任务」
QuickDraft? parseQuickAdd(String raw, {required DateTime now, List<Lane>? lanes}) {
  var text = raw.trim();
  if (text.isEmpty) return null;

  var rest = text;
  // 「晚 / 下午 / 夜」这类词：光写 8点 要理解成 20:00
  final eveningHint = RegExp(r'晚|下午|夜').hasMatch(text);
  String cut(String matched) {
    rest = rest.replaceFirst(matched, ' ');
    return matched;
  }

  // 相对日期
  var day = DateTime(now.year, now.month, now.day);
  for (final entry in _relativeDays.entries) {
    if (rest.contains(entry.key)) {
      cut(entry.key);
      day = day.add(Duration(days: entry.value));
      break;
    }
  }

  // 绝对日期（11/20、11月20日）
  final dateMatch = _datePattern.firstMatch(rest);
  if (dateMatch != null) {
    final month = int.tryParse(dateMatch.group(1)!);
    final dayOfMonth = int.tryParse(dateMatch.group(2)!);
    if (month != null &&
        dayOfMonth != null &&
        month >= 1 &&
        month <= 12 &&
        dayOfMonth >= 1 &&
        dayOfMonth <= 31) {
      var candidate = DateTime(day.year, month, dayOfMonth);
      // 已经过去的日子，理解成明年
      if (candidate.isBefore(day)) {
        candidate = DateTime(day.year + 1, month, dayOfMonth);
      }
      day = candidate;
      cut(dateMatch.group(0)!);
    }
  }

  // 时段词（上午 / 下午 / 晚上 …），决定 12 小时制往哪边落
  var periodOffset = 0;
  var periodExplicit = false;
  final periodMatch = _periodPattern.firstMatch(rest);
  if (periodMatch != null) {
    periodOffset = _periodOffset(periodMatch.group(0)!) ?? 0;
    periodExplicit = true;
    cut(periodMatch.group(0)!);
  }

  // 时长
  var durationMin = 30;
  var durationCut = false;
  final halfMatch = _halfHourPattern.firstMatch(rest);
  if (halfMatch != null) {
    final whole = halfMatch.group(1) == null ? 0 : (_parseNum(halfMatch.group(1)!) ?? 0);
    durationMin = (whole * 60 + 30).clamp(kMinDuration, 12 * 60);
    cut(halfMatch.group(0)!);
    durationCut = true;
  }
  if (!durationCut) {
    final quarterMatch = _quarterPattern.firstMatch(rest);
    if (quarterMatch != null) {
      final count = quarterMatch.group(1) == null ? 1 : (_parseNum(quarterMatch.group(1)!) ?? 1);
      durationMin = (count * 15).clamp(kMinDuration, 12 * 60);
      cut(quarterMatch.group(0)!);
      durationCut = true;
    }
  }
  if (!durationCut) {
    final durationMatch = _durationPattern.firstMatch(rest);
    if (durationMatch != null) {
      final value = _parseNum(durationMatch.group(1)!);
      final unit = durationMatch.group(2)!;
      if (value != null) {
        final hours = unit.contains('小时') || unit.contains('钟头') || unit == 'h';
        durationMin = (hours ? value * 60 : value).round();
        durationMin = durationMin.clamp(kMinDuration, 12 * 60);
        cut(durationMatch.group(0)!);
      }
    }
  }

  // 时间（10:30 / 10点半 / 10点 / 十一点半 / 下午三点）
  var startMin = -1;
  final timeMatch = _timePattern.firstMatch(rest);
  if (timeMatch != null) {
    final hour = _parseNum(timeMatch.group(1)!);
    final minuteRaw = timeMatch.group(2);
    final suffix = timeMatch.group(3);
    var minute = minuteRaw == null ? 0 : (_parseNum(minuteRaw) ?? 0);
    if (suffix == '半') minute = 30;
    if (suffix == '一刻') minute = 15;
    if (suffix == '三刻') minute = 45;
    if (hour != null && hour < 24 && minute < 60) {
      startMin = hour * 60 + minute;
      if (hour < 12) startMin += periodOffset;
      cut(timeMatch.group(0)!);
    }
  }
  if (startMin >= 0) {
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    final nowMinutes = now.hour * 60 + now.minute;
    final looksMorning = startMin < 12 * 60;
    if (!periodExplicit &&
        looksMorning &&
        (eveningHint || (isToday && startMin <= nowMinutes))) {
      // 写成 8点 的，要么带「晚」，要么今天已经过了，都当成晚上 8 点
      startMin += 12 * 60;
    }
  }
  if (startMin < 0) {
    // 默认：下一个半点
    final nextHalf = ((now.hour * 60 + now.minute) ~/ 30 + 1) * 30;
    startMin = nextHalf.clamp(0, kMinutesPerDay - durationMin);
  }
  startMin = snapMinute(startMin);
  if (startMin > kMinutesPerDay - kMinDuration) {
    startMin = kMinutesPerDay - kMinDuration;
  }

  // 优先级：`A级` 后面直接跟汉字也能认；单独一个 A 要两侧是边界
  var priority = Priority.c;
  final levelMatch = _priorityLevelPattern.firstMatch(rest);
  final looseMatch = levelMatch ?? _priorityLoosePattern.firstMatch(rest);
  if (looseMatch != null) {
    final letter = looseMatch.group(1)!.toUpperCase();
    priority = switch (letter) {
      'A' => Priority.a,
      'B' => Priority.b,
      'D' => Priority.d,
      _ => Priority.c,
    };
    cut(looseMatch.group(0)!);
  }

  // 泳道
  var lane = Lane.temp;
  // 先按用户自定义的泳道名匹配（比如自己加了「工作」「家庭」）
  final custom = <String, Lane>{
    for (final l in (lanes ?? Lane.defaults)) l.name: l,
  };
  var laneMatched = false;
  for (final entry in custom.entries) {
    if (entry.key.isNotEmpty && text.contains(entry.key)) {
      lane = entry.value;
      rest = rest.replaceFirst(entry.key, ' ');
      laneMatched = true;
      break;
    }
  }
  if (!laneMatched) {
    for (final entry in _laneWords.entries) {
      if (rest.contains(entry.key)) {
        lane = entry.value;
        cut(entry.key);
        break;
      }
    }
  }

  final title = rest
      .replaceAll(RegExp(r'[\s,，。.;；]+'), ' ')
      .trim();

  return QuickDraft(
    day: day,
    startMin: startMin,
    durationMin: durationMin,
    title: title.isEmpty ? '新任务' : title,
    priority: priority,
    lane: lane,
  );
}
