import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../core/time_utils.dart';
import 'timeline_strip.dart';

/// 把时间条画成一张图片（地铁线路图风格）。
///
/// 三端共用这一份绘制：手机通知、Android 小组件、Windows 悬浮条都只是显示这张图，
/// 样式改一次三端全变，不用再维护三套原生绘制。
class StripImage {
  const StripImage({
    required this.width,
    required this.height,
    required this.rgba,
  });

  final int width;
  final int height;

  /// 逐行 RGBA（非预乘），原生侧按自己方便转 ARGB / BGRA
  final Uint8List rgba;

  Map<String, Object?> toJson() => <String, Object?>{
    'width': width,
    'height': height,
    'rgba': base64Encode(rgba),
  };
}


/// 时间条可调样式：文字大小、左右文字是否显示、中间线路占多宽
class StripStyle {
  const StripStyle({
    this.textScale = 1.0,
    this.showLeft = true,
    this.showRight = true,
    this.lineRatio = 1.0,
    this.light = false,
  });

  /// 文字整体缩放（0.8 ~ 1.4）
  final double textScale;

  /// 是否显示左侧「现在做什么 / 没做完」
  final bool showLeft;

  /// 是否显示右侧「接下来」
  final bool showRight;

  /// 中间线路占可用宽度的比例（0.5 ~ 1.0）
  final double lineRatio;

  /// 浅色外观（桌面小组件跟随系统时用）
  final bool light;
}

const Color _progress = Color(0xFF3D7BFF);
const Color _accentNow = Color(0xFFFF3B30);

/// 深色 / 浅色两套用色（小组件跟随系统）
class _Tint {
  const _Tint({
    required this.bg,
    required this.line,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDim,
  });

  final Color bg;
  final Color line;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDim;

  static const dark = _Tint(
    bg: Color(0xFF151821),
    line: Color(0xFF2A3040),
    textPrimary: Color(0xFFEAF0FF),
    textSecondary: Color(0xFF9AA3B8),
    textDim: Color(0xFF6B7488),
  );

  static const light = _Tint(
    bg: Color(0xFFF3F6FC),
    line: Color(0xFFD7DDEA),
    textPrimary: Color(0xFF0B1220),
    textSecondary: Color(0xFF44506B),
    textDim: Color(0xFF6E7891),
  );
}

