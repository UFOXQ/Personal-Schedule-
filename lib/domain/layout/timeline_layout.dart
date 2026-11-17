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
    this.segments,
  });

  final TBlock block;

  /// 内容坐标系（y 已按 pxPerMin 换算，不含滚动偏移）
  final Rect rect;

  /// 是否处于最高优先级（A 或临近死线的 B）
  final bool isTop;

  /// 同一簇内并列的第几列，以及总列数
  final int column;
  final int columns;

  /// 只在「重叠处分割」时才有值：同一方块按时间切片后的各段矩形。
  ///
  /// 为空表示整个方块是一整块（没有和别的方块重叠）。
  final List<Rect>? segments;

  bool get isSplit => columns > 1;
}

/// 时间轴布局
class TimelineLayout {
  TimelineLayout({
    required this.viewport,
    required this.pxPerMin,
    required this.lanes,
    required this.laneRects,
    required this.placed,
    required this.now,
  });

  final Size viewport;
  final double pxPerMin;

  /// 当前显示的泳道（按从左到右排序；被隐藏的泳道不在这里）
  final List<Lane> lanes;

  /// 与 [lanes] 一一对应的横向范围（y 从 0 到 contentHeight）
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
  static const double edgeHandle = 22;

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

  /// 某条泳道的横向范围；该泳道被隐藏时返回全零矩形
  Rect laneRectAt(Lane lane) {
    final i = lanes.indexOf(lane);
    if (i < 0 || i >= laneRects.length) return Rect.zero;
    return laneRects[i];
  }

  /// 横坐标落在哪条泳道
  Lane? laneAtX(double x) {
    for (var i = 0; i < laneRects.length; i++) {
      final r = laneRects[i];
      if (x >= r.left - laneGap / 2 && x <= r.right + laneGap / 2) {
        return lanes[i];
      }
    }
    return null;
  }

  /// 命中测试，contentPoint 为内容坐标系下的点
  ///
  /// [slop] 给方块四周一点容差：方块被压得很窄时，手指很难精确点中
  PlacedBlock? hitTest(Offset contentPoint, {double slop = 0}) {
    if (slop > 0) {
      for (var i = placed.length - 1; i >= 0; i--) {
        if (placed[i].rect.inflate(slop).contains(contentPoint)) {
          return placed[i];
        }
      }
    }
    for (var i = placed.length - 1; i >= 0; i--) {
      if (placed[i].rect.contains(contentPoint)) return placed[i];
    }
    return null;
  }

  /// 把手伸到方块外面的长度（箭头画在外面，不压住方块内容）
  static const double handleOutset = 14;

  /// 某个点是否落在「上方箭头」上：方块上边缘外侧一条
  static bool isOnTopHandle(PlacedBlock placed, Offset contentPoint) {
    final r = placed.rect;
    if (contentPoint.dx < r.left - 8 || contentPoint.dx > r.right + 8) {
      return false;
    }
    // 方块很矮时，上下两个把手在方块内部各占一半，免得互相抢
    final insideLimit = r.height < 34 ? r.center.dy : r.top + 8;
    return contentPoint.dy >= r.top - handleOutset &&
        contentPoint.dy <= insideLimit;
  }

  /// 某个点是否落在「下方箭头」上
  static bool isOnBottomHandle(PlacedBlock placed, Offset contentPoint) {
    final r = placed.rect;
    if (contentPoint.dx < r.left - 8 || contentPoint.dx > r.right + 8) {
      return false;
    }
    final insideLimit = r.height < 34 ? r.center.dy : r.bottom - 8;
    return contentPoint.dy >= insideLimit &&
        contentPoint.dy <= r.bottom + handleOutset;
  }

  /// 某个点是否落在方块底部边缘（用于改时长）
  static bool isOnBottomEdge(PlacedBlock placed, Offset contentPoint) {
    return contentPoint.dy >= placed.rect.bottom - edgeHandle &&
        placed.rect.height > 26;
  }

  /// 某个点是否落在方块顶部边缘（用于「开始时间 + 时长」一起改、结束时间不动）
  static bool isOnTopEdge(PlacedBlock placed, Offset contentPoint) {
    return contentPoint.dy <= placed.rect.top + edgeHandle &&
        placed.rect.height > 26;
  }

