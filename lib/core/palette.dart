/// 配色。UI 层的事，domain 不感知颜色。
library;

import 'package:material_ui/material_ui.dart';

import '../domain/models/tblock.dart';

/// 主题：跟随系统 / 强制深色 / 强制浅色。
enum AppThemeMode { system, dark, light }

extension AppThemeModeLabel on AppThemeMode {
  String get label => switch (this) {
    AppThemeMode.system => '跟随系统',
    AppThemeMode.dark => '深色',
    AppThemeMode.light => '浅色',
  };
}

/// 语义色板。
///
/// 这些是**可变静态量**（而不是 const）：切主题时直接换一套值再整树重建，
/// 这样几百处 `Palette.textPrimary` 都不用改。代价是它们不能用在 const
/// 构造函数里 —— 这个约束在代码里已经统一处理了。
class Palette {
  Palette._();

  static bool _light = false;

  static bool get isLight => _light;

  static Color bg = const Color(0xFF0E1014);
  static Color surface = const Color(0xFF151821);
  static Color surfaceHigh = const Color(0xFF1C2029);
  static Color laneBg = const Color(0xFF11141B);
  static Color line = const Color(0xFF242938);
  static Color lineFaint = const Color(0xFF191D26);

  static Color textPrimary = const Color(0xE8FFFFFF);
  static Color textSecondary = const Color(0xFF8C95A8);
  static Color textDim = const Color(0xFF5C6478);
  static Color textOnAccent = const Color(0xFF0B1220);

  static Color accent = const Color(0xFF4C8DFF);

  /// 置顶统一用醒目红，和分类本身的颜色无关
  static Color top = const Color(0xFFFF3B30);

  /// 切主题：只改这一组语义色，其他都用它们推导。
  static void apply(Brightness brightness) {
    _light = brightness == Brightness.light;
    if (_light) {
      bg = const Color(0xFFF6F7FA);
      surface = const Color(0xFFFFFFFF);
      surfaceHigh = const Color(0xFFF0F2F7);
      laneBg = const Color(0xFFF1F3F8);
      line = const Color(0xFFDCE0E8);
      lineFaint = const Color(0xFFE9ECF2);
      textPrimary = const Color(0xDE0B1220);
      textSecondary = const Color(0xFF5C6478);
      textDim = const Color(0xFF8B93A5);
      textOnAccent = const Color(0xFFFFFFFF);
      accent = const Color(0xFF2F6FE4);
      top = const Color(0xFFE0332B);
    } else {
      bg = const Color(0xFF0E1014);
      surface = const Color(0xFF151821);
      surfaceHigh = const Color(0xFF1C2029);
      laneBg = const Color(0xFF11141B);
      line = const Color(0xFF242938);
      lineFaint = const Color(0xFF191D26);
      textPrimary = const Color(0xE8FFFFFF);
      textSecondary = const Color(0xFF8C95A8);
      textDim = const Color(0xFF5C6478);
      textOnAccent = const Color(0xFF0B1220);
      accent = const Color(0xFF4C8DFF);
      top = const Color(0xFFFF3B30);
    }
  }

  static Brightness resolvedBrightness(AppThemeMode mode, Brightness platform) {
    return switch (mode) {
      AppThemeMode.system => platform,
      AppThemeMode.dark => Brightness.dark,
      AppThemeMode.light => Brightness.light,
    };
  }

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
