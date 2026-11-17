import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';

/// 手绘图案编辑器：在一个小方格里随便画几笔，保存成 `x,y;x,y|...`（坐标 0..1）。
Future<String?> showDoodleEditor(
  BuildContext context, {
  String initial = '',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _DoodleEditor(initial: initial),
  );
}

class _DoodleEditor extends StatefulWidget {
  const _DoodleEditor({required this.initial});

  final String initial;

  @override
  State<_DoodleEditor> createState() => _DoodleEditorState();
}

class _DoodleEditorState extends State<_DoodleEditor> {
  final List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset>? _current;

  @override
  void initState() {
    super.initState();
    if (widget.initial.trim().isNotEmpty) {
      for (final stroke in widget.initial.split('|')) {
        final points = <Offset>[];
        for (final pair in stroke.split(';')) {
          final parts = pair.split(',');
          if (parts.length != 2) continue;
          final x = double.tryParse(parts[0]);
          final y = double.tryParse(parts[1]);
          if (x == null || y == null) continue;
          points.add(Offset(x, y));
        }
        if (points.length >= 2) _strokes.add(points);
      }
    }
  }

  String _serialize() {
    final parts = <String>[];
    for (final stroke in _strokes) {
      parts.add(stroke.map((p) => '${p.dx.toStringAsFixed(3)},'
          '${p.dy.toStringAsFixed(3)}').join(';'));
    }
    return parts.join('|');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '画个图案',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '在下面方格里按住画，可以画好几笔；画完会缩小显示在圆形标识里',
              style: TextStyle(fontSize: 12, color: Palette.textSecondary),
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox.square(
                dimension: math.min(
                  MediaQuery.sizeOf(context).width - 80,
                  MediaQuery.sizeOf(context).height * 0.46,
                ),
                child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = constraints.maxWidth;
                  return GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _current = <Offset>[
                          Offset(
                            (details.localPosition.dx / side).clamp(0.0, 1.0),
                            (details.localPosition.dy / side).clamp(0.0, 1.0),
                          ),
                        ];
                      });
                    },
                    onPanUpdate: (details) {
                      final point = Offset(
                        (details.localPosition.dx / side).clamp(0.0, 1.0),
                        (details.localPosition.dy / side).clamp(0.0, 1.0),
                      );
                      setState(() => _current?.add(point));
                    },
                    onPanEnd: (_) {
                      setState(() {
                        if (_current != null && _current!.length >= 2) {
                          _strokes.add(_current!);
                        }
                        _current = null;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Palette.laneBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Palette.line),
                      ),
                      child: CustomPaint(
                        painter: _DoodlePainter(_strokes, _current),
                      ),
                    ),
                  );
                },
              ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _strokes.isEmpty
                      ? null
                      : () => setState(() {
                            _strokes.clear();
                            _current = null;
                          }),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('重画'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(''),
                  child: const Text('用回预置图案'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_serialize()),
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter(this.strokes, this.current);

  final List<List<Offset>> strokes;
  final List<Offset>? current;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in <List<Offset>>[...strokes, ?current]) {
      if (stroke.length < 2) continue;
      final path = Path()
        ..moveTo(stroke.first.dx * size.width, stroke.first.dy * size.height);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx * size.width, p.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter old) => true;
}
