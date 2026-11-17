import '../models/tblock.dart';
import '../priority.dart';

/// 某一天的概览：日历下方那条「总览一天」用它。
class DayOverview {
  DayOverview({required this.dateKey, required this.blocks, required this.now});

  final String dateKey;
  final List<TBlock> blocks;
  final DateTime now;

  bool get isEmpty => blocks.isEmpty;

  /// 排好序的方块（按开始时间）
  List<TBlock> get sorted {
    final list = [...blocks]..sort((a, b) => a.startMin.compareTo(b.startMin));
    return list;
  }

  /// 当天还占着的时间（分钟）
  int get totalMinutes =>
      blocks.fold<int>(0, (sum, block) => sum + block.durationMin);

  /// 按泳道数数
  Map<Lane, int> get laneCounts {
    final counts = {for (final lane in Lane.defaults) lane: 0};
    for (final block in blocks) {
      counts[block.lane] = (counts[block.lane] ?? 0) + 1;
    }
    return counts;
  }

  /// 会被顶到置顶区的方块
  List<TBlock> get top =>
      sortByPriority(blocks.where((block) => isTopPriority(block, now)), now);

  /// 空闲时段（相邻方块之间的空档，至少 30 分钟）
  List<(int, int)> get gaps {
    final list = sorted;
    final result = <(int, int)>[];
    var cursor = 0;
    for (final block in list) {
      final start = block.startMin;
      if (start - cursor >= 30) result.add((cursor, start));
      if (block.endMin > cursor) cursor = block.endMin;
    }
    return result;
  }
}
