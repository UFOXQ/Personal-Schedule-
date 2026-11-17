import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/palette.dart';
import '../../domain/models/tblock.dart';
import '../settings/ui_prefs.dart';

/// 首次启动引导：四页，讲清楚「三个泳道 / 怎么改时间 / 提醒与时间条 / 还能从哪改」
Future<void> showOnboarding(
  BuildContext context,
  WidgetRef ref, {
  int initialPage = 0,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => OnboardingPage(
        initialPage: initialPage,
        onDone: () => ref.read(uiPrefsProvider.notifier).setOnboarded(true),
      ),
    ),
  );
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onDone,
    this.initialPage = 0,
  });

  final Future<void> Function() onDone;
  final int initialPage;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _controller =
      PageController(initialPage: widget.initialPage);
  late int _index = widget.initialPage;

  static const List<_Slide> _slides = [
    _Slide(
      title: '一天三层，纵向是时间',
      body: '日常 / 打卡 / 临时三条泳道并排，方块的高度就是时长。'
          '顶上一排是今天最要紧的几件（置顶），红字是快到死线的。',
      icon: Icons.view_column_outlined,
    ),
    _Slide(
      title: '按住才能改，轻点只是选中',
      body: '长按方块拿起来再拖，可以换时间、换泳道、拖到最上面换日期；'
          '拖底边往上收是改时长。轻点只选中，不会误触。',
      icon: Icons.pan_tool_alt_outlined,
    ),
    _Slide(
      title: '整块搬：合集与长期计划',
      body: '底部「库」里把常一起做的事捆成合集（早间流程、晚间收尾），点一下整套投到某天；'
          '长期计划（每天/工作日/周几 的固定安排）会自动出现在对应日子的时间轴上。',
      icon: Icons.library_add_outlined,
    ),
    _Slide(
      title: '不改也能用：提醒 + 时间条',
      body: '设置里打开「到点提醒」，方块开始前会弹通知；'
          '再开「常驻时间条」，通知栏和桌面小组件里会有一条今天的线路图，红线跟着时间走。',
      icon: Icons.notifications_active_outlined,
    ),
    _Slide(
      title: '不确定就先锁上',
      body: '顶栏的锁按下去后只能看不能改，防止口袋里误拖。'
          '觉得哪里别扭：设置里能调主题、字号、泳道、手柄粗细，还能导出备份。',
      icon: Icons.lock_outline,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await widget.onDone();
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_index >= _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _slides.length - 1;
    return Scaffold(
      backgroundColor: Palette.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  '跳过',
                  style: TextStyle(color: Palette.textSecondary),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, index) => _SlideView(
                  slide: _slides[index],
                  index: index,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index ? Palette.accent : Palette.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: SizedBox(
                height: 46,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(last ? '开始用' : '下一步'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.index});

  final _Slide slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Palette.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(slide.icon, size: 30, color: Palette.accent),
          ),
          const SizedBox(height: 26),
          Text(
            slide.title,
            style: TextStyle(
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.body,
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Palette.textSecondary,
            ),
          ),
          const SizedBox(height: 30),
          _Thumb(index: index),
        ],
      ),
    );
  }
}

/// 每页一个小示意图，纯手画，不依赖截图
class _Thumb extends StatelessWidget {
  const _Thumb({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: CustomPaint(painter: _ThumbPainter(index)),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.index);

  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Palette.laneBg;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    canvas.drawRRect(rrect, bg);

    final line = Paint()
      ..color = Palette.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, line);

