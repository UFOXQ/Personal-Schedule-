/// 时间轴几何计算：把领域里的方块摆到屏幕坐标上。
/// 纯计算，不碰 Widget，也不负责画——方便单测和复用（桌面/手机同一套）。
library;

import 'dart:ui';

import '../../core/time_utils.dart';
import '../models/tblock.dart';
import '../priority.dart';

/// 一个已经摆好位置的方块
class PlacedBlock {
  const PlacedBlock({
    required this.block,
    required this.rect,
    required this.isTop,
    required this.column,
    required this.columns,
  });

  final TBlock block;

  /// 内容坐标系（y 已按 pxPerMin 换算，不含滚动偏移）
  final Rect rect;

  /// 是否处于最高优先级（A 或临近死线的 B）
  final bool isTop;

  /// 同一簇内并列的第几列，以及总列数
  final int column;
  final int columns;

  bool get isSplit => columns > 1;
}

/// 时间轴布局
class TimelineLayout {
  TimelineLayout({
    required this.viewport,
    required this.pxPerMin,
    required this.laneRects,
    required this.placed,
    required this.now,
  });

  final Size viewport;
  final double pxPerMin;

  /// 三条泳道的横向范围（y 从 0 到 contentHeight）
  final List<Rect> laneRects;

  final List<PlacedBlock> placed;
  final DateTime now;

  // ── 几何常量 ────────────────────────────────────────────────
  /// 左侧小时刻度栏宽度
  static const double gutterWidth = 54;

  /// 泳道之间的间隙
  static const double laneGap = 8;

  /// 顶部泳道标题栏高度（吸顶，不随滚动移动）
  static const double headerHeight = 38;

  /// 并列方块之间的间隙
  static const double blockGap = 3;

  /// 从方块底部多高的范围内按下算「改时长」
  static const double edgeHandle = 20;

  /// 底部留白
  static const double bottomPadding = 24;

  /// 右侧留白，避免最后一条泳道贴边
  static const double rightInset = 12;

  double get contentHeight => kMinutesPerDay * pxPerMin + bottomPadding;

  double get laneWidth => laneRects.isEmpty ? 0 : laneRects.first.width;

  /// 分钟 → 内容坐标 y
  double yForMinute(num minute) => minute * pxPerMin;

  /// 内容坐标 y → 分钟（不吸附）
  double minuteForY(num y) => y / pxPerMin;

  Rect laneRectAt(Lane lane) => laneRects[lane.index];

  /// 横坐标落在哪条泳道
  Lane? laneAtX(double x) {
    for (var i = 0; i < laneRects.length; i++) {
      final r = laneRects[i];
      if (x >= r.left - laneGap / 2 && x <= r.right + laneGap / 2) {
        return Lane.byIndex(i);
      }
    }
    return null;
  }

  /// 命中测试，contentPoint 为内容坐标系下的点
  PlacedBlock? hitTest(Offset contentPoint) {
    for (var i = placed.length - 1; i >= 0; i--) {
      if (placed[i].rect.contains(contentPoint)) return placed[i];
    }
    return null;
  }

  /// 某个点是否落在方块底部边缘（用于改时长）
  static bool isOnBottomEdge(PlacedBlock placed, Offset contentPoint) {
    return contentPoint.dy >= placed.rect.bottom - edgeHandle &&
        placed.rect.height > 26;
  }

  /// 计算布局
  ///
  /// - [blocks] 会先过滤掉「已置顶且开关要求不在原泳道显示」的方块
  /// - 重叠的方块在同一泳道内并列分列（sweep + 贪心染色）
  static TimelineLayout compute({
    required Size viewport,
    required double pxPerMin,
    required Iterable<TBlock> blocks,
    required bool showTopInLane,
    required DateTime now,
  }) {
    final laneCount = Lane.values.length;
    final gutter = gutterWidth;
    final available =
        viewport.width - gutter - rightInset - laneGap * (laneCount - 1);
    final laneW = available <= 0 ? 1.0 : available / laneCount;
    final contentH = kMinutesPerDay * pxPerMin + bottomPadding;

    final laneRects = <Rect>[
      for (var i = 0; i < laneCount; i++)
        Rect.fromLTWH(gutter + i * (laneW + laneGap), 0, laneW, contentH),
    ];

    // 过滤：置顶项是否还要在原泳道里出现
    final visible = blocks.where((b) {
      if (showTopInLane) return true;
      return !isTopPriority(b, now);
    }).toList();

    final placed = <PlacedBlock>[];

    for (var laneIndex = 0; laneIndex < laneCount; laneIndex++) {
      final laneRect = laneRects[laneIndex];
      final laneBlocks =
          visible.where((b) => b.lane.index == laneIndex).toList()
            ..sort((a, b) {
              final cmp = a.startMin.compareTo(b.startMin);
              if (cmp != 0) return cmp;
              return b.durationMin.compareTo(a.durationMin);
            });

      if (laneBlocks.isEmpty) continue;

      // 1) 切成互相重叠的簇（簇与簇之间互不影响，各自平分宽度）
      var i = 0;
      while (i < laneBlocks.length) {
        var clusterEnd = laneBlocks[i].endMin;
        var j = i + 1;
        while (j < laneBlocks.length && laneBlocks[j].startMin < clusterEnd) {
          if (laneBlocks[j].endMin > clusterEnd) {
            clusterEnd = laneBlocks[j].endMin;
          }
          j++;
        }
        final cluster = laneBlocks.sublist(i, j);

        // 2) 贪心染色：给每个方块找第一条空着的列
        final columnEnds = <int>[];
        final assignment = <int>[];
        for (final b in cluster) {
          var col = 0;
          while (col < columnEnds.length && columnEnds[col] > b.startMin) {
            col++;
          }
          if (col == columnEnds.length) {
            columnEnds.add(b.endMin);
          } else {
            columnEnds[col] = b.endMin;
          }
          assignment.add(col);
        }

        final columns = columnEnds.length;
        final columnWidth = laneRect.width / columns;

        for (var k = 0; k < cluster.length; k++) {
          final b = cluster[k];
          final col = assignment[k];
          final left = laneRect.left + col * columnWidth + blockGap / 2;
          final width = (columnWidth - blockGap).clamp(6.0, double.infinity);
          final startClamped = b.startMin.clamp(0, kMinutesPerDay - 1);
          final durationClamped = b.durationMin.clamp(
            kMinDuration,
            kMinutesPerDay - startClamped,
          );
          final top = startClamped * pxPerMin;
          final height = (durationClamped * pxPerMin - 2).clamp(
            10.0,
            double.infinity,
          );
          placed.add(
            PlacedBlock(
              block: b,
              rect: Rect.fromLTWH(left, top, width, height),
              isTop: isTopPriority(b, now),
              column: col,
              columns: columns,
            ),
          );
        }

        i = j;
      }
    }

    return TimelineLayout(
      viewport: viewport,
      pxPerMin: pxPerMin,
      laneRects: laneRects,
      placed: placed,
      now: now,
    );
  }
}
