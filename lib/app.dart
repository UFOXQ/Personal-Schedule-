import 'package:material_ui/material_ui.dart';

import 'core/palette.dart';
import 'features/timeline/timeline_page.dart';

/// 应用根：深色主题 + 依赖注入容器
class TntApp extends StatelessWidget {
  const TntApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Palette.accent,
      brightness: Brightness.dark,
      surface: Palette.surface,
    );

    return MaterialApp(
      title: 'TNT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: Palette.bg,
        splashFactory: InkSparkle.splashFactory,
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Palette.surfaceHigh,
          contentTextStyle: TextStyle(color: Palette.textPrimary, fontSize: 13),
          behavior: SnackBarBehavior.floating,
        ),
        tooltipTheme: const TooltipThemeData(
          textStyle: TextStyle(color: Palette.textPrimary, fontSize: 11),
        ),
      ),
      home: const TimelinePage(),
    );
  }
}