    switch (index) {
      case 0:
        _lanes(canvas, size);
      case 1:
        _drag(canvas, size);
      case 2:
        _library(canvas, size);
      case 3:
        _strip(canvas, size);
      default:
        _lock(canvas, size);
    }
  }

  void _lanes(Canvas canvas, Size size) {
    final gap = 10.0;
    final width = (size.width - 32 - gap * 2) / 3;
    final colors = [Palette.accent, Palette.of(Priority.b), Palette.of(Priority.c)];
    for (var i = 0; i < 3; i++) {
      final left = 16 + i * (width + gap);
      final lane = Rect.fromLTWH(left, 16, width, size.height - 32);
      canvas.drawRRect(
        RRect.fromRectAndRadius(lane, const Radius.circular(10)),
        Paint()..color = Palette.surface,
      );
      for (var j = 0; j < 3 - i; j++) {
        final block = Rect.fromLTWH(
          left + 6,
          26.0 + j * 38,
          width - 12,
          26,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(block, const Radius.circular(7)),
          Paint()..color = colors[i].withValues(alpha: 0.55),
        );
      }
    }
  }

  void _drag(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // 原位（虚线幽灵框）
    final ghost = RRect.fromRectAndRadius(
      Rect.fromLTWH(30, h - 62, w * 0.34, 40),
      const Radius.circular(9),
    );
    canvas.drawRRect(
      ghost,
      Paint()..color = Palette.accent.withValues(alpha: 0.10),
    );
    _dashedRRect(canvas, ghost, Palette.textDim.withValues(alpha: 0.55));

    // 拿起来的样子
    final block = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.42, 26, w * 0.36, 60),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      block,
      Paint()..color = Palette.accent.withValues(alpha: 0.45),
    );
    canvas.drawRRect(
      block,
      Paint()
        ..color = Palette.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 上下把手（选中时真实 UI 里出现的小抽屉）
    for (final dy in [-9.0, 69.0]) {
      final pill = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(block.center.dx, block.top + dy),
          width: 26,
          height: 8,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(pill, Paint()..color = Palette.surface);
      canvas.drawRRect(
        pill,
        Paint()
          ..color = Palette.accent
          ..style = PaintingStyle.stroke,
      );
    }

    // 从原位拖到新位置的虚线箭头
    final from = Offset(ghost.right + 4, ghost.center.dy);
    final to = Offset(block.left - 10, block.bottom - 6);
    final arrow = Paint()
      ..color = Palette.accent.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(
        (from.dx + to.dx) / 2,
        from.dy - 34,
        to.dx,
        to.dy,
      );
    canvas.drawPath(path, arrow);
    final head = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - 7, to.dy - 5)
      ..lineTo(to.dx - 6, to.dy + 4)
      ..close();
    canvas.drawPath(head, Paint()..color = Palette.accent.withValues(alpha: 0.85));
  }

  void _dashedRRect(Canvas canvas, RRect rrect, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + 5).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 4;
      }
    }
  }

  /// 合集（左上两张卡）→ 拖/点 → 落到今天的时间轴（右下）
  void _library(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cardW = w * 0.40;
    final cardH = h * 0.26;

    void card(double top, String label, double count) {
      final rect = Rect.fromLTWH(14, top, cardW, cardH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()..color = Palette.surface,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        Paint()
          ..color = Palette.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      // 左侧色条
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left + 8, rect.top + 8, 4, cardH - 16),
          const Radius.circular(2),
        ),
        Paint()..color = Palette.accent.withValues(alpha: 0.8),
      );
      // 标题与条数用色块示意（不画字，保持和其它页一致）
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left + 18, rect.top + 10, cardW * 0.45, 8),
          const Radius.circular(4),
        ),
        Paint()..color = Palette.textSecondary.withValues(alpha: 0.55),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left + 18, rect.top + 24, cardW * 0.25, 6),
          const Radius.circular(3),
        ),
        Paint()..color = Palette.textDim.withValues(alpha: 0.5),
      );
      // 右下角「投入」小胶囊
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.right - 46, rect.bottom - 20, 38, 12),
          const Radius.circular(6),
        ),
        Paint()..color = Palette.accent.withValues(alpha: 0.28),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.right - 44, rect.bottom - 18, count, 8),
          const Radius.circular(4),
        ),
        Paint()..color = Palette.accent,
      );
    }

    card(14, 'a', 10);
    card(14 + cardH + 10, 'b', 14);

    // 中间箭头
    final arrow = Paint()
      ..color = Palette.accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final x0 = 14 + cardW + 10;
    final y0 = h * 0.5;
    canvas.drawLine(Offset(x0, y0), Offset(x0 + 18, y0), arrow);
    canvas.drawLine(
      Offset(x0 + 18, y0),
      Offset(x0 + 12, y0 - 5),
      arrow,
    );
    canvas.drawLine(
      Offset(x0 + 18, y0),
      Offset(x0 + 12, y0 + 5),
      arrow,
    );

    // 右边：今天的时间轴（两根泳道 + 三个块）
    final laneX = x0 + 26;
    final laneW = w - laneX - 14;
    for (var i = 0; i < 2; i++) {
      final rect = Rect.fromLTWH(
        laneX,
        16 + i * (h * 0.42 + 8),
        laneW,
        h * 0.42,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(9)),
        Paint()..color = Palette.surface,
      );
      for (var j = 0; j < 2; j++) {
        final block = Rect.fromLTWH(
          rect.left + 8,
          rect.top + 10 + j * 26,
          (laneW - 16) * 0.8,
          18,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(block, const Radius.circular(6)),
          Paint()
            ..color = (i == 0 ? Palette.accent : Palette.of(Priority.b))
                .withValues(alpha: 0.5),
        );
      }
    }
  }

  void _strip(Canvas canvas, Size size) {
    final y = size.height * 0.55;
    canvas.drawLine(
      Offset(24, y),
      Offset(size.width - 24, y),
      Paint()
        ..color = Palette.line
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    final done = size.width * 0.45;
    canvas.drawLine(
      Offset(24, y),
      Offset(24 + done, y),
      Paint()
        ..color = Palette.accent
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 4; i++) {
      final x = 24 + done * i / 3;
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Palette.surface);
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = Palette.accent
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.drawCircle(
      Offset(24 + done, y),
      5,
      Paint()..color = Palette.top,
    );
  }

  void _lock(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      34,
      Paint()..color = Palette.top.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center,
      34,
      Paint()
        ..color = Palette.top
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center.translate(0, 4), width: 22, height: 18),
      const Radius.circular(4),
    );
    canvas.drawRRect(body, Paint()..color = Palette.top);
    final shackle = Paint()
      ..color = Palette.top
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(
      Rect.fromCenter(center: center.translate(0, -8), width: 16, height: 18),
      3.14159,
      3.14159,
      false,
      shackle,
    );
  }

  @override
  bool shouldRepaint(covariant _ThumbPainter oldDelegate) =>
      oldDelegate.index != index;
}
