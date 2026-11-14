// window_manager 0.7 起主入口换成 nativeapi 风格 API，
// 0.5 时代的 windowManager 单例还留在 legacy.dart 里（已标记 deprecated）。
// 原型阶段先用 legacy，等做托盘/最小化到托盘时再迁到新 API。
// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:window_manager/legacy.dart';

/// 桌面端窗口初始化。移动端直接返回。
Future<void> setupDesktopWindow() async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

  await windowManager.ensureInitialized();

  const options = WindowOptions(
    size: Size(880, 760),
    minimumSize: Size(420, 560),
    center: true,
    title: 'TNT',
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
