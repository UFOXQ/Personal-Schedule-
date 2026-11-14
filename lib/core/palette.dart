/// 配色。UI 层的事，domain 不感知颜色。
library;

import 'package:material_ui/material_ui.dart';

import '../domain/models/tblock.dart';

class Palette {
  Palette._();

  static const Color bg = Color(0xFF0E1014);
  static const Color surface = Color(0xFF151821);
  static const Color surfaceHigh = Color(0xFF1C2029);
  static const Color laneBg = Color(0xFF11141B);
  static const Color line = Color(0xFF242938);
  static const Color lineFaint = Color(0xFF191D26);

  static const Color textPrimary = Color(0xE8FFFFFF);
  static const Color textSecondary = Color(0xFF8C95A8);
  static const Color textDim = Color(0xFF5C6478);

  static const Color accent = Color(0xFF4C8DFF);

  /// 置顶统一用醒目红，和分类本身的颜色无关
  static const Color top = Color(0xFFFF3B30);

  /// 分类基础色
  static Color of(Priority priority) => switch (priority) {
    Priority.a => const Color(0xFFFF5A5F),
    Priority.b => const Color(0xFFFFA657),
    Priority.c => const Color(0xFF5B9DFF),
    Priority.d => const Color(0xFF56C596),
  };

  /// A 与临近死线的 B 都归到 red
  static Color ofBlock(TBlock block, bool isTop) =>
      isTop ? top : of(block.priority);
}
