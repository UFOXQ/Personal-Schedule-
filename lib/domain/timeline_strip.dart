import 'package:material_ui/material_ui.dart';

import '../core/palette.dart';
import '../core/time_utils.dart';
import 'models/tblock.dart';
import 'priority.dart';

/// 时间条上的一段（{start, duration} 都是「当天第几分钟」）
class StripSegment {
  const StripSegment({
    required this.title,
    required this.laneName,
    required this.startMin,
    required this.durationMin,
    required this.color,
    required this.isTop,
  });

  final String title;
  final String laneName;
  final int startMin;
  final int durationMin;
  final int color;
  final bool isTop;

  Map<String, Object?> toJson() => <String, Object?>{
    'title': title,
    'lane': laneName,
    'start': startMin,
    'duration': durationMin,
    'color': color,
    'top': isTop,
  };
}

/// 常驻时间条的数据：手机通知、Android 小组件、Windows 悬浮条共用
class StripPayload {
  const StripPayload({
    required this.nowMin,
    required this.dayLabel,
    required this.segments,
  });

  final int nowMin;
  final String dayLabel;
  final List<StripSegment> segments;

  /// 当前正在做的事（没有就取下一件）
  StripSegment? get current {
    for (final segment in segments) {
      if (nowMin >= segment.startMin &&
          nowMin < segment.startMin + segment.durationMin) {
        return segment;
      }
    }
    for (final segment in segments) {
      if (segment.startMin > nowMin) return segment;
    }
    return null;
  }

  /// 现在这一刻正在做的事（严格匹配，没有就是 null）
  StripSegment? get nowPlaying {
    for (final segment in segments) {
      if (nowMin >= segment.startMin &&
          nowMin < segment.startMin + segment.durationMin) {
        return segment;
      }
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'now': nowMin,
    'day': dayLabel,
    'segments': segments.map((segment) => segment.toJson()).toList(),
  };
}

Color _colorOfSegments(TBlock block, bool isTop) => Palette.ofBlock(block, isTop);

/// 把当天方块压成一条 0..1440 的时间条
StripPayload buildStripPayload({
  required Iterable<TBlock> blocks,
  required DateTime now,
  Set<Lane> hiddenLanes = const <Lane>{},
  int limit = 40,
}) {
  final segments = <StripSegment>[];
  for (final block in blocks) {
    if (block.done) continue;
    if (!block.status.isActive) continue;
    if (hiddenLanes.contains(block.lane)) continue;
    if (block.startMin >= kMinutesPerDay) continue;
    final top = isTopPriority(block, now);
    final color = _colorOfSegments(block, top);
    segments.add(
      StripSegment(
        title: block.title,
        laneName: block.lane.name,
        startMin: block.startMin,
        durationMin: block.durationMin,
        color: color.toARGB32(),
        isTop: top,
      ),
    );
    if (segments.length >= limit) break;
  }
  segments.sort((a, b) => a.startMin.compareTo(b.startMin));
  return StripPayload(
    nowMin: now.hour * 60 + now.minute,
    dayLabel: '${now.month} 月 ${now.day} 日',
    segments: segments,
  );
}
