import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

/// 「现在时刻」标识的款式
enum NowMarkerStyle {
  /// 现在这样：小胶囊里写时间
  pill,

  /// 箭头：一个指向时间轴的三角形 + 时间
  arrow,

  /// 指针：一个圆点加一根细指针
  pointer,

  /// 自定义图案：从几个图标里挑一个（扫把、火箭、猫爪、星星、闹钟）
  icon,
}

extension NowMarkerStyleLabel on NowMarkerStyle {
  String get label => switch (this) {
        NowMarkerStyle.pill => '胶囊',
        NowMarkerStyle.arrow => '箭头',
        NowMarkerStyle.pointer => '指针',
        NowMarkerStyle.icon => '自定义图案',
      };
}

/// 「自定义图案」可选的图标（第一个是扫把，用户点名要的）
const List<IconData> nowMarkerIcons = <IconData>[
  Icons.cleaning_services_outlined,
  Icons.rocket_launch_outlined,
  Icons.pets,
  Icons.star_border,
  Icons.alarm,
];

const List<String> nowMarkerIconNames = <String>[
  '扫把',
  '火箭',
  '猫爪',
  '星星',
  '闹钟',
];


/// 「现在」标识 / 现在线可选的颜色
const List<Color> nowColors = <Color>[
  Color(0xFFFF3B30), // 红
  Color(0xFFFF9500), // 橙
  Color(0xFFFFCC00), // 黄
  Color(0xFF34C759), // 绿
  Color(0xFF3D7BFF), // 蓝
  Color(0xFFAF52DE), // 紫
];

const List<String> nowColorNames = <String>['红', '橙', '黄', '绿', '蓝', '紫'];

/// 把 `doodle`（形如 `x,y;x,y|...`，坐标 0..1）画进 [area] 里。
void paintDoodle(Canvas canvas, Rect area, String doodle, Color color) {
  if (doodle.trim().isEmpty) return;
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.2, area.width * 0.11)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  for (final stroke in doodle.split('|')) {
    final points = <Offset>[];
    for (final pair in stroke.split(';')) {
      final parts = pair.split(',');
      if (parts.length != 2) continue;
      final x = double.tryParse(parts[0]);
      final y = double.tryParse(parts[1]);
      if (x == null || y == null) continue;
      points.add(Offset(area.left + x * area.width, area.top + y * area.height));
    }
    if (points.length < 2) continue;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }
}

