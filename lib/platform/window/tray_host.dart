// tray_manager 0.9 的主入口也换成了 nativeapi 风格 API，
// 0.5 时代的 trayManager / TrayListener / Menu(items:) 留在 legacy.dart。
// 原型阶段沿用 legacy：语义一样、写法更短，等 S8 收尾再迁新 API。
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:tray_manager/legacy.dart';
import 'package:window_manager/legacy.dart';

import '../../core/app_log.dart';

/// 桌面端「常驻托盘」的宿主。
///
/// 两个行为：
/// 1. 点标题栏 ✕ 不退出，只是 `hide()`，托盘图标还在；
/// 2. 托盘左键 → 显示主窗口；右键 → 弹菜单（显示主窗口 / 退出）。
///
/// 移动端不启用（[install] 里直接返回）。
class TrayHost with TrayListener, WindowListener {
  TrayHost();

  bool _installed = false;
  bool _quitting = false;

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux);

  /// 装上托盘 + 接管关闭按钮。调用一次即可。
  Future<void> install() async {
    if (!_isDesktop || _installed) return;
    _installed = true;

    try {
      windowManager.addListener(this);
      await windowManager.setPreventClose(true);

      await trayManager.setIcon('assets/tray_icon.png');
      await trayManager.setToolTip('TNT · 一天的时间轴');
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(key: 'show', label: '显示主窗口'),
            MenuItem.separator(),
            MenuItem(key: 'hint', label: '关闭窗口不会退出，点托盘图标可再打开', disabled: true),
            MenuItem.separator(),
            MenuItem(key: 'quit', label: '退出 TNT'),
          ],
        ),
      );
      trayManager.addListener(this);
      await appLog('托盘已就位（图标在任务栏溢出区里，点 ^ 可见）');
    } catch (error) {
      // 托盘失败不影响主功能，但要落盘留痕：
      // 低完整性（沙箱）或权限受限时会走到这里。
      await appLog('托盘初始化失败 -> $error');
    }
  }

  /// 真正退出前调用：撤掉托盘图标，避免托盘区留下幽灵图标。
  Future<void> disposeTray() async {
    if (!_isDesktop) return;
    try {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
      await trayManager.destroy();
    } catch (error) {
      debugPrint('TNT: 托盘清理失败 -> $error');
    }
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quit() async {
    if (_quitting) return;
    _quitting = true;
    await disposeTray();
    await windowManager.destroy();
    exit(0);
  }

  // ── 托盘事件 ──────────────────────────────────────────────
  @override
  void onTrayIconMouseDown() {
    unawaited(_showWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    // Windows 上托盘菜单需要自己弹
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        unawaited(_showWindow());
      case 'quit':
        unawaited(_quit());
    }
  }

  // ── 窗口事件 ──────────────────────────────────────────────
  @override
  void onWindowClose() {
    // setPreventClose(true) 之后关闭请求会被取消，这里改成藏起来
    if (_quitting) return;
    unawaited(windowManager.hide());
  }
}
