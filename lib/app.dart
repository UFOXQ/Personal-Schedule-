import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/palette.dart';
import 'features/settings/ui_prefs.dart';
import 'features/settings/ui_scale.dart';
import 'features/timeline/timeline_page.dart';

/// 应用根：主题 + 依赖注入容器
class TntApp extends ConsumerWidget {
  const TntApp({super.key});

  static ThemeData _theme(Brightness brightness) {
    // 先切色板再取色，这样 ThemeData 里的颜色和 Palette 一致
    Palette.apply(brightness);
    final scheme = ColorScheme.fromSeed(
      seedColor: Palette.accent,
      brightness: brightness,
      surface: Palette.surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: Palette.bg,
      splashFactory: InkSparkle.splashFactory,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Palette.surfaceHigh,
        contentTextStyle: TextStyle(color: Palette.textPrimary, fontSize: 13),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        textStyle: TextStyle(color: Palette.textPrimary, fontSize: 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(uiScaleProvider);
    final mode = ref.watch(uiPrefsProvider).themeMode;
    final themeMode = switch (mode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.light => ThemeMode.light,
    };

    return MaterialApp(
      title: 'TNT',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: themeMode,
      // 只放大文字与控件，不动时间轴的 px/分钟
      builder: (context, child) {
        // 真正生效的亮度可能来自系统，这里根据它把色板再切一次
        Palette.apply(Theme.of(context).brightness);
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const TimelinePage(),
    );
  }
}
