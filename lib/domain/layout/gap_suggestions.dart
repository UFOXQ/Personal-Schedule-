import '../../core/time_utils.dart';
import '../models/tblock.dart';

/// 在一天的方块之间找「够塞下一段时长」的空档，返回空档起点（分钟）。
///
/// 只用于编辑面板的「塞进空档」建议：不改数据，纯计算，方便单测。
List<int> suggestGapStarts({
  required Iterable<TBlock> blocks,
  required int durationMin,
  String? excludeId,
  int? currentStart,
  int limit = 3,
}) {
  if (durationMin <= 0) return const [];

  final sorted = blocks
      .where((b) => b.id != excludeId && !b.done)
      .toList()
    ..sort((a, b) => a.startMin.compareTo(b.startMin));

  final starts = <int>[];
  var cursor = 0;
  for (final block in sorted) {
    if (block.startMin - cursor >= durationMin) starts.add(cursor);
    if (block.endMin > cursor) cursor = block.endMin;
  }
  if (kMinutesPerDay - cursor >= durationMin) starts.add(cursor);

  return starts
      .where((start) => currentStart == null || start != currentStart)
      .take(limit)
      .toList();
}
