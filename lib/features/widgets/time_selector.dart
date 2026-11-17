import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../core/time_utils.dart';
import '../settings/ui_prefs.dart';

/// 弹出「选时间」面板：圆盘 / 滚动数字两种，选好后返回分钟数（0..1439）。
Future<int?> showTimeSelector(
  BuildContext context, {
  required int initialMinute,
  String title = '选个时间',
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _TimeSelectorSheet(initialMinute: initialMinute, title: title),
  );
}

class _TimeSelectorSheet extends ConsumerStatefulWidget {
  const _TimeSelectorSheet({required this.initialMinute, required this.title});

  final int initialMinute;
  final String title;

  @override
  ConsumerState<_TimeSelectorSheet> createState() => _TimeSelectorSheetState();
}

class _TimeSelectorSheetState extends ConsumerState<_TimeSelectorSheet> {
  late int _minute = widget.initialMinute.clamp(0, kMinutesPerDay - 1);

  void _set(int value) {
    setState(() => _minute = value.clamp(0, kMinutesPerDay - 1));
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(uiPrefsProvider);
    final mode = prefs.timePickerMode;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Palette.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  formatMinute(_minute),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Palette.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SegmentedButton<TimePickerMode>(
              segments: const [
                ButtonSegment(
                  value: TimePickerMode.dial,
                  icon: Icon(Icons.access_time, size: 16),
                  label: Text('圆盘'),
                ),
                ButtonSegment(
                  value: TimePickerMode.wheel,
                  icon: Icon(Icons.view_week_outlined, size: 16),
                  label: Text('滚动数字'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (value) => ref
                  .read(uiPrefsProvider.notifier)
                  .setTimePickerMode(value.first),
            ),
            const SizedBox(height: 10),
            if (mode == TimePickerMode.dial)
              _Dial(minute: _minute, onChanged: _set)
            else
              _Wheels(minute: _minute, onChanged: _set),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_minute),
                  child: const Text('用这个时间'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 24 小时一圈的圆盘：拖哪儿指哪儿，整圈 = 一天。
class _Dial extends StatelessWidget {
  const _Dial({required this.minute, required this.onChanged});

  final int minute;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 232,
        height: 232,
        child: GestureDetector(
          onPanDown: (d) => _handle(d.localPosition, 232),
          onPanUpdate: (d) => _handle(d.localPosition, 232),
          child: CustomPaint(painter: _DialPainter(minute)),
        ),
      ),
    );
  }

  void _handle(Offset local, double side) {
    final center = Offset(side / 2, side / 2);
    final v = local - center;
    // 12 点方向为 0 点，顺时针走
    var angle = math.atan2(v.dx, -v.dy);
    if (angle < 0) angle += math.pi * 2;
    final raw = angle / (math.pi * 2) * kMinutesPerDay;
    onChanged(snapMinute(raw.round()));
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.minute);

  final int minute;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Palette.line;
    canvas.drawCircle(center, radius, track);

    // 每 3 小时一个刻度
    for (var h = 0; h < 24; h += 3) {
      final angle = h / 24 * math.pi * 2;
      final from = center + Offset(math.sin(angle), -math.cos(angle)) * (radius - 12);
      final to = center + Offset(math.sin(angle), -math.cos(angle)) * (radius + 2);
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = Palette.textDim
          ..strokeWidth = 1.5,
      );
      final label = h.toString().padLeft(2, '0');
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 10, color: Palette.textDim),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos =
          center + Offset(math.sin(angle), -math.cos(angle)) * (radius - 26);
      painter.paint(canvas, pos - Offset(painter.width / 2, painter.height / 2));
    }

    final angle = minute / kMinutesPerDay * math.pi * 2;
    final hand = Offset(math.sin(angle), -math.cos(angle));
    // 已走过的弧
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      angle,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = Palette.accent,
    );
    canvas.drawLine(
      center,
      center + hand * (radius - 8),
      Paint()
        ..color = Palette.accent
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 4, Paint()..color = Palette.accent);
    final knob = center + hand * (radius - 8);
    canvas.drawCircle(knob, 8, Paint()..color = Palette.accent);
    canvas.drawCircle(knob, 3.4, Paint()..color = Palette.bg);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.minute != minute;
}

/// 两个滚轮：小时 + 分钟（5 分钟一档）。
class _Wheels extends StatefulWidget {
  const _Wheels({required this.minute, required this.onChanged});

  final int minute;
  final ValueChanged<int> onChanged;

  @override
  State<_Wheels> createState() => _WheelsState();
}

class _WheelsState extends State<_Wheels> {
  late int _hour = widget.minute ~/ 60;
  late int _minuteOfHour = widget.minute % 60;

  @override
  Widget build(BuildContext context) {
    final itemHeight = 42.0;
    return SizedBox(
      height: itemHeight * 5,
      child: Row(
        children: [
          Expanded(
            child: _wheel(
              count: 24,
              initial: _hour,
              itemHeight: itemHeight,
              format: (i) => i.toString().padLeft(2, '0'),
              onSelected: (i) {
                _hour = i;
                widget.onChanged(_hour * 60 + _minuteOfHour);
              },
            ),
          ),
          Text(
            ':',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Palette.textSecondary,
            ),
          ),
          Expanded(
            child: _wheel(
              count: 60 ~/ 5,
              initial: _minuteOfHour ~/ 5,
              itemHeight: itemHeight,
              format: (i) => (i * 5).toString().padLeft(2, '0'),
              onSelected: (i) {
                _minuteOfHour = i * 5;
                widget.onChanged(_hour * 60 + _minuteOfHour);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _wheel({
    required int count,
    required int initial,
    required double itemHeight,
    required String Function(int) format,
    required ValueChanged<int> onSelected,
  }) {
    return ListWheelScrollView.useDelegate(
      itemExtent: itemHeight,
      perspective: 0.003,
      diameterRatio: 1.6,
      controller: FixedExtentScrollController(initialItem: initial),
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelected,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) => Center(
          child: Text(
            format(index),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Palette.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
