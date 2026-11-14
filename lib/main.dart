import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'platform/notifications/reminder_scheduler.dart';
import 'platform/window/tray_host.dart';
import 'platform/window/window_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDesktopWindow();

  // 通知插件与时区要在第一帧之前就绪，否则启动那几分钟的提醒排不上
  final scheduler = LocalReminderScheduler();
  await scheduler.init();

  // 桌面端常驻托盘：点 ✕ 只是藏窗口，托盘图标还在
  await TrayHost().install();

  runApp(
    ProviderScope(
      overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
      child: const TntApp(),
    ),
  );
}
