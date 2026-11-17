import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../domain/now_marker.dart';
import 'doodle_editor.dart';
import 'ui_prefs.dart';

/// 「现在时刻」标识的小预览：一条灰线 + 当前款式的标识，用来在设置里挑样式。
class NowMarkerPreview extends StatelessWidget {
  const NowMarkerPreview({
    super.key,
    required this.style,
    this.icon = 0,
    this.colorIndex = 0,
    this.size = 1.0,
    this.right = false,
    this.doodle = '',
    this.width = 132,
    this.height = 40,
  });

  final NowMarkerStyle style;
  final int icon;
  final int colorIndex;
  final double size;
  final bool right;
  final String doodle;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _MarkerPreviewPainter(
          style: style,
          icon: icon,
          colorIndex: colorIndex,
          scale: size,
          right: right,
          doodle: doodle,
        ),
      ),
    );
  }
}

class _MarkerPreviewPainter extends CustomPainter {
  _MarkerPreviewPainter({
    required this.style,
    required this.icon,
    required this.colorIndex,
    required this.scale,
    required this.right,
    required this.doodle,
  });

  final NowMarkerStyle style;
  final int icon;
  final int colorIndex;
  final double scale;
  final bool right;
  final String doodle;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.62;
    final gutter = size.width * (right ? 0.5 : 0.22);
    final color = nowColors[colorIndex.clamp(0, nowColors.length - 1)];
    canvas.drawLine(
      Offset(size.width * 0.16, y),
      Offset(size.width - 4, y),
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    final style0 = TextStyle(
      fontSize: 10 * scale,
      fontWeight: FontWeight.w700,
      color: color,
    );
    final label = '09:30';
    switch (style) {
      case NowMarkerStyle.pill:
        final painter = TextPainter(
          text: TextSpan(text: label, style: style0),
          textDirection: TextDirection.ltr,
        )..layout();
        final rect = Rect.fromLTWH(
          gutter,
          y - painter.height / 2 - 3 * scale,
          painter.width + 10 * scale,
          painter.height + 6 * scale,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(5 * scale)),
          Paint()..color = color,
        );
        painter.paint(
          canvas,
          Offset(rect.left + 5 * scale, y - painter.height / 2),
        );
      case NowMarkerStyle.arrow:
        final path = Path()
          ..moveTo(gutter + 10 * scale, y)
          ..lineTo(gutter + 22 * scale, y - 6 * scale)
          ..lineTo(gutter + 22 * scale, y + 6 * scale)
          ..close();
        canvas.drawPath(path, Paint()..color = color);
        _text(canvas, label, Offset(gutter + 26 * scale, y - 15 * scale), style0);
      case NowMarkerStyle.pointer:
        canvas.drawLine(
          Offset(gutter + 6, y - 8 * scale),
          Offset(gutter + 6, y + 8 * scale),
          Paint()
            ..color = color
            ..strokeWidth = 2 * scale,
        );
        canvas.drawCircle(
          Offset(gutter + 6, y - 9 * scale),
          3 * scale,
          Paint()..color = color,
        );
        _text(canvas, label, Offset(gutter + 14 * scale, y - 17 * scale), style0);
      case NowMarkerStyle.icon:
        final center = Offset(gutter + 8 * scale, y);
        final radius = 10 * scale;
        canvas.drawCircle(center, radius, Paint()..color = color);
        if (doodle.trim().isNotEmpty) {
          paintDoodle(
            canvas,
            Rect.fromCircle(center: center, radius: radius * 0.72),
            doodle,
            Palette.bg,
          );
        } else {
          final glyph = nowMarkerIcons[icon.clamp(0, nowMarkerIcons.length - 1)];
          final painter = TextPainter(
            text: TextSpan(
              text: String.fromCharCode(glyph.codePoint),
              style: TextStyle(
                fontSize: 12 * scale,
                fontFamily: glyph.fontFamily,
                package: glyph.fontPackage,
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
        _text(canvas, label, Offset(gutter + 16 * scale, y - 18 * scale), style0);
    }
  }

  void _text(Canvas canvas, String value, Offset at, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
  }

  @override
  bool shouldRepaint(covariant _MarkerPreviewPainter old) =>
      old.style != style ||
      old.icon != icon ||
      old.colorIndex != colorIndex ||
      old.scale != scale ||
      old.right != right ||
      old.doodle != doodle;
}

/// 弹出「现在时刻标识」面板：四款各带真实预览，下面还能调大小 / 位置 / 颜色 / 线宽 / 图案。
Future<void> showNowMarkerPicker(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Consumer(
        builder: (context, ref, _) {
          final prefs = ref.watch(uiPrefsProvider);
          final notifier = ref.read(uiPrefsProvider.notifier);
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
                  child: Text(
                    '现在时刻标识',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Palette.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    '改哪一项，上面的预览和时间轴都会立刻跟着变',
                    style: TextStyle(fontSize: 12, color: Palette.textSecondary),
                  ),
                ),
                for (final style in NowMarkerStyle.values)
                  InkWell(
                    onTap: () => notifier.setNowMarkerStyle(style),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          NowMarkerPreview(
                            style: style,
                            icon: prefs.nowMarkerIcon,
                            colorIndex: prefs.nowMarkerColorIndex,
                            size: prefs.nowMarkerSize,
                            right: prefs.nowMarkerRight,
                            doodle: prefs.nowMarkerDoodle,
                            width: 150,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              style.label,
                              style: TextStyle(
                                fontSize: 14,
                                color: Palette.textPrimary,
                              ),
                            ),
                          ),
                          if (prefs.nowMarkerStyle == style)
                            Icon(
                              Icons.check,
                              size: 18,
                              color: Palette.accent,
                            ),
                        ],
                      ),
                    ),
                  ),
                Divider(height: 20, color: Palette.line),
                _SliderRow(
                  label: '标识大小',
                  value: prefs.nowMarkerSize,
                  min: 0.7,
                  max: 1.6,
                  display: '${(prefs.nowMarkerSize * 100).round()}%',
                  onChanged: notifier.setNowMarkerSize,
                ),
                _SliderRow(
                  label: '红线粗细',
                  value: prefs.nowLineWidth,
                  min: 1,
                  max: 4,
                  display: prefs.nowLineWidth.toStringAsFixed(1),
                  onChanged: notifier.setNowLineWidth,
                ),
                SwitchListTile(
                  title: Text(
                    '标识放在时间轴右侧',
                    style: TextStyle(fontSize: 14, color: Palette.textPrimary),
                  ),
                  subtitle: Text(
                    '默认在左边时刻栏里；打开后压在泳道上',
                    style: TextStyle(fontSize: 11, color: Palette.textDim),
                  ),
                  value: prefs.nowMarkerRight,
                  onChanged: notifier.setNowMarkerRight,
                ),
                _ColorRow(
                  label: '标识颜色',
                  selected: prefs.nowMarkerColorIndex,
                  onSelected: notifier.setNowMarkerColorIndex,
                ),
                _ColorRow(
                  label: '红线颜色',
                  selected: prefs.nowLineColorIndex,
                  onSelected: notifier.setNowLineColorIndex,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 6),
                  child: Text(
                    '自定义图案',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Palette.textSecondary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < nowMarkerIcons.length; i++)
                        ChoiceChip(
                          label: Text(nowMarkerIconNames[i]),
                          selected:
                              prefs.nowMarkerDoodle.isEmpty &&
                              prefs.nowMarkerIcon == i,
                          onSelected: (_) {
                            notifier.setNowMarkerDoodle('');
                            notifier.setNowMarkerIcon(i);
                          },
                        ),
                      ChoiceChip(
                        avatar: const Icon(Icons.draw_outlined, size: 16),
                        label: const Text('自己画一个'),
                        selected: prefs.nowMarkerDoodle.isNotEmpty,
                        onSelected: (_) async {
                          final doodle = await showDoodleEditor(
                            sheetContext,
                            initial: prefs.nowMarkerDoodle,
                          );
                          if (doodle == null) return;
                          await notifier.setNowMarkerDoodle(doodle);
                          if (doodle.isNotEmpty) {
                            await notifier.setNowMarkerStyle(
                              NowMarkerStyle.icon,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(
                    '图案只在「自定义图案」款式下显示；画的那个会一直留着，可以再改',
                    style: TextStyle(fontSize: 11, color: Palette.textDim),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Palette.textPrimary),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              display,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: Palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Palette.textPrimary),
            ),
          ),
          for (var i = 0; i < nowColors.length; i++)
            GestureDetector(
              onTap: () => onSelected(i),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: nowColors[i],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected == i ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
