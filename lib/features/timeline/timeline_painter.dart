import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
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
  });

  final TimelineLayout layout;
  final double scroll;
  final String? selectedId;
  final bool showTopInLane;

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
    _paintNowLine(canvas, size);
    _paintBlocks(canvas, size);
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
        RRect.fromRectAndRadius(r, const Radius.circular(10)),
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
    final paint = Paint()
      ..color = Palette.top
      ..strokeWidth = 1.4;
    canvas.drawLine(
      Offset(TimelineLayout.gutterWidth, y),
      Offset(size.width, y),
      paint,
    );
    canvas.drawCircle(
      Offset(TimelineLayout.gutterWidth, y),
      3.5,
      Paint()..color = Palette.top,
    );
    _drawBadge(
      canvas,
      formatMinute(minute),
      Offset(TimelineLayout.gutterWidth + 6, y - 9),
      bg: Palette.top,
    );
  }

  // ── 方块 ────────────────────────────────────────────────────
  void _paintBlocks(Canvas canvas, Size size) {
    for (final placed in layout.placed) {
      final block = placed.block;
      final color = Palette.ofBlock(block, placed.isTop);
      final rect = placed.rect;
      final selected = block.id == selectedId;

      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(9));

      // 底色
      canvas.drawRRect(
        rrect,
        Paint()..color = color.withValues(alpha: block.done ? 0.08 : 0.20),
      );

      // 左侧色条
      final barWidth = rect.width < 24 ? 3.0 : 4.0;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(rect.left, rect.top, barWidth, rect.height),
          topLeft: const Radius.circular(9),
          bottomLeft: const Radius.circular(9),
        ),
        Paint()..color = color,
      );

      // 描边：置顶红框 / 普通淡边 / 选中白框
      final border = Paint()..style = PaintingStyle.stroke;
      if (selected) {
        border
          ..color = Colors.white
          ..strokeWidth = 2;
      } else if (placed.isTop) {
        border
          ..color = Palette.top
          ..strokeWidth = 1.6;
      } else {
        border
          ..color = color.withValues(alpha: 0.45)
          ..strokeWidth = 1;
      }
      canvas.drawRRect(rrect, border);

      // 文字
      if (rect.width >= 34 && rect.height >= 16) {
        canvas.save();
        canvas.clipRRect(rrect);
        final textLeft = rect.left + barWidth + 6;
        final textWidth = math.max(0.0, rect.right - textLeft - 6);
        final titleSize = rect.width < 80 ? 11.0 : 12.5;
        _drawText(
          canvas,
          block.title,
          Offset(textLeft, rect.top + 4),
          size: titleSize,
          color: Palette.textPrimary,
          weight: FontWeight.w600,
          maxWidth: textWidth,
          maxLines: rect.height < 34 ? 1 : 2,
        );
        if (rect.height >= 40 && textWidth > 60) {
          _drawText(
            canvas,
            formatRange(block.startMin, block.durationMin),
            Offset(textLeft, rect.top + (rect.height < 56 ? 20 : 22)),
            size: 10,
            color: Palette.textSecondary,
            maxWidth: textWidth,
          );
        }
        if (rect.height >= 62 && placed.isTop && textWidth > 60) {
          final left = deadlineLabel(block, layout.now);
          if (left.isNotEmpty) {
            _drawText(
              canvas,
              '死线$left',
              Offset(textLeft, rect.bottom - 16),
              size: 10,
              color: Palette.top,
              weight: FontWeight.w600,
              maxWidth: textWidth,
            );
          }
        }
        canvas.restore();
      }

      // 底部改时长把手（选中时显示）
      if (selected && rect.height > 30) {
        final handleY = rect.bottom - 4;
        canvas.drawLine(
          Offset(rect.left + 8, handleY),
          Offset(rect.right - 8, handleY),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.5)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
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
      final lane = Lane.byIndex(i);
      final rect = layout.laneRects[i];
      final count = counts[lane] ?? 0;
      final label = count > 0 ? '${lane.label} · $count' : lane.label;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left, 0, rect.width, h - 6),
          const Radius.circular(10),
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
    Color color = Palette.textPrimary,
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

  void _drawBadge(Canvas canvas, String text, Offset at, {required Color bg}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromLTWH(
      at.dx,
      at.dy,
      painter.width + 10,
      painter.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = bg,
    );
    painter.paint(canvas, Offset(at.dx + 5, at.dy + 2));
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) => true;
}