  /// 计算布局
  ///
  /// - [hiddenLanes] 里的泳道整条不显示，其中的方块也不参与布局
  /// - [blocks] 会先过滤掉「已置顶且开关要求不在原泳道显示」的方块
  /// - 重叠的方块在同一泳道内并列分列（sweep + 贪心染色）
  static TimelineLayout compute({
    required Size viewport,
    required double pxPerMin,
    required Iterable<TBlock> blocks,
    required bool showTopInLane,
    required DateTime now,
    Set<Lane> hiddenLanes = const <Lane>{},
    List<Lane> laneOrder = Lane.defaults,
    double laneGapScale = 1.0,
  }) {
    final lanes = <Lane>[
      for (final lane in laneOrder)
        if (!hiddenLanes.contains(lane)) lane,
    ];
    final laneCount = lanes.length;
    final gap = laneGap * laneGapScale;
    final gutter = gutterWidth;
    final available = viewport.width -
        gutter -
        rightInset -
        (laneCount > 1 ? gap * (laneCount - 1) : 0);
    final laneW = available <= 0 ? 1.0 : available / laneCount;
    final contentH = kMinutesPerDay * pxPerMin + bottomPadding;

    final laneRects = <Rect>[
      for (var i = 0; i < laneCount; i++)
        Rect.fromLTWH(gutter + i * (laneW + gap), 0, laneW, contentH),
    ];

    // 过滤：置顶项是否还要在原泳道里出现
    final visible = blocks.where((b) {
      if (hiddenLanes.contains(b.lane)) return false;
      if (showTopInLane) return true;
      return !isTopPriority(b, now);
    }).toList();

    final placed = <PlacedBlock>[];

    for (var i = 0; i < laneCount; i++) {
      final lane = lanes[i];
      final laneRect = laneRects[i];
      final laneBlocks = visible.where((b) => b.lane == lane).toList()
        ..sort((a, b) {
          final cmp = a.startMin.compareTo(b.startMin);
          if (cmp != 0) return cmp;
          return b.durationMin.compareTo(a.durationMin);
        });

      if (laneBlocks.isEmpty) continue;

      // 1) 切成互相重叠的簇（簇与簇之间互不影响，各自平分宽度）
      var c = 0;
      while (c < laneBlocks.length) {
        var clusterEnd = laneBlocks[c].endMin;
        var j = c + 1;
        while (j < laneBlocks.length && laneBlocks[j].startMin < clusterEnd) {
          if (laneBlocks[j].endMin > clusterEnd) {
            clusterEnd = laneBlocks[j].endMin;
          }
          j++;
        }
        final cluster = laneBlocks.sublist(c, j);

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

        // 3) 按时间切片：只有真正重叠的那几段才分列，不重叠的地方铺满整条泳道
        final cuts = <int>{};
        for (final b in cluster) {
          cuts.add(b.startMin.clamp(0, kMinutesPerDay));
          cuts.add(b.endMin.clamp(0, kMinutesPerDay));
        }
        final boundaries = cuts.toList()..sort();
        final segments = <TBlock, List<Rect>>{};
        var maxColumns = 1;
        for (var t = 0; t + 1 < boundaries.length; t++) {
          final sliceStart = boundaries[t];
          final sliceEnd = boundaries[t + 1];
          if (sliceEnd <= sliceStart) continue;
          final active = cluster
              .where((b) => b.startMin < sliceEnd && b.endMin > sliceStart)
              .toList()
            ..sort((a, b) {
              final cmp = a.startMin.compareTo(b.startMin);
              if (cmp != 0) return cmp;
              final cmp2 = b.durationMin.compareTo(a.durationMin);
              if (cmp2 != 0) return cmp2;
              return a.id.compareTo(b.id);
            });
          if (active.isEmpty) continue;
          final cols = active.length;
          if (cols > maxColumns) maxColumns = cols;
          final colWidth = laneRect.width / cols;
          for (var k = 0; k < cols; k++) {
            final b = active[k];
            final left = laneRect.left + k * colWidth + blockGap / 2;
            final width = (colWidth - blockGap).clamp(6.0, double.infinity);
            final top = sliceStart * pxPerMin;
            final height = ((sliceEnd - sliceStart) * pxPerMin - 1).clamp(
              2.0,
              double.infinity,
            );
            segments
                .putIfAbsent(b, () => <Rect>[])
                .add(Rect.fromLTWH(left, top, width, height));
          }
        }

        for (var k = 0; k < cluster.length; k++) {
          final b = cluster[k];
          final rects = segments[b] ?? const <Rect>[];
          if (rects.isEmpty) continue;
          var union = rects.first;
          for (final r in rects.skip(1)) {
            union = union.expandToInclude(r);
          }
          placed.add(
            PlacedBlock(
              block: b,
              rect: union,
              isTop: isTopPriority(b, now),
              column: assignment[k],
              columns: maxColumns,
              segments: rects.length > 1 ? rects : null,
            ),
          );
        }

        c = j;
      }
    }

    return TimelineLayout(
      viewport: viewport,
      pxPerMin: pxPerMin,
      lanes: lanes,
      laneRects: laneRects,
      placed: placed,
      now: now,
    );
  }
}
