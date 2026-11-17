import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../domain/now_marker.dart';
import '../../core/time_utils.dart';
import '../../domain/layout/timeline_layout.dart';
import '../../domain/models/tblock.dart';
import '../../domain/priority.dart';

/// 时间轴的全部绘制。只有一块 CustomPaint，方块再多也不会堆 Widget。
class TimelinePainter extends CustomPainter {
  TimelinePainter({
    required this.layout,
    required this.scroll,
    required this.selectedId,
    required this.showTopInLane,
    this.draggingId,
    this.handleScale = 1.0,
    this.nowMarkerStyle = NowMarkerStyle.pill,
    this.nowMarkerIcon = 0,
    this.nowMarkerDoodle = '',
    this.nowColorIndex = 0,
    this.nowLineColorIndex = 0,
    this.nowMarkerSize = 1.0,
    this.nowMarkerRight = false,
    this.nowLineWidth = 1.6,
  });

  final TimelineLayout layout;
  final double scroll;
  final String? selectedId;
  final bool showTopInLane;

  /// 正在被拖动/拉长的方块：稍微抬起一点，给手感反馈
  final String? draggingId;

  /// 上下把手的大小倍率（设置里的「手柄大小」）
  final double handleScale;
  final NowMarkerStyle nowMarkerStyle;
  final int nowMarkerIcon;
  final String nowMarkerDoodle;
  final int nowColorIndex;
  final int nowLineColorIndex;
  final double nowMarkerSize;
  final bool nowMarkerRight;
  final double nowLineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.bg);

    final contentTop = TimelineLayout.headerHeight;
    final contentRect = Rect.fromLTWH(
      0,
      contentTop,
      size.width,
      math.max(0, size.height - contentTop),
    );

    canvas.save();
    canvas.clipRect(contentRect);
    canvas.translate(0, contentTop - scroll);

    _paintLanes(canvas, size);
    _paintGrid(canvas, size);
    _paintBlocks(canvas, size);
    // 现在时刻画在方块上面，否则被方块盖住就看不到标识了
    _paintNowLine(canvas, size);
    _paintGutterDivider(canvas, size);

    canvas.restore();

    _paintHeader(canvas, size);
  }

  // ── 泳道底色 ────────────────────────────────────────────────
  void _paintLanes(Canvas canvas, Size size) {
    final paint = Paint()..color = Palette.laneBg;
    for (final rect in layout.laneRects) {
      final r = Rect.fromLTWH(rect.left, 0, rect.width, layout.contentHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(10)),
        paint,
      );
    }
  }

  // ── 小时线与刻度 ────────────────────────────────────────────
  void _paintGrid(Canvas canvas, Size size) {
    final hourLine = Paint()
      ..color = Palette.line
      ..strokeWidth = 1;
    final halfLine = Paint()
      ..color = Palette.lineFaint
      ..strokeWidth = 1;

    final right = size.width;
    final gutter = TimelineLayout.gutterWidth;

    for (var minute = 0; minute <= kMinutesPerDay; minute += 30) {
      final y = layout.yForMinute(minute);
      final isHour = minute % 60 == 0;
      canvas.drawLine(
        Offset(gutter, y),
        Offset(right, y),
        isHour ? hourLine : halfLine,
      );
      if (isHour) {
        _drawText(
          canvas,
          formatMinute(math.min(minute, kMinutesPerDay - 1)),
          Offset(0, y - 7),
          size: 11,
          color: Palette.textDim,
          align: TextAlign.right,
          maxWidth: gutter - 12,
        );
      }
    }
  }

  // ── 当前时刻 ────────────────────────────────────────────────
  void _paintNowLine(Canvas canvas, Size size) {
    final now = layout.now;
    final minute = now.hour * 60 + now.minute;
    final y = layout.yForMinute(minute);
    final accent = nowColors[
        nowColorIndex.clamp(0, nowColors.length - 1)];
    final lineAccent = nowColors[
        nowLineColorIndex.clamp(0, nowColors.length - 1)];
    final scale = nowMarkerSize.clamp(0.7, 1.6);
    final gx = TimelineLayout.gutterWidth;
    // 标识可以放到时间轴左侧（默认）或右侧（压在泳道上）
    final anchorX = nowMarkerRight ? gx + 8 : gx;
    final paint = Paint()
      ..color = lineAccent
      ..strokeWidth = nowLineWidth.clamp(1.0, 4.0);
    canvas.drawLine(
      Offset(gx, y),
      Offset(size.width, y),
      paint,
    );
    canvas.drawCircle(
      Offset(gx, y),
      3.5 * scale,
      Paint()..color = lineAccent,
    );

    final label = formatMinute(minute);
    switch (nowMarkerStyle) {
      case NowMarkerStyle.pill:
        _drawBadge(
          canvas,
          label,
          Offset(anchorX + 6, y - 9 * scale),
          bg: accent,
          scale: scale,
        );
      case NowMarkerStyle.arrow:
        // 指向时间轴的三角 + 右侧时间
        final tip = Offset(anchorX + 2, y);
        final path = Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(tip.dx + 12 * scale, tip.dy - 7 * scale)
          ..lineTo(tip.dx + 12 * scale, tip.dy + 7 * scale)
          ..close();
        canvas.drawPath(path, Paint()..color = accent);
        _textMark(
          canvas,
          label,
          Offset(tip.dx + 16 * scale, y - 17 * scale),
          color: accent,
          scale: scale,
        );
      case NowMarkerStyle.pointer:
        // 一根细指针 + 一个小圆头
        canvas.drawLine(
          Offset(anchorX, y - 12 * scale),
          Offset(anchorX, y),
          Paint()
            ..color = accent
            ..strokeWidth = 1.6 * scale
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          Offset(anchorX, y - 13 * scale),
          4.2 * scale,
          Paint()..color = accent,
        );
        _textMark(
          canvas,
          label,
          Offset(anchorX + 8 * scale, y - 20 * scale),
          color: accent,
          scale: scale,
        );
      case NowMarkerStyle.icon:
        final center = Offset(anchorX + 2, y - 2);
        final radius = 10 * scale;
        canvas.drawCircle(center, radius, Paint()..color = accent);
        if (nowMarkerDoodle.trim().isNotEmpty) {
          // 自己画的图案：画在圆里，留一点内边距
          paintDoodle(
            canvas,
            Rect.fromCircle(center: center, radius: radius * 0.72),
            nowMarkerDoodle,
            Palette.bg,
          );
        } else {
          final icon = nowMarkerIcons[
              nowMarkerIcon.clamp(0, nowMarkerIcons.length - 1)];
          final painter = TextPainter(
            text: TextSpan(
              text: String.fromCharCode(icon.codePoint),
              style: TextStyle(
                fontFamily: icon.fontFamily,
                package: icon.fontPackage,
                fontSize: 13 * scale,
                color: Palette.bg,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          painter.paint(
            canvas,
            center - Offset(painter.width / 2, painter.height / 2),
          );
        }
        _textMark(
          canvas,
          label,
          Offset(anchorX + 16 * scale, y - 20 * scale),
          color: accent,
          scale: scale,
        );
    }
  }

  void _textMark(
    Canvas canvas,
    String value,
    Offset at, {
    required Color color,
    double scale = 1.0,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: 10.5 * scale,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  // ── 方块 ────────────────────────────────────────────────────
  //
  // 分两趟画：先把所有方块的底色铺完，再统一描边。
  // 这样上层的半透明填充不会把下层的描边透出来（重叠处最容易「串线」）。
  void _paintBlocks(Canvas canvas, Size size) {
    final drawables = <_BlockDraw>[];
    for (final placed in layout.placed) {
      final block = placed.block;
      final color = Palette.ofBlock(block, placed.isTop);
      final dragging = block.id == draggingId;
      final selected = block.id == selectedId;
      final segments = placed.segments;
      final split = segments != null && segments.length > 1;
      var rects = (split ? segments : <Rect>[placed.rect]);
      if (split) {
        // 相邻两列之间留 0.75px 缝，避免两个方块的外框贴成一条「双线」；
        // 上下各多盖 0.6px，让同一方块切成的时间片在合并时真正连成一片，
        // 否则抗锯齿会在片与片之间留下一条浅色横线（看起来像「工」字）。
        rects = [
          for (final r in rects)
            Rect.fromLTWH(r.left + 0.75, r.top - 0.6, r.width - 1.5, r.height + 1.2),
        ];
      }
      final rect = dragging
          ? placed.rect.inflate(1.5).translate(0, -1.5)
          : placed.rect;

      // 最宽的一段用来放文字
      var labelRect = rects.first;
      for (final r in rects) {
        if (r.width * r.height > labelRect.width * labelRect.height) labelRect = r;
      }

      final fillColor = Color.alphaBlend(
        color.withValues(alpha: block.done ? 0.10 : 0.24),
        Palette.laneBg,
      );
      drawables.add(_BlockDraw(
        block: block,
        color: color,
        fillColor: fillColor,
        rects: rects,
        rect: rect,
        labelRect: labelRect,
        isTop: placed.isTop,
        selected: selected,
        dragging: dragging,
      ));
    }

    for (final d in drawables) {
      if (d.dragging) {
        for (final r in d.rects) {
          canvas.drawShadow(
            Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(9))),
            Color(0xCC000000),
            10,
            false,
          );
        }
      }
      var fill = Path()..addRect(d.rects.first);
      for (final r in d.rects.skip(1)) {
        fill = Path.combine(PathOperation.union, fill, Path()..addRect(r));
      }
      canvas.drawPath(fill, Paint()..color = d.fillColor);

      final first = d.rects.first;
      final barWidth = first.width < 24 ? 3.0 : 4.0;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(first.left, first.top, barWidth, first.height),
          topLeft: Radius.circular(3),
          bottomLeft: Radius.circular(3),
        ),
        Paint()..color = d.color,
      );
    }

    // 第二趟：每个方块描「外圈」轮廓（多段先合成一个 Path，所以不会有内部横线）
    for (final d in drawables) {
      final borderColor = d.selected
          ? Colors.white
          : (d.isTop ? Palette.top : d.color.withValues(alpha: 0.55));
      final borderWidth = d.selected ? 2.0 : (d.isTop ? 1.6 : 1.0);
      var outline = Path()..addRect(d.rects.first);
      for (final r in d.rects.skip(1)) {
        outline = Path.combine(PathOperation.union, outline, Path()..addRect(r));
      }
      canvas.drawPath(
        outline,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = borderColor
          ..strokeWidth = borderWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // 第三趟：文字（所有方块都画，不再依赖选中）+ 选中方块的把手
    for (final d in drawables) {
      final labelRect = d.labelRect;
      if (labelRect.width >= 34 && labelRect.height >= 16) {
        final rrect = RRect.fromRectAndRadius(labelRect, Radius.circular(6));
        canvas.save();
        canvas.clipRRect(rrect);
        final barWidth = labelRect.width < 24 ? 3.0 : 4.0;
        final textLeft = labelRect.left + barWidth + 6;
        final textWidth = math.max(0.0, labelRect.right - textLeft - 6);
        final titleSize = labelRect.width < 80 ? 11.0 : 12.5;
        _drawText(
          canvas,
          d.block.title,
          Offset(textLeft, labelRect.top + 4),
          size: titleSize,
          color: Palette.textPrimary,
          weight: FontWeight.w600,
          maxWidth: textWidth,
          maxLines: labelRect.height < 34 ? 1 : 2,
        );
        if (labelRect.height >= 40 && textWidth > 60) {
          _drawText(
            canvas,
            formatRange(d.block.startMin, d.block.durationMin),
            Offset(textLeft, labelRect.top + (labelRect.height < 56 ? 20 : 22)),
            size: 10,
            color: Palette.textSecondary,
            maxWidth: textWidth,
          );
        }
        if (labelRect.height >= 62 && d.isTop && textWidth > 60) {
          final left = deadlineLabel(d.block, layout.now);
          if (left.isNotEmpty) {
            _drawText(
              canvas,
              '死线剩 $left',
              Offset(textLeft, labelRect.bottom - 16),
              size: 10,
              color: Palette.top,
              weight: FontWeight.w600,
              maxWidth: textWidth,
            );
          }
        }
        canvas.restore();
      }

      if (d.selected) {
        final cx = d.rect.center.dx;
        _paintHandleGrip(canvas, Offset(cx, d.rect.top - 7), true);
        _paintHandleGrip(canvas, Offset(cx, d.rect.bottom + 7), false);
      }
    }
  }

  /// 选中方块外侧的小箭头把手（上＝改开始时间，下＝改时长）
  void _paintHandleGrip(Canvas canvas, Offset center, bool pointingUp) {
    final w = 28 * handleScale;
    final h = 14 * handleScale;
    final pill = Rect.fromCenter(center: center, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(pill, Radius.circular(h / 2));
    canvas.drawRRect(rrect, Paint()..color = Palette.surfaceHigh);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Palette.accent.withValues(alpha: 0.85),
    );
    final path = Path();
    final cx = center.dx;
    final cy = center.dy;
    final dx = 4 * handleScale;
    final dy = 2.5 * handleScale;
    if (pointingUp) {
      path
        ..moveTo(cx - dx, cy + dy * 0.8)
        ..lineTo(cx, cy - dy)
        ..lineTo(cx + dx, cy + dy * 0.8);
    } else {
      path
        ..moveTo(cx - dx, cy - dy * 0.8)
        ..lineTo(cx, cy + dy)
        ..lineTo(cx + dx, cy - dy * 0.8);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Palette.accent,
    );
  }

  void _paintGutterDivider(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(TimelineLayout.gutterWidth - 6, 0),
      Offset(TimelineLayout.gutterWidth - 6, layout.contentHeight),
      Paint()
        ..color = Palette.line
        ..strokeWidth = 1,
    );
  }

  // ── 吸顶泳道标题 ────────────────────────────────────────────
  void _paintHeader(Canvas canvas, Size size) {
    final h = TimelineLayout.headerHeight;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, h),
      Paint()..color = Palette.bg,
    );

    final counts = <Lane, int>{};
    for (final p in layout.placed) {
      counts[p.block.lane] = (counts[p.block.lane] ?? 0) + 1;
    }

    for (var i = 0; i < layout.laneRects.length; i++) {
      final lane = layout.lanes[i];
      final rect = layout.laneRects[i];
      final count = counts[lane] ?? 0;
      final label = count > 0 ? '${lane.name} · $count' : lane.name;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left, 0, rect.width, h - 6),
          Radius.circular(10),
        ),
        Paint()..color = Palette.surface,
      );
      _drawText(
        canvas,
        label,
        Offset(rect.left, h / 2 - 8),
        size: 12,
        color: count > 0 ? Palette.textPrimary : Palette.textDim,
        weight: FontWeight.w600,
        maxWidth: rect.width,
        align: TextAlign.center,
      );
    }

    _drawText(
      canvas,
      '时刻',
      Offset(0, h / 2 - 7),
      size: 11,
      color: Palette.textDim,
      maxWidth: TimelineLayout.gutterWidth - 12,
      align: TextAlign.right,
    );
  }

  // ── 文本工具 ────────────────────────────────────────────────
  void _drawText(
    Canvas canvas,
    String text,
    Offset at, {
    double size = 12,
    Color? color,
    FontWeight weight = FontWeight.w500,
    double maxWidth = double.infinity,
    int maxLines = 1,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
      textAlign: align,
    )..layout(maxWidth: maxWidth.isFinite ? maxWidth : 4000);

    var dx = at.dx;
    if (align == TextAlign.right) {
      dx = at.dx + maxWidth - painter.width;
    } else if (align == TextAlign.center) {
      dx = at.dx + (maxWidth - painter.width) / 2;
    }
    painter.paint(canvas, Offset(dx, at.dy));
  }

  void _drawBadge(
    Canvas canvas,
    String text,
    Offset at, {
    required Color bg,
    double scale = 1.0,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10 * scale,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromLTWH(
      at.dx,
      at.dy,
      painter.width + 10 * scale,
      painter.height + 4 * scale,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(4 * scale)),
      Paint()..color = bg,
    );
    painter.paint(canvas, Offset(at.dx + 5 * scale, at.dy + 2 * scale));
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) => true;
}

/// 一趟绘制需要的中间数据
class _BlockDraw {
  _BlockDraw({
    required this.block,
    required this.color,
    required this.fillColor,
    required this.rects,
    required this.rect,
    required this.labelRect,
    required this.isTop,
    required this.selected,
    required this.dragging,
  });

  final TBlock block;
  final Color color;
  final Color fillColor;
  final List<Rect> rects;
  final Rect rect;
  final Rect labelRect;
  final bool isTop;
  final bool selected;
  final bool dragging;
}