/// 画出时间条位图。[pixelRatio] 控制清晰度（原生侧按 dp 显示）
Future<StripImage> renderStripImage(
  StripPayload payload, {
  double width = 720,
  double height = 150,
  double pixelRatio = 2.0,
  StripStyle style = const StripStyle(),
}) async {
  final image = await _renderStrip(
    payload,
    width: width,
    height: height,
    pixelRatio: pixelRatio,
    style: style,
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final imageWidth = image.width;
  final imageHeight = image.height;
  image.dispose();
  return StripImage(
    width: imageWidth,
    height: imageHeight,
    rgba: data!.buffer.asUint8List(),
  );
}

/// 同一份绘制输出 PNG：Binder 单次事务扛不住 1.7MB 原始像素，手机端走压缩图
Future<Uint8List> renderStripPng(
  StripPayload payload, {
  double width = 720,
  double height = 150,
  double pixelRatio = 2.0,
  StripStyle style = const StripStyle(),
}) async {
  final image = await _renderStrip(
    payload,
    width: width,
    height: height,
    pixelRatio: pixelRatio,
    style: style,
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Future<ui.Image> _renderStrip(
  StripPayload payload, {
  required double width,
  required double height,
  required double pixelRatio,
  required StripStyle style,
}) async {
  final tint = style.light ? _Tint.light : _Tint.dark;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final w = width * pixelRatio;
  final h = height * pixelRatio;
  canvas.scale(pixelRatio);

  // 背景
  final bgPaint = Paint()..color = tint.bg;
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, height), const Radius.circular(14)),
    bgPaint,
  );

  final current = payload.nowPlaying;
  final upcoming = _upcoming(payload);
  final unfinished = _unfinishedBefore(payload);

  // 左右两栏宽度按比例，中间留给线路；隐藏某一栏时把空间让给线路
  final leftWidth = style.showLeft ? width * 0.30 : 0.0;
  final rightWidth = style.showRight ? width * 0.20 : 0.0;
  var midLeft = leftWidth + (style.showLeft ? 10 : 12);
  var midRight = width - rightWidth - (style.showRight ? 10 : 12);
  final ratio = style.lineRatio.clamp(0.5, 1.0);
  if (ratio < 1.0) {
    final midWidth = midRight - midLeft;
    final targetWidth = midWidth * ratio;
    final center = (midLeft + midRight) / 2;
    midLeft = center - targetWidth / 2;
    midRight = center + targetWidth / 2;
  }

  if (style.showLeft) {
    _paintLeft(
      canvas,
      payload,
      current,
      upcoming,
      unfinished,
      leftWidth,
      style.textScale,
      tint,
    );
  }
  if (style.showRight) {
    _paintRight(canvas, upcoming, width, rightWidth, style.textScale, tint);
  }
  _paintLine(canvas, payload, midLeft, midRight, height, tint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(w.round(), h.round());
  picture.dispose();
  return image;
}

StripSegment? _upcoming(StripPayload payload) {
  for (final segment in payload.segments) {
    if (segment.startMin > payload.nowMin) return segment;
  }
  return null;
}

List<StripSegment> _unfinishedBefore(StripPayload payload) {
  final list = <StripSegment>[];
  for (final segment in payload.segments) {
    if (segment.startMin + segment.durationMin <= payload.nowMin) {
      list.add(segment);
    }
  }
  return list;
}

void _paintLeft(
  Canvas canvas,
  StripPayload payload,
  StripSegment? current,
  StripSegment? upcoming,
  List<StripSegment> unfinished,
  double width,
  double textScale,
  _Tint tint,
) {
  const padLeft = 12.0;
  final ty1 = 14 + (1 - textScale) * 6;
  final ty2 = ty1 + 16 * textScale;
  final ty3 = ty2 + 26 * textScale;
  final textWidth = width - padLeft - 6;

  // 第一行小字：之前还没做完的
  final small = unfinished.isEmpty
      ? '前面都清空了'
      : '没做完 ${unfinished.map((s) => s.title).take(3).join(' · ')}';
  _text(
    canvas,
    small,
    Offset(padLeft, ty1),
    maxWidth: textWidth,
    size: 10.5 * textScale,
    color: unfinished.isEmpty ? tint.textDim : _accentNow.withValues(alpha: 0.9),
  );

  // 主标题：现在做什么（真没有安排就写「现在空闲」）
  final title = current?.title ?? '现在空闲';
  _text(
    canvas,
    title,
    Offset(padLeft, ty2),
    maxWidth: textWidth,
    size: 17 * textScale,
    weight: FontWeight.w700,
    color: tint.textPrimary,
  );

  // 时间：正在做就写它的区间，否则写下一件什么时候开始
  if (current == null && upcoming != null) {
    _text(
      canvas,
      '下一件 ${formatMinute(upcoming.startMin)} · ${upcoming.title}',
      Offset(padLeft, ty3),
      maxWidth: textWidth,
      size: 11 * textScale,
      color: tint.textSecondary,
    );
  }
  if (current != null) {
    _text(
      canvas,
      '${formatMinute(current.startMin)} - ${formatMinute(current.startMin + current.durationMin)}',
      Offset(padLeft, ty3),
      maxWidth: textWidth,
      size: 11 * textScale,
      color: tint.textSecondary,
    );
  }
}

void _paintRight(
  Canvas canvas,
  StripSegment? upcoming,
  double width,
  double rightWidth,
  double textScale,
  _Tint tint,
) {
  final left = width - rightWidth;
  const pad = 2.0;
  final ry1 = 14 + (1 - textScale) * 6;
  final ry2 = ry1 + 16 * textScale;
  final ry3 = ry2 + 22 * textScale;
  final textWidth = rightWidth - pad;

  _text(
    canvas,
    '接下来',
    Offset(left, ry1),
    maxWidth: textWidth,
    size: 10.5 * textScale,
    color: tint.textDim,
  );
  if (upcoming == null) {
    _text(
      canvas,
      '今天结束',
      Offset(left, ry2),
      maxWidth: textWidth,
      size: 14 * textScale,
      weight: FontWeight.w600,
      color: tint.textSecondary,
    );
    return;
  }
  _text(
    canvas,
    upcoming.title,
    Offset(left, ry2),
    maxWidth: textWidth,
    size: 13 * textScale,
    weight: FontWeight.w600,
    color: tint.textPrimary,
  );
  _text(
    canvas,
    formatMinute(upcoming.startMin),
    Offset(left, ry3),
    maxWidth: textWidth,
    size: 11 * textScale,
    color: tint.textSecondary,
  );
}

/// 中间的「地铁线路」：一条主线 + 进度 + 每一站一个圆点
void _paintLine(
  Canvas canvas,
  StripPayload payload,
  double left,
  double right,
  double height,
  _Tint tint,
) {
  final y = height * 0.58;
  final width = right - left;

  // 底轨
  final track = Paint()
    ..color = tint.line
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(left, y), Offset(right, y), track);

  // 线路配色：每一段用自己那件事的颜色，已走过的实一点、还没到的淡一点
  // （像地铁线路图里不同区间用不同颜色，远看能一眼分出几段）
  final ratio = (payload.nowMin / kMinutesPerDay).clamp(0.0, 1.0);
  final nowX = left + width * ratio;
  final ordered = payload.segments.toList()
    ..sort((a, b) => a.startMin.compareTo(b.startMin));
  for (var i = 0; i < ordered.length; i++) {
    final segment = ordered[i];
    final from = left + width * (segment.startMin / kMinutesPerDay).clamp(0.0, 1.0);
    final to = i + 1 < ordered.length
        ? left + width * (ordered[i + 1].startMin / kMinutesPerDay).clamp(0.0, 1.0)
        : right;
    if (to - from < 0.5) continue;
    final base = Color(segment.color);
    final paint = Paint()
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.butt;
    // 已经过去的区间用实色，未来的用 45% 透明
    paint.color = to <= nowX
        ? base
        : (from >= nowX ? base.withValues(alpha: 0.45) : base);
    if (from < nowX && to > nowX) {
      // 跨过「现在」的这一段：前半实、后半淡
      canvas.drawLine(Offset(from, y), Offset(nowX, y), paint);
      paint.color = base.withValues(alpha: 0.45);
      canvas.drawLine(Offset(nowX, y), Offset(to, y), paint);
      continue;
    }
    canvas.drawLine(Offset(from, y), Offset(to, y), paint);
  }
  // 已走过的主干再压一层高亮，强调「进度」
  final progress = Paint()
    ..color = _progress.withValues(alpha: 0.55)
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;
  if (ratio > 0) {
    canvas.drawLine(Offset(left, y), Offset(nowX, y), progress);
  }

  // 每一站
  for (final segment in payload.segments) {
    final x = left + width * (segment.startMin / kMinutesPerDay).clamp(0.0, 1.0);
    final color = Color(segment.color);
    canvas.drawCircle(Offset(x, y), 4.4, Paint()..color = tint.bg);
    canvas.drawCircle(Offset(x, y), 3.4, Paint()..color = color);
    if (segment.isTop) {
      canvas.drawCircle(
        Offset(x, y),
        6.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _accentNow,
      );
    }
  }

  // 现在的位置
  canvas.drawLine(
    Offset(nowX, y - 16),
    Offset(nowX, y + 16),
    Paint()
      ..color = _accentNow
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round,
  );
  canvas.drawCircle(Offset(nowX, y - 18), 3.2, Paint()..color = _accentNow);

  _text(
    canvas,
    formatMinute(payload.nowMin),
    Offset(nowX - 14, y + 20),
    maxWidth: 40,
    size: 9.5,
    weight: FontWeight.w700,
    color: _accentNow,
  );
}

void _text(
  Canvas canvas,
  String value,
  Offset at, {
  required double maxWidth,
  double size = 12,
  Color color = const Color(0xFFEAF0FF),
  FontWeight weight = FontWeight.w500,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: value,
      style: TextStyle(color: color, fontSize: size, fontWeight: weight, height: 1.15),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth < 8 ? 8 : maxWidth);
  painter.paint(canvas, at);
}
