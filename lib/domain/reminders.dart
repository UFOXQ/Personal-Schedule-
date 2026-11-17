import '../core/time_utils.dart';
import 'quiet_hours.dart';
import 'models/tblock.dart';

/// 一条待发的到点提醒。
class Reminder {
  const Reminder({
    required this.id,
    required this.blockId,
    required this.title,
    required this.body,
    required this.at,
  });

  /// 通知 id（同一个方块恒定，方便取消）。
  final int id;
  final String blockId;
  final String title;
  final String body;
  final DateTime at;
}

/// 由方块 id 算稳定的通知 id（FNV-1a 32 位，取正）。
///
/// 不能用 `hashCode`：Dart 的字符串 hashCode 每次进程启动都可能变，
/// 那样重启后就取消不掉上次排的通知了。
int reminderIdFor(String blockId) {
  var hash = 0x811c9dc5;
  for (final unit in blockId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

/// 方块在 [day] 这天的提醒时刻；不该提醒时返回 null。
///
/// 已完成 / 非 planned 的方块不提醒；提前量允许为负（准点 = 0）。
DateTime? reminderAt(TBlock block, DateTime day, int leadMinutes) {
  if (block.done || block.status != BlockStatus.planned) return null;
  final start = DateTime(
    day.year,
    day.month,
    day.day,
  ).add(Duration(minutes: block.startMin));
  return start.subtract(Duration(minutes: leadMinutes));
}

/// 算出 [day] 这天需要排的全部提醒，已过去的丢掉。
///
/// [workdaysOnly] 只在周一到周五提醒；[quietStartMin]/[quietEndMin] 给出
/// 免打扰时段（可跨零点），落在这个窗口里的提醒直接跳过、不补发。
List<Reminder> planReminders({
  required Iterable<TBlock> blocks,
  required DateTime day,
  required int leadMinutes,
  required DateTime now,
  bool workdaysOnly = false,
  int? quietStartMin,
  int? quietEndMin,
  String Function(TBlock block)? bodyBuilder,
}) {
  if (workdaysOnly && (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday)) {
    return const <Reminder>[];
  }

  final ordered =
      blocks.where((b) => !b.done && b.status == BlockStatus.planned).toList()
        ..sort((a, b) => a.startMin.compareTo(b.startMin));

  final seen = <String>{};
  final result = <Reminder>[];
  for (final block in ordered) {
    if (!seen.add(block.id)) continue;
    final at = reminderAt(block, day, leadMinutes);
    if (at == null || !at.isAfter(now)) continue;
    // 提醒落进免打扰：静默跳过。挪到窗外再响会更烦人，所以不补发。
    if (quietStartMin != null && quietEndMin != null) {
      final minute = at.hour * 60 + at.minute;
      if (inQuietWindow(minute, quietStartMin, quietEndMin)) continue;
    }
    result.add(
      Reminder(
        id: reminderIdFor(block.id),
        blockId: block.id,
        title: block.title,
        body:
            bodyBuilder?.call(block) ??
            '${block.lane.name} · ${formatRange(block.startMin, block.durationMin)}',
        at: at,
      ),
    );
  }
  return result;
}
